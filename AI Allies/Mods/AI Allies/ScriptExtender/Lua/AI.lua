----------------------------------------------------------------------------------
-- AI Module: Archetype Management and Status Handling
-- Handles AI status tracking, archetype application, and combat status management
----------------------------------------------------------------------------------

local Shared = Ext.Require("Shared.lua")
local AI = {}

-- Export shared references for easy access
local STATUS = Shared.STATUS
local CONSTANTS = Shared.CONSTANTS
local DebugLog = Shared.DebugLog
local SafeOsiCall = Shared.SafeOsiCall
local CachedExists = Shared.CachedExists

----------------------------------------------------------------------------------
-- Status Lists and Tracking
----------------------------------------------------------------------------------
-- List of AI statuses to track for CurrentAllies
AI.aiStatuses = {
    STATUS.MELEE_CONTROLLER,
    STATUS.RANGED_CONTROLLER,
    STATUS.HEALER_MELEE_CONTROLLER,
    STATUS.HEALER_RANGED_CONTROLLER,
    STATUS.MAGE_MELEE_CONTROLLER,
    STATUS.MAGE_RANGED_CONTROLLER,
    STATUS.GENERAL_CONTROLLER,
    STATUS.TRICKSTER_CONTROLLER,
    STATUS.AI_CONTROLLED,
    STATUS.CUSTOM_CONTROLLER,
    STATUS.CUSTOM_CONTROLLER_2,
    STATUS.CUSTOM_CONTROLLER_3,
    STATUS.CUSTOM_CONTROLLER_4,
    STATUS.THROWER_CONTROLLER,
    STATUS.DEFAULT_CONTROLLER
}

-- List of all combat statuses
AI.aiCombatStatuses = {
    STATUS.MELEE,
    STATUS.RANGED,
    STATUS.HEALER_MELEE,
    STATUS.HEALER_RANGED,
    STATUS.MAGE_MELEE,
    STATUS.MAGE_RANGED,
    STATUS.GENERAL,
    STATUS.CUSTOM,
    STATUS.CUSTOM_2,
    STATUS.CUSTOM_3,
    STATUS.CUSTOM_4,
    STATUS.TRICKSTER,
    STATUS.THROWER,
    STATUS.DEFAULT,
    STATUS.MELEE_NPC,
    STATUS.RANGED_NPC,
    STATUS.HEALER_MELEE_NPC,
    STATUS.HEALER_RANGED_NPC,
    STATUS.MAGE_MELEE_NPC,
    STATUS.MAGE_RANGED_NPC,
    STATUS.GENERAL_NPC,
    STATUS.CUSTOM_NPC,
    STATUS.CUSTOM_2_NPC,
    STATUS.CUSTOM_3_NPC,
    STATUS.CUSTOM_4_NPC,
    STATUS.TRICKSTER_NPC,
    STATUS.THROWER_NPC,
    STATUS.DEFAULT_NPC
}

-- List of NPC statuses
AI.NPCStatuses = {
    STATUS.MELEE_NPC,
    STATUS.RANGED_NPC,
    STATUS.HEALER_MELEE_NPC,
    STATUS.HEALER_RANGED_NPC,
    STATUS.MAGE_MELEE_NPC,
    STATUS.MAGE_RANGED_NPC,
    STATUS.GENERAL_NPC,
    STATUS.CUSTOM_NPC,
    STATUS.CUSTOM_2_NPC,
    STATUS.CUSTOM_3_NPC,
    STATUS.CUSTOM_4_NPC,
    STATUS.TRICKSTER_NPC,
    STATUS.THROWER_NPC,
    STATUS.DEFAULT_NPC
}

