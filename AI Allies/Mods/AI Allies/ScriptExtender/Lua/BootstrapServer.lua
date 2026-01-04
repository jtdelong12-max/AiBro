-- Current Allies
Mods = Mods or {}
Mods.AIAllies = Mods.AIAllies or {}
local ModuleUUID = "b485d242-f267-2d22-3108-631ba0549512"
if Mods.BG3MCM then
    setmetatable(Mods.AIAllies, { __index = Mods.BG3MCM })
end

----------------------------------------------------------------------------------
-- Constants
----------------------------------------------------------------------------------
local CONSTANTS = {
    -- Timer delays (milliseconds)
    COMBAT_RESUME_DELAY = 2000,
    WILDSHAPE_REMOVAL_DELAY = 500,
    SPELL_MODIFICATION_DELAY = 250,
    CHARACTER_ADD_DELAY = 1000,
    COMBAT_SAFETY_TIMEOUT = 60000,
    
    -- Status durations
    AI_ALLY_DURATION = -1,
    FOR_AI_SPELLS_DURATION = -1,
    
    -- Debug settings
    DEBUG_MODE = false  -- Set to true to enable debug logging
}

----------------------------------------------------------------------------------
-- Debug Logging System
----------------------------------------------------------------------------------
Mods.AIAllies.Debug = CONSTANTS.DEBUG_MODE

--- Conditional debug logging function
--- @param message string The message to log
--- @param category string Optional category for filtering logs
local function DebugLog(message, category)
    if Mods.AIAllies.Debug then
        local prefix = category and "[" .. category .. "] " or "[DEBUG] "
        Ext.Utils.Print(prefix .. message)
    end
end

--- Safe wrapper for Osiris API calls with error handling
--- @param func function The Osiris function to call
--- @param ... any Arguments to pass to the function
--- @return boolean success Whether the call succeeded
--- @return any result The result of the function call or error message
local function SafeOsiCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        Ext.Utils.Print("[ERROR] Osiris call failed: " .. tostring(result))
        return false, result
    end
    return true, result
end

