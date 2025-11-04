# LandSandBoat Gameplay Systems

## Overview

LandSandBoat implements Final Fantasy XI gameplay through a layered architecture:
- **C++ Engine Layer**: Core mechanics, calculations, entity management
- **Lua Scripting Layer**: Content implementation, quest logic, NPC behaviors

## Entity System

### Entity Hierarchy

Located in `/src/map/entities/`:

```
baseentity (foundation)
  └─ battleentity (combat-capable)
      ├─ charentity (player characters)
      ├─ mobentity (monsters)
      ├─ npcentity (NPCs)
      ├─ petentity (player pets)
      ├─ trustentity (Trust NPCs)
      ├─ automatonentity (Puppetmaster automatons)
      └─ fellowentity (Fellowship NPCs)
```

### Entity Properties

**Base Entity** (`baseentity.cpp/h`):
- Position, rotation
- Zone membership
- Entity ID
- Render flags
- Name, model

**Battle Entity** (`battleentity.cpp/h`):
- HP, MP, TP
- Status effects
- Combat stats (STR, DEX, VIT, AGI, INT, MND, CHR)
- Elemental resistances
- Claim system
- Enmity tracking
- Allegiance (player, enemy, neutral)

**Character Entity** (`charentity.cpp/h`):
- Jobs (main job, subjob, levels)
- Equipment
- Inventory containers
- Skills and abilities
- Quests and missions
- Linkshell membership
- Party/alliance
- Merit points, job points
- Playtime, nation
- GM level

**Mob Entity** (`mobentity.cpp/h`):
- AI controller
- Spawn point
- Drop list
- Roaming behavior
- Aggro behavior
- Respawn timer
- Super link/linking behavior
- Special mob flags (notorious monster, force pop, etc.)

## Combat System

### Core Combat Loop

Implemented in `/src/map/`:

1. **Engagement** (`attack.cpp`)
   - Player/mob targets enemy
   - Claim established
   - Attack rounds begin

2. **Attack Rounds** (`attackround.cpp`)
   - Auto-attacks at regular intervals
   - Hit/miss calculations
   - Critical hits
   - Multi-hit weapons
   - Counter, parry, guard, evade

3. **Damage Calculation** (`attack.cpp`)
   - Base damage from weapon
   - STR/DEX modifiers
   - Enemy defense
   - Resistance checks
   - Random variance (cRatio)

4. **TP Accumulation**
   - Gain TP on hit (based on delay)
   - Store TP trait modifiers
   - TP overflow on 3000

### Abilities

**Implementation**: `ability.cpp`, `/scripts/actions/abilities/`

**Categories**:
- Job abilities (2-hour, special abilities)
- Pet commands
- Quick draw (COR)
- Phantom roll (COR)
- Blood pacts (SMN)
- Ready moves (BST)
- Stratagems (SCH)

**Execution Flow**:
1. Validate ability use (job, level, recast, MP/TP cost)
2. Apply animation
3. Execute Lua script (`/scripts/actions/abilities/[ability].lua`)
4. Apply effects (damage, buffs, debuffs)
5. Handle status effect application
6. Start recast timer

### Weapon Skills

**Implementation**: `weapon_skill.cpp`, `/scripts/actions/weaponskills/`

**Properties**:
- TP cost (1000, 1500, 2000, 3000)
- TP modifier (affects damage)
- Skill type (slashing, piercing, blunt, H2H, etc.)
- Primary/secondary/tertiary modifiers (STR, DEX, VIT, etc.)
- Element
- Skillchain properties

**Damage Formula**:
```
Base damage = weapon damage × fTP × stat modifiers × buffs
Final damage = base damage × enemy resistance × random variance
```

**Skillchains**:
- Closing weapon skill must match opening properties
- Skillchain levels: 1, 2, 3, 4 (light/darkness)
- Skillchain damage formula in `/scripts/globals/magic.lua`

### Magic System

**Implementation**: `/src/map/spell.cpp`, `/scripts/actions/spells/`

