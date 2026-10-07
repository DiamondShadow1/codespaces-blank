CCTVClient = CCTVClient or {}
CCTVClient.Data = CCTVClient.Data or {}

RegisterNUICallback('cctv:nui:close', function(data, cb)
    CCTVClient.Camera.Close()
    TriggerEvent('cctv:client:closeMenu')
    cb({ success = true })
end)

RegisterNUICallback('cctv:nui:requestData', function(data, cb)
    TriggerServerEvent('cctv:server:requestData')
    cb({ success = true })
end)

RegisterNUICallback('cctv:nui:openCamera', function(data, cb)
    if data and data.cameraId then
        TriggerServerEvent('cctv:server:openCamera', tonumber(data.cameraId))
    end
    cb({ success = true })
end)

RegisterNUICallback('cctv:nui:toggleCameraStatus', function(data, cb)
    if data and data.cameraId then
        TriggerServerEvent('cctv:server:updateCamera', tonumber(data.cameraId), {
            status = data.status or 'ONLINE'
        })
    end
    cb({ success = true })
end)

RegisterNUICallback('cctv:nui:createCamera', function(data, cb)
    if data then
        TriggerServerEvent('cctv:server:createCamera', data)
    end
    cb({ success = true })
end)

RegisterNUICallback('cctv:nui:deleteCamera', function(data, cb)
    if data and data.cameraId then
        TriggerServerEvent('cctv:server:deleteCamera', tonumber(data.cameraId))
    end
    cb({ success = true })
end)

RegisterNUICallback('cctv:nui:saveEvidence', function(data, cb)
    if data then
        TriggerServerEvent('cctv:server:saveEvidence', data)
    end
    cb({ success = true })
end)
