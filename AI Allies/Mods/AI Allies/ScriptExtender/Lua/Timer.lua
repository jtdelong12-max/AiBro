----------------------------------------------------------------------------------
-- Timer Module: Centralized Timer Management
-- Handles all timer-based operations (character addition, spell modification, combat resume, wildshape)
--
-- Why use timers instead of direct execution:
-- 1. Osiris API restrictions: Some operations fail if called during certain events
-- 2. State synchronization: Delays allow game state to stabilize before modifications
-- 3. Race condition prevention: Timers serialize operations that could conflict
-- 4. Animation coordination: Delays sync with character animations and transitions
--
-- Timer lifecycle:
-- 1. Operation needed → Register timer with callback/data
-- 2. Timer launches with appropriate delay
-- 3. TimerFinished event fires → Lookup timer, execute operation
-- 4. Cleanup timer from tracking table
----------------------------------------------------------------------------------

local Shared = Ext.Require("Shared.lua")
local Timer = {}

-- Export shared references
local CONSTANTS = Shared.CONSTANTS
local DebugLog = Shared.DebugLog
local CachedExists = Shared.CachedExists

----------------------------------------------------------------------------------
-- Timer Tracking and Cleanup
----------------------------------------------------------------------------------
-- Track all active timers for cleanup and debugging
-- Structure: {timerName = {type = "character"|"combat"|"spell"|"wildshape", timestamp = createTime}}
local activeTimers = {}
local TIMER_CLEANUP_INTERVAL = 60000  -- Clean up expired timers every 60 seconds
local TIMER_MAX_AGE = 300000  -- Consider timers older than 5 minutes as expired

--- Register a timer for tracking
--- @param timerName string The timer identifier
--- @param timerType string The type of timer (character, combat, spell, wildshape)
function Timer.RegisterTimer(timerName, timerType)
    activeTimers[timerName] = {
        type = timerType,
        timestamp = Ext.Utils.MonotonicTime()
    }
end

--- Remove a timer from tracking
--- @param timerName string The timer identifier
local function UnregisterTimer(timerName)
    activeTimers[timerName] = nil
end

--- Clean up expired or orphaned timers
--- Timers may become orphaned if:
--- - The target entity was destroyed before timer fired
--- - Combat ended before combat timer fired
--- - Character left party before character timer fired
--- @param characterTimers table Reference to character timers table
--- @param spellTimers table Reference to spell modification timers table
--- @param combatTimers table Reference to combat timers table
local function CleanupExpiredTimers(characterTimers, spellTimers, combatTimers)
    local currentTime = Ext.Utils.MonotonicTime()
    local cleanedCount = 0
    
    for timerName, timerData in pairs(activeTimers) do
        local age = currentTime - timerData.timestamp
        
        if age > TIMER_MAX_AGE then
            -- Timer is too old, likely orphaned
            DebugLog("[TIMER CLEANUP] Removing expired timer: " .. timerName .. " (age: " .. age .. "ms)", "TIMER")
            
            -- Clean up from tracking tables
            if characterTimers then characterTimers[timerName] = nil end
            if spellTimers then spellTimers[timerName] = nil end
            if combatTimers then combatTimers[timerName] = nil end
            
            activeTimers[timerName] = nil
            cleanedCount = cleanedCount + 1
        end
    end
    
    if cleanedCount > 0 then
        DebugLog("[TIMER CLEANUP] Cleaned up " .. cleanedCount .. " expired timers", "TIMER")
    end
end

--- Initialize timer cleanup system
local function InitializeTimerCleanup()
    -- Start periodic cleanup timer
    Osi.TimerLaunch("AIAllies_TimerCleanup", TIMER_CLEANUP_INTERVAL)
end

--- Stop timer cleanup system
local function StopTimerCleanup()
    -- Cancel the cleanup timer (BG3 automatically cancels all timers on session end,
    -- but we clear the tracking table to prevent issues on reload)
    activeTimers = {}
    DebugLog("[TIMER] Timer cleanup system stopped", "TIMER")
end

----------------------------------------------------------------------------------
-- Timer Registration
----------------------------------------------------------------------------------
--- Register consolidated timer listener
function Timer.RegisterListeners(CurrentAllies)
    Ext.Osiris.RegisterListener("TimerFinished", 1, "after", function(timer)
        -- Handle periodic timer cleanup
        if timer == "AIAllies_TimerCleanup" then
            CleanupExpiredTimers(
                Mods.AIAllies.characterTimers,
                Mods.AIAllies.spellModificationTimers,
                Mods.AIAllies.combatTimers
            )
            -- Relaunch cleanup timer
            Osi.TimerLaunch("AIAllies_TimerCleanup", TIMER_CLEANUP_INTERVAL)
            return
        end
        
        -- Handle character addition timers
        local uuid = Mods.AIAllies.characterTimers[timer]
        if uuid and type(uuid) == "string" then
            CurrentAllies[uuid] = true
            Mods.AIAllies.PersistentVars.CurrentAllies = CurrentAllies
            Ext.Utils.Print("Added to CurrentAllies after delay: " .. uuid)
            Mods.AIAllies.characterTimers[timer] = nil
            UnregisterTimer(timer)
            return
        end
        
        -- Handle wildshape FORCE_USE status removal (table with object and status)
        if uuid and type(uuid) == "table" and uuid.object and uuid.status then
            if Osi.Exists(uuid.object) == 1 then
                Osi.RemoveStatus(uuid.object, uuid.status)
            end
            Mods.AIAllies.characterTimers[timer] = nil
            UnregisterTimer(timer)
            return
        end
        
        -- Handle spell modification timers
        local callback = Mods.AIAllies.spellModificationTimers[timer]
        if callback then
            callback()
            Mods.AIAllies.spellModificationTimers[timer] = nil
            UnregisterTimer(timer)
            return
        end
        
        -- Handle combat resume timers
        local combatGuid = Mods.AIAllies.combatTimers[timer]
        if combatGuid then
            Osi.ResumeCombat(combatGuid)
            Ext.Utils.Print("Resuming combat")
            Mods.AIAllies.combatTimers[timer] = nil
            Mods.AIAllies.combatStartTimes[combatGuid] = nil
            UnregisterTimer(timer)
            return
        end
    end)
    
    -- Initialize timer cleanup on session load
    Ext.Events.SessionLoaded:Subscribe(function()
        InitializeTimerCleanup()
        DebugLog("[TIMER] Timer cleanup system initialized", "TIMER")
    end)
    
    -- Stop timer cleanup on session ending
    Ext.Events.SessionEnding:Subscribe(function()
        StopTimerCleanup()
    end)
end

return Timer