----------------------------------------------------------------------------------
-- String Constants
----------------------------------------------------------------------------------
local STATUS = {
    -- Controller Statuses
    MELEE_CONTROLLER = "AI_ALLIES_MELEE_Controller",
    RANGED_CONTROLLER = "AI_ALLIES_RANGED_Controller",
    HEALER_MELEE_CONTROLLER = "AI_ALLIES_HEALER_MELEE_Controller",
    HEALER_RANGED_CONTROLLER = "AI_ALLIES_HEALER_RANGED_Controller",
    MAGE_MELEE_CONTROLLER = "AI_ALLIES_MAGE_MELEE_Controller",
    MAGE_RANGED_CONTROLLER = "AI_ALLIES_MAGE_RANGED_Controller",
    GENERAL_CONTROLLER = "AI_ALLIES_GENERAL_Controller",
    TRICKSTER_CONTROLLER = "AI_ALLIES_TRICKSTER_Controller",
    CUSTOM_CONTROLLER = "AI_ALLIES_CUSTOM_Controller",
    CUSTOM_CONTROLLER_2 = "AI_ALLIES_CUSTOM_Controller_2",
    CUSTOM_CONTROLLER_3 = "AI_ALLIES_CUSTOM_Controller_3",
    CUSTOM_CONTROLLER_4 = "AI_ALLIES_CUSTOM_Controller_4",
    THROWER_CONTROLLER = "AI_ALLIES_THROWER_CONTROLLER",
    DEFAULT_CONTROLLER = "AI_ALLIES_DEFAULT_Controller",
    AI_CONTROLLED = "AI_CONTROLLED",
    
    -- Combat Statuses (Player)
    MELEE = "AI_ALLIES_MELEE",
    RANGED = "AI_ALLIES_RANGED",
    HEALER_MELEE = "AI_ALLIES_HEALER_MELEE",
    HEALER_RANGED = "AI_ALLIES_HEALER_RANGED",
    MAGE_MELEE = "AI_ALLIES_MAGE_MELEE",
    MAGE_RANGED = "AI_ALLIES_MAGE_RANGED",
    GENERAL = "AI_ALLIES_GENERAL",
    TRICKSTER = "AI_ALLIES_TRICKSTER",
    CUSTOM = "AI_ALLIES_CUSTOM",
    CUSTOM_2 = "AI_ALLIES_CUSTOM_2",
    CUSTOM_3 = "AI_ALLIES_CUSTOM_3",
    CUSTOM_4 = "AI_ALLIES_CUSTOM_4",
    THROWER = "AI_ALLIES_THROWER",
    DEFAULT = "AI_ALLIES_DEFAULT",
    
    -- Combat Statuses (NPC)
    MELEE_NPC = "AI_ALLIES_MELEE_NPC",
    RANGED_NPC = "AI_ALLIES_RANGED_NPC",
    HEALER_MELEE_NPC = "AI_ALLIES_HEALER_MELEE_NPC",
    HEALER_RANGED_NPC = "AI_ALLIES_HEALER_RANGED_NPC",
    MAGE_MELEE_NPC = "AI_ALLIES_MAGE_MELEE_NPC",
    MAGE_RANGED_NPC = "AI_ALLIES_MAGE_RANGED_NPC",
    GENERAL_NPC = "AI_ALLIES_GENERAL_NPC",
    TRICKSTER_NPC = "AI_ALLIES_TRICKSTER_NPC",
    CUSTOM_NPC = "AI_ALLIES_CUSTOM_NPC",
    CUSTOM_2_NPC = "AI_ALLIES_CUSTOM_2_NPC",
    CUSTOM_3_NPC = "AI_ALLIES_CUSTOM_3_NPC",
    CUSTOM_4_NPC = "AI_ALLIES_CUSTOM_4_NPC",
    THROWER_NPC = "AI_ALLIES_THROWER_NPC",
    DEFAULT_NPC = "AI_ALLIES_DEFAULT_NPC",
    
    -- Special Statuses
    AI_ALLY = "AI_ALLY",
    AI_CANCEL = "AI_CANCEL",
    FOR_AI_SPELLS = "FOR_AI_SPELLS",
    TOGGLE_IS_NPC = "ToggleIsNPC",
    ALLIES_WARNING = "ALLIES_WARNING",
    ALLIES_MINDCONTROL = "ALLIES_MINDCONTROL",
    ALLIES_ORDER_FOLLOW = "ALLIES_ORDER_FOLLOW",
    AI_ALLIES_POSSESSED = "AI_ALLIES_POSSESSED",
    MARK_NPC = "MARK_NPC",
    MARK_PLAYER = "MARK_PLAYER",
    FORCE_USE = "FORCE_USE",
    FORCE_USE_MORE = "FORCE_USE_MORE",
    FORCE_USE_MOST = "FORCE_USE_MOST"
}

local SPELL = {
    -- AI Spell Variants
    ACTION_SURGE_AI = "Shout_ActionSurge_AI",
    DASH_AI = "Shout_Dash_AI",
    DASH_CUNNING_AI = "Shout_Dash_CunningAction_AI",
    RAGE_BERSERKER_AI = "Shout_Rage_Berserker_AI",
    RAGE_WILDHEART_AI = "Shout_Rage_Wildheart_AI",
    RAGE_WILDMAGIC_AI = "Shout_Rage_WildMagic_AI",
    
    -- Base Spells
    ACTION_SURGE = "Shout_ActionSurge",
    DASH = "Shout_Dash",
    DASH_CUNNING = "Shout_Dash_CunningAction",
    RAGE_BERSERKER = "Shout_Rage_Berserker",
    RAGE_WILDHEART = "Shout_Rage_Wildheart",
    RAGE_WILDMAGIC = "Shout_Rage_WildMagic",
    
    -- Special Spells
    MINDCONTROL_TELEPORT = "Target_Allies_C_Order_Teleport",
    ALLIES_TELEPORT = "C_Shout_Allies_Teleport",
    FACTION_JOIN = "G_Target_Allies_Faction",
    FACTION_LEAVE = "H_Target_Allies_Faction_Leave",
    CHECK_ARCHETYPE = "I_Target_Allies_Check_Archetype"
}

