----------------------------------------------------------------------------------
-- Dialog Module: Dialog System and NPC/Player Conversion Management
-- Handles dialog interactions with AI allies, preserving their faction and state
----------------------------------------------------------------------------------

local Shared = Ext.Require("Shared.lua")
local AI = Ext.Require("AI.lua")
local Dialog = {}

-- Export shared references
local STATUS = Shared.STATUS
local DebugLog = Shared.DebugLog
local SafeOsiCall = Shared.SafeOsiCall
local CachedExists = Shared.CachedExists

-- Module state
local relevantDialogInstance = nil
local transformedCompanions = {}

----------------------------------------------------------------------------------
-- Helper Functions
----------------------------------------------------------------------------------
local function HasRelevantStatus(character)
    for _, status in ipairs(AI.aiCombatStatuses) do
        if Osi.HasActiveStatus(character, status) == 1 and Osi.HasActiveStatus(character, STATUS.TOGGLE_IS_NPC) == 1 then
            return true
        end
    end
    return false
end

local function IsCurrentAlly(actorUuid, CurrentAllies)
    return CurrentAllies[actorUuid] ~= nil
end

----------------------------------------------------------------------------------
-- Dialog Event Handlers
----------------------------------------------------------------------------------
local function HandleDialogStarted(dialog, instanceID)
    relevantDialogInstance = instanceID
    Ext.Utils.Print("Relevant dialog started for instance: " .. tostring(instanceID))
end

local function HandleDialogActorJoined(instanceID, actor, CurrentAllies)
    -- Validate actor exists
    if not actor then
        DebugLog("[ERROR] HandleDialogActorJoined called with nil actor", "DIALOG")
        return
    end
    
    local actorUuid = Osi.GetUUID(actor)
    if not actorUuid then
        DebugLog("[ERROR] Failed to get UUID for actor: " .. tostring(actor), "DIALOG")
        return
    end
    
    if not CachedExists(actor) then
        DebugLog("[ERROR] Actor does not exist: " .. actorUuid, "DIALOG")
        return
    end
    
    if instanceID == relevantDialogInstance and IsCurrentAlly(actorUuid, CurrentAllies) and HasRelevantStatus(actor) then
        local success, originalFaction = SafeOsiCall(Osi.GetFaction, actor)
        if success and originalFaction then
            transformedCompanions[actorUuid] = {
                wasNPC = true,
                faction = originalFaction,
                actorName = Osi.GetDisplayName(actor) or "Unknown"
            }
            
            local makePlayerSuccess = SafeOsiCall(Osi.MakePlayer, actor)
            if makePlayerSuccess then
                DebugLog("[DIALOG] Temporarily turned " .. transformedCompanions[actorUuid].actorName .. " (" .. actorUuid .. ") into player for dialog", "DIALOG")
            else
                DebugLog("[ERROR] Failed to convert " .. actorUuid .. " to player for dialog", "DIALOG")
                transformedCompanions[actorUuid] = nil
            end
        else
            DebugLog("[ERROR] Failed to get faction for actor " .. actorUuid .. " before dialog conversion", "DIALOG")
        end
    end
end

local function HandleDialogEnded(dialog, instanceID)
    if instanceID == relevantDialogInstance then
        local revertCount = 0
        local errorCount = 0
        
        for actorUuid, data in pairs(transformedCompanions) do
            if not CachedExists(actorUuid) then
                DebugLog("[WARNING] Actor " .. actorUuid .. " no longer exists, skipping reversion", "DIALOG")
                errorCount = errorCount + 1
            else
                -- Validate data structure
                if type(data) ~= "table" then
                    DebugLog("[ERROR] Invalid data structure for actor " .. actorUuid .. ", skipping", "DIALOG")
                    errorCount = errorCount + 1
                else
                    local success2, inCombat = SafeOsiCall(Osi.IsInCombat, actorUuid)
                    if success2 and inCombat == 0 then
                        DebugLog("[DIALOG] " .. (data.actorName or actorUuid) .. " not in combat, remaining as player", "DIALOG")
                    else
                        -- Revert to NPC
                        local makeNPCSuccess = SafeOsiCall(Osi.MakeNPC, actorUuid)
                        if makeNPCSuccess then
                            revertCount = revertCount + 1
                            
                            -- Restore faction
                            if data.faction then
                                local factionSuccess = SafeOsiCall(Osi.SetFaction, actorUuid, data.faction)
                                if factionSuccess then
                                    DebugLog("[DIALOG] Restored " .. (data.actorName or actorUuid) .. " to NPC with faction " .. data.faction, "DIALOG")
                                else
                                    DebugLog("[WARNING] Failed to restore faction " .. data.faction .. " for " .. actorUuid, "DIALOG")
                                end
                            else
                                DebugLog("[WARNING] No faction data stored for " .. actorUuid .. ", using default", "DIALOG")
                            end
                        else
                            DebugLog("[ERROR] Failed to revert " .. actorUuid .. " to NPC after dialog", "DIALOG")
                            errorCount = errorCount + 1
                        end
                    end
                end
            end
        end
        
        DebugLog("[DIALOG] Dialog ended - Reverted " .. revertCount .. " allies, " .. errorCount .. " errors", "DIALOG")
        transformedCompanions = {}
        relevantDialogInstance = nil
    end
end

--- Cleanup function to recover from dialog crashes
local function CleanupDialogState(CurrentAllies)
    for actorUuid, _ in pairs(transformedCompanions) do
        if CachedExists(actorUuid) == 1 and IsCurrentAlly(actorUuid, CurrentAllies) then
            local actor = actorUuid
            if HasRelevantStatus(actor) and Osi.IsInCombat(actor) == 1 then
                Osi.MakeNPC(actorUuid)
                Ext.Utils.Print("[RECOVERY] Reverted " .. actorUuid .. " back to NPC after session load")
            end
        end
    end
    transformedCompanions = {}
    relevantDialogInstance = nil
end

----------------------------------------------------------------------------------
-- Dialog Registration
----------------------------------------------------------------------------------
--- Register all dialog-related event listeners
function Dialog.RegisterListeners(CurrentAllies)
    Ext.Osiris.RegisterListener("DialogStarted", 2, "after", HandleDialogStarted)
    
    Ext.Osiris.RegisterListener("DialogActorJoined", 4, "after", function(dialog, instanceID, actor, speakerIndex)
        HandleDialogActorJoined(instanceID, actor, CurrentAllies)
    end)
    
    Ext.Osiris.RegisterListener("DialogEnded", 2, "after", HandleDialogEnded)
    
    -- Subscribe to SessionLoaded to clean up any stuck dialog states
    Ext.Events.SessionLoaded:Subscribe(function()
        CleanupDialogState(CurrentAllies)
    end)
end

return Dialog
