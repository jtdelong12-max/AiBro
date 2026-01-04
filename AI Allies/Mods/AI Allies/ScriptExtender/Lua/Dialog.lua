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
    local actorUuid = Osi.GetUUID(actor)
    if not actorUuid or CachedExists(actor) ~= 1 then
        return
    end
    
    if instanceID == relevantDialogInstance and IsCurrentAlly(actorUuid, CurrentAllies) and HasRelevantStatus(actor) then
        local success, originalFaction = SafeOsiCall(Osi.GetFaction, actor)
        if success then
            transformedCompanions[actorUuid] = {
                wasNPC = true,
                faction = originalFaction
            }
            
            local makePlayerSuccess = SafeOsiCall(Osi.MakePlayer, actor)
            if makePlayerSuccess then
                DebugLog("Temporarily turned " .. actor .. " into a player for dialog instance " .. tostring(instanceID), "DIALOG")
            end
        end
    end
end

local function HandleDialogEnded(dialog, instanceID)
    if instanceID == relevantDialogInstance then
        for actorUuid, data in pairs(transformedCompanions) do
            if CachedExists(actorUuid) ~= 1 then
                Ext.Utils.Print("[WARNING] Actor " .. actorUuid .. " no longer exists, skipping reversion")
            else
                local success2, inCombat = SafeOsiCall(Osi.IsInCombat, actorUuid)
                if success2 and inCombat == 0 then
                    DebugLog("Character " .. actorUuid .. " is not in combat, remaining as player character after dialog end.", "DIALOG")
                else
                    local makeNPCSuccess = SafeOsiCall(Osi.MakeNPC, actorUuid)
                    if makeNPCSuccess then
                        if type(data) == "table" and data.faction then
                            local factionSuccess = SafeOsiCall(Osi.SetFaction, actorUuid, data.faction)
                            if factionSuccess then
                                DebugLog("[FACTION] Restored faction for " .. actorUuid .. " to " .. data.faction, "DIALOG")
                            end
                        end
                        DebugLog("Reverted " .. actorUuid .. " back to NPC after dialog end in instance " .. tostring(instanceID), "DIALOG")
                    end
                end
            end
        end
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
