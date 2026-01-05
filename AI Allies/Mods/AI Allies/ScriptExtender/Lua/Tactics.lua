----------------------------------------------------------------------------------
-- Tactics Module: AI Behavior Toggle Management
-- Manages exclusive toggleable passives for AI combat tactics
----------------------------------------------------------------------------------

local Tactics = {}
local Shared = Ext.Require("Shared.lua")

-- Export shared references
local DebugLog = Shared.DebugLog

----------------------------------------------------------------------------------
-- Exclusive Passive Management
----------------------------------------------------------------------------------
--- Enforce exclusivity between Aggressive and Conservative modes
--- When one mode is toggled on, the other is automatically toggled off
function Tactics.RegisterListeners()
    -- Listen for Status Application to enforce exclusivity
    Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, causee, storyActionID)
        if status == "ALLIES_AGGRESSIVE" then
            -- If Aggressive applied, turn off Conservative
            if Osi.HasPassive(object, "Passive_AI_Mode_Conservative") == 1 then
                Osi.RemovePassive(object, "Passive_AI_Mode_Conservative")
                DebugLog("Tactics: Removed Conservative mode (Aggressive activated)", "TACTICS")
            end
        elseif status == "ALLIES_DEFENSIVE" then
            -- If Conservative applied, turn off Aggressive
            if Osi.HasPassive(object, "Passive_AI_Mode_Aggressive") == 1 then
                Osi.RemovePassive(object, "Passive_AI_Mode_Aggressive")
                DebugLog("Tactics: Removed Aggressive mode (Conservative activated)", "TACTICS")
            end
        end
    end)
    
    DebugLog("Tactics module listeners registered", "TACTICS")
end

return Tactics
