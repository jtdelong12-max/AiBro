----------------------------------------------------------------------------------
-- SpellControl Module: Spell Spam Prevention and Smart Casting
-- Prevents AI from spamming the same spell or wasting resources on low-value casts
----------------------------------------------------------------------------------

local Shared = Ext.Require("Shared.lua")
local SpellControl = {}

-- Track recent spell usage per entity
local recentSpellUsage = {}
local SPELL_COOLDOWN_TRACKING = 3000 -- Track spells used in last 3 seconds
local MAX_SAME_SPELL_USES = 2 -- Max times same spell can be used consecutively

----------------------------------------------------------------------------------
-- Non-Combat/Utility Spells to Block During Combat
-- These are handled via Block_AI.txt but we provide Lua-level tracking as backup
----------------------------------------------------------------------------------
local utlitySpellsToBlock = {
    -- Movement/Positioning (already in Block_AI.txt)
    "Target_Longstrider",
    "Shout_FeatherFall",
    "Target_GaseousForm",
    "Shout_Disengage",
    
    -- Buffs that should be pre-combat only
    "Target_Sanctuary",
    "Target_WardingBond",
    "Target_BlessingOfTheTrickster",
    "Target_Guidance",
    
    -- Social/Utility
    "Shout_Thaumaturgy",
    "Target_Sleep", -- Low value in most combats
    
    -- Modded utility detection patterns
    -- Add common patterns for modded utility spells
    "_Utility_",
    "_NonCombat_",
    "_Exploration_"
}

--- Check if a spell is a utility spell that should be blocked in combat
--- @param spellName string The spell name to check
--- @return boolean blocked True if spell should be blocked
function SpellControl.IsUtilitySpell(spellName)
    if not spellName then return false end
    
    for _, pattern in ipairs(utlitySpellsToBlock) do
        if string.find(spellName, pattern) then
            return true
        end
    end
    
    return false
end

--- Check if entity has used a spell too recently (spam prevention)
--- @param entity string Entity UUID
--- @param spellName string Spell name
--- @return boolean spamming True if spell is being spammed
function SpellControl.IsSpamming(entity, spellName)
    if not entity or not spellName then return false end
    
    local currentTime = Ext.Utils.MonotonicTime()
    
    -- Initialize tracking for this entity if needed
    if not recentSpellUsage[entity] then
        recentSpellUsage[entity] = {}
    end
    
    -- Clean up old entries (older than cooldown tracking window)
    local cleaned = {}
    for spell, uses in pairs(recentSpellUsage[entity]) do
        local recentUses = {}
        for _, timestamp in ipairs(uses) do
            if currentTime - timestamp < SPELL_COOLDOWN_TRACKING then
                table.insert(recentUses, timestamp)
            end
        end
        if #recentUses > 0 then
            cleaned[spell] = recentUses
        end
    end
    recentSpellUsage[entity] = cleaned
    
    -- Check if this spell has been used too much recently
    local uses = recentSpellUsage[entity][spellName] or {}
    if #uses >= MAX_SAME_SPELL_USES then
        Shared.DebugLog(string.format("[SPAM] %s has used %s %d times recently", 
            entity, spellName, #uses), "SPELL")
        return true
    end
    
    return false
end

--- Record that an entity used a spell
--- @param entity string Entity UUID
--- @param spellName string Spell name
function SpellControl.RecordSpellUse(entity, spellName)
    if not entity or not spellName then return end
    
    local currentTime = Ext.Utils.MonotonicTime()
    
    if not recentSpellUsage[entity] then
        recentSpellUsage[entity] = {}
    end
    
    if not recentSpellUsage[entity][spellName] then
        recentSpellUsage[entity][spellName] = {}
    end
    
    table.insert(recentSpellUsage[entity][spellName], currentTime)
    
    Shared.DebugLog(string.format("[SPELL] %s used %s", entity, spellName), "SPELL")
end

--- Clear spell usage tracking for an entity (call on combat end)
--- @param entity string Entity UUID
function SpellControl.ClearSpellTracking(entity)
    if entity and recentSpellUsage[entity] then
        recentSpellUsage[entity] = nil
        Shared.DebugLog("[SPAM] Cleared spell tracking for " .. entity, "SPELL")
    end
end

--- Clear all spell tracking (call on session restart)
function SpellControl.ClearAllSpellTracking()
    recentSpellUsage = {}
    Shared.DebugLog("[SPAM] Cleared all spell tracking", "SPELL")
end

----------------------------------------------------------------------------------
-- Event Listeners
----------------------------------------------------------------------------------
--- Register spell control event listeners
function SpellControl.RegisterListeners()
    -- Track spell usage
    Ext.Osiris.RegisterListener("SpellCast", 5, "after", function(caster, spell, spellType, spellElement, storyActionID)
        if caster and spell then
            SpellControl.RecordSpellUse(caster, spell)
        end
    end)
    
    -- Clear tracking on combat end
    Ext.Osiris.RegisterListener("CombatEnded", 1, "after", function(combatGuid)
        -- Clear tracking for all participants
        local participants = Osi.DB_CombatCharacters:Get(combatGuid, nil)
        if participants then
            for _, participant in pairs(participants) do
                if participant and participant[2] then
                    SpellControl.ClearSpellTracking(participant[2])
                end
            end
        end
    end)
    
    Shared.DebugLog("[INIT] SpellControl listeners registered", "SYSTEM")
end

return SpellControl
