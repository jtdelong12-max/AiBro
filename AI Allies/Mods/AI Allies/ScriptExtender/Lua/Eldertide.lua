----------------------------------------------------------------------------------
-- Eldertide Module: Eldertide Armaments Mod Integration
-- Detects equipped Eldertide items and force-adds spells to AI characters
----------------------------------------------------------------------------------

local Eldertide = {}
local Shared = Ext.Require("Shared.lua")

-- MAPPING: Template UUID -> List of Spells/Interrupts to Add
Eldertide.GearMap = {
    -- === RINGS ===
    ["761aa984-3a34-4b21-a1ce-3adf917796ac"] = {"ELDER_Zone_DragonkinHeritage_Container", "ELDER_Projectile_SkywardSoar"}, -- Dragonkin
    ["7b4b5661-f80c-443b-a681-ccbebd987a97"] = {"ELDER_Target_LogariusFinalEmbrace", "ELDER_Target_Lifesteal", "ELDER_Shout_Bloodborne", "ELDER_Target_CursedAwakening"}, -- Blood Oath
    ["faf5642a-28c2-466d-ac75-d94abeae6b76"] = {"ELDER_Projectile_CataclysmBlast", "ELDER_Target_Riftbreaker"}, -- Ethereal Phantoms
    ["5d93b3ea-dd1c-4dfb-a70f-122dc472f8bf"] = {"ELDER_Projectile_JudgmentBolt", "ELDER_Projectile_ShadowsRetribution"}, -- Dusk and Dawn
    ["61c2ab30-46c9-44a1-849b-7df18ccd49ef"] = {"ELDER_Target_TrickstersSanctuary", "ELDER_Target_MidasTouch"}, -- Sly Joker
    ["25fe39cb-5e29-46f7-a949-c91447033aaf"] = {"ELDER_Zone_MindBlast", "ELDER_Target_BlackHole", "ELDER_Target_MindSanctuary"}, -- Mind Ring
    ["5719879b-e593-4c55-ba30-0a616ccce9da"] = {"ELDER_Target_MindflayersBane", "ELDER_Shout_AstralArena", "ELDER_Target_EtherealAlliance"}, -- Astral Legacy
    ["fe43ae60-20b7-4aeb-9a34-f8fcb54e467d"] = {"ELDER_Projectile_Annihilation", "ELDER_Target_SoulDrain", "ELDER_Shout_RevenantFury"}, -- Veilwalker
    ["f1f64253-0409-4417-ad97-f91cd6a5928d"] = { -- Thunder God (Expanded)
        "ELDER_Shout_Thor_Fury",
        "ELDER_Shout_EirsBlessing",
        "ELDER_Projectile_MightyDive",
        "ELDER_Rush_AsgardianCharge",
        "ELDER_Target_Lightning_Punch",
        "ELDER_Target_MightOfTheSkies"
    },
    ["25327e35-d6ec-4cdd-8739-548a704ffd38"] = {"ELDER_Target_FrostTempest", "ELDER_Target_CryomancerMark"}, -- Cryomancer
    ["2f431e1c-ebd9-4e34-a6d6-74e62cbb79e7"] = {"ELDER_Projectile_FingerOfDeath", "ELDER_Shout_Ketheric_HowlOfTheDead", "ELDER_Target_DeathStep"}, -- Darkmaster
    ["18db8bf4-5184-4c38-a4a8-9591ac2bf66b"] = {"ELDER_Shout_Wish_Container", "ELDER_Target_MentalMaelstrom"}, -- Mental Acuity
    ["308e7426-0401-4fe1-a6fa-15b9cc4f4246"] = {"ELDER_Shout_WrathOfAvernus", "ELDER_Target_HellishPact", "ELDER_Target_InfernalBlink"}, -- Blazing Hellfire
    
    -- === AMULETS ===
    ["82d3cecf-9a9f-456b-99c6-f8d76a5a970c"] = {"ELDER_Shout_HillGiantForm"}, -- Hill Giant
    ["bfb66459-0887-412c-a470-61f12a1264d6"] = {"ELDER_Projectile_DivineBeamOfRecovery", "ELDER_Teleportation_EtherealResurgence", "ELDER_Shout_DivineRestoration"}, -- Lifebringer
    ["5084b08f-b076-4c95-806b-0c33d3b92de9"] = {"ELDER_Target_ReckoningOfTheDualFlame", "ELDER_Projectile_RayOfTheInfernalPhoenix", "ELDER_Projectile_ScorchingTalonsOfTheFirehawk"}, -- Firewalker
    ["d2a937c0-4499-4d2b-932f-29a66f203aea"] = {"ELDER_Shout_Shapeshifter", "ELDER_Shout_FeralSwiftness"}, -- Shapeshifter
    ["caffb007-7cf9-4d84-9976-4abcf2732e1e"] = {"ELDER_Target_AbsoluteReinforcement", "ELDER_Target_MaledictionOfRuin"}, -- Zealot
    ["53f192c8-c69c-46a7-b2fa-917492757c34"] = { -- Witcher Medallion (Expanded)
        "ELDER_Shout_HuntersSense", "ELDER_Shout_WitcherWeapon",
        "ELDER_Zone_Igni", "ELDER_Zone_Aard", "ELDER_Shout_Quen", "ELDER_Target_Yrden_Trap", "ELDER_Target_Axii"
    },
    ["d6292882-5093-4fae-97ef-d4e18bf81b2e"] = {"ELDER_Projectile_BewitchingBolt", "ELDER_Target_WitchQueenCauldron"}, -- Witch Queen
    
    -- === WEAPONS & SPECIAL ===
    -- If you know the UUID for the item granting 'Dreadful Backlash', add it here.
    -- Otherwise, the script below now includes a passive check.
}

