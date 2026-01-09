-- =============================================================================
-- AdvancedFeatures.lua
-- Advanced AI features including aggression modes, auto-heal, and spell priorities
-- =============================================================================

local Shared = Ext.Require("Shared.lua")
local AI = Ext.Require("AI.lua")
AdvancedFeatures = {}

-- Tracking tables
local aggressionSettings = {}
local autoHealEnabled = {}

--- Check if auto-heal is enabled for entity
--- @param entity string Entity UUID
--- @return boolean enabled True if auto-heal enabled
function AdvancedFeatures.IsAutoHealEnabled(entity)
    if not Shared.CachedExists(entity) then return false end
    return Osi.HasActiveStatus(entity, Shared.STATUS.AUTO_HEAL_ENABLED) == 1
end

--- Toggle auto-heal for entity
--- @param entity string Entity UUID
function AdvancedFeatures.ToggleAutoHeal(entity)
    if not Shared.CachedExists(entity) then return end
    
    if AdvancedFeatures.IsAutoHealEnabled(entity) then
        Osi.RemoveStatus(entity, Shared.STATUS.AUTO_HEAL_ENABLED)
        Shared.DebugLog("AdvancedFeatures", string.format("Auto-heal disabled for %s", entity))
    else
        Osi.ApplyStatus(entity, Shared.STATUS.AUTO_HEAL_ENABLED, -1, 0, entity)
        Shared.DebugLog("AdvancedFeatures", string.format("Auto-heal enabled for %s", entity))
    end
end

--- Get aggression mode for entity
--- @param entity string Entity UUID
--- @return string|nil mode "AGGRESSIVE", "DEFENSIVE", "SUPPORT", or nil
function AdvancedFeatures.GetAggressionMode(entity)
    if not Shared.CachedExists(entity) then return nil end
    
    if Osi.HasActiveStatus(entity, Shared.STATUS.AGGRESSIVE_MODE) == 1 then
        return "AGGRESSIVE"
    elseif Osi.HasActiveStatus(entity, Shared.STATUS.DEFENSIVE_MODE) == 1 then
        return "DEFENSIVE"
    elseif Osi.HasActiveStatus(entity, Shared.STATUS.SUPPORT_MODE) == 1 then
        return "SUPPORT"
    end
    
    return nil
end

--- Set aggression mode for entity
--- @param entity string Entity UUID
--- @param mode string Mode ("AGGRESSIVE", "DEFENSIVE", "SUPPORT", or nil to clear)
function AdvancedFeatures.SetAggressionMode(entity, mode)
    if not entity or not Shared.CachedExists(entity) then
        Shared.DebugLog("AdvancedFeatures", "[ERROR] Invalid entity in SetAggressionMode")
        return
    end
    
    -- Remove all aggression modes
    Shared.SafeOsiCall(Osi.RemoveStatus, entity, Shared.STATUS.AGGRESSIVE_MODE)
    Shared.SafeOsiCall(Osi.RemoveStatus, entity, Shared.STATUS.DEFENSIVE_MODE)
    Shared.SafeOsiCall(Osi.RemoveStatus, entity, Shared.STATUS.SUPPORT_MODE)
    
    -- Apply new mode if specified
    local statusMap = {
        AGGRESSIVE = Shared.STATUS.AGGRESSIVE_MODE,
        DEFENSIVE = Shared.STATUS.DEFENSIVE_MODE,
        SUPPORT = Shared.STATUS.SUPPORT_MODE
    }
    
    if mode and type(mode) == "string" then
        local status = statusMap[mode]
        if status then
            local success = Shared.SafeOsiCall(Osi.ApplyStatus, entity, status, -1, 0, entity)
            if success then
                Shared.DebugLog("AdvancedFeatures", string.format("[MODE] Set %s to %s mode", entity, mode))
            else
                Shared.DebugLog("AdvancedFeatures", string.format("[ERROR] Failed to set %s mode for %s", mode, entity))
            end
        else
            Shared.DebugLog("AdvancedFeatures", "[WARNING] Unknown aggression mode: " .. tostring(mode))
        end
    else
        Shared.DebugLog("AdvancedFeatures", "[MODE] Cleared aggression mode for " .. entity)
    end
end

--- Check if entity needs healing based on threshold
--- @param entity string Entity UUID
--- @return boolean needsHealing True if health below threshold
function AdvancedFeatures.NeedsHealing(entity)
    if not entity or not Shared.CachedExists(entity) then
        return false
    end
    
    if not AdvancedFeatures.IsAutoHealEnabled(entity) then
        return false
    end
    
    local currentHP = Osi.GetHitpoints(entity)
    local maxHP = Osi.GetMaxHitpoints(entity)
    
    -- Validate HP values
    if not currentHP or not maxHP then
        Shared.DebugLog("AdvancedFeatures", "[ERROR] Failed to get HP for entity " .. entity)
        return false
    end
    
    if maxHP <= 0 then
        Shared.DebugLog("AdvancedFeatures", "[WARNING] Entity " .. entity .. " has invalid maxHP: " .. maxHP)
        return false
    end
    
    local healthPercent = currentHP / maxHP
    
    if healthPercent < 0 or healthPercent > 1 then
        Shared.DebugLog("AdvancedFeatures", "[WARNING] Invalid health percentage for " .. entity .. ": " .. healthPercent)
        return false
    end
    
    return healthPercent < Shared.CONSTANTS.AUTO_HEAL_THRESHOLD
