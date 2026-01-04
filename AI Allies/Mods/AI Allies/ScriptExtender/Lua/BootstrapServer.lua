-- Current Allies
Mods = Mods or {}
Mods.AIAllies = Mods.AIAllies or {}
local ModuleUUID = "b485d242-f267-2d22-3108-631ba0549512"
if Mods.BG3MCM then
    setmetatable(Mods.AIAllies, { __index = Mods.BG3MCM })
end


Mods.AIAllies.PersistentVars = Mods.AIAllies.PersistentVars or {}
Mods.AIAllies.PersistentVars.firstTimeRewardGiven = Mods.AIAllies.PersistentVars.firstTimeRewardGiven or false

-- Store factions for AI control
Mods.AIAllies.PersistentVars.aiControlOriginalFactions = Mods.AIAllies.PersistentVars.aiControlOriginalFactions or {}

local aiControlOriginalFactions = Mods.AIAllies.PersistentVars.aiControlOriginalFactions

-- Initialize the aiControlOriginalFactions table from PersistentVars when the session loads
local function InitAIControlOriginalFactions()
    aiControlOriginalFactions = Mods.AIAllies.PersistentVars.aiControlOriginalFactions or {}
    Mods.AIAllies.PersistentVars.aiControlOriginalFactions = aiControlOriginalFactions
end

Ext.Events.SessionLoaded:Subscribe(InitAIControlOriginalFactions)

-- Local table to keep track of the current allies
local CurrentAllies = {}

-- Namespace all module-specific global variables under Mods.AIAllies
Mods.AIAllies.characterTimers = Mods.AIAllies.characterTimers or {}
Mods.AIAllies.appliedStatuses = Mods.AIAllies.appliedStatuses or {}
Mods.AIAllies.spellModificationTimers = Mods.AIAllies.spellModificationTimers or {}
Mods.AIAllies.modifiedCharacters = Mods.AIAllies.modifiedCharacters or {}
Mods.AIAllies.spellModificationQueue = Mods.AIAllies.spellModificationQueue or {}
Mods.AIAllies.currentlyProcessing = false
Mods.AIAllies.combatTimers = {}
Mods.AIAllies.combatStartTimes = {}

-- Initialize the CurrentAllies table from PersistentVars when the session loads
local function InitCurrentAllies()
    Mods.AIAllies = Mods.AIAllies or {}
    Mods.AIAllies.PersistentVars = Mods.AIAllies.PersistentVars or {}
    CurrentAllies = Mods.AIAllies.PersistentVars.CurrentAllies or {}
end

-- Subscribe to the SessionLoaded event to initialize CurrentAllies
Ext.Events.SessionLoaded:Subscribe(InitCurrentAllies)
-------------------------------------------------------------------------------
-- MCM test
-- Function to check and manage custom archetypes
local function ManageCustomArchetypes()
    if Mods.AIAllies.MCMAPI then
        local enableCustomArchetypes = Mods.AIAllies.MCMAPI:GetSettingValue("enableCustomArchetypes", ModuleUUID)
        local players = Osi.DB_PartOfTheTeam:Get(nil)
        for _, player in pairs(players) do
            local character = player[1]
            if enableCustomArchetypes then
                if Osi.HasPassive(character, 'UnlockCustomArchetypes') == 0 then
                    Osi.AddPassive(character, 'UnlockCustomArchetypes')
                    --Ext.Utils.Print("Given 'UnlockCustomArchetypes' to: " .. character)
                end
            else
                if Osi.HasPassive(character, 'UnlockCustomArchetypes') == 1 then
                    Osi.RemovePassive(character, 'UnlockCustomArchetypes')
                    --Ext.Utils.Print("Removed 'UnlockCustomArchetypes' from: " .. character)
                end
            end
        end
    end
end

local function ManageAlliesMind()
    if Mods.AIAllies.MCMAPI then
        local enableAlliesMind = Mods.AIAllies.MCMAPI:GetSettingValue("enableAlliesMind", ModuleUUID)
        local players = Osi.DB_PartOfTheTeam:Get(nil)
        for _, player in pairs(players) do
            local character = player[1]
            if enableAlliesMind then
                if Osi.HasPassive(character, 'AlliesMind') == 0 then
                    Osi.AddPassive(character, 'AlliesMind')
                    --Ext.Utils.Print("Given 'AlliesMind' to: " .. character)
                end
            else
                if Osi.HasPassive(character, 'AlliesMind') == 1 then
                    Osi.RemovePassive(character, 'AlliesMind')
                    --Ext.Utils.Print("Removed 'AlliesMind' from: " .. character)
                end
            end
        end
    end
end

local function ManageAlliesDashing()
    if Mods.AIAllies.MCMAPI then
        local disableAlliesDashing = Mods.AIAllies.MCMAPI:GetSettingValue("disableAlliesDashing", ModuleUUID)
        local players = Osi.DB_PartOfTheTeam:Get(nil)
        for _, player in pairs(players) do
            local character = player[1]
            if disableAlliesDashing then
                if Osi.HasPassive(character, 'AlliesDashingDisabled') == 0 then
                    Osi.AddPassive(character, 'AlliesDashingDisabled')
                    --Ext.Utils.Print("Added 'AlliesDashingDisabled' to: " .. character)
                end
            else
                if Osi.HasPassive(character, 'AlliesDashingDisabled') == 1 then
                    Osi.RemovePassive(character, 'AlliesDashingDisabled')
                    --Ext.Utils.Print("Removed 'AlliesDashingDisabled' from: " .. character)
                end
            end
        end
    end
end

local function ManageAlliesThrowing()
    if Mods.AIAllies.MCMAPI then
        local disableAlliesThrowing = Mods.AIAllies.MCMAPI:GetSettingValue("disableAlliesThrowing", ModuleUUID)
        local players = Osi.DB_PartOfTheTeam:Get(nil)
        for _, player in pairs(players) do
            local character = player[1]
            if disableAlliesThrowing then
                if Osi.HasPassive(character, 'AlliesThrowingDisabled') == 0 then
                    Osi.AddPassive(character, 'AlliesThrowingDisabled')
                    --Ext.Utils.Print("Added 'AlliesThrowingDisabled' to: " .. character)
                end
            else
                if Osi.HasPassive(character, 'AlliesThrowingDisabled') == 1 then
                    Osi.RemovePassive(character, 'AlliesThrowingDisabled')
                    --Ext.Utils.Print("Removed 'AlliesThrowingDisabled' from: " .. character)
                end
            end
        end
    end
end

