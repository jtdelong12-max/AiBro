----------------------------------------------------------------------------------
-- Combat Module: Combat Systems, Spell Modifications, and Status Management
-- Handles combat entry/exit, spell modifications, and combat-related status tracking
----------------------------------------------------------------------------------

local Shared = Ext.Require("Shared.lua")
local AI = Ext.Require("AI.lua")
local Combat = {}

-- Export shared references
local STATUS = Shared.STATUS
local SPELL = Shared.SPELL
local CONSTANTS = Shared.CONSTANTS
local DebugLog = Shared.DebugLog
local SafeOsiCall = Shared.SafeOsiCall
local CachedExists = Shared.CachedExists
local ThrottleEvent = Shared.ThrottleEvent

----------------------------------------------------------------------------------
-- Spell Mappings and Modifications
----------------------------------------------------------------------------------
-- Mapping of original spells to their AI versions
local spellMappings = {
    [SPELL.ACTION_SURGE] = SPELL.ACTION_SURGE_AI,
    [SPELL.DASH] = SPELL.DASH_AI,
    [SPELL.DASH_CUNNING] = SPELL.DASH_CUNNING_AI,
    [SPELL.RAGE_BERSERKER] = SPELL.RAGE_BERSERKER_AI,
    [SPELL.RAGE_WILDHEART] = SPELL.RAGE_WILDHEART_AI,
    [SPELL.RAGE_WILDMAGIC] = SPELL.RAGE_WILDMAGIC_AI
}

--- Add or remove AI-specific spell variants for a character
--- @param character string The character UUID
--- @param addSpell boolean True to add AI spells, false to remove them
function Combat.ModifyAISpells(character, addSpell)
    if not character or CachedExists(character) ~= 1 then
        Ext.Utils.Print("[WARNING] Cannot modify spells - invalid character: " .. tostring(character))
        return
    end
    
    for originalSpell, aiSpell in pairs(spellMappings) do
        local success, hasAIVersion = SafeOsiCall(Osi.HasSpell, character, aiSpell)
        if not success then
            hasAIVersion = false
        end
        
        if addSpell and hasAIVersion == 0 then
            local addSuccess = SafeOsiCall(Osi.AddSpell, character, aiSpell)
            if addSuccess then
                DebugLog("Added " .. aiSpell .. " to " .. character, "SPELL")
            end
        elseif not addSpell and hasAIVersion == 1 then
            local removeSuccess = SafeOsiCall(Osi.RemoveSpell, character, aiSpell)
            if removeSuccess then
                DebugLog("Removed " .. aiSpell .. " from " .. character, "SPELL")
            end
        end
    end
    
    if addSpell then
        Mods.AIAllies.modifiedCharacters[character] = true
    else
        Mods.AIAllies.modifiedCharacters[character] = nil
    end
end

