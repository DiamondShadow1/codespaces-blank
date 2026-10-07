CCTV = CCTV or {}
CCTV.Evidence = CCTV.Evidence or {}

local Evidence = CCTV.Evidence
Evidence.list = Evidence.list or {}

function Evidence.Count()
    return #Evidence.list
end

function Evidence.Create(recordingId, officerIdentifier, officerName, caseNumber, reason)
    if not recordingId then
        return false, 'No recording selected'
    end

    local caseValue = caseNumber and caseNumber ~= '' and caseNumber or nil
    MySQL.insert('INSERT INTO evidence (recording_id, officer_identifier, officer_name, case_number, reason) VALUES (?, ?, ?, ?, ?)', {
        tonumber(recordingId),
        tostring(officerIdentifier or ''),
        tostring(officerName or 'Unknown'),
        caseValue,
        tostring(reason or 'Unspecified reason')
    }, function(insertId)
        if insertId then
            table.insert(Evidence.list, {
                id = tonumber(insertId),
                recording_id = tonumber(recordingId),
                officer_identifier = tostring(officerIdentifier or ''),
                officer_name = tostring(officerName or 'Unknown'),
                case_number = caseValue,
                reason = tostring(reason or 'Unspecified reason'),
                created_at = os.date('!%Y-%m-%d %H:%M:%S')
            })
        end
    end)

    return true, 'Evidence stored successfully'
end

function Evidence.GetAll()
    return Evidence.list or {}
end

function Evidence.Delete(evidenceId)
    if not evidenceId then
        return false, 'No evidence id provided'
    end

    MySQL.query('DELETE FROM evidence WHERE id = ?', { tonumber(evidenceId) }, function()
        for index, item in ipairs(Evidence.list) do
            if tonumber(item.id) == tonumber(evidenceId) then
                table.remove(Evidence.list, index)
                break
            end
        end
    end)

    return true, 'Evidence deleted successfully'
end