local function ManageDynamicSpellblock()
    if Mods.AIAllies.MCMAPI then
        local enableDynamicSpellblock = Mods.AIAllies.MCMAPI:GetSettingValue("enableDynamicSpellblock", ModuleUUID)
        local players = Osi.DB_PartOfTheTeam:Get(nil)
        for _, player in pairs(players) do
            local character = player[1]
            if enableDynamicSpellblock then
                if Osi.HasPassive(character, 'AlliesDynamicSpellblock') == 0 then
                    Osi.AddPassive(character, 'AlliesDynamicSpellblock')
                    --Ext.Utils.Print("Given 'AlliesDynamicSpellblock' to: " .. character)
                end
            else
                if Osi.HasPassive(character, 'AlliesDynamicSpellblock') == 1 then
                    Osi.RemovePassive(character, 'AlliesDynamicSpellblock')
                    --Ext.Utils.Print("Removed 'AlliesDynamicSpellblock' from: " .. character)
                end
            end
        end
    end
end

local function ManageAlliesSwarm()
    if Mods.AIAllies.MCMAPI then
        local enableAlliesSwarm = Mods.AIAllies.MCMAPI:GetSettingValue("enableAlliesSwarm", ModuleUUID)
        local players = Osi.DB_PartOfTheTeam:Get(nil)
        for _, player in pairs(players) do
            local character = player[1]
            if enableAlliesSwarm then
                if Osi.HasPassive(character, 'AlliesSwarm') == 0 then
                    Osi.AddPassive(character, 'AlliesSwarm')
                    --Ext.Utils.Print("Given 'AlliesSwarm' to: " .. character)
                end
            else
                if Osi.HasPassive(character, 'AlliesSwarm') == 1 then
                    Osi.RemovePassive(character, 'AlliesSwarm')
                    --Ext.Utils.Print("Removed 'AlliesSwarm' from: " .. character)
                end
            end
        end
    end
end

local function ManageOrderSpellsPassive()
    local players = Osi.DB_PartOfTheTeam:Get(nil)
    if Mods.AIAllies.MCMAPI then
        local enableOrdersBonusAction = Mods.AIAllies.MCMAPI:GetSettingValue("enableOrdersBonusAction", ModuleUUID)
        for _, player in pairs(players) do
            local character = player[1]
            if enableOrdersBonusAction then
                if Osi.HasPassive(character, 'UnlockAlliesOrders') == 1 then
                    Osi.RemovePassive(character, 'UnlockAlliesOrders')
                end
                if Osi.HasPassive(character, 'UnlockAlliesOrdersBonus') == 0 then
                    Osi.AddPassive(character, 'UnlockAlliesOrdersBonus')
                end
            else
                if Osi.HasPassive(character, 'UnlockAlliesOrdersBonus') == 1 then
                    Osi.RemovePassive(character, 'UnlockAlliesOrdersBonus')
                end
                if Osi.HasPassive(character, 'UnlockAlliesOrders') == 0 then
                    Osi.AddPassive(character, 'UnlockAlliesOrders')
                end
            end
        end
    else
        for _, player in pairs(players) do
            local character = player[1]
            if Osi.HasPassive(character, 'UnlockAlliesOrders') == 0 then
                Osi.AddPassive(character, 'UnlockAlliesOrders')
            end
        end
    end
end

local function ManageDebugSpells()
    if Mods.AIAllies.MCMAPI then
        local enableDebugSpells = Mods.AIAllies.MCMAPI:GetSettingValue("enableDebugSpells", ModuleUUID)
        local players = Osi.DB_PartOfTheTeam:Get(nil)
        for _, player in pairs(players) do
            local character = player[1]
            if enableDebugSpells then
                if Osi.HasPassive(character, 'UnlockAlliesExtraSpells') == 1 then
                    Osi.RemovePassive(character, 'UnlockAlliesExtraSpells')
                end
                if Osi.HasPassive(character, 'UnlockAlliesExtraSpells_ALT') == 0 then
                    Osi.AddPassive(character, 'UnlockAlliesExtraSpells_ALT')
                end
            else
                if Osi.HasPassive(character, 'UnlockAlliesExtraSpells_ALT') == 1 then
                    Osi.RemovePassive(character, 'UnlockAlliesExtraSpells_ALT')
                end
                if Osi.HasPassive(character, 'UnlockAlliesExtraSpells') == 0 then
                    Osi.AddPassive(character, 'UnlockAlliesExtraSpells')
                end
            end
        end
    else
        -- If MCM is not available, ensure the player has the default passive
        local players = Osi.DB_PartOfTheTeam:Get(nil)
        for _, player in pairs(players) do
            local character = player[1]
            if Osi.HasPassive(character, 'UnlockAlliesExtraSpells') == 0 then
                Osi.AddPassive(character, 'UnlockAlliesExtraSpells')
            end
            if Osi.HasPassive(character, 'UnlockAlliesExtraSpells_ALT') == 1 then
                Osi.RemovePassive(character, 'UnlockAlliesExtraSpells_ALT')
            end
        end
    end
end


-------------------------------------------------------------------------------

-- Function to check and give passives to players
local function CheckAndGivePassiveToPlayers()
    local players = Osi.DB_PartOfTheTeam:Get(nil)
    for _, player in pairs(players) do
        local character = player[1]
        if Osi.IsPlayer(character) == 1 then
            if Osi.HasPassive(character, 'GiveAlliesSpell') == 0 then
                Osi.AddPassive(character, 'GiveAlliesSpell')
                Ext.Utils.Print("Given 'GiveAlliesSpell' to: " .. character)
            end
            if Osi.HasPassive(character, 'AlliesToggleNPC') == 0 then
                Osi.AddPassive(character, 'AlliesToggleNPC')
                Ext.Utils.Print("Given 'AlliesToggleNPC' to: " .. character)
            end
        end
    end
    ManageCustomArchetypes()
    ManageAlliesMind()
    ManageAlliesDashing()
    ManageAlliesThrowing()
    ManageDynamicSpellblock()
    ManageAlliesSwarm()
    ManageOrderSpellsPassive()
    ManageDebugSpells()
end

Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "after", function()
    CheckAndGivePassiveToPlayers()

    local players = Osi.DB_PartOfTheTeam:Get(nil)
    for _, player in pairs(players) do
        local character = player[1]
        Osi.BlockNewCrimeReactions(character, 1)
        --Ext.Utils.Print("Crime reactions blocked for ally: " .. character)
    end

    -- for uuid, _ in pairs(CurrentAllies) do
    --     if CurrentAllies[uuid] then
    --         Osi.BlockNewCrimeReactions(uuid, 1)
    --         --Ext.Utils.Print("Crime reactions blocked for ally: " .. uuid)
    --     end
    -- end
end)

Ext.Osiris.RegisterListener("CharacterJoinedParty", 1, "after", function(character)
    CheckAndGivePassiveToPlayers()
    Osi.BlockNewCrimeReactions(character, 1)
end)

Ext.Osiris.RegisterListener("CharacterLeftParty", 1, "after", function(character)
    if character then
        local isInCombat = Osi.IsInCombat(character)
        if isInCombat == 0 then
            Osi.ApplyStatus(character, "AI_CANCEL", 0)
        end
    end
end)


