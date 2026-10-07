CCTVClient = CCTVClient or {}
CCTVClient.Camera = CCTVClient.Camera or {}

local Camera = CCTVClient.Camera

function Camera.Open(camera)
    if not camera then
        return
    end

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local cameraCoords = vector3(tonumber(camera.x) or playerCoords.x, tonumber(camera.y) or playerCoords.y, tonumber(camera.z) or playerCoords.z + 1.0)

    if CCTVClient.state.cameraHandle then
        RenderScriptCams(false, false, 0, true, false)
        DestroyCam(CCTVClient.state.cameraHandle, false)
        CCTVClient.state.cameraHandle = nil
    end

    local newCamera = CreateCameraWithParams('DEFAULT_SCRIPTED_CAMERA', cameraCoords.x, cameraCoords.y, cameraCoords.z + 1.0, 0.0, 0.0, tonumber(camera.rotation) or 0.0, tonumber(camera.fov) or 70.0, true, 2)
    SetCamActive(newCamera, true)
    RenderScriptCams(true, false, 0, true, false)
    PointCamAtCoord(newCamera, cameraCoords.x, cameraCoords.y, cameraCoords.z)

    CCTVClient.state.cameraViewActive = true
    CCTVClient.state.currentCamera = camera
    CCTVClient.state.cameraHandle = newCamera
end

function Camera.Close()
    if CCTVClient.state.cameraHandle then
        RenderScriptCams(false, false, 0, true, false)
        DestroyCam(CCTVClient.state.cameraHandle, false)
        CCTVClient.state.cameraHandle = nil
    end

    CCTVClient.state.cameraViewActive = false
    CCTVClient.state.currentCamera = nil
end

function Camera.Next()
    if not CCTVClient.state.currentCamera then
        return
    end

    local cameraList = (CCTVClient and CCTVClient.Data and CCTVClient.Data.cameras) or {}
    if #cameraList <= 1 then
        return
    end

    local currentId = tonumber(CCTVClient.state.currentCamera.id)
    local nextCamera = nil
    for i, camera in ipairs(cameraList) do
        if tonumber(camera.id) == currentId then
            if i + 1 <= #cameraList then
                nextCamera = cameraList[i + 1]
            else
                nextCamera = cameraList[1]
            end
            break
        end
    end

    if nextCamera then
        Camera.Open(nextCamera)
    end
end

function Camera.Previous()
    if not CCTVClient.state.currentCamera then
        return
    end

    local cameraList = (CCTVClient and CCTVClient.Data and CCTVClient.Data.cameras) or {}
    if #cameraList <= 1 then
        return
    end

    local currentId = tonumber(CCTVClient.state.currentCamera.id)
    local previousCamera = nil
    for i, camera in ipairs(cameraList) do
        if tonumber(camera.id) == currentId then
            if i - 1 >= 1 then
                previousCamera = cameraList[i - 1]
            else
                previousCamera = cameraList[#cameraList]
            end
            break
        end
    end

    if previousCamera then
        Camera.Open(previousCamera)
    end
end
