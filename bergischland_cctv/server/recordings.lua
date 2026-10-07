CCTV = CCTV or {}
CCTV.Recordings = CCTV.Recordings or {}

local Recordings = CCTV.Recordings
Recordings.list = Recordings.list or {}

function Recordings.Count()
    return #Recordings.list
end

function Recordings.Create(cameraId, startTime)
    if not cameraId then
        return nil
    end

    local timestamp = startTime or os.date('!%Y-%m-%d %H:%M:%S')

    local data = {
        camera_id = tonumber(cameraId),
        start_time = timestamp,
        end_time = nil,
        destroyed = 0,
        destroyed_at = nil,
        recording_data = json.encode({
            cameraId = tonumber(cameraId),
            startTime = timestamp,
            events = {}
        })
    }

    MySQL.insert('INSERT INTO recordings (camera_id, start_time, end_time, destroyed, destroyed_at, recording_data) VALUES (?, ?, ?, ?, ?, ?)', {
        data.camera_id,
        data.start_time,
        data.end_time,
        data.destroyed,
        data.destroyed_at,
        data.recording_data,
    }, function(insertId)
        if insertId then
            local newRecording = {
                id = tonumber(insertId),
                camera_id = data.camera_id,
                start_time = data.start_time,
                end_time = data.end_time,
                destroyed = data.destroyed,
                destroyed_at = data.destroyed_at,
                recording_data = data.recording_data,
            }
            table.insert(Recordings.list, newRecording)
        end
    end)

    return true
end

function Recordings.Close(cameraId, endTime)
    local latest = nil
    for _, recording in ipairs(Recordings.list) do
        if tonumber(recording.camera_id) == tonumber(cameraId) and not recording.end_time then
            latest = recording
            break
        end
    end

    if not latest then
        return false
    end

    MySQL.update('UPDATE recordings SET end_time = ? WHERE id = ?', {
        endTime or os.date('!%Y-%m-%d %H:%M:%S'),
        latest.id,
    }, function(affectedRows)
        if affectedRows and affectedRows > 0 then
            latest.end_time = endTime or os.date('!%Y-%m-%d %H:%M:%S')
        end
    end)

    return true
end

function Recordings.MarkDestroyed(cameraId, destroyedAt)
    local latest = nil
    for _, recording in ipairs(Recordings.list) do
        if tonumber(recording.camera_id) == tonumber(cameraId) and not recording.destroyed then
            latest = recording
            break
        end
    end

    if not latest then
        return false
    end

    latest.destroyed = 1
    latest.destroyed_at = destroyedAt or os.date('!%Y-%m-%d %H:%M:%S')
    latest.end_time = latest.destroyed_at

    MySQL.update('UPDATE recordings SET destroyed = 1, destroyed_at = ?, end_time = ? WHERE id = ?', {
        latest.destroyed_at,
        latest.end_time,
        latest.id,
    }, function() end)

    return true
end