----------------------------------------------------------------------------------
-- Combat Event Handlers
----------------------------------------------------------------------------------
--- Register all combat-related event listeners
function Combat.RegisterListeners(CurrentAllies)
    -- CombatStarted: Apply AI_ALLY status to all allies
    Ext.Osiris.RegisterListener("CombatStarted", 1, "after", function(combatGuid)
        for uuid, _ in pairs(CurrentAllies) do
            if CurrentAllies[uuid] and CachedExists(uuid) == 1 then
                Osi.ApplyStatus(uuid, STATUS.AI_ALLY, -1)
            elseif CurrentAllies[uuid] and CachedExists(uuid) ~= 1 then
                CurrentAllies[uuid] = nil
                Ext.Utils.Print("[CLEANUP] Removed dead entity from CurrentAllies: " .. uuid)
            end
        end
        
        -- Pause combat to allow AI initialization
        Osi.PauseCombat(combatGuid)
        DebugLog("Pausing combat to allow AI to initialize", "COMBAT")
        local InitializeTimerAI = "ResumeCombatTimer_" .. tostring(combatGuid)
        Mods.AIAllies.combatTimers[InitializeTimerAI] = combatGuid
        Mods.AIAllies.combatStartTimes[combatGuid] = Ext.Utils.MonotonicTime()
        Osi.TimerLaunch(InitializeTimerAI, CONSTANTS.COMBAT_RESUME_DELAY)
    end)
    
    -- EnteredCombat: Apply archetype and AI statuses
    Ext.Osiris.RegisterListener("EnteredCombat", 2, "after", function(object, combatGuid)
        if AI.hasControllerStatus(object) and not AI.hasAnyAICombatStatus(object) then
            AI.ApplyStatusFromControllerBuff(object)
        end
        if AI.hasControllerStatus(object) then
            Osi.ApplyStatus(object, STATUS.AI_ALLY, CONSTANTS.AI_ALLY_DURATION)
            Osi.ApplyStatus(object, STATUS.FOR_AI_SPELLS, CONSTANTS.FOR_AI_SPELLS_DURATION)
        end
    end)
    
    -- EnteredForceTurnBased: Similar to CombatStarted
    Ext.Osiris.RegisterListener("EnteredForceTurnBased", 2, "after", function(object, combatGuid)
        for uuid, _ in pairs(CurrentAllies) do
            if CurrentAllies[uuid] and CachedExists(uuid) == 1 then
                Osi.ApplyStatus(uuid, STATUS.AI_ALLY, -1)
            end
        end
    end)
    
    -- CombatEnded: Remove all AI combat statuses
    Ext.Osiris.RegisterListener("CombatEnded", 1, "after", function(combatGuid)
        for uuid, _ in pairs(CurrentAllies) do
            for _, status in ipairs(AI.aiCombatStatuses) do
                if Osi.HasActiveStatus(uuid, status) == 1 then
                    Osi.RemoveStatus(uuid, status)
                end
            end
            
            -- Clean up orphaned statuses
            if Mods.AIAllies.appliedStatuses[uuid] then
                for _, status in ipairs(Mods.AIAllies.appliedStatuses[uuid]) do
                    if Osi.HasActiveStatus(uuid, status) == 1 then
                        Osi.RemoveStatus(uuid, status)
                        Ext.Utils.Print("[CLEANUP] Removed orphaned status " .. status .. " from " .. uuid)
                    end
                end
                Mods.AIAllies.appliedStatuses[uuid] = nil
            end
        end
    end)
    
    -- StatusApplied: Handle controller statuses during combat
    Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, causee, storyActionID)
        if AI.isControllerStatus(status) and Osi.IsInCombat(object) == 1 then
            AI.ApplyStatusFromControllerBuff(object)
        end
    end)
    
    -- StatusRemoved: Revert NPC back to player
    Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", function(object, status, causee, storyActionID)
        if AI.IsNPCStatus(status) then
            Osi.MakePlayer(object)
        end
    end)
    
    -- TurnStarted: Apply status based on controller buff (throttled)
    Ext.Osiris.RegisterListener("TurnStarted", 1, "after", function(character)
        if ThrottleEvent("TurnStarted_" .. character) then
            if not AI.hasAnyNPCStatus(character) then
                local status = AI.ApplyStatusBasedOnBuff(character)
                if status then
                    Mods.AIAllies.appliedStatuses[character] = status
                end
            end
        end
    end)
    
    -- TurnEnded: Remove temporary status (throttled)
    Ext.Osiris.RegisterListener("TurnEnded", 1, "after", function(character)
        if ThrottleEvent("TurnEnded_" .. character) then
            if not AI.hasAnyNPCStatus(character) then
                local status = Mods.AIAllies.appliedStatuses[character]
                if status then
                    local success = SafeOsiCall(Osi.RemoveStatus, character, status, character)
                    if success then
                        DebugLog("Removed " .. status .. " from " .. character, "TURN")
                    end
                    Mods.AIAllies.appliedStatuses[character] = nil
                end
            end
        end
    end)
    
    -- Safety mechanism: Force resume combat if paused too long
    Ext.Osiris.RegisterListener("TurnStarted", 1, "after", function(entityGuid)
        local combatGuid = Osi.CombatGetGuidFor(entityGuid)
        if combatGuid and Mods.AIAllies.combatStartTimes[combatGuid] then
            local elapsed = Ext.Utils.MonotonicTime() - Mods.AIAllies.combatStartTimes[combatGuid]
            if elapsed > CONSTANTS.COMBAT_SAFETY_TIMEOUT then
                Osi.ResumeCombat(combatGuid)
                Ext.Utils.Print("[SAFETY] Force resuming combat after timeout: " .. combatGuid)
                Mods.AIAllies.combatStartTimes[combatGuid] = nil
                for timer, guid in pairs(Mods.AIAllies.combatTimers) do
                    if guid == combatGuid then
                        Mods.AIAllies.combatTimers[timer] = nil
                    end
                end
            end
        end
    end)
    
    -- StatusApplied: Queue spell modifications when combat status applied
    Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(character, status, causee, storyActionID)
        if AI.hasAnyAICombatStatus(character) and not Mods.AIAllies.modifiedCharacters[character] and Osi.HasActiveStatus(character, STATUS.TOGGLE_IS_NPC) == 0 then
            local timerName = "ModifySpells_" .. character
            Mods.AIAllies.spellModificationTimers[timerName] = function()
                Combat.ModifyAISpells(character, true)
            end
            Osi.TimerLaunch(timerName, CONSTANTS.SPELL_MODIFICATION_DELAY)
        end
    end)
    
    -- StatusRemoved: Remove AI spells when FOR_AI_SPELLS removed
    Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", function(character, status, causee, storyActionID)
        if status == STATUS.FOR_AI_SPELLS then
            local success = SafeOsiCall(Combat.ModifyAISpells, character, false)
            if success then
                DebugLog("Removed AI spells from " .. character, "SPELL")
            end
        end
    end)
    
    -- Wildshape: Delay removal to give AI time to process
    Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, causee, storyActionID)
        if status == STATUS.FORCE_USE_MOST or status == STATUS.FORCE_USE_MORE then
            local wildshapeTimer = "WildshapeForceRemove_" .. object .. "_" .. status
            Mods.AIAllies.characterTimers[wildshapeTimer] = {object = object, status = status}
            Osi.TimerLaunch(wildshapeTimer, CONSTANTS.WILDSHAPE_REMOVAL_DELAY)
        end
    end)
