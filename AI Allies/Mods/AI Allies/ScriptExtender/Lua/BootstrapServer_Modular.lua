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
local SpellControl = Ext.Require("SpellControl.lua")

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
-- PersistentVars stores data that survives game saves/loads
-- This is critical for maintaining AI ally assignments across sessions
Mods.AIAllies.PersistentVars = Mods.AIAllies.PersistentVars or {}
Mods.AIAllies.PersistentVars.CurrentAllies = Mods.AIAllies.PersistentVars.CurrentAllies or {}
Mods.AIAllies.PersistentVars.charactersUnderMindControl = Mods.AIAllies.PersistentVars.charactersUnderMindControl or {}

-- Runtime state (cleared on game restart, not saved)
-- These tables manage temporary states and pending operations
CurrentAllies = Mods.AIAllies.PersistentVars.CurrentAllies  -- Main tracking table: {uuid = true} for all AI allies
Mods.AIAllies.characterTimers = {}  -- Pending character additions: {timerName = uuid}
Mods.AIAllies.wildshapeTimers = {}  -- Wildshape status cleanup timers
Mods.AIAllies.spellModificationQueue = {}  -- Queued spell modifications
Mods.AIAllies.spellModificationTimers = {}  -- Pending spell modification callbacks: {timerName = callback}
Mods.AIAllies.currentlyProcessing = false  -- Prevents concurrent modifications
Mods.AIAllies.modifiedCharacters = {}  -- Tracks which characters have AI spells: {uuid = true}
Mods.AIAllies.appliedStatuses = {}  -- Tracks temporary statuses applied during turns: {uuid = statusName}
Mods.AIAllies.combatTimers = {}  -- Combat initialization timers: {timerName = combatGuid}
Mods.AIAllies.combatStartTimes = {}  -- Combat start timestamps for timeout detection: {combatGuid = timestamp}

-- Export BootstrapServer for global module access
-- This allows other modules (Formations, Dialog, etc.) to access CurrentAllies
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
-- Character addition/removal workflow:
-- 1. Controller status applied → Start CHARACTER_ADD_DELAY timer (1000ms)
-- 2. Timer expires → Add character to CurrentAllies
-- 3. Combat starts → Apply AI_ALLY and combat status
-- 4. Controller status removed → Immediately remove from CurrentAllies
-- 5. AI_CANCEL status applied → Immediately remove from CurrentAllies
--
-- The delay prevents premature addition during status application spam
-- and gives the game engine time to fully initialize the character state
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, causee, storyActionID)
    if AI.isControllerStatus(status) and Osi.IsPartyFollower(object) == 0 then
        local uuid = Osi.GetUUID(object)
        local PFtimer = "AddToAlliesTimer_" .. uuid
        Osi.TimerLaunch(PFtimer, CONSTANTS.CHARACTER_ADD_DELAY)
        Mods.AIAllies.characterTimers[PFtimer] = uuid
        Timer.RegisterTimer(PFtimer, "character")
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
-- Register Module Listeners (Deferred until SessionLoaded to avoid Osiris errors)
----------------------------------------------------------------------------------
Ext.Events.SessionLoaded:Subscribe(function()
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
    SpellControl.RegisterListeners()
    
    -- Initialize new modules
    Formations.Initialize()
    AdvancedFeatures.Initialize()
    
    Ext.Utils.Print("[AI Allies] All Osiris listeners registered successfully")
end)

----------------------------------------------------------------------------------
-- Module Initialization Complete
----------------------------------------------------------------------------------
Ext.Utils.Print("========================================")
Ext.Utils.Print("AI Allies Mod - Modular Edition Loaded")
Ext.Utils.Print("Modules: Shared, AI, MCM, Combat, Timer, Dialog, Features, Formations, AdvancedFeatures, Eldertide, Tactics, SpellControl")
Ext.Utils.Print("Multiplayer Support: ENABLED")
Ext.Utils.Print("Debug Mode: " .. tostring(CONSTANTS.DEBUG_MODE))
Ext.Utils.Print("========================================")
