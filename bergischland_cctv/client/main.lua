CCTVClient = CCTVClient or {}
CCTVClient.state = CCTVClient.state or {
    isOpen = false,
    cameraViewActive = false,
    currentCamera = nil,
    cameraHandle = nil,
}

local function setNuiOpen(open)
    CCTVClient.state.isOpen = open
    SetNuiFocus(open, open)
end

RegisterNetEvent('cctv:client:openMenu', function(data)
    SendNUIMessage({
        action = 'setData',
        payload = data or {}
    })
    SendNUIMessage({ action = 'open' })
    setNuiOpen(true)
end)

RegisterNetEvent('cctv:client:closeMenu', function()
    SendNUIMessage({ action = 'close' })
    setNuiOpen(false)
end)

RegisterNetEvent('cctv:client:receiveData', function(data)
    if not data then
        return
    end

    SendNUIMessage({
        action = 'setData',
        payload = data
    })
end)

RegisterNetEvent('cctv:client:openCameraView', function(camera)
    CCTVClient.Camera.Open(camera)
end)

RegisterCommand('cctv', function()
    TriggerServerEvent('cctv:server:requestData')
end, false)

RegisterCommand('cctvadmin', function()
    TriggerServerEvent('cctv:server:requestData')
end, false)

RegisterCommand('cctvdebug', function()
    TriggerServerEvent('cctv:server:requestData')
end, false)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    if CCTVClient.state.cameraViewActive and CCTVClient.state.cameraHandle then
        RenderScriptCams(false, false, 0, true, false)
        DestroyCam(CCTVClient.state.cameraHandle, false)
    end
end)