local PASSIVE = {
    UNLOCK_CUSTOM_ARCHETYPES = "UnlockCustomArchetypes",
    ALLIES_MIND = "AlliesMind",
    ALLIES_DASHING_DISABLED = "AlliesDashingDisabled",
    ALLIES_THROWING_DISABLED = "AlliesThrowingDisabled",
    ALLIES_DYNAMIC_SPELLBLOCK = "AlliesDynamicSpellblock",
    ALLIES_SWARM = "AlliesSwarm",
    UNLOCK_ALLIES_ORDERS = "UnlockAlliesOrders",
    UNLOCK_ALLIES_ORDERS_BONUS = "UnlockAlliesOrdersBonus",
    UNLOCK_ALLIES_EXTRA_SPELLS = "UnlockAlliesExtraSpells",
    UNLOCK_ALLIES_EXTRA_SPELLS_ALT = "UnlockAlliesExtraSpells_ALT",
    GIVE_ALLIES_SPELL = "GiveAlliesSpell",
    ALLIES_TOGGLE_NPC = "AlliesToggleNPC"
}


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
-- MCM Management System
-------------------------------------------------------------------------------

--- Generic function to manage MCM-controlled passives
--- @param settingKey string The MCM setting key to check
--- @param passiveName string The passive ability to add/remove
--- @param inverted boolean Optional - if true, passive is added when setting is false
local function ManageMCMPassive(settingKey, passiveName, inverted)
    if not Mods.AIAllies.MCMAPI then
        return
    end
    
    local settingValue = Mods.AIAllies.MCMAPI:GetSettingValue(settingKey, ModuleUUID)
    local shouldHavePassive = inverted and not settingValue or settingValue
    local players = Osi.DB_PartOfTheTeam:Get(nil)
    
    for _, player in pairs(players) do
        local character = player[1]
        local hasPassive = Osi.HasPassive(character, passiveName) == 1
        
        if shouldHavePassive and not hasPassive then
            Osi.AddPassive(character, passiveName)
            DebugLog("Added '" .. passiveName .. "' to: " .. character, "MCM")
        elseif not shouldHavePassive and hasPassive then
            Osi.RemovePassive(character, passiveName)
            DebugLog("Removed '" .. passiveName .. "' from: " .. character, "MCM")
        end
    end
end

-- Legacy wrapper functions for backward compatibility
local function ManageCustomArchetypes()
    ManageMCMPassive("enableCustomArchetypes", PASSIVE.UNLOCK_CUSTOM_ARCHETYPES)
end

local function ManageAlliesMind()
    ManageMCMPassive("enableAlliesMind", PASSIVE.ALLIES_MIND)
end

local function ManageAlliesDashing()
    ManageMCMPassive("disableAlliesDashing", PASSIVE.ALLIES_DASHING_DISABLED)
end

local function ManageAlliesThrowing()
    ManageMCMPassive("disableAlliesThrowing", PASSIVE.ALLIES_THROWING_DISABLED)
end

local function ManageDynamicSpellblock()
    ManageMCMPassive("enableDynamicSpellblock", PASSIVE.ALLIES_DYNAMIC_SPELLBLOCK)
end

local function ManageAlliesSwarm()
    ManageMCMPassive("enableAlliesSwarm", PASSIVE.ALLIES_SWARM)
end

