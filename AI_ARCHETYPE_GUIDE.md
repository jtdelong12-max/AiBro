# AI Archetype Configuration Guide

## How Archetypes Work with Modded Content

Your AI archetypes (`AI_healer_ranged.txt`, `AI_mage_ranged.txt`, etc.) control HOW the AI evaluates and uses ALL spells and equipment - including modded content.

### Automatic Mod Support

The archetypes use **multipliers** that apply to spell/item categories, NOT specific spell names. This means:

✅ **Modded spells work automatically** - The AI evaluates them based on their effects:
- Damage spells use `MULTIPLIER_DAMAGE_ENEMY_POS`
- Healing spells use `MULTIPLIER_HEAL_ALLY_POS`
- Control effects use `MULTIPLIER_CONTROL_ENEMY_POS`
- Buffs use `MULTIPLIER_BOOST_ALLY_POS`

✅ **Modded equipment works automatically** - The AI uses equipped items just like vanilla

✅ **Modded consumables work** - Controlled by `USE_ITEM_MODIFIER`

### Key Multipliers Explained

| Multiplier | Purpose | Higher Value = |
|------------|---------|----------------|
| `MULTIPLIER_DAMAGE_ENEMY_POS` | How much AI values damaging enemies | More aggressive damage dealing |
| `MULTIPLIER_HEAL_ALLY_POS` | How much AI values healing allies | More healing priority |
| `MULTIPLIER_CONTROL_ENEMY_POS` | How much AI values CC effects | More crowd control |
| `MULTIPLIER_BOOST_ALLY_POS` | How much AI values buffing | More buff casting |
| `MULTIPLIER_DOT_ENEMY_POS` | How much AI values damage-over-time | More DoT application |
| `MULTIPLIER_FIRST_ACTION_BUFF` | Boost for buffs as first action | Higher = buff before attacking |
| `MULTIPLIER_TARGET_HEALTH_BIAS` | Target selection by HP | Negative = focus high HP, Positive = focus low HP |

### Preventing Non-Combat Spell Usage

Non-combat/utility spells are blocked via:
1. **Block_AI.txt** - Adds `RequirementConditions` to specific spells
2. **AlliesBannedActions status** - Applied during combat
3. **SpellControl.lua** - Lua-level spam prevention (new)

### Customization Tips

**For MORE aggressive AI:**
- Increase `MULTIPLIER_DAMAGE_ENEMY_POS` (e.g., 1.5 → 2.0)
- Decrease `MULTIPLIER_HEAL_ALLY_POS` (e.g., 0.89 → 0.5)

**For MORE supportive AI:**
- Increase `MULTIPLIER_HEAL_ALLY_POS` (e.g., 0.89 → 1.5)
- Increase `MULTIPLIER_BOOST_ALLY_POS` (e.g., 1.15 → 1.5)

**For SMARTER targeting:**
- Adjust `MULTIPLIER_TARGET_PREFERRED` (makes AI respect your marks/orders)
- Adjust `MULTIPLIER_TARGET_HEALTH_BIAS` (negative = focus healthy targets first)

### Important: Concentration Management

The setting `MODIFIER_CONCENTRATION_REMOVE_SELF = 19.0` is critical! This makes AI **highly value maintaining concentration**, preventing them from:
- Dropping important buffs (Bless, Haste, etc.)
- Breaking concentration on control effects (Hold Person, etc.)

### Testing Modded Content

When testing with modded spells:
1. Check the spell's stats (damage/healing/control type)
2. The AI will categorize it based on its effects automatically
3. No archetype changes needed UNLESS you want to adjust priorities
4. Use `Debug Mode = true` in Shared.lua to see AI decisions in console

### Common Issues

**"AI isn't using my modded spell!"**
- Check if it's marked as `AIFlags "CanNotUse"` in the spell stats
- Check if it requires resources the AI can't access
- Check if it's being blocked by `AlliesBannedActions` or `Block_AI.txt`

**"AI is spamming cantrips!"**
- The new SpellControl.lua prevents this
- Adjust archetype to prioritize leveled spells more

**"AI wastes spell slots on weak targets!"**
- Adjust `MULTIPLIER_TARGET_HEALTH_BIAS` in archetype
- AlliesDynamicSpellblock already blocks high-level slots at full HP