end

--- Get aggression multiplier for entity based on mode
--- @param entity string Entity UUID
--- @return number multiplier Aggression multiplier (0.5 = defensive, 1.0 = normal, 1.5 = aggressive)
function AdvancedFeatures.GetAggressionMultiplier(entity)
    if not Shared.CachedExists(entity) then return 1.0 end
    
    local mode = AdvancedFeatures.GetAggressionMode(entity)
    
    if mode == "AGGRESSIVE" then
        return 1.5
    elseif mode == "DEFENSIVE" then
        return 0.5
    elseif mode == "SUPPORT" then
        return 0.75
    end
    
    return Shared.CONSTANTS.AGGRESSION_LEVEL_DEFAULT
end

--- Handle healer logic on turn start
--- @param entity string The character starting their turn (potential Healer)
function AdvancedFeatures.ProcessHealerLogic(entity)
    if not entity or Shared.CachedExists(entity) ~= 1 then return end
    
    -- 1. Check if this entity is a Healer (Has Healer status or Auto-Heal enabled)
    local isHealer = false
    if AdvancedFeatures.IsAutoHealEnabled(entity) then isHealer = true end
    if AI and AI.hasControllerStatus and (AI.hasControllerStatus(entity, "HEALER") or AI.hasControllerStatus(entity, "SUPPORT")) then
        isHealer = true
    end
    if not isHealer then return end
    
    -- 2. Scan PARTY MEMBERS for low HP (Standard AI ignores players sometimes, this forces a check)
    local partyMembers = Shared.GetPartyMembers()
    for _, target in ipairs(partyMembers) do
        
        -- Don't heal enemies or dead people
        if Shared.CachedExists(target) == 1 and Osi.IsDead(target) == 0 and Osi.IsEnemy(entity, target) == 0 then
            
            -- Check HP Threshold (50%)
            local hp = Osi.GetHitpoints(target)
            local maxHp = Osi.GetMaxHitpoints(target)
            
            if hp and maxHp and maxHp > 0 and (hp / maxHp) < Shared.CONSTANTS.AUTO_HEAL_THRESHOLD then
                Shared.DebugLog("AdvancedFeatures", string.format("[AUTO-HEAL] %s detected injured ally: %s (%.0f%%)", entity, target, (hp/maxHp)*100))
                
                -- OPTIONAL: Apply a temporary status to the TARGET that encourages AI to heal them
                -- This effectively "taunts" the healer's AI to target this friend
                Osi.ApplyStatus(target, "AI_HELPER_AVATAR", 6.0, 1, entity) 
            end
        end
    end
end

--- Handle aggression mode spell cast
--- @param caster string Caster UUID
--- @param target string Target UUID
--- @param spell string Spell name
function AdvancedFeatures.HandleAggressionSpell(caster, target, spell)
    if not Shared.CachedExists(target) then return end
    
    local modeMap = {
        [Shared.SPELL.SET_AGGRESSIVE] = "AGGRESSIVE",
        [Shared.SPELL.SET_DEFENSIVE] = "DEFENSIVE",
        [Shared.SPELL.SET_SUPPORT] = "SUPPORT"
    }
    
    local mode = modeMap[spell]
    if mode then
        AdvancedFeatures.SetAggressionMode(target, mode)
        Shared.DebugLog("AdvancedFeatures", string.format("%s set %s to %s mode", caster, target, mode))
    end
end

--- Updated Turn Handler
function AdvancedFeatures.OnTurnStarted(entity)
    if not Shared.ThrottleEvent("AdvancedFeatures_Turn_" .. entity) then
        return
    end
    
    -- Run the corrected Healer Logic
    AdvancedFeatures.ProcessHealerLogic(entity)
end

--- Register advanced features event listeners
function AdvancedFeatures.RegisterListeners()
    -- Handle auto-heal toggle spell
    Ext.Osiris.RegisterListener("CastFinished", 5, "after", function(caster, target, spell, _, _)
        if spell == Shared.SPELL.TOGGLE_AUTO_HEAL then
            AdvancedFeatures.ToggleAutoHeal(target)
        else
            AdvancedFeatures.HandleAggressionSpell(caster, target, spell)
        end
    end)
    
    -- Handle turn events for auto-heal
    Ext.Osiris.RegisterListener("TurnStarted", 1, "after", function(entity)
        AdvancedFeatures.OnTurnStarted(entity)
    end)
    
    Shared.DebugLog("AdvancedFeatures", "Advanced features listeners registered")
end

--- Initialize advanced features
function AdvancedFeatures.Initialize()
    Shared.DebugLog("AdvancedFeatures", "Advanced features initialized")
end

return AdvancedFeatures