----------------------------------------------------------------------------------------------
-- MCM Listeners
if Ext.ModEvents.BG3MCM and Ext.ModEvents.BG3MCM["MCM_Setting_Saved"] then
    Ext.ModEvents.BG3MCM["MCM_Setting_Saved"]:Subscribe(function(payload)
        if not payload or payload.modUUID ~= ModuleUUID or not payload.settingId then
            return
        end
        
        if payload.settingId == "enableCustomArchetypes" then
            ManageCustomArchetypes()
        elseif payload.settingId == "enableAlliesMind" then
            ManageAlliesMind()
        elseif payload.settingId == "disableAlliesDashing" then
            ManageAlliesDashing()
        elseif payload.settingId == "disableAlliesThrowing" then
            ManageAlliesThrowing()
        elseif payload.settingId == "enableDynamicSpellblock" then
            ManageDynamicSpellblock()
        elseif payload.settingId == "enableAlliesSwarm" then
            ManageAlliesSwarm()
        elseif payload.settingId == "enableOrdersBonusAction" then
            ManageOrderSpellsPassive()
        elseif payload.settingId == "enableDebugSpells" then
            ManageDebugSpells()
        end
    end)
end

----------------------------------------------------------------------------------------------
-- List of AI statuses to track for CurrentAllies
local aiStatuses = {
    "AI_ALLIES_MELEE_Controller",
    "AI_ALLIES_RANGED_Controller",
    "AI_ALLIES_HEALER_MELEE_Controller",
    "AI_ALLIES_HEALER_RANGED_Controller",
    "AI_ALLIES_MAGE_MELEE_Controller",
    "AI_ALLIES_MAGE_RANGED_Controller",
    "AI_ALLIES_GENERAL_Controller",
    "AI_ALLIES_TRICKSTER_Controller",
    "AI_CONTROLLED",
    "AI_ALLIES_CUSTOM_Controller",
    "AI_ALLIES_CUSTOM_Controller_2",
    "AI_ALLIES_CUSTOM_Controller_3",
    "AI_ALLIES_CUSTOM_Controller_4",
    "AI_ALLIES_THROWER_CONTROLLER",
    "AI_ALLIES_DEFAULT_Controller"
}

-- List of all combat statuses
local aiCombatStatuses = {
    'AI_ALLIES_MELEE',
    'AI_ALLIES_RANGED',
    'AI_ALLIES_HEALER_MELEE',
    'AI_ALLIES_HEALER_RANGED',
    'AI_ALLIES_MAGE_MELEE',
    'AI_ALLIES_MAGE_RANGED',
    'AI_ALLIES_GENERAL',
    'AI_ALLIES_CUSTOM',
    'AI_ALLIES_CUSTOM_2',
    'AI_ALLIES_CUSTOM_3',
    'AI_ALLIES_CUSTOM_4',
    'AI_ALLIES_TRICKSTER',
    'AI_ALLIES_THROWER',
    'AI_ALLIES_DEFAULT',
    'AI_ALLIES_MELEE_NPC',
    'AI_ALLIES_RANGED_NPC',
    'AI_ALLIES_HEALER_MELEE_NPC',
    'AI_ALLIES_HEALER_RANGED_NPC',
    'AI_ALLIES_MAGE_MELEE_NPC',
    'AI_ALLIES_MAGE_RANGED_NPC',
    'AI_ALLIES_GENERAL_NPC',
    'AI_ALLIES_CUSTOM_NPC',
    'AI_ALLIES_CUSTOM_2_NPC',
    'AI_ALLIES_CUSTOM_3_NPC',
    'AI_ALLIES_CUSTOM_4_NPC',
    'AI_ALLIES_TRICKSTER_NPC',
    'AI_ALLIES_THROWER_NPC',
    'AI_ALLIES_DEFAULT_NPC'
}

-- List of NPC statuses
local NPCStatuses = {
    'AI_ALLIES_MELEE_NPC',
    'AI_ALLIES_RANGED_NPC',
    'AI_ALLIES_HEALER_MELEE_NPC',
    'AI_ALLIES_HEALER_RANGED_NPC',
    'AI_ALLIES_MAGE_MELEE_NPC',
    'AI_ALLIES_MAGE_RANGED_NPC',
    'AI_ALLIES_GENERAL_NPC',
    'AI_ALLIES_CUSTOM_NPC',
    'AI_ALLIES_CUSTOM_2_NPC',
    'AI_ALLIES_CUSTOM_3_NPC',
    'AI_ALLIES_CUSTOM_4_NPC',
    'AI_ALLIES_TRICKSTER_NPC',
    'AI_ALLIES_THROWER_NPC',
    'AI_ALLIES_DEFAULT_NPC'
}
---------------------------------------------------------------------------------------------
-- Check status helper
local function hasAnyAICombatStatus(character)
    for _, status in ipairs(aiCombatStatuses) do
        if Osi.HasActiveStatus(character, status) == 1 then
            return true
        end
    end
    return false
end

local function hasAnyNPCStatus(character)
    for _, status in ipairs(NPCStatuses) do
        if Osi.HasActiveStatus(character, status) == 1 then
            return true
        end
    end
    return false
end

local function isControllerStatus(status)
    for _, brainStatus in ipairs(aiStatuses) do
        if brainStatus == status then
            return true
        end
    end
    return false
end

local function hasControllerStatus(character)
    for _, brainStatus in ipairs(aiStatuses) do
        if Osi.HasActiveStatus(character, brainStatus) == 1 then
            return true
        end
    end
    return false
end

local NPCStatusSet = {}
for _, status in ipairs(NPCStatuses) do
    NPCStatusSet[status] = true
end

local function IsNPCStatus(status)
    return NPCStatusSet[status] ~= nil
end
---------------------------------------------------------------------------------------------
-- No idea why I'm doing this
local warningMessages = {
    "Stop it!",
    "Come on, pay attention!",
    "Seriously, stop!",
    "I'm warning you!",
    "Knock it off!",
    "This is your last warning!",
    "Fine! take this. Now, please stop."
}

local currentWarningIndex = 1

local function GetNextWarningMessage()
    local message = warningMessages[currentWarningIndex]
    if currentWarningIndex == #warningMessages then
        local hostCharacter = Osi.GetHostCharacter()
        if not Mods.AIAllies.PersistentVars.firstTimeRewardGiven then
            Osi.UserAddGold(hostCharacter, 200)
            Mods.AIAllies.PersistentVars.firstTimeRewardGiven = true
            Ext.Utils.Print("Attempting to bribe player: " .. hostCharacter)
        else
            Osi.UserAddGold(hostCharacter, 2)
            Ext.Utils.Print("Attempting to bribe a greedy player: " .. hostCharacter)
        end
    end
    currentWarningIndex = currentWarningIndex % #warningMessages + 1
    return message