local function ManageOrderSpellsPassive()
    local players = Osi.DB_PartOfTheTeam:Get(nil)
    if Mods.AIAllies.MCMAPI then
        local enableOrdersBonusAction = Mods.AIAllies.MCMAPI:GetSettingValue("enableOrdersBonusAction", ModuleUUID)
        for _, player in pairs(players) do
            local character = player[1]
            if enableOrdersBonusAction then
                if Osi.HasPassive(character, PASSIVE.UNLOCK_ALLIES_ORDERS) == 1 then
                    Osi.RemovePassive(character, PASSIVE.UNLOCK_ALLIES_ORDERS)
                end
                if Osi.HasPassive(character, PASSIVE.UNLOCK_ALLIES_ORDERS_BONUS) == 0 then
                    Osi.AddPassive(character, PASSIVE.UNLOCK_ALLIES_ORDERS_BONUS)
                end
            else
                if Osi.HasPassive(character, PASSIVE.UNLOCK_ALLIES_ORDERS_BONUS) == 1 then
                    Osi.RemovePassive(character, PASSIVE.UNLOCK_ALLIES_ORDERS_BONUS)
                end
                if Osi.HasPassive(character, PASSIVE.UNLOCK_ALLIES_ORDERS) == 0 then
                    Osi.AddPassive(character, PASSIVE.UNLOCK_ALLIES_ORDERS)
                end
            end
        end
    else
        for _, player in pairs(players) do
            local character = player[1]
            if Osi.HasPassive(character, PASSIVE.UNLOCK_ALLIES_ORDERS) == 0 then
                Osi.AddPassive(character, PASSIVE.UNLOCK_ALLIES_ORDERS)
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
                if Osi.HasPassive(character, PASSIVE.UNLOCK_ALLIES_EXTRA_SPELLS) == 1 then
                    Osi.RemovePassive(character, PASSIVE.UNLOCK_ALLIES_EXTRA_SPELLS)
                end
                if Osi.HasPassive(character, PASSIVE.UNLOCK_ALLIES_EXTRA_SPELLS_ALT) == 0 then
                    Osi.AddPassive(character, PASSIVE.UNLOCK_ALLIES_EXTRA_SPELLS_ALT)
                end
            else
                if Osi.HasPassive(character, PASSIVE.UNLOCK_ALLIES_EXTRA_SPELLS_ALT) == 1 then
                    Osi.RemovePassive(character, PASSIVE.UNLOCK_ALLIES_EXTRA_SPELLS_ALT)
                end
                if Osi.HasPassive(character, PASSIVE.UNLOCK_ALLIES_EXTRA_SPELLS) == 0 then
                    Osi.AddPassive(character, PASSIVE.UNLOCK_ALLIES_EXTRA_SPELLS)
                end
            end
        end
    else
        -- If MCM is not available, ensure the player has the default passive
        local players = Osi.DB_PartOfTheTeam:Get(nil)
        for _, player in pairs(players) do
            local character = player[1]
            if Osi.HasPassive(character, PASSIVE.UNLOCK_ALLIES_EXTRA_SPELLS) == 0 then
                Osi.AddPassive(character, PASSIVE.UNLOCK_ALLIES_EXTRA_SPELLS)
            end
            if Osi.HasPassive(character, PASSIVE.UNLOCK_ALLIES_EXTRA_SPELLS_ALT) == 1 then
                Osi.RemovePassive(character, PASSIVE.UNLOCK_ALLIES_EXTRA_SPELLS_ALT)
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
            if Osi.HasPassive(character, PASSIVE.GIVE_ALLIES_SPELL) == 0 then
                Osi.AddPassive(character, PASSIVE.GIVE_ALLIES_SPELL)
                Ext.Utils.Print("Given '" .. PASSIVE.GIVE_ALLIES_SPELL .. "' to: " .. character)
            end
            if Osi.HasPassive(character, PASSIVE.ALLIES_TOGGLE_NPC) == 0 then
                Osi.AddPassive(character, PASSIVE.ALLIES_TOGGLE_NPC)
                Ext.Utils.Print("Given '" .. PASSIVE.ALLIES_TOGGLE_NPC .. "' to: " .. character)
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
            Osi.ApplyStatus(character, STATUS.AI_CANCEL, 0)
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
local aiCombatStatuses = {
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
local NPCStatuses = {
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
    if status == STATUS.TOGGLE_IS_NPC and Osi.IsPartyFollower(object) == 1 then
        local hostCharacter = Osi.GetHostCharacter()
        Osi.ApplyStatus(object, STATUS.ALLIES_WARNING, 0, 0, hostCharacter)
        Osi.TogglePassive(object, PASSIVE.ALLIES_TOGGLE_NPC)
        Osi.ShowNotification(hostCharacter, GetNextWarningMessage())
        Ext.Utils.Print("Not enabling NPC toggle, character is a party follower: " .. object)
    elseif isControllerStatus(status) and Osi.IsPartyFollower(object) == 0 then
        local uuid = Osi.GetUUID(object)
        local PFtimer = "AddToAlliesTimer_" .. uuid
        Osi.TimerLaunch(PFtimer, CONSTANTS.CHARACTER_ADD_DELAY)
        Mods.AIAllies.characterTimers[PFtimer] = uuid
        DebugLog("Started timer for " .. uuid, "TIMER")
    end
end)

--- Remove a specific character from CurrentAllies tracking
--- @param uuid string The UUID of the character to remove
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
    if status == STATUS.AI_CANCEL then
        local uuid = Osi.GetUUID(object)
        RemoveFromCurrentAllies(uuid)
    end
end)
---------------------------------------------------------------------------------------------
Ext.Osiris.RegisterListener("CombatStarted", 1, "after", function(combatGuid)
    for uuid, _ in pairs(CurrentAllies) do
        if CurrentAllies[uuid] and Osi.Exists(uuid) == 1 then
            Osi.ApplyStatus(uuid, STATUS.AI_ALLY, -1)
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

--- Teleport a character to the host player's location
--- @param character string The character UUID to teleport
--- @param alwaysTeleport boolean If true, always teleport; if false, only teleport if follow order is active
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
        local success = SafeOsiCall(Osi.TeleportTo, character, playerCharacter)
        if success then
            DebugLog("Teleported " .. character .. " to player: " .. playerCharacter, "TELEPORT")
            if CanFollow() then
                SafeOsiCall(Osi.PROC_Follow, character, playerCharacter)
            end
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
    if status == STATUS.ALLIES_MINDCONTROL then
        Osi.PROC_StopFollow(object)
        UpdateMindControlStatus(object, true)
        UpdateFollowingBehavior(object)
    elseif status == STATUS.ALLIES_ORDER_FOLLOW then
        UpdateFollowForAll()
    end
end)

Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", function (object, status, causee, storyActionID)
    if status == STATUS.ALLIES_MINDCONTROL then
        UpdateMindControlStatus(object, nil)
        Osi.PROC_StopFollow(object)
        if Osi.HasActiveStatus(object, STATUS.AI_ALLIES_POSSESSED) == 1 then
            Osi.RemoveStatus(object, STATUS.AI_ALLIES_POSSESSED)
            Ext.Utils.Print("Removed Possessed status from: " .. object)
        end
    elseif status == 'ALLIES_ORDER_FOLLOW' then
        UpdateFollowForAll()
    end