-- Mapping of controller buffs to combat status buffs
AI.controllerToStatusTranslator = {
    [STATUS.MELEE_CONTROLLER] = STATUS.MELEE,
    [STATUS.RANGED_CONTROLLER] = STATUS.RANGED,
    [STATUS.HEALER_MELEE_CONTROLLER] = STATUS.HEALER_MELEE,
    [STATUS.HEALER_RANGED_CONTROLLER] = STATUS.HEALER_RANGED,
    [STATUS.MAGE_MELEE_CONTROLLER] = STATUS.MAGE_MELEE,
    [STATUS.MAGE_RANGED_CONTROLLER] = STATUS.MAGE_RANGED,
    [STATUS.GENERAL_CONTROLLER] = STATUS.GENERAL,
    [STATUS.CUSTOM_CONTROLLER] = STATUS.CUSTOM,
    [STATUS.CUSTOM_CONTROLLER_2] = STATUS.CUSTOM_2,
    [STATUS.CUSTOM_CONTROLLER_3] = STATUS.CUSTOM_3,
    [STATUS.CUSTOM_CONTROLLER_4] = STATUS.CUSTOM_4,
    [STATUS.THROWER_CONTROLLER] = STATUS.THROWER,
    [STATUS.DEFAULT_CONTROLLER] = STATUS.DEFAULT,
    [STATUS.TRICKSTER_CONTROLLER] = STATUS.TRICKSTER
}

----------------------------------------------------------------------------------
-- Helper Functions
----------------------------------------------------------------------------------
function AI.hasAnyAICombatStatus(character)
    for _, status in ipairs(AI.aiCombatStatuses) do
        if Osi.HasActiveStatus(character, status) == 1 then
            return true
        end
    end
    return false
end

function AI.hasAnyNPCStatus(character)
    for _, status in ipairs(AI.NPCStatuses) do
        if Osi.HasActiveStatus(character, status) == 1 then
            return true
        end
    end
    return false
end

function AI.isControllerStatus(status)
    for _, brainStatus in ipairs(AI.aiStatuses) do
        if brainStatus == status then
            return true
        end
    end
    return false
end

function AI.hasControllerStatus(character)
    for _, brainStatus in ipairs(AI.aiStatuses) do
        if Osi.HasActiveStatus(character, brainStatus) == 1 then
            return true
        end
    end
    return false
end

-- Create NPC status set for fast lookup
local NPCStatusSet = {}
for _, status in ipairs(AI.NPCStatuses) do
    NPCStatusSet[status] = true
end

function AI.IsNPCStatus(status)
    return NPCStatusSet[status] ~= nil
end

----------------------------------------------------------------------------------
-- Status Application Functions
----------------------------------------------------------------------------------
--- Apply the appropriate AI status based on controller buff
--- @param character string The character UUID
--- @return string|nil The status that was applied, or nil if none
function AI.ApplyStatusBasedOnBuff(character)
    for controllerBuff, status in pairs(AI.controllerToStatusTranslator) do
        local success1, hasController = SafeOsiCall(Osi.HasActiveStatus, character, controllerBuff)
        if success1 and hasController == 1 then
            local success2, hasNPC = SafeOsiCall(Osi.HasActiveStatus, character, STATUS.TOGGLE_IS_NPC)
            if success2 and hasNPC == 0 then
                local success3 = SafeOsiCall(Osi.ApplyStatus, character, status, -1, 1, character)
                if success3 then
                    DebugLog("Applied " .. status .. " to " .. character, "STATUS")
                    return status
                end
            end
        end
    end
    return nil
end

--- Apply controller buff status during combat entry
--- @param character string The character UUID
function AI.ApplyStatusFromControllerBuff(character)
    for controllerBuff, status in pairs(AI.controllerToStatusTranslator) do
        local success, hasStatus = SafeOsiCall(Osi.HasActiveStatus, character, controllerBuff)
        if success and hasStatus == 1 then
            local success2, hasNPC = SafeOsiCall(Osi.HasActiveStatus, character, STATUS.TOGGLE_IS_NPC)
            if success2 and hasNPC == 1 then
                status = status .. '_NPC'
                SafeOsiCall(Osi.MakeNPC, character)
            end
            SafeOsiCall(Osi.ApplyStatus, character, status, -1, 1, character)
            DebugLog("Applied " .. status .. " based on controller buff for " .. character, "STATUS")
            break
        end
    end
end

return AI
