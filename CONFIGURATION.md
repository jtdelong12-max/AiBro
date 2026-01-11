# AI Allies - Configuration Guide

This document provides detailed explanations of all MCM (Mod Configuration Menu) settings available for AI Allies.

## Table of Contents

- [General Settings](#general-settings)
- [AI Behavior Settings](#ai-behavior-settings)
- [Advanced Features](#advanced-features)
- [Formation System](#formation-system)
- [Aggression Modes](#aggression-modes)
- [Auto-Heal Configuration](#auto-heal-configuration)
- [Without MCM](#without-mcm)

---

## General Settings

### Enable Debug Spells
**Setting ID:** `enableDebugSpells`  
**Type:** Checkbox  
**Default:** Disabled

**Description:**  
Adds diagnostic and testing spells to the "AI Allies: Extra Spells" category for debugging and advanced customization.

**Debug Spells Include:**
- **Check Archetype** - Displays active and base archetype of a target
- **Mark as NPC** - Manually converts a character to NPC control
- **Mark as Player** - Manually converts a character to player control
- **Faction Join** - Makes caster join target's faction (for testing)
- **Faction Leave** - Returns caster to original faction

**When to Enable:**
- Troubleshooting AI behavior issues
- Testing custom archetype configurations
- Verifying faction relationships
- Advanced mod development

**Warning:** Debug spells can break quests or cause unexpected behavior. Use with caution and keep multiple saves.

---

### Enable Custom Archetypes
**Setting ID:** `enableCustomArchetypes`  
**Type:** Checkbox  
**Default:** Disabled

**Description:**  
Unlocks 4 additional custom archetype slots (Custom 1, Custom 2, Custom 3, Custom 4) that can be manually configured.

**What It Unlocks:**
- Custom Archetype 1 - Empty archetype template
- Custom Archetype 2 - Empty archetype template
- Custom Archetype 3 - Empty archetype template
- Custom Archetype 4 - Empty archetype template

**Use Cases:**
1. **Specialized Builds** - Create archetypes for specific multiclass combinations
2. **Quest-Specific Tactics** - Configure behaviors for particular encounters
3. **Roleplay Scenarios** - Design archetypes matching character backstories
4. **Experimental Tactics** - Test new AI behavior patterns

**How to Configure:**
Custom archetypes require manual configuration by editing archetype files in the mod's `Archetypes` folder. Advanced users can:
1. Copy an existing archetype file as a template
2. Modify AI behaviors, spell priorities, and tactics
3. Apply the custom archetype in-game
4. Test and iterate on the behavior

**Warning:** Requires knowledge of BG3 AI scripting. Misconfigured archetypes may cause AI to act unpredictably.

---

### Enable Mindcontrol Art
**Setting ID:** `enableAlliesMind`  
**Type:** Checkbox  
**Default:** Disabled

**Description:**  
Grants spells for mind control, possession, and advanced command over AI allies.

**Unlocked Abilities:**

**Mind Control Spells:**
- **Mind Control: Teleport** - Teleports all mind-controlled allies to you
- **Possession** - Take direct control of an ally temporarily
- **Follow Order** - Commands allies to follow you closely
- **Release Control** - Removes mind control from an ally

**How It Works:**
1. Apply the "Mind Control" status to an ally
2. The ally maintains AI control but responds to your commands
3. Use teleport or follow orders to direct their movement
4. Use possession to take direct control when precision is needed

**Use Cases:**
- **Repositioning in Combat** - Quickly teleport scattered allies
- **Exploration** - Keep party together during non-combat movement
- **Puzzle Solving** - Position allies precisely for environmental interactions
- **Emergency Extraction** - Pull allies out of danger zones

**Limitations:**
- Cannot mind control hostile NPCs (only companions)
- Possession ends if the ally enters dialog
- Some quest-critical moments disable mind control

**Roleplay Considerations:**
This feature represents psychic control abilities. Consider whether it fits your character's moral alignment and capabilities.

---

### Give Swarm Spells
**Setting ID:** `enableAlliesSwarm`  
**Type:** Checkbox  
**Default:** Disabled

**Description:**  
Enables swarm group mechanics where allies can be assigned to coordinated units that act with synchronized initiative.

**Swarm Groups:**
- **Swarm Group: Alpha** - First coordinated unit
- **Swarm Group: Bravo** - Second coordinated unit
- **Swarm Group: Charlie** - Third coordinated unit
- **Swarm Group: Delta** - Fourth coordinated unit
- **Clear Swarm Group** - Removes ally from swarm

**How Swarm Works:**
1. Assign allies to the same swarm group
2. In combat, all members act on initiative 6
3. Coordinated attacks overwhelm single targets
4. Ideal for focusing down priority enemies

**Tactical Applications:**
- **Alpha Strike Teams** - Group high-damage dealers for burst damage
- **Defensive Walls** - Coordinate tanks to block chokepoints
- **Healer Chains** - Synchronize healers for mass healing turns
- **Crowd Control Combos** - Stack debuffs from multiple controllers

**Limitations:**
- **WARNING: Swarm AI is VERY limited**
- BG3's native swarm AI is designed for animal groups (spiders, imps)
- Humanoid swarms may not utilize full tactical abilities
- Positioning can be unpredictable
- Only use if you understand the limitations

**Best Practices:**
- Test in low-stakes encounters first
- Use with simple archetypes (Melee, Ranged)
- Avoid with spell-heavy archetypes (Mage, Controller)
- Keep swarm groups to 2-3 allies maximum

---

### Enable Orders Bonus Action Cost
**Setting ID:** `enableOrdersBonusAction`  
**Type:** Checkbox  
**Default:** Disabled

**Description:**  
Changes the action cost of Focus/Ignore command spells from full actions to bonus actions, with slight mechanical adjustments.

**Affected Spells:**
- **Focus Target** - Command allies to prioritize a specific enemy
- **Ignore Target** - Tell allies to avoid attacking a target
- Other tactical command spells

**Mechanical Changes:**

**Standard Mode (Disabled - Default):**
- Commands cost a full action
- Stronger, more persistent effects
- Strategic turn investment
- Best for turn-based tactical play

**Bonus Action Mode (Enabled):**
- Commands cost only a bonus action
- Slightly reduced duration or potency
- More fluid battlefield command
- Better for action-heavy characters

**When to Enable:**

**Enable If:**
- You're playing a caster who uses bonus actions less
- You want more responsive battlefield control
- Your character concept includes commander/leader abilities
- You prefer faster-paced combat management

**Keep Disabled If:**
- You're playing a class with bonus action competition (Rogue, Monk, dual-wielder)
- You prefer deliberate, strategic command investment
- You want stronger, longer-lasting command effects
- Your playstyle doesn't require frequent command changes

**Class Synergies:**
- **Great for:** Wizards, Sorcerers, Warlocks, Fighters (non-dual-wield)
- **Conflicts with:** Rogues (Cunning Action), Monks (Flurry), dual-wielders, Barbarians (Rage)

---

## AI Behavior Settings

### Disable Allies Dashing
**Setting ID:** `disableAlliesDashing`  
**Type:** Checkbox  
**Default:** Disabled (Dashing enabled)

**Description:**  
When enabled, prevents AI allies from using Dash or Cunning Action Dash abilities.

**Why Disable Dashing?**

**Movement Conservation:**
- Allies won't waste turns repositioning
- More turns spent attacking or using abilities
- Better for high-mobility parties

**Bonus Action Preservation:**
- Rogues save Cunning Action for Hide/Disengage
- Monks preserve Ki for other abilities
- More consistent ability usage

**Tactical Positioning:**
- Allies stay in assigned formations
- Reduces overextension into danger
- Maintains party cohesion

**Resource Management:**
- Some archetypes use Dash spells that cost spell slots
- Prevents unnecessary spell slot consumption
- Better spell resource allocation

**When to Enable:**

**Enable If:**
- Allies frequently waste turns dashing
- You want tighter formation control
- Your party is mobile enough naturally
- Allies overextend and get isolated

**Keep Disabled If:**
- You have immobile allies (heavy armor, low speed)
- Positioning is critical in your strategy
- You need allies to reposition quickly
- You're fighting mobile or flying enemies

---

### Disable Allies Throwing
**Setting ID:** `disableAlliesThrowing`  
**Type:** Checkbox  
**Default:** Disabled (Throwing enabled)

**Description:**  
When enabled, prevents AI allies from throwing weapons, items, or consumables.

**Why Disable Throwing?**

**Consumable Conservation:**
- Prevents AI from wasting valuable potions
- Preserves alchemical bombs for player use
- Saves throwing weapons for manual targeting

**Weapon Management:**
- Allies won't throw equipped weapons and be disarmed
- Maintains consistent damage output
- No turns wasted retrieving thrown weapons

**Gold Preservation:**
- Expensive consumables stay in inventory
- No accidental waste of rare items
- Better inventory management

**Tactical Control:**
- Player decides when to use special items
- Prevents premature reveal of special tactics
- More predictable ally behavior

**When to Enable:**

**Enable If:**
- You have valuable consumables you want to preserve
- Allies waste grenades on low-value targets
- You want manual control over item usage
- Allies throw important weapons

**Keep Disabled If:**
- You're using the Thrower archetype
- You want allies to use tactical consumables
- You have abundant throwable items
- You're using a throwing weapon build

---

### Enable Dynamic Spellblock
**Setting ID:** `enableDynamicSpellblock`  
**Type:** Checkbox  
**Default:** Disabled

**Description:**  
Advanced system that dynamically filters which spells AI allies can use based on combat context, spell efficiency, and tactical situation.

**How It Works:**

The system analyzes:
1. **Current Combat State** - Number of enemies, ally positions, threat level
2. **Spell Efficiency** - Damage per spell slot, area coverage, save DC
3. **Tactical Context** - Target priority, friendly fire risk, resource availability
4. **Archetype Role** - Ensures spells match assigned archetype behavior

**Benefits:**

**Smarter Spell Usage:**
- AI avoids casting weak spells when strong ones are available
- Better spell slot conservation
- More effective spell targeting

**Reduced Friendly Fire:**
- AoE spells blocked when allies are in range
- Safer use of area effects
- Less reload-heavy gameplay

**Context-Aware Casting:**
- Opening moves differ from cleanup phases
- Emergency healing prioritized when needed
- Buffs applied before debuffs

**Resource Optimization:**
- High-level slots reserved for crisis moments
- Cantrips preferred for low-threat targets
- Concentration spells used strategically

**When to Enable:**

**Enable If:**
- Allies waste powerful spells on weak enemies
- You experience frequent friendly fire incidents
- AI spell selection seems random or inefficient
- You want more "intelligent" spellcasting behavior

**Keep Disabled If:**
- You prefer simpler, more predictable AI
- You manually control all spellcasters
- You want maximum spell variety in combat
- Performance is a concern (slight overhead)

**Performance Note:** Dynamic spellblock adds minor computational overhead. On lower-end systems, this may cause brief hitching when evaluating spell options.

---

## Advanced Features

### Enable Formations
**Setting ID:** `enableFormations`  
**Type:** Checkbox  
**Default:** Varies by installation

**Description:**  
Unlocks the tactical formation system, allowing you to assign allies to positional roles (Frontline, Midline, Backline, Scattered).

**Formation Types:**

**Frontline Formation:**
- Allies position 0-3m ahead of leader
- Ideal for: Tanks, Melee fighters
- Spacing: Close (2-3m between allies)
- Purpose: Engage enemies first, absorb attacks

**Midline Formation:**
- Allies position 2-5m behind frontline
- Ideal for: Versatile fighters, off-tanks, melee supports
- Spacing: Medium (3-4m between allies)
- Purpose: Support frontline, respond to threats

**Backline Formation:**
- Allies position 5-8m behind frontline
- Ideal for: Ranged attackers, mages, healers
- Spacing: Wide (4-5m between allies)
- Purpose: Ranged attacks, spell casting, healing

**Scattered Formation:**
- No fixed position, free movement
- Ideal for: Scouts, rogues, mobile skirmishers
- Spacing: Variable
- Purpose: Flanking, opportunistic attacks, mobility

**How to Use Formations:**

1. Enable formations in MCM
2. Cast formation spells on allies (e.g., "Set Formation: Backline")
3. The system calculates ideal positions relative to the party leader
4. Allies automatically move toward formation positions
5. Formation adjusts dynamically as the leader moves

**Formation Refresh:** Positions update every 2 seconds to maintain formation cohesion.

**Tactical Applications:**

**Standard Tank-DPS-Healer Setup:**
- Tank: Frontline
- Melee DPS: Frontline or Midline
- Ranged DPS: Backline
- Healer: Backline

**All-Melee Party:**
- Tanks: Frontline
- Damage Dealers: Scattered (for flanking)

**All-Ranged Party:**
- All allies: Backline or Scattered
- Maintain distance from enemies

**When to Enable:**

**Enable If:**
- You want structured, predictable positioning
- You're using traditional RPG party composition
- You need to protect vulnerable allies
- You want better tactical control

**Keep Disabled If:**
- You prefer dynamic, fluid combat movement
- Your party composition doesn't fit standard formations
- You're using swarm mechanics (conflicts with formations)
- You want allies to position opportunistically

---

### Enable Auto Heal
**Setting ID:** `enableAutoHeal`  
**Type:** Checkbox  
**Default:** Varies by installation

**Description:**  
Activates the automatic healing system where allies with healing capabilities automatically assist injured party members.

**How Auto-Heal Works:**

**HP Threshold:** 50% (configurable in Shared.lua → AUTO_HEAL_THRESHOLD)

**Heal Priority System:**
1. **Downed/Dying Allies** - Highest priority
   - HELP action if within 3m
   - Healing Word if within 18m
2. **Critical HP (< 25%)** - Very high priority
3. **Below Threshold (< 50%)** - Standard priority
4. **Topped Off (> 75%)** - No healing needed

**Who Can Auto-Heal?**
- Healer archetype (Melee or Ranged)
- Support archetype
- Any ally with "Auto-Heal Enabled" status
- Characters with healing spells and the feature toggled on

**Healing Logic:**

**In Combat:**
- Healers scan party at start of their turn
- Prioritize downed allies first
- Use most efficient healing spell for situation
- Balance between healing and offensive actions

**Out of Combat:**
- Auto-heal disabled (use resting mechanics)
- Prevents unnecessary spell slot consumption
- Players manage long-term healing resources

**Spell Selection:**
- **Emergency (Downed):** HELP (melee), Healing Word (ranged)
- **Critical HP:** Cure Wounds, Mass Healing Word
- **Standard:** Healing Word, Healing Spirit
- **Efficient:** Lowest spell slot that brings above threshold

**When to Enable:**

**Enable If:**
- You frequently have allies at low HP
- You're playing on harder difficulties
- You want hands-off healing management
- Your party includes dedicated healers

**Keep Disabled If:**
- You prefer manual healing control
- You're conserving spell slots
- Your party has high HP/AC and rarely needs healing
- You're using short rest mechanics extensively

**Customization:**

To adjust auto-heal threshold, edit the `CONSTANTS` table in `Shared.lua`:
```lua
Shared.CONSTANTS = {
    -- ... other constants ...
    
    -- Advanced features
    AUTO_HEAL_THRESHOLD = 0.5,     -- Health percentage to trigger auto-heal (50%)
    
    -- ... other constants ...
}
```

Change to:
- `0.3` for 30% (more conservative, saves resources)
- `0.7` for 70% (more aggressive, keeps party healthy)

---

### Enable Aggression Modes
**Setting ID:** `enableAggressionModes`  
**Type:** Checkbox  
**Default:** Varies by installation

**Description:**  
Unlocks three distinct aggression modes that modify how aggressively AI allies engage in combat.

**Aggression Modes:**

### Aggressive Mode
**Multiplier:** 1.5x  
**Behavior:**
- Prioritizes damage dealing over defense
- Uses offensive abilities more frequently
- Engages enemies proactively
- Minimal defensive positioning
- Consumes resources (spell slots, abilities) faster

**Best For:**
- High-damage builds (Berserkers, Paladins)
- Short, decisive encounters
- When you want to end fights quickly
- Overwhelming weaker enemies

**Risks:**
- Allies may take more damage
- Higher resource consumption
- Can overextend into danger

---

### Defensive Mode
**Multiplier:** 0.5x  
**Behavior:**
- Prioritizes survival and damage mitigation
- Conservative ability usage
- Maintains safe positioning
- Uses defensive abilities frequently
- Conserves resources

**Best For:**
- Survival-focused encounters
- When resources are limited
- Protecting vulnerable allies
- Fighting stronger enemies
- Learning new encounters

**Drawbacks:**
- Slower combat resolution
- Less aggressive target elimination
- May allow enemies to regroup

---

### Support Mode
**Multiplier:** 0.75x  
**Behavior:**
- Balanced between offense and support
- Frequent buff/debuff application
- Assists allies with tactical abilities
- Moderate resource usage
- Flexible response to threats

**Best For:**
- Balanced party compositions
- Long adventuring days
- Encounters requiring tactical flexibility
- Support-focused archetypes (Bard, Support Cleric)

**Benefits:**
- Versatile combat approach
- Good resource efficiency
- Adapts to changing situations

---

**How to Assign Modes:**

1. Enable aggression modes in MCM
2. Cast mode spells on allies:
   - "Set Mode: Aggressive"
   - "Set Mode: Defensive"
   - "Set Mode: Support"
3. Mode persists until changed or removed

**Mode + Archetype Synergies:**

| Archetype | Best Mode | Reason |
|-----------|-----------|--------|
| Melee | Aggressive | Maximize damage in close range |
| Ranged | Defensive/Support | Maintain distance, stay safe |
| Healer | Support | Balance healing and combat |
| Mage | Support | Efficient spell usage |
| Tank | Defensive | Maximize survivability |
| Controller | Support | Tactical debuff focus |
| Trickster | Aggressive | High-risk, high-reward plays |

**When to Change Modes:**

**Switch to Aggressive When:**
- Enemies are low on HP (cleanup phase)
- You have abundance of resources
- Time is critical (encounter timer)
- Fighting weaker enemies

**Switch to Defensive When:**
- Party HP is low
- Resources are depleted
- Facing unknown threats
- Multiple allies downed

**Switch to Support When:**
- Balanced encounter
- Long adventuring day
- Need tactical flexibility
- Resource conservation important

---

## Formation System

*(See "Enable Formations" in Advanced Features above for detailed information)*

**Quick Reference:**

| Formation | Distance | Best For |
|-----------|----------|----------|
| Frontline | 0-3m ahead | Tanks, Melee DPS |
| Midline | 2-5m back | Off-tanks, Versatile fighters |
| Backline | 5-8m back | Ranged, Mages, Healers |
| Scattered | Variable | Scouts, Rogues, Skirmishers |

**Update Frequency:** Every 2 seconds (configurable in Shared.lua → FORMATION_UPDATE_INTERVAL)

---

## Aggression Modes

*(See "Enable Aggression Modes" in Advanced Features above for detailed information)*

**Quick Reference:**

| Mode | Multiplier | Resource Use | Risk Level |
|------|------------|--------------|------------|
| Aggressive | 1.5x | High | High |
| Defensive | 0.5x | Low | Low |
| Support | 0.75x | Medium | Medium |
| Default | 1.0x | Medium | Medium |

---

## Auto-Heal Configuration

*(See "Enable Auto Heal" in Advanced Features above for detailed information)*

**Quick Reference:**

**Default Threshold:** 50% HP  
**Heal Priority:**
1. Downed (HELP/Healing Word)
2. Critical < 25%
3. Below Threshold < 50%

**To Modify Threshold:**
Edit the `AUTO_HEAL_THRESHOLD` constant in `Shared.lua`:
```lua
AUTO_HEAL_THRESHOLD = 0.5,  -- Change this value (default 50%)
```

---

## Without MCM

If you're not using BG3MCM, AI Allies uses default settings:

**Default Configuration (No MCM):**
- Custom Archetypes: Disabled
- Mind Control: Disabled
- Debug Spells: Disabled (basic spells enabled)
- Swarm: Disabled
- Orders Cost: Full Action
- Dashing: Enabled
- Throwing: Enabled
- Dynamic Spellblock: Disabled
- Formations: Enabled
- Auto-Heal: Enabled
- Aggression Modes: Enabled

**Manual Configuration (Advanced):**

1. **Locate mod folder:**
   ```
   %LOCALAPPDATA%\Larian Studios\Baldur's Gate 3\Mods\AI Allies\
   ```

2. **Edit MCM_blueprint.json** to change defaults:
   ```json
   {
     "Id": "settingName",
     "Default": true,  // Change to false to disable
   }
   ```

3. **Edit Shared.lua** for technical settings:
   - `AUTO_HEAL_THRESHOLD` - Healing HP threshold
   - `FORMATION_DISTANCE` - Spacing between formation positions
   - `DEBUG_MODE` - Enable debug logging

4. **Restart game** for changes to take effect

**Warning:** Manual configuration requires understanding of JSON and Lua syntax. Errors may prevent the mod from loading.

---

## Performance Tuning

Some settings impact performance differently:

**Low Performance Impact:**
- Enable Custom Archetypes
- Enable Mind Control
- Enable Orders Bonus Action
- Disable Dashing/Throwing

**Medium Performance Impact:**
- Enable Formations (position calculations every 2s)
- Enable Auto-Heal (HP checks each turn)
- Enable Aggression Modes (behavior modification)

**Higher Performance Impact:**
- Enable Dynamic Spellblock (spell evaluation each cast)
- Enable Swarm (group coordination)
- Debug Mode (extensive logging)

**Performance Tips:**
- Disable unused features
- Reduce formation update frequency (edit Shared.lua)
- Disable debug mode in normal gameplay
- Limit swarm group sizes

---

## Troubleshooting Configuration

**Setting Not Taking Effect:**
1. Ensure MCM is installed and up to date
2. Save and reload the game after changing settings
3. Check Script Extender console for errors
4. Verify mod UUID matches in MCM_blueprint.json

**MCM Menu Not Showing:**
1. Confirm BG3MCM is installed
2. Check MCM load order (should load before AI Allies)
3. Try pressing different MCM hotkeys (F10, INS)
4. Verify MCM_blueprint.json exists in mod folder

**Unexpected Behavior After Configuration:**
1. Disable recently changed settings one by one
2. Check for conflicting mods (other AI mods)
3. Enable debug mode to see what's happening
4. Review Script Extender console for errors

**Performance Issues After Enabling Features:**
1. Disable high-impact features (Dynamic Spellblock, Swarm)
2. Reduce formation update frequency
3. Limit number of AI-controlled allies
4. Check for other performance-heavy mods

---

## Advanced Configuration

For modders and advanced users, additional configuration is possible by editing Lua files directly:

**Shared.lua - Constants:**
- Timer delays
- Status durations
- Cache refresh intervals
- Formation distances
- Auto-heal thresholds

**AI.lua - Archetypes:**
- Controller status lists
- Combat status mappings
- Archetype behavior definitions

**Combat.lua - Spell Mappings:**
- AI spell variants
- Rescue priority logic
- Swarm mechanics

**Formations.lua - Formation Types:**
- Position offsets
- Formation spacing
- Update intervals

**See technical documentation for detailed module structure.**

---

*Last Updated: Latest Version*  
*For more information, see [README.md](README.md)*