end)

Ext.Osiris.RegisterListener("UsingSpellOnTarget", 6, "after", function (caster, target, spellName, _, _, _, _)
    if spellName == SPELL.MINDCONTROL_TELEPORT then
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

--- Apply combat AI status based on the character's controller buff
--- Translates Controller statuses (e.g., AI_ALLIES_MELEE_Controller) to combat statuses (e.g., AI_ALLIES_MELEE)
--- Automatically appends _NPC suffix if character has ToggleIsNPC status
--- @param character string The character UUID
--- @return boolean success True if a status was applied, false otherwise
local function ApplyStatusFromControllerBuff(character)
    for controllerBuff, status in pairs(controllerToStatusTranslator) do
        local success, hasStatus = SafeOsiCall(Osi.HasActiveStatus, character, controllerBuff)
        if success and hasStatus == 1 then
            local success2, hasNPC = SafeOsiCall(Osi.HasActiveStatus, character, "ToggleIsNPC")
            if success2 and hasNPC == 1 then
                status = status .. '_NPC'
                SafeOsiCall(Osi.MakeNPC, character)
            end
            local applySuccess = SafeOsiCall(Osi.ApplyStatus, character, status, -1)
            if applySuccess then
                DebugLog("Applied " .. status .. " to " .. character, "STATUS")
                return true
            end
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
        -- Note: AlliesBannedActions is applied to specific utility spells in Block_AI.txt
        -- to prevent AI from wasting actions on non-combat spells during fights
        Osi.ApplyStatus(object, "AI_ALLY", CONSTANTS.AI_ALLY_DURATION)
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
        local success = SafeOsiCall(Osi.AddPartyFollower, object, hostCharacter)
        if success then
            DebugLog("Possessed: " .. object, "POSSESSION")
        end
    end
end)

Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", function (object, status, causee, storyActionID)
    if status == 'AI_ALLIES_POSSESSED' then
        local hostCharacter = Osi.GetHostCharacter()
        SafeOsiCall(Osi.RemovePartyFollower, object, hostCharacter)
        DebugLog("Stopped Possessing: " .. object, "POSSESSION")
        SafeOsiCall(Osi.ApplyStatus, object, "AI_CANCEL", 0)
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
        local success1, hasController = SafeOsiCall(Osi.HasActiveStatus, character, controllerBuff)
        if success1 and hasController == 1 then
            local success2, hasNPC = SafeOsiCall(Osi.HasActiveStatus, character, STATUS.TOGGLE_IS_NPC)
            if success2 and hasNPC == 0 then
                local applySuccess = SafeOsiCall(Osi.ApplyStatus, character, status, -1)
                if applySuccess then
                    DebugLog("Applied " .. status .. " to " .. character, "STATUS")
                    return status
                end
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
            local success = SafeOsiCall(Osi.RemoveStatus, character, status, character)
            if success then
                DebugLog("Removed " .. status .. " from " .. character, "TURN")
            end
            Mods.AIAllies.appliedStatuses[character] = nil
        end
    end
