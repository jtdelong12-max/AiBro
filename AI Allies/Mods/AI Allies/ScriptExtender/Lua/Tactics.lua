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
--- Enforce exclusivity between aggression modes
--- When one mode is toggled on, the others are automatically toggled off
function Tactics.RegisterListeners()
    -- Listen for Status Application to enforce exclusivity
    Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, causee, storyActionID)
        if status == STATUS.AGGRESSIVE_MODE then
            -- If Aggressive applied, turn off Defensive and Support
            if Osi.HasStatus(object, STATUS.DEFENSIVE_MODE) == 1 then
                Osi.RemoveStatus(object, STATUS.DEFENSIVE_MODE)
            end
            if Osi.HasStatus(object, STATUS.SUPPORT_MODE) == 1 then
                Osi.RemoveStatus(object, STATUS.SUPPORT_MODE)
            end
            if Osi.HasPassive(object, "Passive_AI_Mode_Conservative") == 1 then
                Osi.RemovePassive(object, "Passive_AI_Mode_Conservative")
            end
            ShowModeOverhead(object, "Aggressive mode")
        elseif status == STATUS.DEFENSIVE_MODE then
            -- If Defensive applied, turn off Aggressive and Support
            if Osi.HasStatus(object, STATUS.AGGRESSIVE_MODE) == 1 then
                Osi.RemoveStatus(object, STATUS.AGGRESSIVE_MODE)
            end
            if Osi.HasStatus(object, STATUS.SUPPORT_MODE) == 1 then
                Osi.RemoveStatus(object, STATUS.SUPPORT_MODE)
            end
            if Osi.HasPassive(object, "Passive_AI_Mode_Aggressive") == 1 then
                Osi.RemovePassive(object, "Passive_AI_Mode_Aggressive")
            end
            ShowModeOverhead(object, "Defensive mode")
        elseif status == STATUS.SUPPORT_MODE then
            -- If Support applied, turn off Aggressive and Defensive
            if Osi.HasStatus(object, STATUS.AGGRESSIVE_MODE) == 1 then
                Osi.RemoveStatus(object, STATUS.AGGRESSIVE_MODE)
            end
            if Osi.HasStatus(object, STATUS.DEFENSIVE_MODE) == 1 then
                Osi.RemoveStatus(object, STATUS.DEFENSIVE_MODE)
            end
            if Osi.HasPassive(object, "Passive_AI_Mode_Aggressive") == 1 then
                Osi.RemovePassive(object, "Passive_AI_Mode_Aggressive")
            end
            if Osi.HasPassive(object, "Passive_AI_Mode_Conservative") == 1 then
                Osi.RemovePassive(object, "Passive_AI_Mode_Conservative")
            end
            ShowModeOverhead(object, "Support mode")
        elseif status == STATUS.AUTO_HEAL_ENABLED then
            ShowModeOverhead(object, "Auto-heal enabled")
        end
    end)
    
    DebugLog("Tactics module listeners registered", "TACTICS")
end

return Tactics
