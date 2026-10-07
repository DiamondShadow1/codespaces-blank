CCTV = CCTV or {}
CCTV.Cameras = CCTV.Cameras or {}

local Cameras = CCTV.Cameras
Cameras.list = Cameras.list or {}
Cameras.index = Cameras.index or {}

local function normalizeStatus(status)
    local normalized = tostring(status or 'ONLINE'):upper()
    if normalized == 'DAMAGED' or normalized == 'DESTROYED' then
        return 'DAMAGED'
    end
    return normalized
end

local function sanitizeCameraData(data)
    if not data then
        return nil
    end

    local camera = {
        name = tostring(data.name or 'Kamera'),
        type = tostring(data.type or 'public'),
        x = tonumber(data.x) or 0.0,
        y = tonumber(data.y) or 0.0,
        z = tonumber(data.z) or 0.0,
        rotation = tonumber(data.rotation) or 0.0,
        range = tonumber(data.range) or tonumber(Config.DefaultRange) or 35,
        fov = tonumber(data.fov) or tonumber(Config.DefaultFov) or 70,
        status = normalizeStatus(data.status),
        owner = tostring(data.owner or ''),
    }

    return camera
end

function Cameras.Load()
    MySQL.query('SELECT * FROM cameras ORDER BY id ASC', {}, function(results)
        Cameras.list = results or {}
        Cameras.index = {}

        for _, camera in ipairs(Cameras.list) do
            camera.status = normalizeStatus(camera.status)
            Cameras.index[tonumber(camera.id)] = camera
        end

        print(('[CCTV] %d camera(s) loaded from database'):format(#Cameras.list))
    end)
end

function Cameras.GetAll()
    return Cameras.list or {}
end

function Cameras.GetById(cameraId)
    if not cameraId then
        return nil
    end

    return Cameras.index[tonumber(cameraId)]
end

function Cameras.Create(data, sourcePlayer)
    local sanitized = sanitizeCameraData(data)
    if not sanitized then
        return false, 'Invalid camera data'
    end

    if not sanitized.name or sanitized.name == '' then
        return false, 'Camera name is required'
    end

    if sanitized.range > tonumber(Config.MaxCameraDistance or 150) then
        return false, 'Sichtweite exceeds configured maximum'
    end

    local ownerValue = tostring(sourcePlayer or sanitized.owner or '')

    MySQL.insert('INSERT INTO cameras (name, type, x, y, z, rotation, range, fov, status, owner) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        sanitized.name,
        sanitized.type,
        sanitized.x,
        sanitized.y,
        sanitized.z,
        sanitized.rotation,
        sanitized.range,
        sanitized.fov,
        sanitized.status,
        ownerValue,
    }, function(insertId)
        if insertId then
            local createdCamera = {
                id = tonumber(insertId),
                name = sanitized.name,
                type = sanitized.type,
                x = sanitized.x,
                y = sanitized.y,
                z = sanitized.z,
                rotation = sanitized.rotation,
                range = sanitized.range,
                fov = sanitized.fov,
                status = 'ONLINE',
                owner = ownerValue,
                created_at = os.date('!%Y-%m-%d %H:%M:%S'),
                updated_at = os.date('!%Y-%m-%d %H:%M:%S')
            }

            table.insert(Cameras.list, createdCamera)
            Cameras.index[createdCamera.id] = createdCamera
        end
    end)

    return true, 'Camera created successfully'
end

function Cameras.Update(cameraId, updates)
    local camera = Cameras.GetById(cameraId)
    if not camera then
        return false, 'Camera not found'
    end

    local setClauses = {}
    local values = {}

    if updates.name then
        table.insert(setClauses, 'name = ?')
        table.insert(values, tostring(updates.name))
    end

    if updates.type then
        table.insert(setClauses, 'type = ?')
        table.insert(values, tostring(updates.type))
    end

    if updates.range then
        table.insert(setClauses, 'range = ?')
        table.insert(values, tonumber(updates.range))
    end

    if updates.fov then
        table.insert(setClauses, 'fov = ?')
        table.insert(values, tonumber(updates.fov))
    end

    if updates.status then
        table.insert(setClauses, 'status = ?')
        table.insert(values, normalizeStatus(updates.status))
    end

    if updates.rotation then
        table.insert(setClauses, 'rotation = ?')
        table.insert(values, tonumber(updates.rotation))
    end

    if updates.x then
        table.insert(setClauses, 'x = ?')
        table.insert(values, tonumber(updates.x))
    end

    if updates.y then
        table.insert(setClauses, 'y = ?')
        table.insert(values, tonumber(updates.y))
    end

    if updates.z then
        table.insert(setClauses, 'z = ?')
        table.insert(values, tonumber(updates.z))
    end

    if #setClauses == 0 then
        return false, 'No update fields provided'
    end

    table.insert(values, tonumber(cameraId))
    MySQL.update(('UPDATE cameras SET %s WHERE id = ?'):format(table.concat(setClauses, ', ')), values, function(affectedRows)
        if affectedRows and affectedRows > 0 then
            for _, currentCamera in ipairs(Cameras.list) do
                if tonumber(currentCamera.id) == tonumber(cameraId) then
                    if updates.name then currentCamera.name = tostring(updates.name) end
                    if updates.type then currentCamera.type = tostring(updates.type) end
                    if updates.range then currentCamera.range = tonumber(updates.range) end
                    if updates.fov then currentCamera.fov = tonumber(updates.fov) end
                    if updates.status then currentCamera.status = normalizeStatus(updates.status) end
                    if updates.rotation then currentCamera.rotation = tonumber(updates.rotation) end
                    if updates.x then currentCamera.x = tonumber(updates.x) end
                    if updates.y then currentCamera.y = tonumber(updates.y) end
                    if updates.z then currentCamera.z = tonumber(updates.z) end
                    break
                end
            end
        end
    end)

    return true, 'Camera updated successfully'
end

function Cameras.Delete(cameraId)
    if not cameraId then
        return false, 'No valid camera id provided'
    end

    MySQL.query('DELETE FROM cameras WHERE id = ?', { tonumber(cameraId) }, function(result)
        for index, camera in ipairs(Cameras.list) do
            if tonumber(camera.id) == tonumber(cameraId) then
                table.remove(Cameras.list, index)
                Cameras.index[tonumber(cameraId)] = nil
                break
            end
        end
    end)

    return true, 'Camera deleted successfully'
end

function Cameras.GetDashboardData()
    local online = 0
    local offline = 0
    local damaged = 0
    local total = #Cameras.list

    for _, camera in ipairs(Cameras.list) do
        local status = normalizeStatus(camera.status)
        if status == 'ONLINE' then
            online = online + 1
        elseif status == 'OFFLINE' then
            offline = offline + 1
        elseif status == 'DAMAGED' then
            damaged = damaged + 1
        end
    end

    return {
        total = total,
        online = online,
        offline = offline,
        damaged = damaged,
        recordings = CCTV.Recordings and CCTV.Recordings.Count() or 0,
        evidence = CCTV.Evidence and CCTV.Evidence.Count() or 0,
    }
end