end

-- Add to CurrentAllies list or deny
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, causee, storyActionID)
    if status == 'ToggleIsNPC' and Osi.IsPartyFollower(object) == 1 then
        local hostCharacter = Osi.GetHostCharacter()
        Osi.ApplyStatus(object, "ALLIES_WARNING", 0, 0, hostCharacter)
        Osi.TogglePassive(object, 'AlliesToggleNPC')
        Osi.ShowNotification(hostCharacter, GetNextWarningMessage())
        Ext.Utils.Print("Not enabling NPC toggle, character is a party follower: " .. object)
    elseif isControllerStatus(status) and Osi.IsPartyFollower(object) == 0 then
        local uuid = Osi.GetUUID(object)
        local PFtimer = "AddToAlliesTimer_" .. uuid
        Osi.TimerLaunch(PFtimer, 1000)
        Mods.AIAllies.characterTimers[PFtimer] = uuid
        Ext.Utils.Print("Started timer for " .. uuid)
    end
end)

-- Remove a specific character's UUID from CurrentAllies
local function RemoveFromCurrentAllies(uuid)
    CurrentAllies[uuid] = nil
    Mods.AIAllies.PersistentVars.CurrentAllies = CurrentAllies
    Ext.Utils.Print("Removed from CurrentAllies: " .. uuid)
end

-- Consolidated TimerFinished listener for all timer types
Ext.Osiris.RegisterListener("TimerFinished", 1, "after", function (timer)
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
            --Ext.Utils.Print("Removed wildshape status: " .. uuid.status .. " from " .. uuid.object)
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

Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", function (object, status, causee, storyActionID)
    if isControllerStatus(status) then
        local uuid = Osi.GetUUID(object)
        RemoveFromCurrentAllies(uuid)
    end
end)

-- Listener for StatusApplied to remove a specific character's UUID when AI_CANCEL status is applied
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function (object, status, causee, storyActionID)
    if status == 'AI_CANCEL' then
        local uuid = Osi.GetUUID(object)
        RemoveFromCurrentAllies(uuid)
    end
end)
---------------------------------------------------------------------------------------------
Ext.Osiris.RegisterListener("CombatStarted", 1, "after", function(combatGuid)
    for uuid, _ in pairs(CurrentAllies) do
        if CurrentAllies[uuid] and Osi.Exists(uuid) == 1 then
            Osi.ApplyStatus(uuid, 'AI_ALLY', -1)
            --Ext.Utils.Print("Combat started, marking character as ally: " .. uuid)
        elseif CurrentAllies[uuid] and Osi.Exists(uuid) ~= 1 then
            -- Cleanup dead entities
            CurrentAllies[uuid] = nil
            Ext.Utils.Print("[CLEANUP] Removed dead entity from CurrentAllies: " .. uuid)
        end
    end
end)

-- Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function (object, status, causee, storyActionID)
--     if status == 'AI_ALLY' then
--         Ext.Utils.Print("Applied status 'AI_ALLY' to: " .. object)
--     end
-- end)
---------------------------------------------------------------------------------------------
-- Existing Functions for Mindcontrol Art Behavior
-- -------------------------------------------------
local charactersUnderMindControl = {}

local function InitCharactersUnderMindControl()
    if not Mods.AIAllies.PersistentVars.charactersUnderMindControl then
        Mods.AIAllies.PersistentVars.charactersUnderMindControl = {}
    end
    charactersUnderMindControl = Mods.AIAllies.PersistentVars.charactersUnderMindControl
end

Ext.Events.SessionLoaded:Subscribe(InitCharactersUnderMindControl)

local function UpdateMindControlStatus(character, status)
    charactersUnderMindControl[character] = status
    Mods.AIAllies.PersistentVars.charactersUnderMindControl = charactersUnderMindControl
end

local function CanFollow()
    local playerCharacter = Osi.GetHostCharacter()
    return Osi.HasActiveStatus(playerCharacter, 'ALLIES_ORDER_FOLLOW') == 1
end

local function TeleportCharacterToPlayer(character, alwaysTeleport)
    local playerCharacter = Osi.GetHostCharacter()
    -- Add entity existence validation
    if not playerCharacter or not character then
        return
    end
    if Osi.Exists(character) ~= 1 or Osi.Exists(playerCharacter) ~= 1 then
        Ext.Utils.Print("[WARNING] Cannot teleport - entity does not exist")
        return
    end
    
    if alwaysTeleport or CanFollow() then
        Osi.TeleportTo(character, playerCharacter)
        Ext.Utils.Print("Teleporting " .. character .. " to player: " .. playerCharacter)
        if CanFollow() then
            Osi.PROC_Follow(character, playerCharacter)
        end
    end
end

local function UpdateFollowingBehavior(character)
    local playerCharacter = Osi.GetHostCharacter()
    if charactersUnderMindControl[character] then
        if CanFollow() then
            Osi.PROC_Follow(character, playerCharacter)
        else
            Osi.PROC_StopFollow(character)
        end
    end
end

local function UpdateFollowForAll()
    for character, _ in pairs(charactersUnderMindControl) do
        UpdateFollowingBehavior(character)
    end
end

Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function (object, status, causee, storyActionID)
    if status == 'ALLIES_MINDCONTROL' then
        Osi.PROC_StopFollow(object)
        UpdateMindControlStatus(object, true)
        UpdateFollowingBehavior(object)
    elseif status == 'ALLIES_ORDER_FOLLOW' then
        UpdateFollowForAll()
    end
end)

Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", function (object, status, causee, storyActionID)
    if status == 'ALLIES_MINDCONTROL' then
        UpdateMindControlStatus(object, nil)
        Osi.PROC_StopFollow(object)
        if Osi.HasActiveStatus(object, 'AI_ALLIES_POSSESSED') == 1 then
            Osi.RemoveStatus(object, 'AI_ALLIES_POSSESSED')
            Ext.Utils.Print("Removed Possessed status from: " .. object)
        end
    elseif status == 'ALLIES_ORDER_FOLLOW' then
        UpdateFollowForAll()
    end
end)

Ext.Osiris.RegisterListener("UsingSpellOnTarget", 6, "after", function (caster, target, spellName, _, _, _, _)
    if spellName == 'Target_Allies_C_Order_Teleport' then
        for character, _ in pairs(charactersUnderMindControl) do
            TeleportCharacterToPlayer(character, true)
        end
    end
end)

Ext.Osiris.RegisterListener("TeleportToWaypoint", 2, "after", function (target, _, _)
    if CanFollow() then
        for character, _ in pairs(charactersUnderMindControl) do
            TeleportCharacterToPlayer(character, false)
        end
        UpdateFollowForAll()
    end
end)

Ext.Osiris.RegisterListener("TeleportToFromCamp", 1, "after", function (target, _)
    if CanFollow() then
        for character, _ in pairs(charactersUnderMindControl) do
            TeleportCharacterToPlayer(character, false)
        end
        UpdateFollowForAll()
    end
end)

