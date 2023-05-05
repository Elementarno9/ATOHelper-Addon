local NEAREST_WORMHOLE = nil
local SHIP_ID = nil

--- UTILS ---

function Distance(pos1, pos2)
    return math.sqrt(math.pow(pos1.posX - pos2.posX, 2) + math.pow(pos1.posY - pos2.posY, 2) + math.pow(pos1.posZ - pos2.posZ, 2))
end

function GetWormholeColor(objectInfo)
    if not objectInfo then return end
    local path = common.GetTexturePath( objectInfo.image )

    if string.find(path, "Red") then
        return "R"
    elseif string.find(path, "Green") then
        return "G"
    elseif string.find(path, "Blue") then
        return "B"
    else
        return nil
    end
end

--- EVENTS ---

function OnAstralHubChanged()    
    local sectorId = astral.GetCurrentSector()
    if not sectorId then return end

    local sectorInfo = astral.GetSectorInfo(sectorId)
    if not sectorInfo then return end
    
    local center = astral.GetHubCenter()
    local raduis = astral.GetHubRadius()
    local objects = astral.GetObjects()
    local shipInfo = transport.GetShipInfo(SHIP_ID)

    local data = {
        shard = userMods.FromWString(mission.GetShardName()),
        time = mission.GetGlobalDateTime().overallMs,
        sector = userMods.FromWString(sectorInfo.name),
        shipName = userMods.FromWString(shipInfo.name),
        shipOwnerName = userMods.FromWString(shipInfo.ownerName),
        shipOwnerGuildName = userMods.FromWString(shipInfo.ownerGuildName),
        hubCenter = center,
        hubRaduis = raduis,
        objects = {},
        lastTransit = NEAREST_WORMHOLE
    }

    for i, objectId in pairs(objects) do
        local objectInfo = astral.GetObjectInfo(objectId)
        if objectInfo then
            table.insert(data["objects"], {
                name = userMods.FromWString(objectInfo.name),
                position = objectInfo.position,
                image = objectInfo.image,
                color = GetWormholeColor(objectInfo)
            })
        end
    end

    userMods.SetGlobalConfigSection("CurrentAstralData", data)

    NEAREST_WORMHOLE = nil
end

function OnTimer()
    local sectorId = astral.GetCurrentSector()
    if not sectorId then return end

    local shipPos = transport.GetPosition(SHIP_ID)
    local distance = 10000

    local objects = astral.GetObjects()
    for i, objectId in pairs(objects) do
        local objectInfo = astral.GetObjectInfo(objectId)
        if userMods.FromWString(objectInfo.name) == "Астральная воронка" then
            local curDistance = Distance(shipPos, objectInfo.position)
            if curDistance < distance then
                distance = curDistance
                NEAREST_WORMHOLE = GetWormholeColor(objectInfo)
            end
        end
    end
end

function OnTransportChanged()
    SHIP_ID = unit.GetTransport(avatar.GetId())
end

--- INIT ---

function Init()
    OnTransportChanged()
    OnAstralHubChanged()
    
    common.RegisterEventHandler(OnAstralHubChanged, "EVENT_ASTRAL_HUB_CHANGED")
    common.RegisterEventHandler(OnTimer, "EVENT_SECOND_TIMER")
    common.RegisterEventHandler(OnTransportChanged, "EVENT_AVATAR_TRANSPORT_CHANGED")
end


if avatar.IsExist() then
    Init()
end