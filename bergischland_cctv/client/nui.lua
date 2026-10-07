CCTVClient = CCTVClient or {}
CCTVClient.Data = CCTVClient.Data or {}

RegisterNUICallback('open', function(data, cb)
    SetNuiFocus(true, true)
    cb('ok')
end)

RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    if CCTVClient.Camera and CCTVClient.Camera.Close then
        CCTVClient.Camera.Close()
    end
    cb('ok')
end)

RegisterNUICallback('getCameras', function(data, cb)
    TriggerServerEvent('cctv:server:requestData')
    cb('ok')
end)

RegisterNUICallback('selectCamera', function(data, cb)
    if data and data.cameraId then
        TriggerServerEvent('cctv:server:openCamera', tonumber(data.cameraId))
    end
    cb('ok')
end)

RegisterNUICallback('createCamera', function(data, cb)
    if data then
        TriggerServerEvent('cctv:server:createCamera', data)
    end
    cb('ok')
end)

RegisterNUICallback('updateCamera', function(data, cb)
    if data and data.cameraId then
        TriggerServerEvent('cctv:server:updateCamera', tonumber(data.cameraId), data.updates or {})
    end
    cb('ok')
end)

RegisterNUICallback('deleteCamera', function(data, cb)
    if data and data.cameraId then
        TriggerServerEvent('cctv:server:deleteCamera', tonumber(data.cameraId))
    end
    cb('ok')
end)

RegisterNUICallback('getEvidence', function(data, cb)
    TriggerServerEvent('cctv:server:requestData')
    cb('ok')
end)

RegisterNUICallback('saveEvidence', function(data, cb)
    if data then
        TriggerServerEvent('cctv:server:saveEvidence', data)
    end
    cb('ok')
end)

RegisterNUICallback('cctv:nui:close', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    cb('ok')
end)

RegisterNUICallback('cctv:nui:requestData', function(data, cb)
    TriggerServerEvent('cctv:server:requestData')
    cb('ok')
end)

RegisterNUICallback('cctv:nui:openCamera', function(data, cb)
    if data and data.cameraId then
        TriggerServerEvent('cctv:server:openCamera', tonumber(data.cameraId))
    end
    cb('ok')
end)

RegisterNUICallback('cctv:nui:toggleCameraStatus', function(data, cb)
    if data and data.cameraId then
        TriggerServerEvent('cctv:server:updateCamera', tonumber(data.cameraId), {
            status = data.status or 'ONLINE'
        })
    end
    cb('ok')
end)

RegisterNUICallback('cctv:nui:createCamera', function(data, cb)
    if data then
        TriggerServerEvent('cctv:server:createCamera', data)
    end
    cb('ok')
end)

RegisterNUICallback('cctv:nui:deleteCamera', function(data, cb)
    if data and data.cameraId then
        TriggerServerEvent('cctv:server:deleteCamera', tonumber(data.cameraId))
    end
    cb('ok')
end)

RegisterNUICallback('cctv:nui:saveEvidence', function(data, cb)
    if data then
        TriggerServerEvent('cctv:server:saveEvidence', data)
    end
    cb('ok')
end)