**Spell Categories**:
- White magic (healing, buffs, holy damage)
- Black magic (elemental damage, debuffs)
- Summoning magic (blood pacts)
- Ninjutsu (elemental damage, buffs)
- Songs (bard buffs/debuffs)
- Blue magic (learned from enemies)
- Geomancy (area buffs/debuffs)

**Casting Flow**:
1. Validate spell (job, level, MP cost, recast)
2. Begin cast timer
3. Interrupt check (damage taken)
4. Execute Lua script (`/scripts/actions/spells/[spell].lua`)
5. Calculate magic accuracy
6. Calculate damage/potency
7. Apply effects
8. Deduct MP
9. Start recast timer

**Magic Damage Formula** (`/scripts/globals/magic.lua`):
```
Base damage = (D + stat) × V × (1 + Magic damage bonuses)
Magic burst = base damage × magic burst multiplier
Final damage = magic burst × enemy resistance × random variance
```

**Magic Accuracy**:
- Skill level vs. enemy magic evasion
- INT/MND modifiers
- Elemental affinity
- Day/weather bonuses

### Mob Skills

**Implementation**: `mobskill.cpp`, `/scripts/actions/mobskills/`

**Properties**:
- TP cost
- Animation ID
- Area of effect (cone, AoE, single target)
- Primary modifier (physical, magical, breath)
- Damage type
- Status effects

**Special Mechanics**:
- TP moves at 1000, 2000, 3000 TP
- Notorious monsters have unique TP moves
- Some TP moves are "readies only" (no TP required)

## Status Effects

### Status Effect System

**Implementation**: `status_effect_container.cpp`, `/scripts/effects/`

**Core Mechanics**:
- Each entity has a status effect container
- Effects have duration, power, sub-power
- Effects tick at regular intervals
- Multiple effects can be active simultaneously
- Effects can override or stack

**Status Effect Types**:
- Buffs (Protect, Shell, Haste, etc.)
- Debuffs (Poison, Para, Slow, etc.)
- Enfeebles (Blind, Silence, Sleep, etc.)
- Special (Sneak, Invisible, Reraise, etc.)
- Food effects
- Weakness/level sync

**Effect Application**:
1. Check if effect can be applied (immunities, existing effects)
2. Calculate potency and duration
3. Add to status effect container
4. Apply stat modifiers
5. Start effect tick timer

**Effect Removal**:
- Natural expiration (duration reaches 0)
- Death
- Dispel/Erase
- Zone change
- Effect overwrite

### Latent Effects

**Implementation**: `latent_effect.cpp`

**Purpose**: Equipment/food effects that activate under specific conditions

**Conditions**:
- HP threshold (<50%, >75%, etc.)
- MP threshold
- TP threshold
- Time of day
- Day of week
- Weather
- Moon phase
- Job equipped
- In combat vs. out of combat
- Specific zone
- Status effect present

## AI System

### AI Architecture

Located in `/src/map/ai/`:

**Components**:
- **Controllers** (`ai_container.cpp`, `ai_char_normal.cpp`, `ai_mob_normal.cpp`): Decision-making logic
- **States** (`states/*.cpp`): State machine for behavior
- **Helpers** (`helpers/*.cpp`): Utility functions

### Mob AI States

**States**:
- **INACTIVE**: Mob is not active (not spawned or despawned)
- **SPAWN**: Mob just spawned, initializing
- **ROAM**: Wandering within spawn area
- **ENGAGE**: In combat with target
- **ATTACK**: Performing auto-attacks
- **MOBSKILL**: Using TP move
- **MAGIC**: Casting spell
- **DEATH**: Mob has died
- **RESPAWN**: Waiting to respawn

**State Transitions**:
```
SPAWN → ROAM → ENGAGE → ATTACK
                     ↓
                   DEATH → RESPAWN → SPAWN
```

### Aggro System

**Aggro Types**:
- **Sight**: Aggro on line-of-sight
- **Sound**: Aggro on nearby movement
- **Magic**: Aggro on spell casting
- **Heal**: Aggro on healing
- **Low HP**: Aggro on low health players
- **True sight**: See through sneak/invisible
- **True sound**: Hear through sneak

