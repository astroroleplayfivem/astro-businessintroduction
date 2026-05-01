Config = {}

Config.Debug = false
Config.Command = 'businessdirectory'
Config.AdminCommand = 'businessdirectoryadmin'
Config.UseTarget = true
Config.InteractDistance = 2.0
Config.TargetIcon = 'fas fa-building'
Config.TargetLabel = 'Open Business Directory'
Config.Ped = {
    model = 'a_m_y_business_03',
    coords = vec4(-1291.97, 289.82, 64.81, 247.95),
    scenario = 'WORLD_HUMAN_CLIPBOARD'
}

Config.AdminPermissions = { 'god', 'admin' }
Config.DefaultImage = 'https://cdn.discordapp.com/attachments/000000000000000000/000000000000000000/business_placeholder.png'
Config.StarterMessage = 'Visit the Location to apply for a job at the door!'
Config.OnlyDiscordImages = true
Config.AllowedImageHosts = {
    'cdn.discordapp.com',
    'media.discordapp.net'
}

Config.Categories = {
    'Food',
    'Nightlife',
    'Mechanic',
    'Retail',
    'Services',
    'Medical',
    'Legal',
    'Government',
    'Other'
}

Config.Blip = {
    enabled = false,
    sprite = 280,
    color = 3,
    scale = 0.75,
    name = 'Business Directory'
}
