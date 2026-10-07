Config = {}

Config.Framework = 'esx'
Config.ResourceName = 'bergischland_cctv'

Config.AdminGroups = {
    'admin',
    'superadmin'
}

Config.PoliceJobs = {
    police = 0,
    sheriff = 0,
    fib = 0
}

Config.JobAccess = {
    police = true,
    fib = true,
    sheriff = true,
    ambulance = false,
    fire = false
}

Config.CameraTypes = {
    'police',
    'business',
    'gas_station',
    'bank',
    'public',
    'private',
    'custom'
}

Config.DefaultRecordingMinutes = 30
Config.DefaultRange = 35
Config.DefaultFov = 70
Config.MaxCameraDistance = 150.0
Config.MaxCameras = 250
Config.EnableDiscordLogs = false
Config.DiscordWebhook = ''
Config.Debug = false

Config.LastActionLog = {}
