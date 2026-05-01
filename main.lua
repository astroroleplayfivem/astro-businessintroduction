local spawnedPed = nil
local uiOpen = false
local lastState = nil

local function notify(msg, ntype)
    lib.notify({
        description = msg,
        type = ntype or 'inform'
    })
end

local function setNui(open, focus)
    uiOpen = open
    SetNuiFocus(focus, focus)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = 'toggle', state = open })
end

local function fetchState()
    lastState = lib.callback.await('businessintroduction:server:getState', false)
    return lastState
end

local function openDirectory(mode)
    local state = fetchState() or {}
    setNui(true, true)
    SendNUIMessage({
        action = 'loadState',
        businesses = state.businesses or {},
        isAdmin = state.isAdmin == true,
        categories = state.categories or Config.Categories,
        defaultImage = state.defaultImage or Config.DefaultImage,
        starterMessage = state.starterMessage or Config.StarterMessage,
        mode = mode == 'admin' and 'admin' or 'public',
        adminPermissions = state.adminPermissions or Config.AdminPermissions
    })
end

local function loadModel(model)
    local hash = joaat(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(0)
    end
    return hash
end

local function removePedTarget()
    if not DoesEntityExist(spawnedPed) then return end

    if GetResourceState('ox_target') == 'started' then
        pcall(function()
            exports.ox_target:removeLocalEntity(spawnedPed, { 'businessintroduction_open' })
        end)
    end
end

local function spawnPed()
    if DoesEntityExist(spawnedPed) then
        removePedTarget()
        DeleteEntity(spawnedPed)
        spawnedPed = nil
    end

    local pedData = Config.Ped
    local hash = loadModel(pedData.model)
    spawnedPed = CreatePed(0, hash, pedData.coords.x, pedData.coords.y, pedData.coords.z - 1.0, pedData.coords.w, false, false)
    SetEntityInvincible(spawnedPed, true)
    SetBlockingOfNonTemporaryEvents(spawnedPed, true)
    FreezeEntityPosition(spawnedPed, true)

    if pedData.scenario and pedData.scenario ~= '' then
        TaskStartScenarioInPlace(spawnedPed, pedData.scenario, 0, true)
    end

    if Config.UseTarget then
        if GetResourceState('ox_target') == 'started' then
            exports.ox_target:addLocalEntity(spawnedPed, {
                {
                    name = 'businessintroduction_open',
                    icon = Config.TargetIcon,
                    label = Config.TargetLabel,
                    distance = Config.InteractDistance,
                    onSelect = function()
                        openDirectory('public')
                    end
                }
            })
        elseif GetResourceState('qb-target') == 'started' then
            exports['qb-target']:AddTargetEntity(spawnedPed, {
                options = {
                    {
                        icon = Config.TargetIcon,
                        label = Config.TargetLabel,
                        action = function()
                            openDirectory('public')
                        end
                    }
                },
                distance = Config.InteractDistance
            })
        end
    end

    if Config.Blip.enabled then
        local blip = AddBlipForCoord(pedData.coords.x, pedData.coords.y, pedData.coords.z)
        SetBlipSprite(blip, Config.Blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.Blip.scale)
        SetBlipColour(blip, Config.Blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(Config.Blip.name)
        EndTextCommandSetBlipName(blip)
    end

    SetModelAsNoLongerNeeded(hash)
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(1000)
    spawnPed()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    Wait(500)
    spawnPed()
end)

RegisterNetEvent('businessintroduction:client:syncBusinesses', function(businesses)
    if uiOpen then
        SendNUIMessage({ action = 'syncBusinesses', businesses = businesses or {} })
    end
end)

RegisterNetEvent('businessintroduction:client:setWaypoint', function(coords, label)
    if not coords then return end
    SetNewWaypoint((coords.x or 0.0) + 0.0, (coords.y or 0.0) + 0.0)
    notify(('GPS set to %s.'):format(label or 'business'), 'success')
end)

RegisterCommand(Config.Command, function()
    openDirectory('public')
end, false)

RegisterCommand(Config.AdminCommand, function()
    openDirectory('admin')
end, false)

RegisterNUICallback('close', function(_, cb)
    setNui(false, false)
    cb('ok')
end)

RegisterNUICallback('saveBusiness', function(data, cb)
    TriggerServerEvent('businessintroduction:server:saveBusiness', data)
    cb('ok')
end)

RegisterNUICallback('deleteBusiness', function(data, cb)
    TriggerServerEvent('businessintroduction:server:deleteBusiness', data.id)
    cb('ok')
end)

RegisterNUICallback('setWaypoint', function(data, cb)
    TriggerServerEvent('businessintroduction:server:setWaypoint', data.id)
    cb('ok')
end)

CreateThread(function()
    if LocalPlayer.state.isLoggedIn then
        Wait(1000)
        spawnPed()
    end
end)
