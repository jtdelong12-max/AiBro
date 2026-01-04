-- =============================================================================
-- Formations.lua
-- Formation positioning system for AI Allies
-- =============================================================================

Formations = {}

-- Formation tracking
local formationData = {}

--- Formation types with position offsets
local FORMATION_TYPES = {
    FRONTLINE = {
        positions = {
            {x = 0, y = 0},
            {x = -2, y = 0},
            {x = 2, y = 0},
            {x = -4, y = 0},
            {x = 4, y = 0}
        }
    },
    MIDLINE = {
        positions = {
            {x = 0, y = 0},
            {x = -2, y = -2},
            {x = 2, y = -2},
            {x = -4, y = -4},
            {x = 4, y = -4}
        }
    },
    BACKLINE = {
        positions = {
            {x = 0, y = -3},
            {x = -2, y = -5},
            {x = 2, y = -5},
            {x = -4, y = -7},
            {x = 4, y = -7}
        }
    },
    SCATTERED = nil  -- No fixed positions, free movement
}

--- Get formation type for entity
--- @param entity string Entity UUID
--- @return string|nil formationType Formation type or nil if none
function Formations.GetFormationType(entity)
    if not Shared.CachedExists(entity) then return nil end
    
    if Osi.HasActiveStatus(entity, Shared.STATUS.FORMATION_FRONTLINE) == 1 then
        return "FRONTLINE"
    elseif Osi.HasActiveStatus(entity, Shared.STATUS.FORMATION_MIDLINE) == 1 then
        return "MIDLINE"
    elseif Osi.HasActiveStatus(entity, Shared.STATUS.FORMATION_BACKLINE) == 1 then
        return "BACKLINE"
    elseif Osi.HasActiveStatus(entity, Shared.STATUS.FORMATION_SCATTERED) == 1 then
        return "SCATTERED"
    end
    
    return nil
end

--- Set formation type for entity
--- @param entity string Entity UUID
--- @param formationType string Formation type (FRONTLINE, MIDLINE, BACKLINE, SCATTERED)
function Formations.SetFormationType(entity, formationType)
    if not Shared.CachedExists(entity) then return end
    
    -- Remove all formation statuses
    Osi.RemoveStatus(entity, Shared.STATUS.FORMATION_FRONTLINE)
    Osi.RemoveStatus(entity, Shared.STATUS.FORMATION_MIDLINE)
    Osi.RemoveStatus(entity, Shared.STATUS.FORMATION_BACKLINE)
    Osi.RemoveStatus(entity, Shared.STATUS.FORMATION_SCATTERED)
    
    -- Apply new formation status
    local statusMap = {
        FRONTLINE = Shared.STATUS.FORMATION_FRONTLINE,
        MIDLINE = Shared.STATUS.FORMATION_MIDLINE,
        BACKLINE = Shared.STATUS.FORMATION_BACKLINE,
        SCATTERED = Shared.STATUS.FORMATION_SCATTERED
    }
    
    local status = statusMap[formationType]
    if status then
        Osi.ApplyStatus(entity, status, -1, 0, entity)
        Shared.DebugLog("Formation", string.format("Set %s to formation %s", entity, formationType))
    end
end

--- Get formation leader for entity (usually closest player)
--- @param entity string Entity UUID
--- @return string|nil leader Entity UUID of formation leader
function Formations.GetFormationLeader(entity)
    if not Shared.CachedExists(entity) then return nil end
    
    -- Check if entity has a designated leader
    local player = Shared.GetPlayerForEntity(entity)
    if player then return player end
    
    -- Fall back to closest player
    return Shared.GetClosestPlayer(entity)
end