end)
------------------------------------------------------------------------------------------
-- AI Specific spells
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
--- Maps base spells (e.g., Shout_Dash) to AI versions (e.g., Shout_Dash_AI)
--- @param character string The character UUID
--- @param addSpell boolean True to add AI spells, false to remove them
local function ModifyAISpells(character, addSpell)
    -- Validate entity exists before modifying spells
    if not character or Osi.Exists(character) ~= 1 then
        Ext.Utils.Print("[WARNING] Cannot modify spells - invalid character: " .. tostring(character))
        return
    end
    
    for originalSpell, aiSpell in pairs(spellMappings) do
        local success, hasAIVersion = SafeOsiCall(Osi.HasSpell, character, aiSpell)
        if not success then
            hasAIVersion = false
        else
            hasAIVersion = hasAIVersion == 1
        end

        local success2, hasOriginal = SafeOsiCall(Osi.HasSpell, character, originalSpell)
        if success2 and hasOriginal == 1 then
            if addSpell and not hasAIVersion then
                SafeOsiCall(Osi.AddSpell, character, aiSpell, 0, 0)
            elseif not addSpell and hasAIVersion then
                SafeOsiCall(Osi.RemoveSpell, character, aiSpell, 0)
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
    Osi.TimerLaunch(nextProcessTimer, CONSTANTS.SPELL_MODIFICATION_DELAY)
    Mods.AIAllies.spellModificationTimers[nextProcessTimer] = function() ProcessQueue() end
end

-- StatusApplied listener adjusted to use queue
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function (character, status, causee, storyActionID)
    if hasAnyAICombatStatus(character) and not Mods.AIAllies.modifiedCharacters[character] and Osi.HasActiveStatus(character, STATUS.TOGGLE_IS_NPC) == 0 then
        Mods.AIAllies.modifiedCharacters[character] = true
        table.insert(Mods.AIAllies.spellModificationQueue, character)
        if not Mods.AIAllies.currentlyProcessing then
            ProcessQueue()
        end
    end
end)

-- Listener for when 'FOR_AI_SPELLS' status is removed
Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", function (character, status, causee, storyActionID)
    if status == STATUS.FOR_AI_SPELLS then
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

Ext.Osiris.RegisterListener("DialogActorJoined", 4, "after", function(dialog, instanceID, actor, speakerIndex)
    HandleDialogActorJoined(instanceID, actor)
end)

local function HandleDialogEnded(dialog, instanceID)
    if instanceID == relevantDialogInstance then
        for actorUuid, data in pairs(transformedCompanions) do
            -- Validate entity still exists
            local success, exists = SafeOsiCall(Osi.Exists, actorUuid)
            if not success or exists ~= 1 then
                Ext.Utils.Print("[WARNING] Actor " .. actorUuid .. " no longer exists, skipping reversion")
            else
                local success2, inCombat = SafeOsiCall(Osi.IsInCombat, actorUuid)
                if success2 and inCombat == 0 then
                    DebugLog("Character " .. actorUuid .. " is not in combat, remaining as player character after dialog end.", "DIALOG")
                else
                    local makeNPCSuccess = SafeOsiCall(Osi.MakeNPC, actorUuid)
                    if makeNPCSuccess then
                        -- Restore original faction
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

Ext.Osiris.RegisterListener("DialogEnded", 2, "after", HandleDialogEnded)
-----------------------------------------------------------------------------------------------
-- Function to teleport allies to the caster
function TeleportAlliesToCaster(caster)
    local target = Osi.GetHostCharacter()
    for uuid, _ in pairs(CurrentAllies) do
        if CurrentAllies[uuid] then
            local success = SafeOsiCall(Osi.TeleportTo, uuid, target, "", 1, 1, 1, 0, 1)
            if success then
                DebugLog("Teleporting ally: " .. uuid, "TELEPORT")
            end
        end
    end
end


