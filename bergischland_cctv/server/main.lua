CCTV = CCTV or {}
CCTV.Server = CCTV.Server or {}

local function logAction(category, message)
    print(('[CCTV][%s] %s'):format(category, message))

    if Config.EnableDiscordLogs and Config.DiscordWebhook and Config.DiscordWebhook ~= '' then
        PerformHttpRequest(Config.DiscordWebhook, function(err, text, headers) end, 'POST', json.encode({
            username = 'CCTV Logs',
            content = ('[%s] %s'):format(category, message)
        }), {
            ['Content-Type'] = 'application/json'
        })
    end
end

local function sendMenuPayload(src)
    TriggerClientEvent('cctv:client:openMenu', src, {
        dashboard = CCTV.Cameras and CCTV.Cameras.GetDashboardData() or {},
        cameras = CCTV.Cameras and CCTV.Cameras.GetAll() or {},
        evidence = CCTV.Evidence and CCTV.Evidence.GetAll() or {}
    })
end

local function buildSystemPayload(src)
    return {
        type = 'system',
        dashboard = CCTV.Cameras and CCTV.Cameras.GetDashboardData() or {},
        cameras = CCTV.Cameras and CCTV.Cameras.GetAll() or {},
        evidence = CCTV.Evidence and CCTV.Evidence.GetAll() or {}
    }
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    if MySQL then
        CCTV.Cameras.Load()
    else
        print('[CCTV] MySQL resource not ready yet. Please ensure oxmysql is started.')
    end
end)

RegisterNetEvent('cctv:server:requestData', function()
    local src = source
    if not CCTV.Permissions.canViewCameras(src) then
        return
    end

    TriggerClientEvent('cctv:client:receiveData', src, buildSystemPayload(src))
end)

RegisterNetEvent('cctv:server:openCamera', function(cameraId)
    local src = source
    if not CCTV.Permissions.canViewCameras(src) then
        return
    end

    local camera = CCTV.Cameras.GetById(cameraId)
    if not camera then
        return
    end

    TriggerClientEvent('cctv:client:openCameraView', src, camera)
    logAction('POLICE', ('%s opened camera #%s'):format(GetPlayerName(src), cameraId))
end)

RegisterNetEvent('cctv:server:createCamera', function(data)
    local src = source
    if not CCTV.Permissions.canManageCameras(src) then
        return
    end

    local ok, message = CCTV.Cameras.Create(data, GetPlayerName(src))
    TriggerClientEvent('cctv:client:receiveData', src, {
        type = 'message',
        success = ok,
        message = message,
        cameras = CCTV.Cameras.GetAll(),
        dashboard = CCTV.Cameras.GetDashboardData(),
    })

    if ok then
        logAction('ADMIN', ('%s created camera %s'):format(GetPlayerName(src), data and data.name or 'unknown'))
    end
end)

RegisterNetEvent('cctv:server:deleteCamera', function(cameraId)
    local src = source
    if not CCTV.Permissions.canManageCameras(src) then
        return
    end

    local ok, message = CCTV.Cameras.Delete(cameraId)
    TriggerClientEvent('cctv:client:receiveData', src, {
        type = 'message',
        success = ok,
        message = message,
        cameras = CCTV.Cameras.GetAll(),
        dashboard = CCTV.Cameras.GetDashboardData(),
    })

    if ok then
        logAction('ADMIN', ('%s deleted camera #%s'):format(GetPlayerName(src), cameraId))
    end
end)

RegisterNetEvent('cctv:server:updateCamera', function(cameraId, updates)
    local src = source
    if not CCTV.Permissions.canManageCameras(src) then
        return
    end

    local ok, message = CCTV.Cameras.Update(cameraId, updates)
    TriggerClientEvent('cctv:client:receiveData', src, {
        type = 'message',
        success = ok,
        message = message,
        cameras = CCTV.Cameras.GetAll(),
        dashboard = CCTV.Cameras.GetDashboardData(),
    })
end)

RegisterNetEvent('cctv:server:saveEvidence', function(payload)
    local src = source
    if not CCTV.Permissions.hasPoliceAccess(src) and not CCTV.Permissions.hasAdminAccess(src) then
        return
    end

    if not payload or not payload.recordingId then
        return
    end

    local ok, message = CCTV.Evidence.Create(payload.recordingId, CCTV.Permissions.getIdentifier(src), GetPlayerName(src), payload.caseNumber, payload.reason)
    TriggerClientEvent('cctv:client:receiveData', src, {
        type = 'message',
        success = ok,
        message = message,
        evidence = CCTV.Evidence.GetAll(),
    })

    if ok then
        logAction('POLICE', ('%s secured evidence for recording #%s'):format(GetPlayerName(src), payload.recordingId))
    end
end)

RegisterNetEvent('cctv:server:markDamaged', function(cameraId)
    local src = source
    if not CCTV.Permissions.canManageCameras(src) then
        return
    end

    local camera = CCTV.Cameras.GetById(cameraId)
    if not camera then
        return
    end

    CCTV.Cameras.Update(cameraId, { status = 'DAMAGED' })
    CCTV.Recordings.MarkDestroyed(cameraId, os.date('!%Y-%m-%d %H:%M:%S'))
    logAction('SYSTEM', ('Camera #%s was destroyed'):format(cameraId))
    TriggerClientEvent('cctv:client:receiveData', src, { type = 'damage', success = true, camera = cameraId })
end)

RegisterCommand('cctv', function(source)
    if not CCTV.Permissions.canViewCameras(source) then
        TriggerClientEvent('chat:addMessage', source, {
            args = {'^1CCTV', 'You do not have permission to access the CCTV system.'}
        })
        return
    end

    sendMenuPayload(source)
end, false)

RegisterCommand('cctvadmin', function(source)
    if not CCTV.Permissions.hasAdminAccess(source) then
        TriggerClientEvent('chat:addMessage', source, {
            args = {'^1CCTV', 'Admin access required.'}
        })
        return
    end

    sendMenuPayload(source)
end, false)

RegisterCommand('cctvcreate', function(source)
    if not CCTV.Permissions.canManageCameras(source) then
        return
    end

    TriggerClientEvent('cctv:client:openMenu', source, {
        dashboard = CCTV.Cameras and CCTV.Cameras.GetDashboardData() or {},
        cameras = CCTV.Cameras and CCTV.Cameras.GetAll() or {},
        evidence = CCTV.Evidence and CCTV.Evidence.GetAll() or {},
        createMode = true,
    })
end, false)

RegisterCommand('cctvdelete', function(source, args)
    if not CCTV.Permissions.canManageCameras(source) then
        return
    end

    local cameraId = tonumber(args[1])
    if not cameraId then
        TriggerClientEvent('chat:addMessage', source, {
            args = {'^1CCTV', 'Usage: /cctvdelete [id]'}
        })
        return
    end

    CCTV.Cameras.Delete(cameraId)
    logAction('ADMIN', ('%s deleted camera #%s'):format(GetPlayerName(source), cameraId))
end, false)

RegisterCommand('cctvdebug', function(source)
    if not CCTV.Permissions.hasAdminAccess(source) then
        return
    end

    print('[CCTV][DEBUG] Total cameras:', #((CCTV.Cameras and CCTV.Cameras.GetAll()) or {}))
    TriggerClientEvent('chat:addMessage', source, {
        args = {'^3CCTV', 'Debug output sent to server console.'}
    })
end, false)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000)
        if MySQL then
            if not CCTV.Cameras or not CCTV.Cameras.GetAll then
                CCTV.Cameras.Load()
            end
        end
    end
end)
