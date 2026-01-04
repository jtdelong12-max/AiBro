----------------------------------------------------------------------------------
-- Features Module: Miscellaneous Features (Mindcontrol, Teleport, Faction, Debug)
-- Handles mind control, teleportation, faction management, and debug spells
----------------------------------------------------------------------------------

local Shared = Ext.Require("Shared.lua")
local Features = {}

-- Export shared references
local STATUS = Shared.STATUS
local SPELL = Shared.SPELL
local PASSIVE = Shared.PASSIVE
local CONSTANTS = Shared.CONSTANTS
local DebugLog = Shared.DebugLog
local SafeOsiCall = Shared.SafeOsiCall
local CachedExists = Shared.CachedExists

-- Module state
local charactersUnderMindControl = {}
local originalFactions = {}
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

----------------------------------------------------------------------------------
-- Warning System (ToggleIsNPC Easter Egg)
----------------------------------------------------------------------------------
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

----------------------------------------------------------------------------------
-- Mind Control System
----------------------------------------------------------------------------------
local function UpdateMindControlStatus(character, status)
    charactersUnderMindControl[character] = status
    Mods.AIAllies.PersistentVars.charactersUnderMindControl = charactersUnderMindControl
end

local function CanFollow()
    local playerCharacter = Osi.GetHostCharacter()
    return Osi.HasActiveStatus(playerCharacter, STATUS.ALLIES_ORDER_FOLLOW) == 1
end

local function UpdateFollowingBehavior(character)
    local playerCharacter = Osi.GetHostCharacter()
    if CanFollow() then
        Osi.PROC_Follow(character, playerCharacter)
    end
end

local function UpdateFollowForAll()
    local playerCharacter = Osi.GetHostCharacter()
    if CanFollow() then
        for character, _ in pairs(charactersUnderMindControl) do
            Osi.PROC_Follow(character, playerCharacter)
        end
    end
end

--- Teleport a character to the host player's location
function Features.TeleportCharacterToPlayer(character, alwaysTeleport)
    local playerCharacter = Osi.GetHostCharacter()
    if not playerCharacter or not character then
        return
    end
    if CachedExists(character) ~= 1 or CachedExists(playerCharacter) ~= 1 then
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

function Features.TeleportAlliesToCaster(caster, CurrentAllies)
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

----------------------------------------------------------------------------------
-- Faction Management
----------------------------------------------------------------------------------
local function InitOriginalFactions()
    if not Mods.AIAllies.PersistentVars.originalFactions then
        Mods.AIAllies.PersistentVars.originalFactions = {}
    end
    originalFactions = Mods.AIAllies.PersistentVars.originalFactions
end

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

