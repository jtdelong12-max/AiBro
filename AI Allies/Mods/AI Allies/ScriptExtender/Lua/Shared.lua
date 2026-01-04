----------------------------------------------------------------------------------
-- Shared Module: Constants, Utilities, and Common Data
-- Contains all shared constants, debug utilities, and performance optimizations
----------------------------------------------------------------------------------

local Shared = {}

----------------------------------------------------------------------------------
-- Constants
----------------------------------------------------------------------------------
Shared.CONSTANTS = {
    -- Timer delays (milliseconds)
    COMBAT_RESUME_DELAY = 2000,
    WILDSHAPE_REMOVAL_DELAY = 500,
    SPELL_MODIFICATION_DELAY = 250,
    CHARACTER_ADD_DELAY = 1000,
    COMBAT_SAFETY_TIMEOUT = 60000,
    
    -- Status durations
    AI_ALLY_DURATION = -1,
    FOR_AI_SPELLS_DURATION = -1,
    
    -- Performance optimization
    ENTITY_CACHE_REFRESH = 1000,  -- How often to refresh entity existence cache (ms)
    EVENT_THROTTLE_DELAY = 100,    -- Minimum delay between identical event processing (ms)
    
    -- Formation positioning
    FORMATION_DISTANCE = 3.0,      -- Distance between formation positions
    FORMATION_UPDATE_INTERVAL = 2000,  -- How often to update formation positions (ms)
    
    -- Advanced features
    AUTO_HEAL_THRESHOLD = 0.5,     -- Health percentage to trigger auto-heal (50%)
    AGGRESSION_LEVEL_DEFAULT = 1.0, -- Default aggression multiplier
    SPELL_PRIORITY_ENABLED = false, -- Enable spell priority system
    
    -- Debug settings
    DEBUG_MODE = false  -- Set to true to enable debug logging
}

----------------------------------------------------------------------------------
-- Performance Optimization: Entity Cache & Event Throttling
----------------------------------------------------------------------------------
local entityCache = {}  -- Cache for entity existence checks
local entityCacheTimer = 0  -- Timestamp of last cache refresh
local eventThrottle = {}  -- Tracks last execution time for throttled events

--- Cached entity existence check with periodic refresh
--- @param entity string The entity UUID to check
--- @return number 1 if entity exists, 0 otherwise
function Shared.CachedExists(entity)
    if not entity or type(entity) ~= "string" or entity == "" then
        return 0
    end
    
    local currentTime = Ext.Utils.MonotonicTime()
    
    -- Refresh cache if expired
    if currentTime - entityCacheTimer > Shared.CONSTANTS.ENTITY_CACHE_REFRESH then
        entityCache = {}  -- Clear old cache
        entityCacheTimer = currentTime
    end
    
    -- Check cache first
    if entityCache[entity] ~= nil then
        return entityCache[entity]
    end
    
    -- Cache miss - check and store result (with error handling)
    local success, exists = pcall(Osi.Exists, entity)
    if not success then
        -- Log error and return 0
        if Shared.CONSTANTS.DEBUG_MODE then
            Ext.Utils.Print("[ERROR] Failed to check existence for entity: " .. tostring(entity))
        end
        return 0
    end
    
    entityCache[entity] = exists or 0
    return exists or 0
end

--- Throttle event processing to prevent spam
--- @param eventKey string Unique key for the event type
--- @return boolean True if event should be processed, false if throttled
function Shared.ThrottleEvent(eventKey)
    local currentTime = Ext.Utils.MonotonicTime()
    local lastTime = eventThrottle[eventKey] or 0
    
    if currentTime - lastTime >= Shared.CONSTANTS.EVENT_THROTTLE_DELAY then
        eventThrottle[eventKey] = currentTime
        return true
    end
    return false
end

----------------------------------------------------------------------------------
-- Debug Logging System
----------------------------------------------------------------------------------
--- Conditional debug logging function
--- @param message string The message to log
--- @param category string Optional category for filtering logs
function Shared.DebugLog(message, category)
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
function Shared.SafeOsiCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        Ext.Utils.Print("[ERROR] Osiris call failed: " .. tostring(result))
        return false, result
    end
    return true, result
end

----------------------------------------------------------------------------------
-- Multiplayer Support Functions
----------------------------------------------------------------------------------
--- Get all player characters in the party
--- @return table Array of player character UUIDs
function Shared.GetAllPlayers()
    local players = {}
    local partyMembers = Osi.DB_PartOfTheTeam:Get(nil)
    for _, member in pairs(partyMembers) do
        local character = member[1]
        if Osi.IsPlayer(character) == 1 then
            table.insert(players, character)
        end
    end
    return players
end

--- Get the player character who owns/summoned an entity
--- Falls back to host character if owner cannot be determined
--- @param entity string The entity UUID to find the owner for
--- @return string|nil The owning player UUID or nil
function Shared.GetPlayerForEntity(entity)
    if not entity then
        return Osi.GetHostCharacter()
    end
    
    -- If the entity itself is a player, return it
    if Osi.IsPlayer(entity) == 1 then
        return entity
    end
    
    -- Check if entity is a party follower (summoned/controlled by a player)
    local players = Shared.GetAllPlayers()
    for _, player in ipairs(players) do
        -- Check if this player is the summoner
        local summoner = Osi.GetSummoner(entity)
        if summoner == player then
            return player
        end
        
        -- Check if entity is following this player
        if Osi.IsPartyFollower(entity, player) == 1 then
            return player
        end
    end
    
    -- Fallback: return host character
    return Osi.GetHostCharacter()
