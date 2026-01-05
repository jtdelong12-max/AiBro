----------------------------------------------------------------------------------
-- MCM Module: Mod Configuration Menu Integration
-- Handles BG3MCM integration and passive management for settings
----------------------------------------------------------------------------------

local Shared = Ext.Require("Shared.lua")
local MCM = {}

-- Export shared references
local PASSIVE = Shared.PASSIVE
local DebugLog = Shared.DebugLog

----------------------------------------------------------------------------------
-- Performance Optimization: Cached Player List
-- Avoids repeated DB_PartOfTheTeam queries when processing multiple settings
----------------------------------------------------------------------------------
local cachedPlayers = nil
local cacheTimestamp = 0
local CACHE_DURATION = 100  -- Cache players for 100ms (covers batch operations)

--- Get cached player list to avoid repeated database queries
--- @return table Array of player entries from DB_PartOfTheTeam
local function GetCachedPlayers()
    local currentTime = Ext.Utils.MonotonicTime()
    
    -- Refresh cache if expired
    if currentTime - cacheTimestamp > CACHE_DURATION or cachedPlayers == nil then
        cachedPlayers = Osi.DB_PartOfTheTeam:Get(nil)
        cacheTimestamp = currentTime
    end
    
    return cachedPlayers
end

--- Clear the player cache (call after batch operations complete)
local function ClearPlayerCache()
    cachedPlayers = nil
    cacheTimestamp = 0
end

----------------------------------------------------------------------------------
-- MCM Management Functions
----------------------------------------------------------------------------------
--- Generic function to manage MCM-controlled passives
--- Uses cached player list to avoid repeated database queries
--- @param settingKey string The MCM setting key to check
--- @param passiveName string The passive ability name to add/remove
--- @param inverted boolean If true, passive is removed when setting is enabled
local function ManageMCMPassive(settingKey, passiveName, inverted)
    inverted = inverted or false
    
    -- Use cached player list for performance
    local players = GetCachedPlayers()
    
    if Mods.BG3MCM then
        local setting = Mods.BG3MCM.MCMAPI:GetSettingValue(settingKey, MCM.ModuleUUID)
        local shouldHavePassive = inverted and not setting or not inverted and setting
        
        for _, player in pairs(players) do
            local character = player[1]
            local hasPassive = Osi.HasPassive(character, passiveName) == 1
            
            if shouldHavePassive and not hasPassive then
                Osi.AddPassive(character, passiveName)
            elseif not shouldHavePassive and hasPassive then
                Osi.RemovePassive(character, passiveName)
            end
        end
    else
        -- If MCM is not available, ensure players have default passives
        for _, player in pairs(players) do
            local character = player[1]
            if Osi.HasPassive(character, passiveName) == 0 and not inverted then
                Osi.AddPassive(character, passiveName)
            end
        end
    end
end

--- Wrapper functions for specific MCM settings
function MCM.ManageCustomArchetypes()
    ManageMCMPassive("enableCustomArchetypes", PASSIVE.UNLOCK_CUSTOM_ARCHETYPES)
end

function MCM.ManageAlliesMind()
    ManageMCMPassive("enableAlliesMind", PASSIVE.ALLIES_MIND)
end

function MCM.ManageAlliesDashing()
    ManageMCMPassive("disableAlliesDashing", PASSIVE.ALLIES_DASHING, true)
end

function MCM.ManageAlliesThrowing()
    ManageMCMPassive("disableAlliesThrowing", PASSIVE.ALLIES_THROWING, true)
end

function MCM.ManageDynamicSpellblock()
    ManageMCMPassive("enableDynamicSpellblock", PASSIVE.DYNAMIC_SPELLBLOCK)
end

function MCM.ManageAlliesSwarm()
    ManageMCMPassive("enableAlliesSwarm", PASSIVE.ALLIES_SWARM)
end

function MCM.ManageOrderSpellsPassive()
    -- Use cached player list for performance
    local players = GetCachedPlayers()
    
    if Mods.BG3MCM then
        local enableBonus = Mods.BG3MCM.MCMAPI:GetSettingValue("enableOrdersBonusAction", MCM.ModuleUUID)
        
        for _, player in pairs(players) do
            local character = player[1]
            if enableBonus then
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

function MCM.ManageDebugSpells()
    -- Use cached player list for performance
    local players = GetCachedPlayers()
    
    if Mods.BG3MCM then
        local enableDebug = Mods.BG3MCM.MCMAPI:GetSettingValue("enableDebugSpells", MCM.ModuleUUID)
        
        for _, player in pairs(players) do
            local character = player[1]
            if enableDebug then
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

--- Initialize all MCM settings
--- Uses cached player list to minimize database queries
function MCM.InitializeAll()
    -- Use cached player list for all operations
    local players = GetCachedPlayers()
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
    
    -- All these functions will use the cached player list
    MCM.ManageCustomArchetypes()
    MCM.ManageAlliesMind()
    MCM.ManageAlliesDashing()
    MCM.ManageAlliesThrowing()
    MCM.ManageDynamicSpellblock()
    MCM.ManageAlliesSwarm()
    MCM.ManageOrderSpellsPassive()
    MCM.ManageDebugSpells()
    
    -- Clear cache after batch operations complete
    ClearPlayerCache()
end

--- Register MCM event listeners
function MCM.RegisterListeners(moduleUUID)
    MCM.ModuleUUID = moduleUUID
    
    if Ext.ModEvents.BG3MCM and Ext.ModEvents.BG3MCM["MCM_Setting_Saved"] then
        Ext.ModEvents.BG3MCM["MCM_Setting_Saved"]:Subscribe(function(payload)
            if not payload or payload.modUUID ~= moduleUUID or not payload.settingId then
                return
            end
            
            if payload.settingId == "enableCustomArchetypes" then
                MCM.ManageCustomArchetypes()
            elseif payload.settingId == "enableAlliesMind" then
                MCM.ManageAlliesMind()
            elseif payload.settingId == "disableAlliesDashing" then
                MCM.ManageAlliesDashing()
            elseif payload.settingId == "disableAlliesThrowing" then
                MCM.ManageAlliesThrowing()
            elseif payload.settingId == "enableDynamicSpellblock" then
                MCM.ManageDynamicSpellblock()
            elseif payload.settingId == "enableAlliesSwarm" then
                MCM.ManageAlliesSwarm()
            elseif payload.settingId == "enableOrdersBonusAction" then
                MCM.ManageOrderSpellsPassive()
            elseif payload.settingId == "enableDebugSpells" then
                MCM.ManageDebugSpells()
            end
        end)
    end
end

return MCM
