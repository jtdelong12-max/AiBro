----------------------------------------------------------------------------------
-- Eldertide Module: Eldertide Armaments Mod Integration
-- Detects equipped Eldertide items and force-adds spells to AI characters
----------------------------------------------------------------------------------

local Shared = Ext.Require("Shared.lua")
local Eldertide = {}

-- Export shared references
local DebugLog = Shared.DebugLog
local CachedExists = Shared.CachedExists

----------------------------------------------------------------------------------
-- Eldertide Armaments Gear Mapping
----------------------------------------------------------------------------------
-- Maps RootTemplate UUIDs to spell IDs that should be granted
Eldertide.GearMap = {
    -- Rings
    ["761aa984-3a34-4b21-a1ce-3adf917796ac"] = {"ELDER_Projectile_SkywardSoar"},
    ["7b4b5661-f80c-443b-a681-ccbebd987a97"] = {"ELDER_Target_LogariusFinalEmbrace", "ELDER_Target_Lifesteal"},
    ["faf5642a-28c2-466d-ac75-d94abeae6b76"] = {"ELDER_Projectile_CataclysmBlast"},
    ["5d93b3ea-dd1c-4dfb-a70f-122dc472f8bf"] = {"ELDER_Projectile_JudgmentBolt"},
    ["61c2ab30-46c9-44a1-849b-7df18ccd49ef"] = {"ELDER_Target_TrickstersSanctuary"},
    ["25fe39cb-5e29-46f7-a949-c91447033aaf"] = {"ELDER_Target_BlackHole", "ELDER_Zone_MindBlast"},
    ["5719879b-e593-4c55-ba30-0a616ccce9da"] = {"ELDER_Shout_AstralArena"},
    ["fe43ae60-20b7-4aeb-9a34-f8fcb54e467d"] = {"ELDER_Projectile_Annihilation"},
    ["f1f64253-0409-4417-ad97-f91cd6a5928d"] = {"ELDER_Shout_Thor_Fury"},
    ["25327e35-d6ec-4cdd-8739-548a704ffd38"] = {"ELDER_Target_FrostTempest"},
    ["2f431e1c-ebd9-4e34-a6d6-74e62cbb79e7"] = {"ELDER_Projectile_FingerOfDeath"},
    ["18db8bf4-5184-4c38-a4a8-9591ac2bf66b"] = {"ELDER_Target_MentalMaelstrom"},
    ["308e7426-0401-4fe1-a6fa-15b9cc4f4246"] = {"ELDER_Shout_WrathOfAvernus"},
    
    -- Amulets
    ["82d3cecf-9a9f-456b-99c6-f8d76a5a970c"] = {"ELDER_Shout_HillGiantForm"},
    ["bfb66459-0887-412c-a470-61f12a1264d6"] = {"ELDER_Projectile_DivineBeamOfRecovery"},
    ["5084b08f-b076-4c95-806b-0c33d3b92de9"] = {"ELDER_Projectile_RayOfTheInfernalPhoenix"},
    ["d2a937c0-4499-4d2b-932f-29a66f203aea"] = {"ELDER_Shout_Shapeshifter"},
    ["caffb007-7cf9-4d84-9976-4abcf2732e1e"] = {"ELDER_Target_AbsoluteReinforcement"},
    ["53f192c8-c69c-46a7-b2fa-917492757c34"] = {"ELDER_Shout_WitcherWeapon"},
    ["d6292882-5093-4fae-97ef-d4e18bf81b2e"] = {"ELDER_Projectile_BewitchingBolt"}
}

----------------------------------------------------------------------------------
-- Equipment Slot Constants
----------------------------------------------------------------------------------
local EQUIPMENT_SLOTS = {
    "Amulet",
    "Ring",
    "Ring2"
}

