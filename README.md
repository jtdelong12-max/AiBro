# AI Allies - Intelligent Companion Control for Baldur's Gate 3

AI Allies is a comprehensive mod for Baldur's Gate 3 that transforms your companions into intelligent AI-controlled allies during combat. Choose from various combat archetypes, configure advanced tactics, and let your allies fight alongside you with strategic AI behaviors.

## Features

### AI Archetypes

Transform your companions into specialized combat roles with intelligent AI behaviors:

- **Melee** - Aggressive frontline fighter that engages enemies in close combat
- **Ranged** - Tactical ranged attacker maintaining optimal distance
- **Healer (Melee)** - Close-range support that heals allies while fighting
- **Healer (Ranged)** - Distant healer providing medical support from safety
- **Mage (Melee)** - Spellsword blending magic with melee combat
- **Mage (Ranged)** - Backline spellcaster unleashing magical attacks
- **Tank** - Defensive specialist drawing enemy attention and protecting allies
- **Support** - Buff-focused ally enhancing party effectiveness
- **Scout** - Mobile reconnaissance specialist with high mobility
- **Controller** - Crowd control expert using debuffs and status effects
- **Trickster** - Deceptive combatant using stealth and misdirection
- **Thrower** - Specialist in throwing weapons and grenades
- **General** - Versatile all-rounder adapting to any situation
- **Custom Archetypes (1-4)** - User-configurable archetypes for advanced tactics

### Advanced Features

#### Formation System
Position your allies strategically on the battlefield:
- **Frontline** - Melee fighters positioned at the front
- **Midline** - Balanced positioning for versatile fighters
- **Backline** - Protected position for ranged attackers and healers
- **Scattered** - Free movement without formation constraints

#### Aggression Modes
Control how aggressively your allies engage in combat:
- **Aggressive Mode** - Increased offensive action (1.5x aggression)
- **Defensive Mode** - Conservative, survival-focused (0.5x aggression)
- **Support Mode** - Balanced support tactics (0.75x aggression)

#### Auto-Heal System
- Automatically triggers healing when allies drop below 50% health
- Compatible with healer archetypes for enhanced medical support
- Intelligent downed ally detection and rescue
- Priority system: HELP action (3m range) → Healing Word (18m range)

#### Mind Control & Commands
- Take direct control of AI allies when needed
- Issue follow commands for party cohesion
- Teleport allies to your position
- Possession mode for temporary direct control

#### Swarm Mechanics
- Group allies into coordinated swarm units (Alpha, Bravo, Charlie, Delta)
- Synchronized initiative for tactical group actions
- Enhanced coordination for overwhelming enemies

### Mod Integration

#### Eldertide Armaments Support
Seamlessly integrates with Eldertide Armaments mod for enhanced weapon compatibility and special interactions.

## Requirements

