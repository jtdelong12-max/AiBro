----------------------------------------------------------------------------------
-- AI Allies Mod - Main Bootstrap File
-- Modular architecture: Loads and coordinates all AI Allies systems
----------------------------------------------------------------------------------

-- Initialize mod namespace
Mods = Mods or {}
Mods.AIAllies = Mods.AIAllies or {}
local ModuleUUID = "b485d242-f267-2d22-3108-631ba0549512"

-- BG3MCM integration
if Mods.BG3MCM then
    setmetatable(Mods.AIAllies, { __index = Mods.BG3MCM })
end

----------------------------------------------------------------------------------
-- Load Modules
----------------------------------------------------------------------------------
local Shared = Ext.Require("Shared.lua")
local AI = Ext.Require("AI.lua")
local MCM = Ext.Require("MCM.lua")
local Combat = Ext.Require("Combat.lua")
local Timer = Ext.Require("Timer.lua")
local Dialog = Ext.Require("Dialog.lua")
local Features = Ext.Require("Features.lua")
local Formations = Ext.Require("Formations.lua")
local AdvancedFeatures = Ext.Require("AdvancedFeatures.lua")
local Eldertide = Ext.Require("Eldertide.lua")
local Tactics = Ext.Require("Tactics.lua")

-- Export shared utilities for global access
local STATUS = Shared.STATUS
local SPELL = Shared.SPELL
local PASSIVE = Shared.PASSIVE
local CONSTANTS = Shared.CONSTANTS
local DebugLog = Shared.DebugLog
local SafeOsiCall = Shared.SafeOsiCall
local CachedExists = Shared.CachedExists

-- Export multiplayer functions for global access
local GetAllPlayers = Shared.GetAllPlayers
local GetPlayerForEntity = Shared.GetPlayerForEntity
local GetClosestPlayer = Shared.GetClosestPlayer
local ForEachPlayer = Shared.ForEachPlayer

-- Initialize debug mode
Mods.AIAllies.Debug = CONSTANTS.DEBUG_MODE

----------------------------------------------------------------------------------
-- Persistent State Management
----------------------------------------------------------------------------------
Mods.AIAllies.PersistentVars = Mods.AIAllies.PersistentVars or {}
Mods.AIAllies.PersistentVars.CurrentAllies = Mods.AIAllies.PersistentVars.CurrentAllies or {}
Mods.AIAllies.PersistentVars.charactersUnderMindControl = Mods.AIAllies.PersistentVars.charactersUnderMindControl or {}

-- Runtime state
CurrentAllies = Mods.AIAllies.PersistentVars.CurrentAllies
Mods.AIAllies.characterTimers = {}
Mods.AIAllies.wildshapeTimers = {}
Mods.AIAllies.spellModificationQueue = {}
Mods.AIAllies.spellModificationTimers = {}
Mods.AIAllies.currentlyProcessing = false
Mods.AIAllies.modifiedCharacters = {}
Mods.AIAllies.appliedStatuses = {}
Mods.AIAllies.combatTimers = {}
Mods.AIAllies.combatStartTimes = {}

-- Export BootstrapServer for global module access
BootstrapServer = BootstrapServer or {}
BootstrapServer.CurrentAllies = CurrentAllies

----------------------------------------------------------------------------------
-- Ally Management Functions
----------------------------------------------------------------------------------
--- Remove a specific character from CurrentAllies tracking
--- @param uuid string The UUID of the character to remove
local function RemoveFromCurrentAllies(uuid)
    CurrentAllies[uuid] = nil
    Mods.AIAllies.PersistentVars.CurrentAllies = CurrentAllies
    Ext.Utils.Print("Removed from CurrentAllies: " .. uuid)
end

----------------------------------------------------------------------------------
-- Core Event Listeners
----------------------------------------------------------------------------------
-- Character addition/removal based on controller status
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, causee, storyActionID)
    if AI.isControllerStatus(status) and Osi.IsPartyFollower(object) == 0 then
        local uuid = Osi.GetUUID(object)
        local PFtimer = "AddToAlliesTimer_" .. uuid
        Osi.TimerLaunch(PFtimer, CONSTANTS.CHARACTER_ADD_DELAY)
        Mods.AIAllies.characterTimers[PFtimer] = uuid
        DebugLog("Started timer for " .. uuid, "TIMER")
    end
end)

Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", function(object, status, causee, storyActionID)
    if AI.isControllerStatus(status) then
        local uuid = Osi.GetUUID(object)
        RemoveFromCurrentAllies(uuid)
    end
end)

Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, causee, storyActionID)
    if status == STATUS.AI_CANCEL then
        local uuid = Osi.GetUUID(object)
        RemoveFromCurrentAllies(uuid)
    end
end)

Ext.Osiris.RegisterListener("CharacterLeftParty", 1, "after", function(character)
    if character then
        local isInCombat = Osi.IsInCombat(character)
        if isInCombat == 0 then
            Osi.ApplyStatus(character, STATUS.AI_CANCEL, 0)
        end
    end
end)

-- Player initialization
Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "after", function()
    MCM.InitializeAll()
    
    local players = Osi.DB_PartOfTheTeam:Get(nil)
    for _, player in pairs(players) do
        local character = player[1]
        Osi.BlockNewCrimeReactions(character, 1)
    end
end)

Ext.Osiris.RegisterListener("CharacterJoinedParty", 1, "after", function(character)
    MCM.InitializeAll()
    Osi.BlockNewCrimeReactions(character, 1)
end)

----------------------------------------------------------------------------------
-- Register Module Listeners
----------------------------------------------------------------------------------
MCM.RegisterListeners(ModuleUUID)
Combat.RegisterListeners(CurrentAllies)
Combat.RegisterSwarmListeners()
Timer.RegisterListeners(CurrentAllies)
Dialog.RegisterListeners(CurrentAllies)
Features.RegisterListeners(CurrentAllies)
Formations.RegisterListeners()
AdvancedFeatures.RegisterListeners()
Eldertide.RegisterListeners()
Tactics.RegisterListeners()

-- Initialize new modules
Formations.Initialize()
AdvancedFeatures.Initialize()

----------------------------------------------------------------------------------
-- Module Initialization Complete
----------------------------------------------------------------------------------
Ext.Utils.Print("========================================")
Ext.Utils.Print("AI Allies Mod - Modular Edition Loaded")
Ext.Utils.Print("Modules: Shared, AI, MCM, Combat, Timer, Dialog, Features, Formations, AdvancedFeatures, Eldertide, Tactics")
Ext.Utils.Print("Multiplayer Support: ENABLED")
Ext.Utils.Print("Debug Mode: " .. tostring(CONSTANTS.DEBUG_MODE))
Ext.Utils.Print("========================================")