----------------------------------------------------------------------------------
-- Gear Detection Functions
----------------------------------------------------------------------------------
--- Check if a character has equipped Eldertide items and add associated spells
--- @param character string The character UUID to check
function Eldertide.CheckGear(character)
    if not character or CachedExists(character) ~= 1 then
        return
    end
    
    -- Only check AI-controlled characters (those with AI_ALLY status or in CurrentAllies)
    local hasAIStatus = Osi.HasStatus(character, "AI_ALLY") == 1
    local isCurrentAlly = CurrentAllies and CurrentAllies[character] ~= nil
    
    if not hasAIStatus and not isCurrentAlly then
        return
    end
    
    DebugLog("Checking Eldertide gear for character: " .. character, "ELDERTIDE")
    
    -- Iterate through equipment slots
    for _, slot in ipairs(EQUIPMENT_SLOTS) do
        local success, item = pcall(Osi.GetEquippedItem, character, slot)
        
        if success and item and item ~= "" and item ~= nil then
            -- Get the RootTemplate UUID of the equipped item
            local itemEntity = Ext.Entity.Get(item)
            
            if itemEntity and itemEntity.GameObjectVisual and itemEntity.GameObjectVisual.RootTemplateId then
                local rootTemplate = itemEntity.GameObjectVisual.RootTemplateId
                
                -- Check if this item is in our Eldertide gear map
                local spells = Eldertide.GearMap[rootTemplate]
                
                if spells then
                    DebugLog("Found Eldertide item in " .. slot .. ": " .. rootTemplate, "ELDERTIDE")
                    
                    -- Add all associated spells
                    for _, spell in ipairs(spells) do
                        if Osi.HasSpell(character, spell) == 0 then
                            Osi.AddSpell(character, spell, 0, 0)
                            DebugLog("Added Eldertide spell to character: " .. spell, "ELDERTIDE")
                        else
                            DebugLog("Character already has spell: " .. spell, "ELDERTIDE")
                        end
                    end
                end
            end
        end
    end
end

--- Check gear for all AI allies
function Eldertide.CheckAllAlliesGear()
    if not CurrentAllies then
        return
    end
    
    for characterUUID, _ in pairs(CurrentAllies) do
        if CachedExists(characterUUID) == 1 then
            Eldertide.CheckGear(characterUUID)
        end
    end
end

----------------------------------------------------------------------------------
-- Event Listeners
----------------------------------------------------------------------------------
--- Register Eldertide event listeners
function Eldertide.RegisterListeners(currentAlliesRef)
    -- Store reference to CurrentAllies
    if currentAlliesRef then
        CurrentAllies = currentAlliesRef
    end
    
    -- Check gear when character enters combat
    Ext.Osiris.RegisterListener("EnteredCombat", 2, "after", function(object, combatGuid)
        if object and CachedExists(object) == 1 then
            Eldertide.CheckGear(object)
        end
    end)
    
    -- Check gear when status is applied (when character becomes AI-controlled)
    Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(object, status, causee, storyActionID)
        if status == "AI_ALLY" and object and CachedExists(object) == 1 then
            -- Small delay to ensure equipment is properly loaded
            Ext.Timer.WaitFor(500, function()
                if CachedExists(object) == 1 then
                    Eldertide.CheckGear(object)
                end
            end)
        end
    end)
    
    -- Check gear when item is equipped
    Ext.Osiris.RegisterListener("Equipped", 2, "after", function(item, character)
        if character and CachedExists(character) == 1 then
            -- Check if this character is AI-controlled
            local hasAIStatus = Osi.HasStatus(character, "AI_ALLY") == 1
            local isCurrentAlly = CurrentAllies and CurrentAllies[character] ~= nil
            
            if hasAIStatus or isCurrentAlly then
                Eldertide.CheckGear(character)
            end
        end
    end)
    
    DebugLog("Eldertide module listeners registered", "ELDERTIDE")
end

--- Initialize Eldertide module (check all existing allies)
function Eldertide.Initialize()
    DebugLog("Initializing Eldertide module", "ELDERTIDE")
    
    -- Check gear for all current allies on load
    Ext.Timer.WaitFor(1000, function()
        Eldertide.CheckAllAlliesGear()
    end)
end

return Eldertide