**Linking**:
- **Link**: Aggro when nearby mob of same type is attacked
- **Super link**: Aggro when any mob of same family is attacked

### Enmity (Hate) System

**Enmity Types**:
- **CE (Cumulative Enmity)**: Decays slowly over time
- **VE (Volatile Enmity)**: Decays quickly over time

**Enmity Generation**:
- Damage dealt
- Healing performed
- Buffs applied
- Flash/Provoke
- Job abilities (e.g., Shield Bash)

**Enmity Management**:
- Tanks generate high enmity
- DPS minimize enmity
- Enmity reset on death
- Some abilities dump/transfer enmity

## Inventory System

### Container Types

**Implementation**: `item_container.cpp`

**Containers**:
- **Inventory**: 30-80 slots (expandable)
- **Mog house**: 80 slots (per zone)
- **Mog safe**: 80 slots (shared across zones)
- **Mog locker**: 80 slots (shared across zones)
- **Mog satchel**: 80 slots (shared)
- **Mog sack**: 80 slots (shared)
- **Mog case**: 80 slots (shared)
- **Equipment**: 16 slots
- **Temporary items**: Special event items
- **Key items**: Quest/mission items (flagged, not actual items)

**Item Properties**:
- Item ID
- Quantity
- Slot location
- Augments (trial/augment data)
- Charges (for rechargeable items)

### Equipment System

**Implementation**: `charentity.cpp`, `/src/map/items/`

**Equipment Slots**:
- Main (weapon)
- Sub (shield/weapon)
- Ranged
- Ammo
- Head, Body, Hands, Legs, Feet
- Neck, Waist, Ears (×2), Rings (×2), Back

**Equipment Stats**:
- Base stats (DEF, HP, MP, etc.)
- Combat modifiers (Attack, Accuracy, Evasion, etc.)
- Magic modifiers (Magic Attack, Magic Accuracy, etc.)
- Latent effects
- Augments
- Special properties (haste, store TP, refresh, etc.)

### Trade System

**Implementation**: `trade_container.cpp`

**Trade Types**:
- Player-to-player trading
- NPC shops
- Guild shops
- Synthesis (crafting)
- Quest item turn-ins

## Crafting System

### Synthesis

**Implementation**: `/scripts/globals/synthing.lua`, `/sql/synth_recipes.sql`

**Crafting Skills**:
- Alchemy
- Bonecraft
- Clothcraft
- Cooking
- Goldsmithing
- Leathercraft
- Smithing
- Woodworking

**Synthesis Process**:
1. Combine crystal + materials
2. Skill check (success, HQ, fail, lose materials)
3. Calculate success rate based on skill level
4. Determine result (normal quality, high quality, failure)
5. Award skill-ups

**HQ (High Quality)**:
- Chance based on skill level vs. recipe level
- HQ tier 1, 2, 3 (progressively rarer)
- Better stats on HQ items

### Desynthesis

Break down items into materials:
- Requires specific crafting skill
- Returns partial materials
- Chance of failure

### Other Crafting Systems

**Synergy** (`/sql/synergy_recipes.sql`):
- Group crafting (multiple players)
- Synergy furnace
- Special recipes

**Gardening** (`/sql/gardening_results.sql`):
- Mog house gardening
- Plant seeds, harvest crops
- Time-based growth

## Party and Social Systems

### Party System

**Implementation**: `party.cpp`, `alliance.cpp`

**Party Mechanics**:
- Maximum 6 players per party
- EXP sharing (based on level, proximity)
- Loot distribution (round-robin, random, leader decides)
- Party buffs and support

**Alliance**:
- Maximum 3 parties (18 players total)
- Cross-party coordination
- Alliance chat

### Linkshell System

**Implementation**: `linkshell.cpp`, database tables

**Features**:
- Private communication channel
- Persistent membership
- Multiple linkshells per character (equip one at a time)
- Linkshell leader can invite/kick members

## Quest and Mission Systems

### Quest System

