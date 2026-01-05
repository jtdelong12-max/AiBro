----------------------------------------------------------------------------------
-- Tactics Module: AI Behavior Toggle Management
-- Manages exclusive toggleable passives for AI combat tactics
----------------------------------------------------------------------------------

local Tactics = {}
local Shared = Ext.Require("Shared.lua")

-- Export shared references
local DebugLog = Shared.DebugLog
local STATUS = Shared.STATUS

--- Show a short overhead message when a mode changes
--- @param object string Entity UUID
--- @param message string Message to display
local function ShowModeOverhead(object, message)
    if not object or not message then
        return
    end
    Osi.CharacterShowOverheadText(object, message, 3)
end

----------------------------------------------------------------------------------
-- Exclusive Passive Management
----------------------------------------------------------------------------------
--- Enforce exclusivity between Aggressive and Conservative modes
--- When one mode is toggled on, the other is automatically toggled off
function Tactics.RegisterListeners()
    -- Listen for Status Application to enforce exclusivity
    Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, causee, storyActionID)
        if status == STATUS.AGGRESSIVE_MODE then
            -- If Aggressive applied, turn off Conservative
            if Osi.HasPassive(object, "Passive_AI_Mode_Conservative") == 1 then
                Osi.RemovePassive(object, "Passive_AI_Mode_Conservative")
                DebugLog("Tactics: Removed Conservative mode (Aggressive activated)", "TACTICS")
            end
            ShowModeOverhead(object, "Aggressive mode")
        elseif status == STATUS.DEFENSIVE_MODE then
            -- If Conservative applied, turn off Aggressive
            if Osi.HasPassive(object, "Passive_AI_Mode_Aggressive") == 1 then
                Osi.RemovePassive(object, "Passive_AI_Mode_Aggressive")
                DebugLog("Tactics: Removed Aggressive mode (Conservative activated)", "TACTICS")
            end
            ShowModeOverhead(object, "Defensive mode")
        elseif status == STATUS.AUTO_HEAL_ENABLED then
            ShowModeOverhead(object, "Auto-heal enabled")
        end
    end)
    
    DebugLog("Tactics module listeners registered", "TACTICS")
end

return Tactics
