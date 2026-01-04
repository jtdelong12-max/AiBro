----------------------------------------------------------------------------------
-- Timer Module: Centralized Timer Management
-- Handles all timer-based operations (character addition, spell modification, combat resume, wildshape)
----------------------------------------------------------------------------------

local Shared = Ext.Require("Shared.lua")
local Timer = {}

-- Export shared references
local CONSTANTS = Shared.CONSTANTS
local DebugLog = Shared.DebugLog
local CachedExists = Shared.CachedExists

----------------------------------------------------------------------------------
-- Timer Registration
----------------------------------------------------------------------------------
--- Register consolidated timer listener
function Timer.RegisterListeners(CurrentAllies)
    Ext.Osiris.RegisterListener("TimerFinished", 1, "after", function(timer)
        -- Handle character addition timers
        local uuid = Mods.AIAllies.characterTimers[timer]
        if uuid and type(uuid) == "string" then
            CurrentAllies[uuid] = true
            Mods.AIAllies.PersistentVars.CurrentAllies = CurrentAllies
            Ext.Utils.Print("Added to CurrentAllies after delay: " .. uuid)
            Mods.AIAllies.characterTimers[timer] = nil
            return
        end
        
        -- Handle wildshape FORCE_USE status removal (table with object and status)
        if uuid and type(uuid) == "table" and uuid.object and uuid.status then
            if Osi.Exists(uuid.object) == 1 then
                Osi.RemoveStatus(uuid.object, uuid.status)
            end
            Mods.AIAllies.characterTimers[timer] = nil
            return
        end
        
        -- Handle spell modification timers
        local callback = Mods.AIAllies.spellModificationTimers[timer]
        if callback then
            callback()
            Mods.AIAllies.spellModificationTimers[timer] = nil
            return
        end
        
        -- Handle combat resume timers
        local combatGuid = Mods.AIAllies.combatTimers[timer]
        if combatGuid then
            Osi.ResumeCombat(combatGuid)
            Ext.Utils.Print("Resuming combat")
            Mods.AIAllies.combatTimers[timer] = nil
            Mods.AIAllies.combatStartTimes[combatGuid] = nil
            return
        end
    end)
end

return Timer