Ext.Osiris.RegisterListener("CombatEnded", 1, "after", function (combat)
    UpdateFollowForAll()
end)
---------------------------------------------------------------------
-- Don't betray the player, ignore their crimes
Ext.Osiris.RegisterListener("CrimeIsRegistered", 8, "after", function(victim, crimeType, crimeID, evidence, criminal1, criminal2, criminal3, criminal4)
    for uuid, _ in pairs(CurrentAllies) do
        if CurrentAllies[uuid] and Osi.Exists(uuid) == 1 then
            Osi.CrimeIgnoreCrime(crimeID, uuid)
            Osi.CharacterIgnoreActiveCrimes(uuid)
            Osi.BlockNewCrimeReactions(uuid, 1)
            --Ext.Utils.Print("Crime ignored by ally: " .. uuid)
        end
    end
end)
---------------------------------------------------------------------
-- Define the mapping of controller buffs to status buffs
local controllerToStatusTranslator = {
    AI_ALLIES_MELEE_Controller = 'AI_ALLIES_MELEE',
    AI_ALLIES_RANGED_Controller = 'AI_ALLIES_RANGED',
    AI_ALLIES_HEALER_MELEE_Controller = 'AI_ALLIES_HEALER_MELEE',
    AI_ALLIES_HEALER_RANGED_Controller = 'AI_ALLIES_HEALER_RANGED',
    AI_ALLIES_MAGE_MELEE_Controller = 'AI_ALLIES_MAGE_MELEE',
    AI_ALLIES_MAGE_RANGED_Controller = 'AI_ALLIES_MAGE_RANGED',
    AI_ALLIES_GENERAL_Controller = 'AI_ALLIES_GENERAL',
    AI_ALLIES_CUSTOM_Controller = 'AI_ALLIES_CUSTOM',
    AI_ALLIES_CUSTOM_Controller_2 = 'AI_ALLIES_CUSTOM_2',
    AI_ALLIES_CUSTOM_Controller_3 = 'AI_ALLIES_CUSTOM_3',
    AI_ALLIES_CUSTOM_Controller_4 = 'AI_ALLIES_CUSTOM_4',
    AI_ALLIES_THROWER_CONTROLLER = 'AI_ALLIES_THROWER',
    AI_ALLIES_DEFAULT_Controller = 'AI_ALLIES_DEFAULT',
    AI_ALLIES_TRICKSTER_Controller = 'AI_ALLIES_TRICKSTER'
}

-- Function to apply status based on controller buff
local function ApplyStatusFromControllerBuff(character)
    for controllerBuff, status in pairs(controllerToStatusTranslator) do
        if Osi.HasActiveStatus(character, controllerBuff) == 1 then
            if Osi.HasActiveStatus(character, "ToggleIsNPC") == 1 then
                status = status .. '_NPC'
                Osi.MakeNPC(character)
            end
            Osi.ApplyStatus(character, status, -1)
            Ext.Utils.Print("Applied " .. status .. " to " .. character)
            return true
        end
    end
    return false
end

-- Register listener for CombatStarted event
-- Ext.Osiris.RegisterListener("CombatStarted", 1, "after", function(combatGuid)
--     for uuid, _ in pairs(CurrentAllies) do
--         if not hasAnyAICombatStatus(uuid) then
--             ApplyStatusFromControllerBuff(uuid)
--         end
--     end
-- end)

-- Register listener for EnteredCombat event
Ext.Osiris.RegisterListener("EnteredCombat", 2, "after", function(object, combatGuid)
    if hasControllerStatus(object) and not hasAnyAICombatStatus(object) then
        ApplyStatusFromControllerBuff(object)
    end
    if hasControllerStatus(object) then
        -- Note: AlliesBannedActions removed - it was blocking too many utility spells
        -- Only apply if specific problematic behaviors are observed
        Osi.ApplyStatus(object, "AI_ALLY", -1)
        Osi.ApplyStatus(object, "FOR_AI_SPELLS", -1)
        --Ext.Utils.Print("(Entered Combat) Applied AI statuses to " .. object)
    end
end)

-- Register listener for StatusApplied event to handle controller statuses during combat
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, causee, storyActionID)
    if isControllerStatus(status) and Osi.IsInCombat(object) == 1 then
        ApplyStatusFromControllerBuff(object)
    end
end)
-- Event Listeners for character turning NPC back and removing statuses at the end of combat
-- -----------------------------------------------------------------------------------------------------------
Ext.Osiris.RegisterListener("CombatEnded", 1, "after", function (combatGuid)
    for uuid, _ in pairs(CurrentAllies) do
        for _, status in ipairs(aiCombatStatuses) do
            if Osi.HasActiveStatus(uuid, status) == 1 then
                Osi.RemoveStatus(uuid, status)
            end
        end
        
        -- Clean up any orphaned statuses from appliedStatuses to prevent AI freezing
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

Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", function (object, status, causee, storyActionID)
    if IsNPCStatus(status) then
        Osi.MakePlayer(object)
    end
end)
--------------------------------------------------------------------
-- Functions to add or remove a character from the party
-- local function RemoveFromParty(characterUUID)
--     if characterUUID then
--         Osi.PROC_GLO_PartyMembers_Remove(characterUUID, 1)
--         Ext.Utils.Print("Removed from party: " .. characterUUID)
--     end
-- end

-- local function AddToParty(characterUUID, hostCharacterUUID)
--     if characterUUID and hostCharacterUUID then
--         Osi.PROC_GLO_PartyMembers_CheckAdd(characterUUID, hostCharacterUUID)
--         Ext.Utils.Print("Added to party: " .. characterUUID)
--     end
-- end
-- Event Listeners for Possession
-- -----------------------------------
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function (object, status, causee, storyActionID)
    if status == 'AI_ALLIES_POSSESSED' then
        local hostCharacter = Osi.GetHostCharacter()
        Osi.AddPartyFollower(object, hostCharacter)
        Ext.Utils.Print("Possessed: " .. object)
    end
end)

Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", function (object, status, causee, storyActionID)
    if status == 'AI_ALLIES_POSSESSED' then
        local hostCharacter = Osi.GetHostCharacter()
        Osi.RemovePartyFollower(object, hostCharacter)
        Ext.Utils.Print("Stopped Possessing: " .. object)
        Osi.ApplyStatus(object, "AI_CANCEL", 0)
    end
end)

-- Listener for Long Rest Started
-- Ext.Osiris.RegisterListener("LongRestStarted", 0, "before", function ()
--     for character, _ in pairs(charactersUnderMindControl) do
--         if Osi.HasActiveStatus(character, 'AI_ALLIES_POSSESSED') == 1 then
--             Osi.RemoveStatus(character, 'AI_ALLIES_POSSESSED')
--             Ext.Utils.Print("Removed Possessed status from: " .. character)
--         end
--     end
-- end)

