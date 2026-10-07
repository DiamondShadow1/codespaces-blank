CCTV = CCTV or {}
CCTV.Terminals = CCTV.Terminals or {}

local Terminals = CCTV.Terminals
Terminals.list = Terminals.list or {}

local function normalizeTerminal(data)
    if not data then
        return nil
    end

    return {
        id = tonumber(data.id),
        name = tostring(data.name or 'CCTV-Computer'),
        type = tostring(data.type or 'police'),
        x = tonumber(data.x) or 0.0,
        y = tonumber(data.y) or 0.0,
        z = tonumber(data.z) or 0.0,
        heading = tonumber(data.heading) or 0.0,
        job = tostring(data.job or 'police'),
        created_by = tostring(data.created_by or 'system'),
        created_at = tostring(data.created_at or os.date('!%Y-%m-%d %H:%M:%S')),
    }
end

function Terminals.Load()
    if not MySQL then
        return
    end

    MySQL.query('SELECT * FROM cctv_terminals ORDER BY id ASC', {}, function(results)
        Terminals.list = {}
        if results then
            for _, terminal in ipairs(results) do
                local normalized = normalizeTerminal(terminal)
                if normalized then
                    table.insert(Terminals.list, normalized)
                end
            end
        end
        print(('[CCTV] %d terminal(s) loaded'):format(#Terminals.list))
    end)
end

function Terminals.GetAll()
    return Terminals.list or {}
end

function Terminals.Create(data, sourcePlayer)
    if not data then
        return false, 'Invalid terminal data'
    end

    local terminal = normalizeTerminal({
        name = data.name or 'CCTV-Computer',
        type = data.type or 'police',
        x = data.x,
        y = data.y,
        z = data.z,
        heading = data.heading,
        job = data.job or 'police',
        created_by = sourcePlayer or data.created_by or 'system',
        created_at = os.date('!%Y-%m-%d %H:%M:%S')
    })

    if not terminal then
        return false, 'Bad terminal payload'
    end

    MySQL.insert('INSERT INTO cctv_terminals (name, type, x, y, z, heading, job, created_by, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        terminal.name,
        terminal.type,
        terminal.x,
        terminal.y,
        terminal.z,
        terminal.heading,
        terminal.job,
        terminal.created_by,
        terminal.created_at,
    }, function(insertId)
        if insertId then
            terminal.id = tonumber(insertId)
            table.insert(Terminals.list, terminal)
        end
    end)

    return true, 'Terminal created successfully'
end

function Terminals.Delete(id)
    local targetId = tonumber(id)
    if not targetId then
        return false, 'No terminal id provided'
    end

    MySQL.query('DELETE FROM cctv_terminals WHERE id = ?', { targetId }, function()
        for index, terminal in ipairs(Terminals.list) do
            if tonumber(terminal.id) == targetId then
                table.remove(Terminals.list, index)
                break
            end
        end
    end)

    return true, 'Terminal deleted successfully'
end

function Terminals.SendToClient(src)
    if not src or src <= 0 then
        return
    end

    TriggerClientEvent('cctv:client:syncTerminals', src, Terminals.GetAll())
end