### Essential
- **Baldur's Gate 3** - Latest version recommended
- **[BG3 Script Extender](https://github.com/Norbyte/bg3se)** - Required for mod functionality

### Optional
- **[BG3MCM (Mod Configuration Menu)](https://github.com/AtilioA/BG3-MCM)** - Highly recommended for in-game configuration
  - Without MCM, the mod uses default settings with all features enabled

### Compatibility
- Tested on BG3 v4.1+ (Patch 7)
- Compatible with most other mods
- Multiplayer supported with host-controlled configuration

## Installation

### Standard Installation

1. **Download and Install Prerequisites:**
   - Install BG3 Script Extender (follow its installation guide)
   - *(Optional but recommended)* Install BG3MCM

2. **Install AI Allies:**
   - Download the latest release from the releases page
   - Extract the `AI Allies` folder to:
     ```
     %LOCALAPPDATA%\Larian Studios\Baldur's Gate 3\Mods\
     ```
   - The final path should look like:
     ```
     %LOCALAPPDATA%\Larian Studios\Baldur's Gate 3\Mods\AI Allies\
     ```

3. **Enable the Mod:**
   - Launch BG3 Mod Manager or manually edit `modsettings.lsx`
   - Ensure the mod is enabled in your load order

4. **Launch the Game:**
   - Start the game through BG3 Script Extender (not the vanilla launcher)
   - Verify the mod loaded by checking the Script Extender console

### Verification

On game launch, you should see in the Script Extender console:
```
========================================
AI Allies Mod - Modular Edition Loaded
Modules: Shared, AI, MCM, Combat, Timer, Dialog, Features, Formations, AdvancedFeatures, Eldertide, Tactics
Multiplayer Support: ENABLED
Debug Mode: false
========================================
```

## Usage

### Basic Setup

1. **Assign Archetypes:**
   - Open your spellbook
   - Find "AI Allies: Archetype Selection" spells
   - Cast the desired archetype spell on a companion (e.g., "AI Allies: Set Melee")
   - The companion will now use that AI behavior in combat

2. **Enter Combat:**
   - When combat starts, companions with archetypes will act autonomously
   - They will use abilities, spells, and tactics appropriate to their archetype
   - Combat pauses briefly to allow AI initialization

3. **Manage During Combat:**
   - Use formation spells to reposition allies
   - Toggle auto-heal on healers for emergency medical response
   - Switch aggression modes to adapt to battle conditions

### Advanced Configuration

#### With BG3MCM (Recommended)

Press your MCM hotkey (default: F10) and navigate to "AI Allies Global Settings":

**General Settings:**
- **Enable Custom Archetypes** - Unlock 4 additional custom archetype slots
- **Enable Mindcontrol Art** - Adds mind control and possession abilities
- **Enable Debug Spells** - Adds diagnostic and testing spells
- **Give Swarm Spells** - Enables swarm group mechanics
- **Enable Orders Bonus Action** - Makes command spells cost bonus actions

**AI Behavior:**
- **Disable Allies Dashing** - Prevents AI from using Dash actions
- **Disable Allies Throwing** - Prevents AI from throwing items/weapons
- **Enable Dynamic Spellblock** - Advanced spell filtering system

**Advanced Features:**
- **Enable Formations** - Unlocks tactical formation positioning
- **Enable Auto Heal** - Activates automatic healing below HP threshold
- **Enable Aggression Modes** - Unlocks aggressive/defensive/support modes

#### Without MCM

Without MCM installed, the mod enables all features by default. To customize:
- Manually edit `MCM_blueprint.json` in the mod folder (advanced users only)
- Use in-game debug spells to toggle specific features

### Available Commands & Spells

**Archetype Selection:**
- Target a companion and cast archetype spells from your spellbook
- Removing the archetype status removes AI control

**Formation Commands:**
- Set Formation: Frontline/Midline/Backline/Scattered
- Cast on allies to assign formation positions

**Advanced Commands:**
- Toggle Auto-Heal (on healer archetypes)
- Set Aggression: Aggressive/Defensive/Support
- Mind Control: Teleport/Follow/Possess
- Faction Management (debug): Join/Leave faction

**Swarm Commands (if enabled):**
- Assign Swarm Group: Alpha/Bravo/Charlie/Delta
- Clear Swarm Group

## Configuration Deep-Dive

### MCM Settings Explained

For detailed configuration documentation, see [CONFIGURATION.md](CONFIGURATION.md).

**Key Settings:**

- **`enableCustomArchetypes`**: Unlocks 4 custom archetype slots that can be manually configured with custom AI behaviors and spell loadouts

- **`enableAlliesMind`**: Adds spells for mind control, possession, and direct command over AI allies

- **`disableAlliesDashing`**: When enabled, prevents AI from using Dash/Cunning Action Dash, useful for conserving bonus actions

- **`disableAlliesThrowing`**: Prevents AI from throwing weapons or items, useful for preserving important consumables

- **`enableDynamicSpellblock`**: Advanced feature that dynamically filters spells AI can use based on combat context

- **`enableAlliesSwarm`**: Enables swarm group mechanics where allies can be grouped for synchronized actions (limited AI support)

- **`enableOrdersBonusAction`**: Makes Focus/Ignore command spells cost bonus actions instead of full actions

## Archetypes Documentation

### Standard Archetypes

**Melee (Frontline Fighter)**
- Engages closest enemies aggressively
- Uses melee weapons and close-range abilities
- Prioritizes damage and enemy elimination
- Ideal for Fighters, Barbarians, Paladins

**Ranged (Tactical Shooter)**
- Maintains 15-20m distance from enemies
- Focuses on ranged weapon attacks
- Seeks high ground and cover
- Best for Rangers, Rogues with bows

**Healer - Melee (Combat Medic)**
- Fights in melee while watching ally HP
- Automatically heals injured allies below 50% HP
- Uses HELP action on downed allies within 3m
- Good for War Clerics, Paladins

**Healer - Ranged (Field Medic)**
- Stays at safe distance while monitoring party
- Ranged healing spells (Healing Word, Cure Wounds)
- Resurrects downed allies from up to 18m away
- Perfect for Life Clerics, Bards

**Mage - Melee (Spellsword)**
- Combines spell casting with melee combat
- Uses buff spells before engaging
- Tactical spell selection in close quarters
- Ideal for Eldritch Knights, Bladesingers

**Mage - Ranged (Artillery Caster)**
- Maximum distance spell casting
- Area-of-effect spell preference
- Avoids melee engagement
- Best for Sorcerers, Wizards

**Tank (Defender)**
- Draws enemy attention and absorbs damage
- Uses defensive abilities and crowd control
- Protects vulnerable allies
- Made for Fighters, Barbarians with high AC

**Support (Force Multiplier)**
- Focuses on buffing allies and debuffing enemies
- Uses concentration spells strategically
- Minimal direct damage dealing
- Great for Bards, Support Clerics

**Scout (Reconnaissance)**
- High mobility and positioning flexibility
- Hit-and-run tactics
- Exploits flanking and advantage
- Perfect for Monks, Mobile Rogues

**Controller (Crowd Control)**
- Prioritizes disabling multiple enemies
- Uses status effects and saving throw spells
- Area denial and battlefield control
- Excellent for Wizards, Druids

**Trickster (Infiltrator)**
- Stealth and deception-based tactics
- Sneak attacks and positioning tricks
- Illusion and misdirection spells
- Built for Arcane Tricksters, Trickery Clerics

**Thrower (Grenadier)**
- Specializes in throwing weapons and grenades
- Tactical consumable usage
- Alchemical item exploitation
- Works well with any class with throwing proficiency

**General (Adaptive)**
- Balanced approach to combat
- Switches tactics based on situation
- No specialization, good at everything
- Suitable for multiclass characters

### Custom Archetypes

When **enableCustomArchetypes** is enabled, you gain access to 4 custom archetype slots. These are blank templates that can be customized by:

1. Applying the custom archetype to a companion
2. Manually editing their AI behavior files
3. Adding specific spells and abilities
4. Defining custom tactics and priorities

*Note: Custom archetype configuration requires advanced knowledge of BG3 modding*

## Troubleshooting

### Common Issues

**AI Allies Not Acting in Combat:**
- Verify Script Extender loaded correctly (check console)
- Ensure archetype status is applied to companion
- Check that character is not in a dialog or cutscene
- Try reapplying the archetype spell

**Mod Not Loading:**
- Confirm Script Extender is installed and launching properly
- Check mod load order (AI Allies should load after dependencies)
- Look for error messages in Script Extender console
- Verify file paths are correct

**Allies Acting Strangely:**
- Check if correct archetype is applied (use debug spell to verify)
- Ensure no conflicting AI mods are installed
- Try toggling NPC mode (debug feature) to reset AI
- Review aggression mode settings

**MCM Settings Not Working:**
- Ensure BG3MCM is installed and up to date
- Try saving and reloading the game after changing settings
- Check MCM console for error messages
- Verify mod UUID matches in MCM_blueprint.json

### Debug Mode

Enable debug mode for additional logging:

1. Edit `Shared.lua` in the mod folder
2. Change `DEBUG_MODE = false` to `DEBUG_MODE = true`
3. Reload the game
4. Check Script Extender console for detailed logs

### Reporting Bugs

When reporting issues, please include:
- BG3 version and patch number
- Script Extender version
- MCM version (if installed)
- List of other installed mods
- Script Extender console log (with debug mode enabled)
- Steps to reproduce the issue
- Screenshots or videos if applicable

## Credits

### Original Mod Concept
- AI Allies system and archetype design
- BG3 AI behavior integration

### Contributors
- Community feedback and testing
- Archetype balance and suggestions
- Bug reports and fixes

### Special Thanks
- **Larian Studios** - For Baldur's Gate 3 and mod support
- **Norbyte** - For BG3 Script Extender
- **BG3 Modding Community** - For tools, documentation, and support
- **Eldertide Armaments Team** - For integration support

### Mod Integration Partners
- Eldertide Armaments - Weapon and equipment compatibility

## License

This mod is released for personal use in Baldur's Gate 3. 

**Terms:**
- Free to use and modify for personal gameplay
- Distribution of modified versions requires attribution
- Do not reupload without permission
- Not for commercial use

**Third-Party Assets:**
- All game assets belong to Larian Studios
- Script Extender belongs to Norbyte
- Uses BG3MCM framework with permission

## Support

### Documentation
- [Configuration Guide](CONFIGURATION.md) - Detailed MCM settings documentation
- [Module Structure](AI%20Allies/Mods/AI%20Allies/ScriptExtender/Lua/MODULE_STRUCTURE.md) - Technical documentation for developers

### Community
- Report issues on GitHub Issues
- Join discussions in the community forum
- Share your archetype configurations

### Development
This mod uses a modular architecture for easy maintenance and extension. See the technical documentation in the mod folder for details on the module system.

---

**Version:** Latest
**Author:** AI Allies Team  
**Repository:** https://github.com/jtdelong12-max/AiBro

*Enjoy your intelligent AI companions in Baldur's Gate 3!*