---------------------------------------------------------------
-- Function to apply dodge at the start of combat
-- local function HasAnyOfTheBuffs(character)
--     local buffs = {
--         'AI_ALLIES_MELEE_Controller', 'AI_ALLIES_RANGED_Controller', 'AI_ALLIES_HEALER_MELEE_Controller', 
--         'AI_ALLIES_HEALER_RANGED_Controller', 'AI_ALLIES_MAGE_MELEE_Controller', 'AI_ALLIES_MAGE_RANGED_Controller', 
--         'AI_ALLIES_GENERAL_Controller'
--     }
    
--     for _, buff in ipairs(buffs) do
--         if Osi.HasActiveStatus(character, buff) == 1 then
--             return true
--         end
--     end

--     return false
-- end

-- -- Listener to apply dodge
-- Ext.Osiris.RegisterListener("CombatStarted", 1, "after", function(combatGuid)
--     Ext.Utils.Print("Combat started with combat GUID: " .. combatGuid)

--     local index = 1
--     local partyMember = Osi.CombatGetInvolvedPartyMember(combatGuid, index)

--     while partyMember do
--         if HasAnyOfTheBuffs(partyMember) then
--             Osi.ApplyStatus(partyMember, 'TEMPORARY_REPRIEVE', 6.0, 1, partyMember)
--             Ext.Utils.Print("Applied TEMPORARY_REPRIEVE to " .. partyMember)
--         end

--         index = index + 1
--         partyMember = Osi.CombatGetInvolvedPartyMember(combatGuid, index)
--     end
-- end)
------------------------------------------------------------------------------------------
-- Function to apply status based on controller buff for non-NPCs
local function ApplyStatusBasedOnBuff(character)
    for controllerBuff, status in pairs(controllerToStatusTranslator) do
        if Osi.HasActiveStatus(character, controllerBuff) == 1 then
            if Osi.HasActiveStatus(character, "ToggleIsNPC") == 0 then
                Osi.ApplyStatus(character, status, -1)
                Ext.Utils.Print("Applied " .. status .. " to " .. character)
                return status
            end
        end
    end
    return nil
end

-- Listener for TurnStarted event
Ext.Osiris.RegisterListener("TurnStarted", 1, "after", function(character)
    if not hasAnyNPCStatus(character) then
        local status = ApplyStatusBasedOnBuff(character)
        if status then
            Mods.AIAllies.appliedStatuses[character] = status
        end
    end
end)

-- Listener for TurnEnded event
Ext.Osiris.RegisterListener("TurnEnded", 1, "after", function(character)
    if not hasAnyNPCStatus(character) then
        local status = Mods.AIAllies.appliedStatuses[character]
        if status then
            Osi.RemoveStatus(character, status, character)
            Ext.Utils.Print("Removed " .. status .. " from " .. character)
            Mods.AIAllies.appliedStatuses[character] = nil
        end
    end
end)
------------------------------------------------------------------------------------------
-- AI Specific spells
-- Mapping of original spells to their AI versions
local spellMappings = {
    ['Shout_ActionSurge'] = 'Shout_ActionSurge_AI',
    ['Shout_Dash'] = 'Shout_Dash_AI',
    ['Shout_Dash_CunningAction'] = 'Shout_Dash_CunningAction_AI',
    ['Shout_Rage_Berserker'] = 'Shout_Rage_Berserker_AI',
    ['Shout_Rage_Wildheart'] = 'Shout_Rage_Wildheart_AI',
    ['Shout_Rage_WildMagic'] = 'Shout_Rage_WildMagic_AI'
}

-- Function to add or remove AI spells based on the original spell
local function ModifyAISpells(character, addSpell)
    -- Validate entity exists before modifying spells
    if not character or Osi.Exists(character) ~= 1 then
        Ext.Utils.Print("[WARNING] Cannot modify spells - invalid character: " .. tostring(character))
        return
    end
    
    for originalSpell, aiSpell in pairs(spellMappings) do
        local hasAIVersion = Osi.HasSpell(character, aiSpell) == 1

        if Osi.HasSpell(character, originalSpell) == 1 then
            if addSpell and not hasAIVersion then
                Osi.AddSpell(character, aiSpell, 0, 0)
            elseif not addSpell and hasAIVersion then
                Osi.RemoveSpell(character, aiSpell, 0)
            end
        end
    end
end

local function ProcessQueue()
    if #Mods.AIAllies.spellModificationQueue == 0 then
        Mods.AIAllies.currentlyProcessing = false
        return
    end

    Mods.AIAllies.currentlyProcessing = true
    local character = table.remove(Mods.AIAllies.spellModificationQueue, 1)
    ModifyAISpells(character, true)

    local nextProcessTimer = "NextProcessTimer_" .. character
    Osi.TimerLaunch(nextProcessTimer, 250)
    Mods.AIAllies.spellModificationTimers[nextProcessTimer] = function() ProcessQueue() end
end

-- StatusApplied listener adjusted to use queue
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function (character, status, causee, storyActionID)
    if hasAnyAICombatStatus(character) and not Mods.AIAllies.modifiedCharacters[character] and Osi.HasActiveStatus(character, "ToggleIsNPC") == 0 then
        Mods.AIAllies.modifiedCharacters[character] = true
        table.insert(Mods.AIAllies.spellModificationQueue, character)
        if not Mods.AIAllies.currentlyProcessing then
            ProcessQueue()
        end
    end
end)

-- Listener for when 'FOR_AI_SPELLS' status is removed
Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", function (character, status, causee, storyActionID)
    if status == 'FOR_AI_SPELLS' then
        ModifyAISpells(character, false)
        Mods.AIAllies.modifiedCharacters[character] = nil
    end
end)
-----------------------------------------------------------------------------------------------
-- Dialog fix**
local relevantDialogInstance = nil
local transformedCompanions = {}

-- Cleanup function to recover from dialog crashes
local function CleanupDialogState()
    for actorUuid, _ in pairs(transformedCompanions) do
        if Osi.Exists(actorUuid) == 1 and IsCurrentAlly(actorUuid) then
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

-- Subscribe to SessionLoaded to clean up any stuck dialog states
Ext.Events.SessionLoaded:Subscribe(CleanupDialogState)

local function HasRelevantStatus(character)
    for _, status in ipairs(aiCombatStatuses) do
        if Osi.HasActiveStatus(character, status) == 1 and Osi.HasActiveStatus(character, "ToggleIsNPC") == 1 then
            return true
        end
    end
    return false
end

local function IsCurrentAlly(actorUuid)
    return CurrentAllies[actorUuid] ~= nil
end

local function HandleDialogStarted(dialog, instanceID)
    relevantDialogInstance = instanceID
    Ext.Utils.Print("Relevant dialog started for instance: " .. tostring(instanceID))
