CCTV = CCTV or {}
CCTV.Server = CCTV.Server or {}

local function debugLog(message)
    if Config and Config.Debug then
        print(('[CCTV] %s'):format(message))
    end
end

local function logAction(category, message)
    print(('[CCTV][%s] %s'):format(category, message))

    if Config and Config.EnableDiscordLogs and Config.DiscordWebhook and Config.DiscordWebhook ~= '' then
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

local function isAuthorized(src)
    if not src or src <= 0 then
        return false
    end

    if CCTV.Permissions and (CCTV.Permissions.hasPoliceAccess(src) or CCTV.Permissions.hasAdminAccess(src)) then
        return true
    end

    return false
end

local function openMenuForPlayer(src)
    if not src or src <= 0 then
        return false
    end

    local payload = {
        dashboard = CCTV.Cameras and CCTV.Cameras.GetDashboardData() or {},
        cameras = CCTV.Cameras and CCTV.Cameras.GetAll() or {},
        evidence = CCTV.Evidence and CCTV.Evidence.GetAll() or {}
    }

    TriggerClientEvent('cctv:client:openMenu', src, payload)
    return true
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    debugLog('Resource gestartet')
    if MySQL then
        CCTV.Cameras.Load()
        if CCTV.Terminals and CCTV.Terminals.Load then
            CCTV.Terminals.Load()
        end
    else
        print('[CCTV] MySQL resource not ready yet. Please ensure oxmysql is started.')
    end
end)

RegisterNetEvent('cctv:server:requestOpenMenu', function()
    local src = source

    if Config and Config.Debug then
        print(('[CCTV] /bgcctv wurde ausgeführt'))
        print(('[CCTV] Spieler: %s'):format(GetPlayerName(src)))
        if ESX and ESX.GetPlayerFromId then
            local xPlayer = ESX.GetPlayerFromId(src)
            if xPlayer and xPlayer.job then
                print(('[CCTV] Job: %s'):format(tostring(xPlayer.job.name)))
                print(('[CCTV] Grade: %s'):format(tostring(xPlayer.job.grade)))
            end
        end
    end

    if not isAuthorized(src) then
        TriggerClientEvent('chat:addMessage', src, {
            args = {'^1CCTV', 'Du hast keinen Zugriff auf das CCTV-System.'}
        })
        TriggerClientEvent('cctv:client:closeMenu', src)
        if Config and Config.Debug then
            print(('[CCTV ERROR] Keine Berechtigung für %s'):format(GetPlayerName(src)))
        end
        return
    end

    if Config and Config.Debug then
        print(('[CCTV] Permission: TRUE'))
        print(('[CCTV] Sende Open Event'))
    end

    local opened = openMenuForPlayer(src)
    if opened then
        if CCTV.Terminals and CCTV.Terminals.SendToClient then
            CCTV.Terminals.SendToClient(src)
        end
        if Config and Config.Debug then
            print(('[CCTV] NUI Open Message gesendet'))
        end
        return
    end

    TriggerClientEvent('chat:addMessage', src, {
        args = {'^1CCTV', 'CCTV-System konnte nicht geöffnet werden.'}
    })
    if Config and Config.Debug then
        print('[CCTV ERROR] NUI Open konnte nicht verarbeitet werden')
    end
end)

RegisterNetEvent('cctv:server:requestData', function()
    local src = source
    if not isAuthorized(src) then
        return
    end

    TriggerClientEvent('cctv:client:receiveData', src, buildSystemPayload(src))
end)

RegisterNetEvent('cctv:server:openCamera', function(cameraId)
    local src = source
    if not isAuthorized(src) then
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
    if not isAuthorized(src) then
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

RegisterCommand('bgcctv', function(source)
    if not source or source <= 0 then
        return
    end

    if not isAuthorized(source) then
        TriggerClientEvent('chat:addMessage', source, {
            args = {'^1CCTV', 'Du hast keinen Zugriff auf das CCTV-System.'}
        })
        TriggerClientEvent('cctv:client:closeMenu', source)
        if Config and Config.Debug then
            print(('[CCTV ERROR] Keine Berechtigung für /bgcctv: %s'):format(GetPlayerName(source)))
        end
        return
    end

    if Config and Config.Debug then
        print(('[CCTV] /bgcctv wurde ausgeführt'))
        print(('[CCTV] Spieler: %s'):format(GetPlayerName(source)))
    end

    TriggerClientEvent('cctv:server:requestOpenMenu', source)
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

RegisterCommand('bgcctvadmin', function(source)
    if not CCTV.Permissions.hasAdminAccess(source) then
        TriggerClientEvent('chat:addMessage', source, {
            args = {'^1CCTV', 'Admin access required.'}
        })
        return
    end

    TriggerClientEvent('cctv:server:requestOpenMenu', source)
end, false)

RegisterCommand('bgcctvterminal', function(source)
    if not CCTV.Permissions.hasAdminAccess(source) then
        TriggerClientEvent('chat:addMessage', source, {
            args = {'^1CCTV', 'Admin access required.'}
        })
        return
    end

    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local success, message = CCTV.Terminals.Create({
        name = ('Terminal #%d'):format((#(CCTV.Terminals.GetAll()) + 1)),
        type = 'police',
        x = coords.x,
        y = coords.y,
        z = coords.z,
        heading = heading,
        job = 'police',
        created_by = GetPlayerName(source),
    }, GetPlayerName(source))

    TriggerClientEvent('chat:addMessage', source, {
        args = {'^3CCTV', success and message or 'Terminal konnte nicht erstellt werden.'}
    })
end, false)

RegisterCommand('bgcctvterminals', function(source)
    if not CCTV.Permissions.hasAdminAccess(source) then
        return
    end

    local terminals = CCTV.Terminals.GetAll()
    TriggerClientEvent('chat:addMessage', source, {
        args = {'^3CCTV', ('Vorhandene Terminals: %d'):format(#terminals)}
    })
    for _, terminal in ipairs(terminals) do
        TriggerClientEvent('chat:addMessage', source, {
            args = {'^3CCTV', ('#%d %s | %s | %s'):format(terminal.id, terminal.name, terminal.type, terminal.job)}
        })
    end
end, false)

RegisterCommand('bgcctvterminaldelete', function(source, args)
    if not CCTV.Permissions.hasAdminAccess(source) then
        return
    end

    local id = tonumber(args[1])
    if not id then
        TriggerClientEvent('chat:addMessage', source, {
            args = {'^1CCTV', 'Usage: /bgcctvterminaldelete [id]'}
        })
        return
    end

    local success, message = CCTV.Terminals.Delete(id)
    TriggerClientEvent('chat:addMessage', source, {
        args = {'^3CCTV', success and message or 'Terminal konnte nicht gelöscht werden.'}
    })
end, false)

RegisterCommand('bgcctvdebug', function(source)
    if not CCTV.Permissions.hasAdminAccess(source) then
        return
    end

    if Config and Config.Debug then
        print('[CCTV] Debug aktiviert')
    end
    TriggerClientEvent('chat:addMessage', source, {
        args = {'^3CCTV', 'Debug-Modus aktiviert.'}
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

    if Config and Config.Debug then
        print('[CCTV][DEBUG] Total cameras:', #((CCTV.Cameras and CCTV.Cameras.GetAll()) or {}))
    end
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