--- Calculate ideal formation position for entity
--- @param entity string Entity UUID
--- @param leader string Leader UUID
--- @param formationType string Formation type
--- @param positionIndex number Position index in formation (0-based)
--- @return number|nil, number|nil, number|nil x, y, z coordinates or nil if error
function Formations.CalculateFormationPosition(entity, leader, formationType, positionIndex)
    if not Shared.CachedExists(entity) or not Shared.CachedExists(leader) then
        return nil, nil, nil
    end
    
    local formation = FORMATION_TYPES[formationType]
    if not formation then return nil, nil, nil end
    
    -- Get leader position
    local leaderX, leaderY, leaderZ = Osi.GetPosition(leader)
    if not leaderX then return nil, nil, nil end
    
    -- Get position offset
    local offset = formation.positions[positionIndex + 1] or formation.positions[1]
    if not offset then return nil, nil, nil end
    
    -- Calculate target position (simple offset for now)
    local targetX = leaderX + (offset.x * Shared.CONSTANTS.FORMATION_DISTANCE)
    local targetY = leaderY + (offset.y * Shared.CONSTANTS.FORMATION_DISTANCE)
    local targetZ = leaderZ
    
    return targetX, targetY, targetZ
end

--- Update formation positions for all allies
--- This should be called periodically (e.g., every 2 seconds)
function Formations.UpdateFormations()
    -- Group allies by formation type and leader
    local formationGroups = {}
    
    -- Iterate through all allies
    for ally, _ in pairs(BootstrapServer.CurrentAllies) do
        if Shared.CachedExists(ally) then
            local formationType = Formations.GetFormationType(ally)
            
            -- Skip scattered formation and allies without formation
            if formationType and formationType ~= "SCATTERED" then
                local leader = Formations.GetFormationLeader(ally)
                
                if leader then
                    local groupKey = leader .. "_" .. formationType
                    formationGroups[groupKey] = formationGroups[groupKey] or {
                        leader = leader,
                        formationType = formationType,
                        members = {}
                    }
                    
                    table.insert(formationGroups[groupKey].members, ally)
                end
            end
        end
    end
    
    -- Apply formation positions
    for groupKey, group in pairs(formationGroups) do
        for index, ally in ipairs(group.members) do
            local x, y, z = Formations.CalculateFormationPosition(
                ally,
                group.leader,
                group.formationType,
                index - 1
            )
            
            -- Store ideal position (actual movement controlled by AI)
            if x and y and z then
                formationData[ally] = {
                    targetX = x,
                    targetY = y,
                    targetZ = z,
                    leader = group.leader,
                    formationType = group.formationType
                }
            end
        end
    end
end

--- Handle formation spell cast
--- @param caster string Caster UUID
--- @param target string Target UUID
--- @param spell string Spell name
function Formations.HandleFormationSpell(caster, target, spell)
    if not Shared.CachedExists(target) then return end
    
    local formationMap = {
        [Shared.SPELL.SET_FORMATION_FRONTLINE] = "FRONTLINE",
        [Shared.SPELL.SET_FORMATION_MIDLINE] = "MIDLINE",
        [Shared.SPELL.SET_FORMATION_BACKLINE] = "BACKLINE",
        [Shared.SPELL.SET_FORMATION_SCATTERED] = "SCATTERED"
    }
    
    local formationType = formationMap[spell]
    if formationType then
        Formations.SetFormationType(target, formationType)
        Shared.DebugLog("Formation", string.format("%s set %s to %s formation", caster, target, formationType))
    end
end

--- Register formation event listeners
function Formations.RegisterListeners()
    -- Handle formation spells
    Ext.Osiris.RegisterListener("CastFinished", 5, "after", function(caster, target, spell, _, _)
        Formations.HandleFormationSpell(caster, target, spell)
    end)
    
    -- Periodic formation update
    Ext.Osiris.RegisterListener("TimerFinished", 1, "after", function(timerName)
        if timerName == "Formations_Update" then
            Formations.UpdateFormations()
            Osi.StartTimer("Formations_Update", Shared.CONSTANTS.FORMATION_UPDATE_INTERVAL)
        end
    end)
    
    Shared.DebugLog("Formation", "Formation listeners registered")
end

--- Initialize formation system
function Formations.Initialize()
    -- Start periodic update timer
    Osi.StartTimer("Formations_Update", Shared.CONSTANTS.FORMATION_UPDATE_INTERVAL)
    Shared.DebugLog("Formation", "Formation system initialized")
end

return Formations
