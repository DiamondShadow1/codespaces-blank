CCTV = CCTV or {}
CCTV.Permissions = CCTV.Permissions or {}

local Permissions = CCTV.Permissions

local function getIdentifier(src)
    local ids = GetPlayerIdentifiers(src)
    for _, id in ipairs(ids) do
        if type(id) == 'string' then
            if id:match('steam:') or id:match('license:') then
                return id
            end
        end
    end

    return ids[1] or tostring(src)
end

local function getPlayerGroup(src)
    if ESX and ESX.GetPlayerFromId then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer and xPlayer.getGroup then
            local group = xPlayer.getGroup()
            if group then
                return tostring(group)
            end
        end
    end
    return nil
end

function Permissions.getIdentifier(src)
    return getIdentifier(src)
end

function Permissions.hasAdminAccess(src)
    if not src or src <= 0 then
        return false
    end

    local playerGroup = getPlayerGroup(src)
    if playerGroup then
        if Config.AdminGroups and Config.AdminGroups[playerGroup] then
            return true
        end
    end

    if IsPlayerAceAllowed(src, 'cctv.admin') or IsPlayerAceAllowed(src, 'command.cctvadmin') then
        return true
    end

    if Config.AdminGroups then
        for adminGroup, enabled in pairs(Config.AdminGroups) do
            if enabled and IsPlayerAceAllowed(src, ('group.%s'):format(adminGroup)) then
                return true
            end
        end
    end

    return false
end

function Permissions.hasPoliceAccess(src)
    if not src or src <= 0 then
        return false
    end

    if ESX and ESX.GetPlayerFromId then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer and xPlayer.job then
            local jobName = xPlayer.job.name
            local grade = tonumber(xPlayer.job.grade) or 0

            if jobName and Config.PoliceJobs[jobName] then
                if grade >= tonumber(Config.PoliceJobs[jobName]) then
                    return true
                end
            end
        end
    end

    return false
end

function Permissions.hasJobAccess(src)
    if not src or src <= 0 then
        return false
    end

    if ESX and ESX.GetPlayerFromId then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer and xPlayer.job then
            local jobName = xPlayer.job.name
            if jobName and Config.JobAccess[jobName] == true then
                return true
            end
        end
    end

    return false
end

function Permissions.canViewCameras(src)
    return Permissions.hasAdminAccess(src) or Permissions.hasPoliceAccess(src) or Permissions.hasJobAccess(src)
end

function Permissions.canManageCameras(src)
    return Permissions.hasAdminAccess(src)
end

function Permissions.canDeleteEvidence(src)
    return Permissions.hasAdminAccess(src) or Permissions.hasPoliceAccess(src)
end