end

Ext.Osiris.RegisterListener("DialogStarted", 2, "after", HandleDialogStarted)

local function HandleDialogActorJoined(instanceID, actor)
    local actorUuid = Osi.GetUUID(actor)
    -- Validate entity exists
    if not actorUuid or Osi.Exists(actor) ~= 1 then
        return
    end
    
    if instanceID == relevantDialogInstance and IsCurrentAlly(actorUuid) and HasRelevantStatus(actor) then
        -- Preserve faction before making player
        local originalFaction = Osi.GetFaction(actor)
        transformedCompanions[actorUuid] = {
            wasNPC = true,
            faction = originalFaction
        }
        
        Osi.MakePlayer(actor)
        Ext.Utils.Print("Temporarily turned " .. actor .. " into a player for dialog instance " .. tostring(instanceID))
    end
end

Ext.Osiris.RegisterListener("DialogActorJoined", 4, "after", function(dialog, instanceID, actor, speakerIndex)
    HandleDialogActorJoined(instanceID, actor)
end)

local function HandleDialogEnded(dialog, instanceID)
    if instanceID == relevantDialogInstance then
        for actorUuid, data in pairs(transformedCompanions) do
            -- Validate entity still exists
            if Osi.Exists(actorUuid) ~= 1 then
                Ext.Utils.Print("[WARNING] Actor " .. actorUuid .. " no longer exists, skipping reversion")
            elseif Osi.IsInCombat(actorUuid) == 0 then
                Ext.Utils.Print("Character " .. actorUuid .. " is not in combat, remaining as player character after dialog end.")
            else
                Osi.MakeNPC(actorUuid)
                -- Restore original faction
                if type(data) == "table" and data.faction then
                    Osi.SetFaction(actorUuid, data.faction)
                    Ext.Utils.Print("[FACTION] Restored faction for " .. actorUuid .. " to " .. data.faction)
                end
                Ext.Utils.Print("Reverted " .. actorUuid .. " back to NPC after dialog end in instance " .. tostring(instanceID))
            end
        end
        transformedCompanions = {}
        relevantDialogInstance = nil
    end
end

Ext.Osiris.RegisterListener("DialogEnded", 2, "after", HandleDialogEnded)
-----------------------------------------------------------------------------------------------
-- Function to teleport allies to the caster
function TeleportAlliesToCaster(caster)
    local target = Osi.GetHostCharacter()
    for uuid, _ in pairs(CurrentAllies) do
        if CurrentAllies[uuid] then
            Osi.TeleportTo(uuid, target, "", 1, 1, 1, 0, 1)
            Ext.Utils.Print("Teleporting ally: " .. uuid)
        end
    end
end


-- Listener for the 'C_Shout_Allies_Teleport' spell
Ext.Osiris.RegisterListener("UsingSpellOnTarget", 6, "after", function (caster, target, spellName, _, _, _, _)
    if spellName == 'C_Shout_Allies_Teleport' then
        TeleportAlliesToCaster(caster)
    end
end)
--------------------------------------------------------------
-- Better faction debug
Mods.AIAllies.PersistentVars.originalFactions = Mods.AIAllies.PersistentVars.originalFactions or {}

local originalFactions = {}

local function InitOriginalFactions()
    if not Mods.AIAllies.PersistentVars.originalFactions then
        Mods.AIAllies.PersistentVars.originalFactions = {}
    end
    originalFactions = Mods.AIAllies.PersistentVars.originalFactions
end

Ext.Events.SessionLoaded:Subscribe(InitOriginalFactions)

local function SafelyUpdateFactionStore(character, newFaction)
    if not originalFactions[character] then
        originalFactions[character] = newFaction
        Mods.AIAllies.PersistentVars.originalFactions = originalFactions
        Ext.Utils.Print("Original faction saved for " .. character .. ": " .. newFaction)
    else
        Ext.Utils.Print("Original faction for " .. character .. " already set to: " .. originalFactions[character])
    end
end

local function getCleanFactionID(factionString)
    local factionID = string.match(factionString, "([0-9a-f-]+)$")
    return factionID or factionString
end

-- Faction Debug
Ext.Osiris.RegisterListener("UsingSpellOnTarget", 6, "after", function (caster, target, spell, spellType, spellElement, storyActionID)
    if spell == "G_Target_Allies_Faction" then
        local casterFaction = Osi.GetFaction(caster)
        local targetFaction = Osi.GetFaction(target)
        local hostCharacter = Osi.GetHostCharacter()

        SafelyUpdateFactionStore(hostCharacter, getCleanFactionID(Osi.GetFaction(hostCharacter)))

        Ext.Utils.Print("Caster's current faction: " .. casterFaction)
        Ext.Utils.Print("Target's faction: " .. targetFaction)

        Osi.SetFaction(hostCharacter, getCleanFactionID(targetFaction))
        Ext.Utils.Print("Changed faction of " .. hostCharacter .. " to " .. getCleanFactionID(targetFaction))
    end
end)

Ext.Osiris.RegisterListener("UsingSpellOnTarget", 6, "after", function (caster, target, spell, _, _, _, _)
    if spell == "H_Target_Allies_Faction_Leave" then
        local hostCharacter = Osi.GetHostCharacter()
        local originalFaction = originalFactions[hostCharacter] or "6545a015-1b3d-66a4-6a0e-6ec62065cdb7"

        Osi.SetFaction(hostCharacter, getCleanFactionID(originalFaction))
        Ext.Utils.Print("Reverted faction of " .. hostCharacter .. " to " .. getCleanFactionID(originalFaction))
    end
end)
------------------------------------------------------------------------------------------------
-- for Debug spells
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function (object, status, causee, storyActionID)
    if status == 'MARK_NPC' then
        Osi.MakeNPC(object)
    end
end)

Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function (object, status, causee, storyActionID)
    if status == 'MARK_PLAYER' then
        Osi.MakePlayer(object)
    end
end)

-- Listener function for UsingSpellOnTarget
function OnUsingSpellOnTarget(caster, target, spell, spellType, spellElement, storyActionID)
    if spell == "I_Target_Allies_Check_Archetype" then
        local activeArchetype = Osi.GetActiveArchetype(target)
        local baseArchetype = Osi.GetBaseArchetype(target)
        Ext.Utils.Print("Target: " .. target)
        Ext.Utils.Print("Active Archetype: " .. activeArchetype)
        Ext.Utils.Print("Base Archetype: " .. baseArchetype)
    end
end

Ext.Osiris.RegisterListener("UsingSpellOnTarget", 6, "after", OnUsingSpellOnTarget)
------------------------------------------------------------------------------------------------
-- Testing - Pause combat when it starts to give AI time to initialize 