**Implementation**: Lua scripts in `/scripts/quests/[region]/`

**Quest Structure**:
```lua
quest = {
    name = "Quest Name",
    questId = xi.quest.id.REGION.QUEST_NAME,

    check = function(player)
        -- Check if player can start quest
    end,

    onTrigger = function(player, npc)
        -- Quest trigger (NPC interaction)
    end,

    onEventFinish = function(player, csid, option)
        -- Quest completion
    end
}
```

**Quest Flags**:
- Not started (0)
- In progress (1-N, various stages)
- Completed (quest-specific flag)

**Quest Tracking**:
- Character flags in database
- Binary blob storage for quest states

### Mission System

**Implementation**: Lua scripts in `/scripts/missions/`

**Mission Categories**:
- Nation missions (Bastok, San d'Oria, Windurst)
- Expansion missions (Zilart, Promathia, ToAU, WotG, etc.)

**Mission Progression**:
- Linear progression (must complete in order)
- Cutscenes (CS IDs)
- Battle content (BCNM, battlefield instances)

## Zone System

### Zone Management

**Implementation**: `zone.cpp`, `/scripts/zones/`

**Zone Properties**:
- Zone ID
- Zone name
- Region
- Weather system
- Music
- Zone flags (outdoor, dungeon, city, etc.)

**Zone Data**:
- 297 zones total
- Each zone has dedicated directory in `/scripts/zones/`

**Zone Contents**:
- NPCs (`/scripts/zones/[zone]/npcs/`)
- Mobs (`/scripts/zones/[zone]/mobs/`)
- IDs file (`/scripts/zones/[zone]/IDs.lua`) - Entity IDs, text IDs
- Zone script (`/scripts/zones/[zone]/Zone.lua`) - Zone events

### Instance System

**Implementation**: `instance.cpp`

**Instance Types**:
- BCNM (Burning Circle Notorious Monster)
- Dynamis
- Assault
- Limbus
- Salvage
- Nyzul Isle
- Abyssea

**Instance Mechanics**:
- Time-limited
- Private to party/alliance
- Entry requirements (items, key items, etc.)
- Reward chests

## World Systems

### Conquest System

**Implementation**: `conquest_system.cpp`

**Mechanics**:
- Three nations compete for control
- Region influence
- Tally periods (weekly updates)
- Guards change based on control

### Campaign System

**Implementation**: `campaign_system.cpp`

**Purpose**: Wings of the Goddess content
- Past timeline
- Allied forces vs. Beastmen
- Campaign battles
- Medal system

### Besieged System

**Implementation**: `besieged_system.cpp`

**Purpose**: Treasures of Aht Urhgan content
- Defense of Al Zahbi
- Imperial standing
- NPC defense force

## Character Progression

### Experience and Leveling

**EXP Sources**:
- Defeating monsters (mob level vs. player level)
- Party EXP bonus
- Chain bonuses (killing mobs quickly)
- Field of Valor/Grounds of Valor

**Level Cap**:
- Initial: 50 (or configured in `main.lua`)
- Expansions unlock higher caps (75, 99)
- Limit breaks (quests to raise cap)

### Skill System

**Skill Types**:
- **Combat skills**: Slashing, Piercing, Blunt, Hand-to-Hand, Archery, Marksmanship, Throwing
- **Magic skills**: Divine, Healing, Enhancing, Enfeebling, Elemental, Dark, Summoning, Ninjutsu, Singing, String, Wind, Blue
- **Crafting skills**: 8 crafting skills

**Skill-ups**:
- Gain skill through use
- Skill caps based on job and level
- Skill rank (A-F) determines cap growth

### Merit Points

**Implementation**: `merit.cpp`, `/scripts/globals/merits.lua`

**Purpose**: Post-level-75 character customization

**Merit Categories**:
- HP/MP bonuses
- Combat attributes
- Magic attributes
- Job-specific abilities and traits

### Job Points

**Implementation**: `job_points.cpp`

**Purpose**: Post-level-99 job specialization

**Categories**:
- Job-specific bonuses
- Capacity points spent on job abilities
- Gifts unlocked at specific JP tiers

## Pet System

### Pet Types

**Summoner Pets** (`petentity.cpp`):
- Carbuncle, elemental spirits, avatars
- Blood pacts (physical and magical)
- Perpetuation cost (MP drain)

**Beastmaster Pets** (`petentity.cpp`):
- Jug pets (called from consumable items)
- Charmed monsters
- Ready abilities

**Puppetmaster Automatons** (`automatonentity.cpp`):
- Customizable with attachments
- Frames (melee, ranged, magic)
- Maintenance (oil and repair)

**Dragoon Wyverns** (`petentity.cpp`):
- Breath attacks
- Healing breath

### Pet AI

- Follows master
- Attacks master's target
- Can be commanded (attack, retreat, stay)
- Independent TP and ability usage

## Miscellaneous Systems

### Fishing

**Implementation**: 7+ SQL files in `/sql/`, `/scripts/globals/fishing.lua`

**Mechanics**:
- Fishing skill
- Rod, bait, zone matter
- Catch rates based on skill
- Fish fighting minigame

### Chocobo System

**Implementation**: `/scripts/globals/chocobo.lua`

**Features**:
- Chocobo raising (digging, racing)
- Chocobo rental for transportation
- Chocobo speeds based on zone

### Mog House

**Storage containers**:
- Mog safe, locker, satchel, sack, case
- Furniture placement
- Gardening

### Auction House

**Implementation**: `auction_house.cpp`, `/sql/auction_house.sql`

**Mechanics**:
- List items for sale
- Search and purchase
- Bid system
- AH tax

### Currency Systems

- **Gil**: Primary currency
- **Conquest points**: Nation-specific
- **Imperial standing**: Aht Urhgan
- **Allied notes**: Campaign (WotG)
- **Cruor**: Abyssea
- **Bayld**: Seekers of Adoulin
- **Sparks of Eminence**: Records of Eminence

## Content Implementation Patterns

### Adding a New NPC

1. Create Lua script in `/scripts/zones/[zone]/npcs/[npc_name].lua`
2. Define onTrade, onTrigger, onEventFinish functions
3. Add NPC spawn to database or zone script
4. Implement dialog and functionality

### Adding a New Quest

1. Create quest script in `/scripts/quests/[region]/`
2. Define quest ID in enums
3. Implement check, onTrigger, onEventFinish
4. Add quest rewards and progression logic
5. Test all quest stages

### Adding a New Mob

1. Add spawn point to `mob_spawn_points` SQL table
2. Create mob script in `/scripts/zones/[zone]/mobs/[mob_name].lua`
3. Define onMobSpawn, onMobDeath, onMobFight behavior
4. Set mob stats, drops, and AI behavior

### Implementing Custom Abilities

1. Create Lua script in `/scripts/actions/abilities/`
2. Define ability properties (animation, cost, recast)
3. Implement onAbilityCheck (validation)
4. Implement onUseAbility (effects)
5. Add ability to job ability tables

## Performance Considerations

### Lua Script Performance

- Scripts are JIT-compiled by LuaJIT
- Hot-reloadable (no server restart)
- Avoid complex calculations in frequently called functions
- Cache lookups where possible

### Entity Updates

- Entities updated at regular tick intervals
- Spatial indexing for proximity checks
- Only update active entities (spawned, in combat)

### Database Queries

- Character data loaded on zone-in
- Cached in memory during gameplay
- Written back on zone change or logout
- Avoid frequent database writes

## Debugging and Testing

### Logging

- Use spdlog for C++ logging
- Use print() in Lua for debugging
- Log levels: debug, info, warning, error

### GM Commands

Located in `/scripts/commands/`:
- !pos - Get position
- !additem - Add item to inventory
- !setjob - Change job and level
- !speed - Adjust movement speed
- !gm - Toggle GM mode
- Many more administrative commands

### Testing Framework

Located in `/src/test/` and `/scripts/specs/`:
- Unit tests for C++ code
- Spec tests for Lua code
- CI integration for automated testing