-- Listener for the 'C_Shout_Allies_Teleport' spell
Ext.Osiris.RegisterListener("UsingSpellOnTarget", 6, "after", function (caster, target, spellName, _, _, _, _)
    if spellName == SPELL.ALLIES_TELEPORT then
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
        DebugLog("Original faction saved for " .. character .. ": " .. newFaction, "FACTION")
    else
        DebugLog("Original faction for " .. character .. " already set to: " .. originalFactions[character], "FACTION")
    end
end

local function getCleanFactionID(factionString)
    local factionID = string.match(factionString, "([0-9a-f-]+)$")
    return factionID or factionString
end

-- Faction Debug
Ext.Osiris.RegisterListener("UsingSpellOnTarget", 6, "after", function (caster, target, spell, spellType, spellElement, storyActionID)
    if spell == SPELL.FACTION_JOIN then
        local success1, casterFaction = SafeOsiCall(Osi.GetFaction, caster)
        local success2, targetFaction = SafeOsiCall(Osi.GetFaction, target)
        local hostCharacter = Osi.GetHostCharacter()

        if success1 and success2 and hostCharacter then
            local success3, hostFaction = SafeOsiCall(Osi.GetFaction, hostCharacter)
            if success3 then
                SafelyUpdateFactionStore(hostCharacter, getCleanFactionID(hostFaction))
            end

            DebugLog("Caster's current faction: " .. casterFaction, "FACTION")
            DebugLog("Target's faction: " .. targetFaction, "FACTION")

            local setSuccess = SafeOsiCall(Osi.SetFaction, hostCharacter, getCleanFactionID(targetFaction))
            if setSuccess then
                DebugLog("Changed faction of " .. hostCharacter .. " to " .. getCleanFactionID(targetFaction), "FACTION")
            end
        end
    end
end)

Ext.Osiris.RegisterListener("UsingSpellOnTarget", 6, "after", function (caster, target, spell, _, _, _, _)
    if spell == SPELL.FACTION_LEAVE then
        local hostCharacter = Osi.GetHostCharacter()
        local originalFaction = originalFactions[hostCharacter] or "6545a015-1b3d-66a4-6a0e-6ec62065cdb7"

        local success = SafeOsiCall(Osi.SetFaction, hostCharacter, getCleanFactionID(originalFaction))
        if success then
            DebugLog("Reverted faction of " .. hostCharacter .. " to " .. getCleanFactionID(originalFaction), "FACTION")
        end
    end
end)
------------------------------------------------------------------------------------------------
-- for Debug spells
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function (object, status, causee, storyActionID)
    if status == STATUS.MARK_NPC then
        Osi.MakeNPC(object)
    end
end)

Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function (object, status, causee, storyActionID)
    if status == STATUS.MARK_PLAYER then
        Osi.MakePlayer(object)
    end
end)

-- Listener function for UsingSpellOnTarget
function OnUsingSpellOnTarget(caster, target, spell, spellType, spellElement, storyActionID)
    if spell == SPELL.CHECK_ARCHETYPE then
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

Ext.Osiris.RegisterListener("CombatStarted", 1, "after", function(combatGuid)
    Osi.PauseCombat(combatGuid)
    DebugLog("Pausing combat to allow AI to initialize", "COMBAT")
    local InitializeTimerAI = "ResumeCombatTimer_" .. tostring(combatGuid)
    Mods.AIAllies.combatTimers[InitializeTimerAI] = combatGuid
    Mods.AIAllies.combatStartTimes[combatGuid] = Ext.Utils.MonotonicTime()
    Osi.TimerLaunch(InitializeTimerAI, CONSTANTS.COMBAT_RESUME_DELAY)
end)

-- Fallback: Force resume combat if it's been paused too long (safety mechanism)
Ext.Osiris.RegisterListener("TurnStarted", 1, "after", function(entityGuid)
    local combatGuid = Osi.CombatGetGuidFor(entityGuid)
    if combatGuid and Mods.AIAllies.combatStartTimes[combatGuid] then
        local elapsed = Ext.Utils.MonotonicTime() - Mods.AIAllies.combatStartTimes[combatGuid]
        if elapsed > CONSTANTS.COMBAT_SAFETY_TIMEOUT then
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
    if status == STATUS.FORCE_USE_MOST or status == STATUS.FORCE_USE_MORE then
        -- Delay removal to allow AI to process the status
        local wildshapeTimer = "WildshapeForceRemove_" .. object .. "_" .. status
        Mods.AIAllies.characterTimers[wildshapeTimer] = {object = object, status = status}
        Osi.TimerLaunch(wildshapeTimer, CONSTANTS.WILDSHAPE_REMOVAL_DELAY)
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