local function OnCombatResumeTimerFinished(InitializeTimerAI)
    local combatGuid = Mods.AIAllies.combatTimers[InitializeTimerAI]
    if combatGuid then
        Osi.ResumeCombat(combatGuid)
        Ext.Utils.Print("Resuming combat")
        Mods.AIAllies.combatTimers[InitializeTimerAI] = nil
        Mods.AIAllies.combatStartTimes[combatGuid] = nil
    end
end

Ext.Osiris.RegisterListener("CombatStarted", 1, "after", function(combatGuid)
    Osi.PauseCombat(combatGuid)
    Ext.Utils.Print("Pausing combat to allow AI to initialize")
    local InitializeTimerAI = "ResumeCombatTimer_" .. tostring(combatGuid)
    Mods.AIAllies.combatTimers[InitializeTimerAI] = combatGuid
    Mods.AIAllies.combatStartTimes[combatGuid] = Ext.Utils.MonotonicTime()
    Osi.TimerLaunch(InitializeTimerAI, 2000)
end)

-- Fallback: Force resume combat if it's been paused too long (safety mechanism)
Ext.Osiris.RegisterListener("TurnStarted", 1, "after", function(entityGuid)
    local combatGuid = Osi.CombatGetGuidFor(entityGuid)
    if combatGuid and Mods.AIAllies.combatStartTimes[combatGuid] then
        local elapsed = Ext.Utils.MonotonicTime() - Mods.AIAllies.combatStartTimes[combatGuid]
        if elapsed > 60000 then -- 60 second safety timeout
            Osi.ResumeCombat(combatGuid)
            Ext.Utils.Print("[SAFETY] Force resuming combat after timeout: " .. combatGuid)
            Mods.AIAllies.combatStartTimes[combatGuid] = nil
            -- Clean up any related timers
            for timer, guid in pairs(Mods.AIAllies.combatTimers) do
                if guid == combatGuid then
                    Mods.AIAllies.combatTimers[timer] = nil
                end
            end
        end
    end
end)
------------------------------------------------------------------------------------------------
-- Testing if longer pause = better performance
-- local function NotifyHostPlayer(message)
--     local hostCharacter = Osi.GetHostCharacter()
--     Osi.ShowNotification(hostCharacter, message)
-- end

-- local function StartNextTimer(combatGuid, secondsLeft)
--     if secondsLeft > 0 then
--         local InitializationTimer = "InitializationTimer_" .. tostring(combatGuid) .. "_" .. tostring(secondsLeft)
--         combatTimers[InitializationTimer] = {combatGuid, secondsLeft - 1}
--         Osi.TimerLaunch(InitializationTimer, 1000)
--         if secondsLeft <= 3 then
--             NotifyHostPlayer(tostring(secondsLeft))
--         end
--     else
--         local InitializationTimerResume = "InitializationTimerResume_" .. tostring(combatGuid)
--         combatTimers[InitializationTimerResume] = combatGuid
--         Osi.TimerLaunch(InitializationTimerResume, 1000)
--         NotifyHostPlayer("1")
--     end
-- end

-- local function OnTimerFinished(InitializationTimer)
--     local timerData = combatTimers[InitializationTimer]
--     if type(timerData) == "table" then
--         local combatGuid = timerData[1]
--         local nextSecondsLeft = timerData[2]
--         StartNextTimer(combatGuid, nextSecondsLeft)
--     elseif type(timerData) == "string" then
--         Osi.ResumeCombat(timerData)
--         Ext.Utils.Print("Resuming combat")
--     end
--     combatTimers[InitializationTimer] = nil
-- end

-- Ext.Osiris.RegisterListener("CombatStarted", 1, "after", function(combatGuid)
--     Osi.PauseCombat(combatGuid)
--     Ext.Utils.Print("Pausing combat to allow AI to initialize")
--     StartNextTimer(combatGuid, 6)
-- end)

-- Ext.Osiris.RegisterListener("TimerFinished", 1, "after", function(InitializationTimer)
--     OnTimerFinished(InitializationTimer)
-- end)
------------------------------------------------------------------------------------------------
-- Ext.Osiris.RegisterListener("CombatStarted", 1, "after", function(combatGuid)
--     Ext.Utils.Print("Combat started with GUID: " .. combatGuid)
    
--     -- Function to check and cast Armor of Agathys
--     local function CheckAndCastArmorOfAgathys(character)
--         if Osi.HasSpell(character, "Shout_ArmorOfAgathys") == 1 then
--             Osi.UseSpell(character, "Shout_ArmorOfAgathys", character)
--             Ext.Utils.Print(character .. " cast Armor of Agathys at the start of combat")
--         end
--     end

--     -- Get all characters involved in the combat
--     local index = 1
--     local character = Osi.CombatGetInvolvedPlayer(combatGuid, index)
    
--     while character do
--         CheckAndCastArmorOfAgathys(character)
--         index = index + 1
--         character = Osi.CombatGetInvolvedPlayer(combatGuid, index)
--     end
-- end)
------------------------------------------------------------------------------------------------
-- For wildshape - delay removal to give AI time to process
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function (object, status, causee, storyActionID)
    if status == 'FORCE_USE_MOST' or status == 'FORCE_USE_MORE' then
        -- Delay removal by 500ms to allow AI to process the status
        local wildshapeTimer = "WildshapeForceRemove_" .. object .. "_" .. status
        Mods.AIAllies.characterTimers[wildshapeTimer] = {object = object, status = status}
        Osi.TimerLaunch(wildshapeTimer, 500)
        --Ext.Utils.Print("Scheduled removal of status: " .. status .. " from object: " .. object)
    end
end)
------------------------------------------------------------------------------------------------
-- Swarm Mechanic
local function HandleSwarmGroupAssignment(caster, target, spell)
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

function SetInitiativeToFixedValue(target, fixedInitiative)
    local entity = Ext.Entity.Get(target)
    
    if entity and entity.CombatParticipant and entity.CombatParticipant.CombatHandle then
        entity.CombatParticipant.InitiativeRoll = fixedInitiative
        entity.CombatParticipant.CombatHandle.CombatState.Initiatives[entity] = fixedInitiative
        entity:Replicate("CombatParticipant")
    else
        Ext.Utils.Print(string.format("Failed to set initiative for %s: Entity or CombatHandle is nil.", target))
    end
end

Ext.Osiris.RegisterListener("EnteredCombat", 2, "after", function(object, combatGuid)
    local swarmGroup = Osi.GetSwarmGroup(object)
    
    if swarmGroup == "AlliesSwarm_Alpha" or swarmGroup == "AlliesSwarm_Bravo" or swarmGroup == "AlliesSwarm_Charlie" or swarmGroup == "AlliesSwarm_Delta" then
        SetInitiativeToFixedValue(object, 6)
    end
end)

Ext.Osiris.RegisterListener("UsingSpellOnTarget", 6, "after", function(caster, target, spell, spellType, spellElement, storyActionID)
    HandleSwarmGroupAssignment(caster, target, spell)
end)