end

----------------------------------------------------------------------------------
-- Swarm Mechanic
----------------------------------------------------------------------------------
--- Handle swarm group assignment
function Combat.HandleSwarmGroupAssignment(caster, target, spell)
    local swarmGroups = {
        Target_Allies_Swarm_Group_Alpha = "AlliesSwarm_Alpha",
        Target_Allies_Swarm_Group_Bravo = "AlliesSwarm_Bravo",
        Target_Allies_Swarm_Group_Charlie = "AlliesSwarm_Charlie",
        Target_Allies_Swarm_Group_Delta = "AlliesSwarm_Delta",
        Target_Allies_Swarm_Group_e_Clear = ""
    }
    
    local swarmGroup = swarmGroups[spell]
    if swarmGroup ~= nil then
        Osi.RequestSetSwarmGroup(target, swarmGroup)
        if swarmGroup == "" then
            Ext.Utils.Print(string.format("Cleared swarm group for %s", target))
        else
            Ext.Utils.Print(string.format("Added %s to swarm group: %s", target, swarmGroup))
        end
    end
end

--- Set fixed initiative value for swarm members
function Combat.SetInitiativeToFixedValue(target, fixedInitiative)
    local entity = Ext.Entity.Get(target)
    
    if entity and entity.CombatParticipant and entity.CombatParticipant.CombatHandle then
        entity.CombatParticipant.InitiativeRoll = fixedInitiative
        entity.CombatParticipant.CombatHandle.CombatState.Initiatives[entity] = fixedInitiative
        entity:Replicate("CombatParticipant")
    else
        Ext.Utils.Print(string.format("Failed to set initiative for %s: Entity or CombatHandle is nil.", target))
    end
end

--- Register swarm mechanic listeners
function Combat.RegisterSwarmListeners()
    Ext.Osiris.RegisterListener("EnteredCombat", 2, "after", function(object, combatGuid)
        local swarmGroup = Osi.GetSwarmGroup(object)
        
        if swarmGroup == "AlliesSwarm_Alpha" or swarmGroup == "AlliesSwarm_Bravo" or 
           swarmGroup == "AlliesSwarm_Charlie" or swarmGroup == "AlliesSwarm_Delta" then
            Combat.SetInitiativeToFixedValue(object, 6)
        end
    end)
    
    Ext.Osiris.RegisterListener("UsingSpellOnTarget", 6, "after", function(caster, target, spell, spellType, spellElement, storyActionID)
        Combat.HandleSwarmGroupAssignment(caster, target, spell)
    end)
end

return Combat