----------------------------------------------------------------------------------
-- Event Listeners Registration
----------------------------------------------------------------------------------
function Features.RegisterListeners(CurrentAllies)
    -- Initialize faction system
    Ext.Events.SessionLoaded:Subscribe(InitOriginalFactions)
    
    -- ToggleIsNPC warning system
    Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, causee, storyActionID)
        if status == STATUS.TOGGLE_IS_NPC and Osi.IsPartyFollower(object) == 1 then
            local hostCharacter = Osi.GetHostCharacter()
            Osi.ApplyStatus(object, STATUS.ALLIES_WARNING, 0, 0, hostCharacter)
            Osi.TogglePassive(object, PASSIVE.ALLIES_TOGGLE_NPC)
            Osi.ShowNotification(hostCharacter, GetNextWarningMessage())
            Ext.Utils.Print("Not enabling NPC toggle, character is a party follower: " .. object)
        end
    end)
    
    -- Mind control status management
    Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, causee, storyActionID)
        if status == STATUS.ALLIES_MINDCONTROL then
            Osi.PROC_StopFollow(object)
            UpdateMindControlStatus(object, true)
            UpdateFollowingBehavior(object)
        elseif status == STATUS.ALLIES_ORDER_FOLLOW then
            UpdateFollowForAll()
        end
    end)
    
    Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", function(object, status, causee, storyActionID)
        if status == STATUS.ALLIES_MINDCONTROL then
            UpdateMindControlStatus(object, nil)
            Osi.PROC_StopFollow(object)
            if Osi.HasActiveStatus(object, STATUS.AI_ALLIES_POSSESSED) == 1 then
                Osi.RemoveStatus(object, STATUS.AI_ALLIES_POSSESSED)
                Ext.Utils.Print("Removed Possessed status from: " .. object)
            end
        end
    end)
    
    -- Teleport on mind control spell
    Ext.Osiris.RegisterListener("UsingSpellOnTarget", 6, "after", function(caster, target, spellName, _, _, _, _)
        if spellName == SPELL.MINDCONTROL_TELEPORT then
            for character, _ in pairs(charactersUnderMindControl) do
                Features.TeleportCharacterToPlayer(character, true)
            end
        end
    end)
    
    -- Teleport on camp arrival
    Ext.Osiris.RegisterListener("TeleportToFromCamp", 1, "after", function(target, _)
        if CanFollow() then
            for character, _ in pairs(charactersUnderMindControl) do
                Features.TeleportCharacterToPlayer(character, false)
            end
            UpdateFollowForAll()
        end
    end)
    
    -- Update follow on combat end
    Ext.Osiris.RegisterListener("CombatEnded", 1, "after", function(combat)
        UpdateFollowForAll()
    end)
    
    -- Allies teleport spell
    Ext.Osiris.RegisterListener("UsingSpellOnTarget", 6, "after", function(caster, target, spellName, _, _, _, _)
        if spellName == SPELL.ALLIES_TELEPORT then
            Features.TeleportAlliesToCaster(caster, CurrentAllies)
        end
    end)
    
    -- Possession system
    Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, causee, storyActionID)
        if status == STATUS.AI_ALLIES_POSSESSED then
            local hostCharacter = Osi.GetHostCharacter()
            local success = SafeOsiCall(Osi.AddPartyFollower, object, hostCharacter)
            if success then
                DebugLog("Possessed: " .. object, "POSSESSION")
            end
        end
    end)
    
    Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", function(object, status, causee, storyActionID)
        if status == STATUS.AI_ALLIES_POSSESSED then
            local hostCharacter = Osi.GetHostCharacter()
            SafeOsiCall(Osi.RemovePartyFollower, object, hostCharacter)
            DebugLog("Stopped Possessing: " .. object, "POSSESSION")
            SafeOsiCall(Osi.ApplyStatus, object, STATUS.AI_CANCEL, 0)
        end
    end)
    
    -- Crime immunity
    Ext.Osiris.RegisterListener("CrimeIsRegistered", 8, "after", function(victim, crimeType, crimeID, evidence, criminal1, criminal2, criminal3, criminal4)
        for uuid, _ in pairs(CurrentAllies) do
            if CurrentAllies[uuid] and CachedExists(uuid) == 1 then
                Osi.CrimeIgnoreCrime(crimeID, uuid)
                Osi.CharacterIgnoreActiveCrimes(uuid)
                Osi.BlockNewCrimeReactions(uuid, 1)
            end
        end
    end)
    
    -- Faction debug spells
    Ext.Osiris.RegisterListener("UsingSpellOnTarget", 6, "after", function(caster, target, spell, spellType, spellElement, storyActionID)
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
    
    Ext.Osiris.RegisterListener("UsingSpellOnTarget", 6, "after", function(caster, target, spell, _, _, _, _)
        if spell == SPELL.FACTION_LEAVE then
            local hostCharacter = Osi.GetHostCharacter()
            local originalFaction = originalFactions[hostCharacter] or "6545a015-1b3d-66a4-6a0e-6ec62065cdb7"

            local success = SafeOsiCall(Osi.SetFaction, hostCharacter, getCleanFactionID(originalFaction))
            if success then
                DebugLog("Reverted faction of " .. hostCharacter .. " to " .. getCleanFactionID(originalFaction), "FACTION")
            end
        end
    end)
    
    -- Debug spells
    Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, causee, storyActionID)
        if status == STATUS.MARK_NPC then
            Osi.MakeNPC(object)
        end
    end)
    
    Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, causee, storyActionID)
        if status == STATUS.MARK_PLAYER then
            Osi.MakePlayer(object)
        end
    end)
    
    Ext.Osiris.RegisterListener("UsingSpellOnTarget", 6, "after", function(caster, target, spell, spellType, spellElement, storyActionID)
        if spell == SPELL.CHECK_ARCHETYPE then
            local activeArchetype = Osi.GetActiveArchetype(target)
            local baseArchetype = Osi.GetBaseArchetype(target)
            Ext.Utils.Print("Target: " .. target)
            Ext.Utils.Print("Active Archetype: " .. activeArchetype)
            Ext.Utils.Print("Base Archetype: " .. baseArchetype)
        end
    end)
end

return Features