-- Spell List triggered by Passives (Backup for when UUIDs change or are unknown)
Eldertide.PassiveMap = {
    ["Passive_ELDER_DreadfulBacklash_Unlock"] = {"ELDER_Interrupt_DreadfulBacklash"},
    ["Passive_ELDER_Witcher_Signs"] = {"ELDER_Zone_Igni", "ELDER_Zone_Aard", "ELDER_Shout_Quen", "ELDER_Target_Yrden_Trap", "ELDER_Target_Axii"},
    ["ActionsThorFury"] = {"ELDER_Shout_EirsBlessing", "ELDER_Projectile_MightyDive", "ELDER_Rush_AsgardianCharge", "ELDER_Target_Lightning_Punch", "ELDER_Target_MightOfTheSkies"}
}

function Eldertide.CheckGear(character)
    if not character or Shared.CachedExists(character) ~= 1 then
        return
    end
    
    -- 1. Check Equipped Item UUIDs
    local slots = {"Amulet", "Ring", "Ring2", "MainHand", "OffHand"}
    for _, slot in ipairs(slots) do
        local item = Osi.GetEquippedItem(character, slot)
        if item then
            local template = Osi.GetTemplate(item)
            if template and Eldertide.GearMap[template] then
                for _, spell in ipairs(Eldertide.GearMap[template]) do
                    if Osi.HasSpell(character, spell) == 0 then
                        Osi.AddSpell(character, spell)
                    end
                end
            end
        end
    end
    
    -- 2. Check for Specific Passives (More robust)
    for passive, spells in pairs(Eldertide.PassiveMap) do
        if Osi.HasPassive(character, passive) == 1 then
            for _, spell in ipairs(spells) do
                if Osi.HasSpell(character, spell) == 0 then
                    Osi.AddSpell(character, spell)
                    Shared.DebugLog("Eldertide: Added " .. spell .. " via Passive " .. passive)
                end
            end
        end
    end
end

function Eldertide.RegisterListeners()
    Ext.Osiris.RegisterListener("EnteredCombat", 2, "after", function(object, combatGuid)
        if Osi.IsPartyFollower(object) == 1 then
            Eldertide.CheckGear(object)
        end
    end)
    
    Ext.Osiris.RegisterListener("Equipped", 2, "after", function(item, character)
        if Osi.IsPartyFollower(character) == 1 then
            Eldertide.CheckGear(character)
        end
    end)
end

return Eldertide

