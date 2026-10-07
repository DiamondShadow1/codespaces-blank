CCTVClient = CCTVClient or {}
CCTVClient.state = CCTVClient.state or {
    isOpen = false,
    cameraViewActive = false,
    currentCamera = nil,
    cameraHandle = nil,
}

local function safeNuiClose()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    CCTVClient.state.isOpen = false
end

local function safeNuiOpen(data)
    if data then
        SendNUIMessage({
            action = 'setData',
            payload = data
        })
    end

    SendNUIMessage({ action = 'open' })
    SetNuiFocus(true, true)
    CCTVClient.state.isOpen = true
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    safeNuiClose()
    if Config and Config.Debug then
        print('[CCTV] Resource gestartet')
    end
end)

RegisterNetEvent('cctv:client:openMenu', function(data)
    safeNuiOpen(data)
end)

RegisterNetEvent('cctv:client:closeMenu', function()
    safeNuiClose()
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

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    SetNuiFocus(false, false)
    if CCTVClient.state.cameraViewActive and CCTVClient.state.cameraHandle then
        RenderScriptCams(false, false, 0, true, false)
        DestroyCam(CCTVClient.state.cameraHandle, false)
    end
end)
