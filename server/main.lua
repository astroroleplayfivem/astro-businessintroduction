local RESOURCE_NAME = GetCurrentResourceName()
local DATA_FILE = 'data/businesses.json'

local QBCore = exports['qb-core']:GetCoreObject()
local Businesses = {}

local function debugPrint(...)
    if Config.Debug then
        print(('^3[%s]^7'):format(RESOURCE_NAME), ...)
    end
end

local function trim(value)
    return tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', '')
end

local function isDiscordImageUrl(url)
    url = trim(url)
    if url == '' then
        return false
    end

    local lowered = url:lower()
    if not (lowered:find('^https://') or lowered:find('^http://')) then
        return false
    end

    local host = lowered:match('^https?://([^/%?]+)')
    if not host then
        return false
    end

    local allowed = false
    for _, domain in ipairs(Config.AllowedImageHosts or {}) do
        if host == domain or host:sub(-( #domain + 1)) == '.' .. domain then
            allowed = true
            break
        end
    end

    if not allowed then
        return false
    end

    return lowered:find('%.png') or lowered:find('%.jpg') or lowered:find('%.jpeg') or lowered:find('%.webp') or lowered:find('%.gif')
end

local function hasAdminAccess(src)
    if src == 0 then
        return true
    end

    if not QBCore or not QBCore.Functions or not QBCore.Functions.HasPermission then
        return false
    end

    for _, permission in ipairs(Config.AdminPermissions or { 'god', 'admin' }) do
        if QBCore.Functions.HasPermission(src, permission) then
            return true
        end
    end

    return false
end

local function validateImage(url)
    url = trim(url)
    if url == '' then
        return Config.DefaultImage
    end

    if Config.OnlyDiscordImages and not isDiscordImageUrl(url) then
        return nil
    end

    return url
end

local function ensureBusinessShape(entry)
    local label = trim(entry.label)
    local id = trim(entry.id):lower():gsub('[^%w_%- ]', ''):gsub('%s+', '_')

    if id == '' then
        id = label:lower():gsub('[^%w_%- ]', ''):gsub('%s+', '_')
    end

    if id == '' then
        id = ('business_%s'):format(math.random(10000, 99999))
    end

    local image = validateImage(entry.image or entry.banner or '')
    if not image then
        return nil, 'Business image must be a direct Discord CDN image link.'
    end

    local coords = entry.coords or {}

    return {
        id = id,
        label = label ~= '' and label or 'Unnamed Business',
        category = trim(entry.category) ~= '' and trim(entry.category) or 'Other',
        owner = trim(entry.owner) ~= '' and trim(entry.owner) or 'Unassigned',
        contact = trim(entry.contact) ~= '' and trim(entry.contact) or 'N/A',
        location = trim(entry.location) ~= '' and trim(entry.location) or 'Unknown',
        status = trim(entry.status) ~= '' and trim(entry.status) or 'Open',
        hiring = entry.hiring == true,
        description = trim(entry.description),
        applyText = trim(entry.applyText) ~= '' and trim(entry.applyText) or Config.StarterMessage,
        image = image,
        coords = {
            x = tonumber(coords.x) or 0.0,
            y = tonumber(coords.y) or 0.0,
            z = tonumber(coords.z) or 0.0,
        },
        updatedAt = os.time()
    }
end

local function findBusinessIndex(id)
    id = tostring(id or '')
    for index, business in ipairs(Businesses) do
        if business.id == id then
            return index
        end
    end
    return nil
end

local function loadBusinesses()
    local raw = LoadResourceFile(RESOURCE_NAME, DATA_FILE)
    if not raw or raw == '' then
        Businesses = {}
        SaveResourceFile(RESOURCE_NAME, DATA_FILE, '[]', -1)
        return
    end

    local decoded = json.decode(raw)
    if type(decoded) ~= 'table' then
        print(('^1[%s] Failed to decode %s, resetting.^7'):format(RESOURCE_NAME, DATA_FILE))
        Businesses = {}
        SaveResourceFile(RESOURCE_NAME, DATA_FILE, '[]', -1)
        return
    end

    Businesses = {}
    for _, entry in ipairs(decoded) do
        local business = ensureBusinessShape(entry)
        if business then
            table.insert(Businesses, business)
        end
    end

    debugPrint(('Loaded %s businesses'):format(#Businesses))
end

local function saveBusinesses()
    SaveResourceFile(RESOURCE_NAME, DATA_FILE, json.encode(Businesses, { indent = true }), -1)
end

lib.callback.register('businessintroduction:server:getState', function(source)
    return {
        businesses = Businesses,
        isAdmin = hasAdminAccess(source),
        categories = Config.Categories,
        defaultImage = Config.DefaultImage,
        starterMessage = Config.StarterMessage,
        adminPermissions = Config.AdminPermissions or { 'god', 'admin' }
    }
end)

RegisterNetEvent('businessintroduction:server:saveBusiness', function(payload)
    local src = source
    if not hasAdminAccess(src) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'No permission.' })
        return
    end

    if type(payload) ~= 'table' then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Invalid business payload.' })
        return
    end

    local business, err = ensureBusinessShape(payload)
    if not business then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = err or 'Could not save business.' })
        return
    end

    local existingIndex = findBusinessIndex(business.id)
    if existingIndex then
        Businesses[existingIndex] = business
    else
        table.insert(Businesses, business)
    end

    saveBusinesses()
    TriggerClientEvent('businessintroduction:client:syncBusinesses', -1, Businesses)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('Saved %s.'):format(business.label) })
end)

RegisterNetEvent('businessintroduction:server:deleteBusiness', function(id)
    local src = source
    if not hasAdminAccess(src) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'No permission.' })
        return
    end

    local index = findBusinessIndex(id)
    if not index then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Business not found.' })
        return
    end

    local label = Businesses[index].label
    table.remove(Businesses, index)
    saveBusinesses()
    TriggerClientEvent('businessintroduction:client:syncBusinesses', -1, Businesses)
    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = ('Deleted %s.'):format(label) })
end)

RegisterNetEvent('businessintroduction:server:setWaypoint', function(id)
    local src = source
    local index = findBusinessIndex(id)
    if not index then
        return
    end

    local coords = Businesses[index].coords or {}
    TriggerClientEvent('businessintroduction:client:setWaypoint', src, coords, Businesses[index].label)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= RESOURCE_NAME then
        return
    end
    loadBusinesses()
end)