end

--- Execute a function for each player in the party
--- @param callback function Function to call with each player UUID
function Shared.ForEachPlayer(callback)
    local players = Shared.GetAllPlayers()
    for _, player in ipairs(players) do
        callback(player)
    end
end

--- Get the closest player to an entity
--- @param entity string The entity UUID
--- @return string|nil The closest player UUID or nil
function Shared.GetClosestPlayer(entity)
    if not entity or Shared.CachedExists(entity) ~= 1 then
        return Osi.GetHostCharacter()
    end
    
    local players = Shared.GetAllPlayers()
    if #players == 0 then
        return Osi.GetHostCharacter()
    end
    
    if #players == 1 then
        return players[1]
    end
    
    -- Find closest player by distance
    local closestPlayer = players[1]
    local closestDistance = Osi.GetDistanceTo(entity, closestPlayer)
    
    for i = 2, #players do
        local distance = Osi.GetDistanceTo(entity, players[i])
        if distance < closestDistance then
            closestDistance = distance
            closestPlayer = players[i]
        end
    end
    
    return closestPlayer
end

----------------------------------------------------------------------------------
-- String Constants
----------------------------------------------------------------------------------
Shared.STATUS = {
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
    -- New archetype controllers
    SUPPORT_CONTROLLER = "AI_ALLIES_SUPPORT_Controller",
    SCOUT_CONTROLLER = "AI_ALLIES_SCOUT_Controller",
    TANK_CONTROLLER = "AI_ALLIES_TANK_Controller",
    CONTROLLER_CONTROLLER = "AI_ALLIES_CONTROLLER_Controller",
    
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
    -- New archetype combat statuses
    SUPPORT = "AI_ALLIES_SUPPORT",
    SCOUT = "AI_ALLIES_SCOUT",
    TANK = "AI_ALLIES_TANK",
    CONTROLLER = "AI_ALLIES_CONTROLLER",
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
    -- New archetype NPC combat statuses
    SUPPORT_NPC = "AI_ALLIES_SUPPORT_NPC",
    SCOUT_NPC = "AI_ALLIES_SCOUT_NPC",
    TANK_NPC = "AI_ALLIES_TANK_NPC",
    CONTROLLER_NPC = "AI_ALLIES_CONTROLLER_NPC",
    
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
    FORCE_USE_MOST = "FORCE_USE_MOST",
    
    -- Formation statuses
    FORMATION_FRONTLINE = "ALLIES_FORMATION_FRONTLINE",
    FORMATION_MIDLINE = "ALLIES_FORMATION_MIDLINE",
    FORMATION_BACKLINE = "ALLIES_FORMATION_BACKLINE",
    FORMATION_SCATTERED = "ALLIES_FORMATION_SCATTERED",
    
    -- Advanced feature statuses
    AUTO_HEAL_ENABLED = "ALLIES_AUTO_HEAL",
    AGGRESSIVE_MODE = "ALLIES_AGGRESSIVE",
    DEFENSIVE_MODE = "ALLIES_DEFENSIVE",
    SUPPORT_MODE = "ALLIES_SUPPORT"
}

Shared.SPELL = {
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
    CHECK_ARCHETYPE = "I_Target_Allies_Check_Archetype",
    
    -- Formation spells
    SET_FORMATION_FRONTLINE = "Target_Allies_Formation_Frontline",
    SET_FORMATION_MIDLINE = "Target_Allies_Formation_Midline",
    SET_FORMATION_BACKLINE = "Target_Allies_Formation_Backline",
    SET_FORMATION_SCATTERED = "Target_Allies_Formation_Scattered",
    
    -- Advanced feature spells
    TOGGLE_AUTO_HEAL = "Target_Allies_Toggle_AutoHeal",
    SET_AGGRESSIVE = "Target_Allies_Mode_Aggressive",
    SET_DEFENSIVE = "Target_Allies_Mode_Defensive",
    SET_SUPPORT = "Target_Allies_Mode_Support"
}

Shared.PASSIVE = {
    UNLOCK_CUSTOM_ARCHETYPES = "UnlockCustomArchetypes",
    ALLIES_MIND = "AlliesMind",
    ALLIES_DASHING = "AlliesDashing",
    ALLIES_THROWING = "AlliesThrowing",
    DYNAMIC_SPELLBLOCK = "DynamicSpellblock",
    ALLIES_SWARM = "AlliesSwarm",
    UNLOCK_ALLIES_ORDERS = "UnlockAlliesOrders",
    UNLOCK_ALLIES_ORDERS_BONUS = "UnlockAlliesOrdersBonusAction",
    UNLOCK_ALLIES_EXTRA_SPELLS = "UnlockAlliesExtraSpells",
    UNLOCK_ALLIES_EXTRA_SPELLS_ALT = "UnlockAlliesExtraSpellsAlt",
    GIVE_ALLIES_SPELL = "GiveAlliesSpell",
    ALLIES_TOGGLE_NPC = "AlliesToggleNPC",
    
    -- Formation passives
    UNLOCK_FORMATIONS = "UnlockAlliesFormations",
    
    -- Advanced feature passives
    UNLOCK_ADVANCED_AI = "UnlockAdvancedAI",
    UNLOCK_AUTO_HEAL = "UnlockAutoHeal",
    UNLOCK_AGGRESSION_MODES = "UnlockAggressionModes"
}

return Shared
