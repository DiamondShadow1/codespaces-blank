CCTVClient = CCTVClient or {}
CCTVClient.Terminals = CCTVClient.Terminals or {}

local Terminals = CCTVClient.Terminals
Terminals.list = Terminals.list or {}

local function drawText3D(x, y, z, text)
    local onScreen, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
    if onScreen then
        local scale = 0.35
        local width = string.len(text) * 0.02
        SetTextScale(scale, scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 220)
        SetTextEntry('STRING')
        AddTextComponentString(text)
        SetTextCentre(1)
        DrawText(_x, _y)
        DrawRect(_x, _y + 0.015, width, 0.03, 15, 15, 15, 150)
    end
end

RegisterNetEvent('cctv:client:syncTerminals', function(terminals)
    Terminals.list = terminals or {}
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)

        local ped = PlayerPedId()
        local pedCoords = GetEntityCoords(ped)
        local nearest = nil

        for _, terminal in ipairs(Terminals.list or {}) do
            local dist = #(pedCoords - vector3(tonumber(terminal.x) or 0.0, tonumber(terminal.y) or 0.0, tonumber(terminal.z) or 0.0))
            if dist < 2.0 then
                nearest = terminal
                break
            end
        end

        if nearest then
            drawText3D(tonumber(nearest.x), tonumber(nearest.y), tonumber(nearest.z) + 1.0, '[E] CCTV-System öffnen')
            if IsControlJustPressed(0, 38) then
                TriggerServerEvent('cctv:server:requestOpenMenu')
            end
        end
    end
end)
