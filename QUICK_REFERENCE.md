# 🎮 AI Allies Mod - Quick Reference Card

## ✅ Patch 8 Status: COMPATIBLE

---

## 🚀 What Changed for Patch 8

### Required
- ✅ Script Extender version updated to v11

### Enhanced
- ✅ Spell spam prevention (new SpellControl module)
- ✅ Modded content documentation
- ✅ Better error handling in combat

---

## 🎯 Your Requirements - Status

| Requirement | Status | How It Works |
|------------|--------|-------------|
| Smart AI companions | ✅ WORKING | 13 archetypes with tactical behavior |
| Use modded equipment | ✅ WORKING | Automatic - AI reads all equipment stats |
| Use modded spells | ✅ WORKING | Automatic - categorized by effect type |
| No useless non-combat spells | ✅ WORKING | 3-layer blocking system |
| No spell spam | ✅ WORKING | Dynamic slot blocking + usage tracking |

---

## 🔧 Key Systems

### 1. Non-Combat Spell Blocking
**Files**: `Block_AI.txt`, `SpellControl.lua`

**Blocked in Combat**:
- Movement: Feather Fall, Longstrider, Gaseous Form
- Buffs: Sanctuary, Warding Bond, Guidance
- Social: Thaumaturgy
- Modded utility (pattern-matched)

### 2. Spell Spam Prevention
**Files**: `SpellControl.lua`, `PassiveComp.txt` (AlliesDynamicSpellblock)

**How it Works**:
- Tracks last 3 seconds of casting
- Max 2 uses of same spell
- Blocks high-level slots at high HP
- Example: At 99% HP, can't use spell slots 1-6

### 3. Modded Content Support
**Files**: All archetype .txt files

**Modded Spells Work If**:
- Have proper SpellData definition
- Not flagged `AIFlags "CanNotUse"`
- Have damage/heal/control effects

**AI Auto-Detects**:
- Damage spells → Uses based on `MULTIPLIER_DAMAGE_ENEMY_POS`
- Healing spells → Uses based on `MULTIPLIER_HEAL_ALLY_POS`
- Control spells → Uses based on `MULTIPLIER_CONTROL_ENEMY_POS`
- Buffs → Uses based on `MULTIPLIER_BOOST_ALLY_POS`

---

## 📊 Archetype Quick Settings

### To Make AI More Aggressive
Edit archetype file (e.g., `AI_mage_ranged.txt`):
```
MULTIPLIER_DAMAGE_ENEMY_POS  1.5 → 2.0
MULTIPLIER_HEAL_ALLY_POS     0.3 → 0.1
```

### To Make AI More Supportive
```
MULTIPLIER_HEAL_ALLY_POS     0.89 → 1.5
MULTIPLIER_BOOST_ALLY_POS    1.15 → 1.5
```

### To Improve Target Selection
```
MULTIPLIER_TARGET_HEALTH_BIAS  0.0 → -0.5 (focus high HP)
MULTIPLIER_TARGET_PREFERRED    2.0 → 6.0 (respect orders more)
```

---

## 🐛 Debugging

### Enable Debug Mode
**File**: `Shared.lua`, line 52
```lua
DEBUG_MODE = false  →  DEBUG_MODE = true
```

### Check Logs
Game console will show:
- `[COMBAT]` - Combat decisions
- `[SPELL]` - Spell usage
- `[SPAM]` - Spam prevention triggers
- `[ERROR]` - Error messages

---

## 📁 File Structure

### Core Modules (Lua)
```
ScriptExtender/Lua/
├── BootstrapServer_Modular.lua  # Main entry point
├── Shared.lua                   # Constants & utilities
├── AI.lua                       # Archetype management
├── Combat.lua                   # Combat & spell logic
├── SpellControl.lua             # NEW: Spam prevention
├── AdvancedFeatures.lua         # Auto-heal, modes
└── [other modules...]
```

### AI Configuration (Stats)
```
Public/AI Allies/AI/Archetypes/
├── AI_healer_ranged.txt         # Healer behavior
├── AI_mage_ranged.txt           # Mage behavior
├── AI_general.txt               # Balanced behavior
├── AI_tank.txt                  # Tank behavior
└── [other archetypes...]
```

### Spell Blocking (Stats)
```
Stats/Generated/Data/
├── Block_AI.txt                 # Non-combat spell blocks
├── PassiveComp.txt              # Dynamic spell slot blocking
└── Statuses.txt                 # Status definitions
```

---

## 🔥 Common Issues & Solutions

### "AI isn't using my modded spell"
**Check**:
1. Does spell have proper SpellData?
2. Is it flagged `AIFlags "CanNotUse"`?
3. Is it in Block_AI.txt?
4. Enable debug mode to see why

**Fix**: Add spell to character, enter combat, watch console

### "AI is using utility spells in combat"
**Fix**: Add spell to Block_AI.txt:
```
new entry "Target_YourModdedSpell"
type "SpellData"
using "Target_YourModdedSpell"
data "RequirementConditions" "not HasStatus('AlliesBannedActions')"
```

### "AI is wasting high-level spell slots"
**Check**: AlliesDynamicSpellblock passive is applied
- Should be automatic with archetype status
- Look for status `AlliesDynamicSpellblock` in game

---

## ✨ Advanced: Adding Custom Archetypes

1. Copy existing archetype .txt file
2. Rename (e.g., `AI_my_custom.txt`)
3. Adjust multipliers for desired behavior
4. Add status in `Statuses.txt`:
```
new entry "AI_ALLIES_MYCUSTOM"
type "StatusData"
using "AI_ALLIES_MELEE"
data "DisplayName" "hf8f9a2c8g0000g0000g0000g000000000000;1"
data "Description" "hf8f9a2c8g0000g0000g0000g000000000001;1"
data "AISelfTargetAI" "mycustom"
data "AITargetAllyAI" "mycustom"
data "AITargetEnemyAI" "mycustom"
```

---

## 📞 Quick Support

**Mod Not Loading?**
- Check Script Extender is v11+
- Check Config.json has `RequiredVersion: 11`

**AI Not Activating?**
- Apply controller status (e.g., `AI_ALLIES_MELEE_Controller`)
- Status must be on companion, not player

**Performance Issues?**
- Reduce number of AI companions (max 3 recommended)
- Disable debug mode
- Check entity cache settings in Shared.lua

---

## 🎉 You're Ready!

Your mod is **production-ready** for BG3 Patch 8 with full modded content support!

Key strengths:
- ✅ Clean modular code
- ✅ Comprehensive error handling
- ✅ Smart spell management
- ✅ Automatic mod compatibility
- ✅ No manual configuration needed

**Enjoy your smart AI companions! 🚀**
