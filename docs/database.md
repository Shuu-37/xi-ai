# LandSandBoat Database Architecture Guide

## Overview

This comprehensive guide covers LandSandBoat's database architecture for developers building APIs, tools, and integrations. It's based on deep analysis of the actual LSB codebase and provides practical patterns for working with the database.

**Database**: MariaDB 10.x+
**Character Encoding**: UTF8MB4
**Total Tables**: 124 tables organized into 15 logical categories
**Default Port**: 3306

## Quick Navigation

- [Architecture Overview](#architecture-overview)
- [Character System](#character-system-deep-dive)
- [Item System](#item-system)
- [Monster System](#monster-system)
- [Economy & Auction House](#economy--auction-house)
- [Binary Blob Fields](#working-with-binary-blobs)
- [Transactions & Data Integrity](#transactions--data-integrity)
- [Common Query Patterns](#common-query-patterns)
- [API Development Best Practices](#api-development-best-practices)

---

## Architecture Overview

### Database Organization

LandSandBoat uses **124 tables** organized into these major categories:

#### 1. Account System (5 tables)
- `accounts` - Player accounts
- `accounts_banned` - Ban records
- `accounts_parties` - Party associations
- `accounts_sessions` - Active login sessions
- `account_ip_record` - Login IP history

#### 2. Character System (28 tables)
- `chars` - Main character data (80+ columns with blobs)
- `char_blacklist` - Blocked players
- `char_chocobos` - Chocobo data
- `char_effects` - Active status effects
- `char_equip` - Equipped items
- `char_equip_saved` - Saved equipment sets
- `char_exp` - Experience tracking
- `char_fishing_contest_history` - Fishing contest records
- `char_flags` - Character flags
- `char_history` - Activity log
- `char_inventory` - Items in all containers
- `char_job_points` - Job point allocation
- `char_jobs` - Job levels & experience (22 jobs)
- `char_look` - Character appearance
- `char_merit` - Merit point allocation
- `char_monstrosity` - Monstrosity data
- `char_pet` - Pet information
- `char_points` - Currencies & points (206 types!)
- `char_profile` - Fame, ranks, nation info
- `char_recast` - Ability cooldowns
- `char_skills` - Combat, magic, crafting skills
- `char_spells` - Learned spells
- `char_stats` - Base statistics (STR, DEX, VIT, AGI, INT, MND, CHR, HP, MP)
- `char_storage` - Additional storage
- `char_style` - Style lock data
- `char_unlocks` - Teleports, homepoints, waypoints
- `char_vars` - Key-value storage for scripts
- Note: No `char_armor` table exists (was in old docs)

#### 3. Item System (9 tables)
- `item_basic` - Core item data (name, stack size, price)
- `item_equipment` - Equipment stats (HP, MP, STR, DEX, VIT, AGI, INT, MND, CHR, DEF, ATT, ACC, EVA, jobs, level, slots, races, slot)
- `item_furnishing` - Furniture items
- `item_latents` - Latent effects
- `item_mods` - Item modifiers
- `item_mods_pet` - Pet equipment mods
- `item_puppet` - Automaton equipment
- `item_usable` - Usable items
- `item_weapon` - Weapon stats (damage, delay, skill)

#### 4. Monster System (13 tables)
- `mob_droplist` - Monster drops with rates
- `mob_family_mods` - Family-wide modifiers
- `mob_family_system` - Family system data
- `mob_groups` - Spawn group assignments
- `mob_pool_mods` - Pool-specific modifiers
- `mob_pools` - Base mob stats & AI behavior
- `mob_resistances` - Elemental resistances
- `mob_skill_lists` - Skill list assignments
- `mob_skills` - Mob TP moves & abilities
- `mob_spawn_points` - Spawn locations
- `mob_spawn_sets` - Spawn set groupings
- `mob_spell_lists` - Mob magic assignments

#### 5. Economy System (4 tables)
- `auction_house` - Market listings & sales history
- `auction_house_items` - AH item categories
- `delivery_box` - Mail/delivery system
- `guilds` - Guild information

#### 6. Crafting System (3 tables)
- `synth_recipes` - Synthesis recipes (8 crafts)
- `synergy_recipes` - Synergy recipes (group crafting)
- `gardening_results` - Mog house gardening

#### 7. Game Systems (24 tables)

**World Systems:**
- `conquest_system` - Conquest region control
- `campaign_map` - Campaign (WotG) regions
- `campaign_nation` - Campaign nation data
- `unity_system` - Unity Concord system

**Zones & Transport:**
- `zone_settings` - Zone configuration
- `zone_weather` - Zone weather patterns
- `zonelines` - Zone connections
- `transport` - Airship, boat, chocobo routes
- `water_points` - Water zones for fishing

**Instances & Battles:**
- `bcnm_info` - BCNM/ENM records
- `instance_entities` - Instance entity tracking
- `instance_list` - Active instances

**NPCs & Pets:**
- `npc_list` - NPC definitions
- `pet_list` - Pet data
- `pet_name` - Pet naming
- `pet_skills` - Pet abilities

**Monstrosity:**
- `monstrosity_exp_table` - Monstrosity experience
- `monstrosity_instinct_mods` - Instinct modifiers
- `monstrosity_instincts` - Instinct definitions
- `monstrosity_species` - Monstrosity species

**Other:**
- `exp_base` - Base experience tables
- `exp_table` - Experience requirements by level
- `status_effects` - Status effect definitions
- `server_variables` - Server-wide variables

#### 8. Social System (1 table)
- `linkshells` - Linkshell data (note: members stored in chars table)

#### 9. Audit System (6 tables)
- `audit_bazaar` - Bazaar transactions
- `audit_chat` - Chat logs
- `audit_dbox` - Delivery box usage
- `audit_gm` - GM commands
- `audit_trade` - Player trades
- `audit_vendor` - NPC purchases

#### 10. Abilities & Skills (9 tables)
- `abilities` - Job abilities
- `abilities_charges` - Ability charges/stacks
- `automaton_abilities` - Automaton abilities
- `automaton_spells` - Automaton magic
- `skill_caps` - Skill level caps by job
- `skill_ranks` - Skill rank progression
- `skillchain_damage_modifiers` - Skillchain bonuses
- `weapon_skills` - Weapon skills
- `traits` - Job traits

#### 11. Blue Mage System (3 tables)
- `blue_spell_list` - Blue magic spells
- `blue_spell_mods` - Blue spell modifiers
- `blue_traits` - Blue magic traits

#### 12. Spell System (1 table)
- `spell_list` - All spells (white magic, black magic, summoning, ninjutsu, songs, blue magic, geomancy, trust magic)

#### 13. Fishing System (13 tables)
- `fishing_area` - Fishing areas
- `fishing_bait` - Bait types
- `fishing_bait_affinity` - Bait compatibility
- `fishing_catch` - Catchable fish
- `fishing_contest` - Fishing contests
- `fishing_contest_entries` - Contest entries
- `fishing_fish` - Fish data
- `fishing_group` - Fish groupings
- `fishing_mob` - Monster fishing
- `fishing_rod` - Rod types
- `fishing_zone` - Zone fishing data

#### 14. Guild & Job Systems (5 tables)
- `guild_item_points` - Guild point values
- `guild_shops` - Guild shop inventory
- `job_point_gifts` - Job point gift items
- `job_points` - Job point definitions
- `merits` - Merit point categories

#### 15. Miscellaneous (4 tables)
- `augments` - Item augment definitions
- `cheat_types` - Anti-cheat detection types
- `despoil_effects` - Despoil ability effects
- `ip_exceptions` - IP whitelist/exceptions

---

### Table Count by Category
- Character System: 28 tables
- Game Systems: 24 tables
- Monster System: 13 tables
- Fishing System: 13 tables
- Item System: 9 tables
- Abilities & Skills: 9 tables
- Audit System: 6 tables
- Account System: 5 tables
- Guild & Job Systems: 5 tables
- Economy System: 4 tables
- Miscellaneous: 4 tables
- Blue Mage System: 3 tables
- Crafting System: 3 tables
- Social System: 1 table
- Spell System: 1 table

**Total: 124 tables**

### Storage Engines

LSB uses two storage engines strategically:

- **InnoDB**: Character data (transactional, supports triggers)
  - All `chars*`, `accounts*`, `auction_house`, `delivery_box`
  - Ensures ACID compliance for player data

- **Aria** (MyISAM replacement): Static game data
  - `item_*`, `mob_*`, `spell_list`, `abilities`, `synth_recipes`
  - Faster reads, no transaction overhead for read-only content

### Connection Details

```lua
-- From settings/network.lua
mysql_host = "127.0.0.1"
mysql_port = 3306
mysql_login = "xiserver"
mysql_password = "xiserver"
mysql_database = "xidb"
```

---

## Character System Deep Dive

### Core Character Table: `chars`

The `chars` table is the heart of the character system with **80+ columns**:

```sql
CREATE TABLE `chars` (
  `charid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `accid` int(10) unsigned NOT NULL,
  `charname` varchar(15) NOT NULL,

  -- Location
  `pos_zone` smallint(5) unsigned NOT NULL DEFAULT 0,
  `pos_x` float NOT NULL DEFAULT 0,
  `pos_y` float NOT NULL DEFAULT 0,
  `pos_z` float NOT NULL DEFAULT 0,
  `pos_rot` tinyint(3) unsigned NOT NULL DEFAULT 0,

  -- Jobs
  `mjob` tinyint(2) unsigned NOT NULL DEFAULT 0,
  `sjob` tinyint(2) unsigned NOT NULL DEFAULT 0,
  `mlvl` tinyint(2) unsigned NOT NULL DEFAULT 1,
  `slvl` tinyint(2) unsigned NOT NULL DEFAULT 0,

  -- Core Stats
  `hp` smallint(5) NOT NULL DEFAULT 1,
  `mp` smallint(5) NOT NULL DEFAULT 1,
  `exp` int(10) unsigned NOT NULL DEFAULT 0,
  `merit_points` smallint(3) unsigned NOT NULL DEFAULT 0,
  `limit_points` int(10) unsigned NOT NULL DEFAULT 0,

  -- Admin
  `gmlevel` tinyint(2) unsigned NOT NULL DEFAULT 0,

  -- Progress Data (Binary Blobs)
  `missions` blob DEFAULT NULL,
  `assault` blob DEFAULT NULL,
  `campaign` blob DEFAULT NULL,
  `eminence` blob DEFAULT NULL,
  `quests` blob DEFAULT NULL,
  `keyitems` blob DEFAULT NULL,
  `abilities` blob DEFAULT NULL,
  `weaponskills` blob DEFAULT NULL,
  `titles` blob DEFAULT NULL,
  `zones` blob DEFAULT NULL,
  `set_blue_spells` blob DEFAULT NULL,
  `unlocked_weapons` blob DEFAULT NULL,

  -- Metadata
  `playtime` int(10) unsigned NOT NULL DEFAULT 0,
  `deaths` int(10) unsigned NOT NULL DEFAULT 0,
  `title` smallint(5) unsigned NOT NULL DEFAULT 0,
  `nation` tinyint(2) unsigned NOT NULL DEFAULT 0,

  PRIMARY KEY (`charid`),
  KEY `accid` (`accid`),
  KEY `charname` (`charname`)
) ENGINE=InnoDB;
```

### Character Loading Pattern

LSB loads a complete character using **8 separate queries**:

```sql
-- 1. Main character data + all blobs
SELECT * FROM chars WHERE charid = ?;

-- 2. Spell list
SELECT spellid FROM char_spells WHERE charid = ?;

-- 3. Fame and ranks
SELECT * FROM char_profile WHERE charid = ?;

-- 4. Current stats
SELECT * FROM char_stats WHERE charid = ?;

-- 5. Appearance
SELECT * FROM char_look WHERE charid = ?;

-- 6. Currencies (206 different types!)
SELECT * FROM char_points WHERE charid = ?;

-- 7. Teleport/homepoint unlocks
SELECT * FROM char_unlocks WHERE charid = ?;

-- 8. Full inventory (all containers)
SELECT * FROM char_inventory WHERE charid = ?;
```

**API Recommendation**: Create a single endpoint that loads all character data to minimize round trips:

```typescript
// GET /api/characters/:id
interface CharacterResponse {
  character: Character;      // chars table
  stats: CharacterStats;     // char_stats
  jobs: CharacterJobs;       // char_jobs
  skills: CharacterSkills;   // char_skills
  profile: CharacterProfile; // char_profile
  inventory: InventoryItem[]; // char_inventory
  equipment: Equipment[];     // char_equip joined with inventory
}
```

### Character Relationships

```
accounts (1) ──< (N) chars
                      ├──< (1) char_stats
                      ├──< (1) char_profile
                      ├──< (1) char_jobs
                      ├──< (1) char_skills
                      ├──< (1) char_points
                      ├──< (1) char_unlocks
                      ├──< (1) char_look
                      ├──< (N) char_inventory
                      ├──< (N) char_equip
                      ├──< (N) char_vars (key-value storage)
                      └──< (0-1) accounts_sessions
```

### Character Tables Reference

#### `char_stats` - Base Statistics
```sql
CREATE TABLE `char_stats` (
  `charid` int(10) unsigned NOT NULL,
  `str` smallint(3) unsigned NOT NULL DEFAULT 0,
  `dex` smallint(3) unsigned NOT NULL DEFAULT 0,
  `vit` smallint(3) unsigned NOT NULL DEFAULT 0,
  `agi` smallint(3) unsigned NOT NULL DEFAULT 0,
  `int` smallint(3) unsigned NOT NULL DEFAULT 0,
  `mnd` smallint(3) unsigned NOT NULL DEFAULT 0,
  `chr` smallint(3) unsigned NOT NULL DEFAULT 0,
  `hp` smallint(5) NOT NULL DEFAULT 0,
  `mp` smallint(5) NOT NULL DEFAULT 0,
  PRIMARY KEY (`charid`)
) ENGINE=InnoDB;
```

#### `char_jobs` - Job Levels & Experience
```sql
CREATE TABLE `char_jobs` (
  `charid` int(10) unsigned NOT NULL,
  -- 22 job levels (tinyint 0-99)
  `war` tinyint(2) unsigned NOT NULL DEFAULT 0,
  `mnk` tinyint(2) unsigned NOT NULL DEFAULT 0,
  `whm` tinyint(2) unsigned NOT NULL DEFAULT 0,
  -- ... (rdm, blm, thf, pld, drk, bst, brd, rng, sam, nin, drg, smn, blu, cor, pup, dnc, sch, geo, run)

  -- 22 experience values (int 0-55500+)
  `war_exp` int(10) unsigned NOT NULL DEFAULT 0,
  `mnk_exp` int(10) unsigned NOT NULL DEFAULT 0,
  -- ...

  `unlocked` int(10) unsigned NOT NULL DEFAULT 0, -- Bitfield of unlocked jobs
  PRIMARY KEY (`charid`)
) ENGINE=InnoDB;
```

**Job Bitfield** (`unlocked` column):
- Bit 0 (value 1): WAR (Warrior)
- Bit 1 (value 2): MNK (Monk)
- Bit 2 (value 4): WHM (White Mage)
- Bit 3 (value 8): BLM (Black Mage)
- Bit 4 (value 16): RDM (Red Mage)
- Bit 5 (value 32): THF (Thief)
- Bit 6 (value 64): PLD (Paladin)
- Bit 7 (value 128): DRK (Dark Knight)
- Bit 8 (value 256): BST (Beastmaster)
- Bit 9 (value 512): BRD (Bard)
- Bit 10 (value 1024): RNG (Ranger)
- Bit 11 (value 2048): SAM (Samurai)
- Bit 12 (value 4096): NIN (Ninja)
- Bit 13 (value 8192): DRG (Dragoon)
- Bit 14 (value 16384): SMN (Summoner)
- Bit 15 (value 32768): BLU (Blue Mage)
- Bit 16 (value 65536): COR (Corsair)
- Bit 17 (value 131072): PUP (Puppetmaster)
- Bit 18 (value 262144): DNC (Dancer)
- Bit 19 (value 524288): SCH (Scholar)
- Bit 20 (value 1048576): GEO (Geomancer)
- Bit 21 (value 2097152): RUN (Rune Fencer)

**Example: Check if job is unlocked**
```python
# Check if WAR is unlocked
is_war_unlocked = (unlocked & 1) != 0

# Check if NIN is unlocked
is_nin_unlocked = (unlocked & 4096) != 0

# Unlock multiple jobs (WAR + MNK + WHM)
unlocked = 1 | 2 | 4  # = 7
```

#### `char_inventory` - Item Storage
```sql
CREATE TABLE `char_inventory` (
  `charid` int(10) unsigned NOT NULL,
  `location` tinyint(1) unsigned NOT NULL,
  `slot` tinyint(2) unsigned NOT NULL,
  `itemId` smallint(5) unsigned NOT NULL,
  `quantity` int(10) unsigned NOT NULL,
  `bazaar` int(10) unsigned NOT NULL DEFAULT 0,
  `signature` varchar(27) DEFAULT NULL,
  `extra` blob DEFAULT NULL,
  PRIMARY KEY (`charid`,`location`,`slot`),
  KEY `itemId` (`itemId`)
) ENGINE=InnoDB;
```

**Container IDs** (`location`):
- 0: Inventory (80 slots)
- 1: Mog Safe (80 slots)
- 2: Storage (80 slots)
- 3: Temporary (80 slots)
- 4: Mog Locker (80 slots)
- 5: Mog Satchel (80 slots)
- 6: Mog Sack (80 slots)
- 7: Mog Case (80 slots)
- 8: Wardrobe (80 slots)
- 9-12: Mog Safe 2, Wardrobe 2-4

**Example: Get Character's Main Inventory**
```sql
SELECT
  ci.slot,
  ci.itemId,
  ci.quantity,
  ib.name,
  ib.stackSize,
  ib.BaseSell,
  CASE
    WHEN ci.bazaar > 0 THEN ci.bazaar
    ELSE NULL
  END as bazaar_price
FROM char_inventory ci
JOIN item_basic ib ON ci.itemId = ib.itemid
WHERE ci.charid = ? AND ci.location = 0
ORDER BY ci.slot;
```

#### `char_equip` - Equipped Items
```sql
CREATE TABLE `char_equip` (
  `charid` int(10) unsigned NOT NULL,
  `equipslotid` tinyint(2) unsigned NOT NULL,
  `slotid` tinyint(2) unsigned NOT NULL,
  `containerid` tinyint(2) unsigned NOT NULL,
  PRIMARY KEY (`charid`,`equipslotid`)
) ENGINE=InnoDB;
```

**Equipment Slots** (`equipslotid`):
- 0: Main, 1: Sub, 2: Ranged, 3: Ammo
- 4: Head, 5: Body, 6: Hands, 7: Legs, 8: Feet
- 9: Neck, 10: Waist, 11: Ear1, 12: Ear2, 13: Ring1, 14: Ring2, 15: Back

**Example: Get Equipped Items with Full Details**
```sql
SELECT
  ce.equipslotid,
  CASE ce.equipslotid
    WHEN 0 THEN 'Main' WHEN 1 THEN 'Sub' WHEN 2 THEN 'Ranged'
    WHEN 3 THEN 'Ammo' WHEN 4 THEN 'Head' WHEN 5 THEN 'Body'
    WHEN 6 THEN 'Hands' WHEN 7 THEN 'Legs' WHEN 8 THEN 'Feet'
    WHEN 9 THEN 'Neck' WHEN 10 THEN 'Waist' WHEN 11 THEN 'Ear1'
    WHEN 12 THEN 'Ear2' WHEN 13 THEN 'Ring1' WHEN 14 THEN 'Ring2'
    WHEN 15 THEN 'Back'
  END as slot_name,
  ib.itemid,
  ib.name,
  ie.level,
  ie.DEF, ie.HP, ie.MP,
  ie.STR, ie.DEX, ie.VIT, ie.AGI, ie.INT, ie.MND, ie.CHR,
  iw.damage, iw.delay
FROM char_equip ce
JOIN char_inventory ci
  ON ce.charid = ci.charid
  AND ce.slotid = ci.slot
  AND ce.containerid = ci.location
JOIN item_basic ib ON ci.itemId = ib.itemid
LEFT JOIN item_equipment ie ON ib.itemid = ie.itemId
LEFT JOIN item_weapon iw ON ib.itemid = iw.itemId
WHERE ce.charid = ?
ORDER BY ce.equipslotid;
```

#### `char_vars` - Key-Value Storage
```sql
CREATE TABLE `char_vars` (
  `charid` int(10) unsigned NOT NULL,
  `varname` varchar(30) NOT NULL,
  `value` int(11) NOT NULL,
  `expiry` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`charid`,`varname`)
) ENGINE=InnoDB;
```

**Purpose**: Flexible storage for:
- Quest progress tracking
- Temporary flags and cooldowns
- Custom script data
- Event states

**Example Usage**:
```sql
-- Set a quest variable
INSERT INTO char_vars (charid, varname, value)
VALUES (1000123, 'QUEST_SANDORIA_1_PROGRESS', 3)
ON DUPLICATE KEY UPDATE value = 3;

-- Set with expiry (Unix timestamp)
INSERT INTO char_vars (charid, varname, value, expiry)
VALUES (1000123, 'DAILY_LOGIN_BONUS', 1, UNIX_TIMESTAMP(NOW() + INTERVAL 1 DAY))
ON DUPLICATE KEY UPDATE value = 1, expiry = UNIX_TIMESTAMP(NOW() + INTERVAL 1 DAY);

-- Get variable
SELECT value FROM char_vars
WHERE charid = ? AND varname = ?;

-- Clean expired variables
DELETE FROM char_vars
WHERE expiry > 0 AND expiry < UNIX_TIMESTAMP(NOW());
```

#### `char_points` - Currencies & Points

This table stores **206 different currency types**!

```sql
CREATE TABLE `char_points` (
  `charid` int(10) unsigned NOT NULL,

  -- Core Currencies
  `sandoria_cp` smallint(5) unsigned NOT NULL DEFAULT 0,
  `bastok_cp` smallint(5) unsigned NOT NULL DEFAULT 0,
  `windurst_cp` smallint(5) unsigned NOT NULL DEFAULT 0,

  -- Special Currencies
  `imperial_standing` smallint(5) unsigned NOT NULL DEFAULT 0,
  `assault_points_lebros` smallint(5) unsigned NOT NULL DEFAULT 0,
  `assault_points_mamool` smallint(5) unsigned NOT NULL DEFAULT 0,
  -- ... (50+ assault/nyzul points)

  -- Abyssea
  `lunar_abyssites` tinyint(2) unsigned NOT NULL DEFAULT 0,
  `cruor` int(10) unsigned NOT NULL DEFAULT 0,
  `resistance_credits` smallint(5) unsigned NOT NULL DEFAULT 0,

  -- Modern Content
  `sparks` int(10) unsigned NOT NULL DEFAULT 0,
  `unity_accolades` int(10) unsigned NOT NULL DEFAULT 0,
  `bayld` int(10) unsigned NOT NULL DEFAULT 0,
  `hallmarks` int(10) unsigned NOT NULL DEFAULT 0,
  `mweya_plasm` int(10) unsigned NOT NULL DEFAULT 0,

  -- And 150+ more...

  PRIMARY KEY (`charid`)
) ENGINE=InnoDB;
```

### Account Tables

#### `accounts` - Player Accounts
```sql
CREATE TABLE `accounts` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `login` varchar(16) NOT NULL,
  `password` varchar(64) NOT NULL,
  `email` varchar(50) DEFAULT NULL,
  `status` tinyint(1) unsigned NOT NULL DEFAULT 1,
  `priv` tinyint(2) unsigned NOT NULL DEFAULT 0,
  `charcount` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `timecreate` timestamp NOT NULL DEFAULT current_timestamp(),
  `timelastmodify` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `login` (`login`)
) ENGINE=InnoDB;
```

**Privilege Levels** (`priv`):
- 0: Normal player
- 1-5: GM levels (increasing permissions)

#### `accounts_sessions` - Active Sessions
```sql
CREATE TABLE `accounts_sessions` (
  `accid` int(10) unsigned NOT NULL,
  `charid` int(10) unsigned NOT NULL,
  `session_key` blob NOT NULL,
  `server_addr` int(10) unsigned NOT NULL DEFAULT 0,
  `server_port` smallint(5) unsigned NOT NULL DEFAULT 0,
  `client_addr` int(10) unsigned NOT NULL DEFAULT 0,
  `client_port` smallint(5) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`accid`),
  KEY `charid` (`charid`)
) ENGINE=InnoDB;
```

**Example: Get Online Players**
```sql
SELECT
  c.charid,
  c.charname,
  c.mjob,
  c.mlvl,
  c.pos_zone,
  zs.name as zone_name,
  INET_NTOA(s.client_addr) as client_ip
FROM accounts_sessions s
JOIN chars c ON s.charid = c.charid
LEFT JOIN zone_settings zs ON c.pos_zone = zs.zoneid
ORDER BY c.charname;
```

---

## Item System

### Item Table Structure

```
item_basic (1) ──< (0-1) item_equipment
               ├──< (0-1) item_weapon
               ├──< (0-1) item_armor
               ├──< (N) item_mods
               └──< (N) item_latents
```

### `item_basic` - Core Item Data
```sql
CREATE TABLE `item_basic` (
  `itemid` smallint(5) unsigned NOT NULL,
  `name` varchar(28) NOT NULL,
  `sortname` varchar(20) NOT NULL,
  `stackSize` smallint(4) unsigned NOT NULL DEFAULT 1,
  `flags` int(10) unsigned NOT NULL DEFAULT 0,
  `aH` tinyint(2) unsigned NOT NULL DEFAULT 0,
  `NoSale` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `BaseSell` int(10) NOT NULL DEFAULT 0,
  PRIMARY KEY (`itemid`),
  KEY `name` (`name`)
) ENGINE=Aria;
```

**Item Flags** (bitfield):
- 0x0001: Rare (can only have 1)
- 0x0002: Ex (cannot trade)
- 0x0004: Equippable
- 0x0008: Not sendable
- 0x0040: No AH (cannot auction)

**Example: Search Items**
```sql
SELECT itemid, name, BaseSell, stackSize
FROM item_basic
WHERE name LIKE ?
ORDER BY name
LIMIT 50;
```

### `item_equipment` - Equipment Stats
```sql
CREATE TABLE `item_equipment` (
  `itemId` smallint(5) unsigned NOT NULL,
  `jobs` int(10) unsigned NOT NULL DEFAULT 0,
  `level` tinyint(2) unsigned NOT NULL DEFAULT 0,
  `slots` int(10) unsigned NOT NULL DEFAULT 0,
  `races` int(10) unsigned NOT NULL DEFAULT 0,
  `slot` tinyint(2) unsigned NOT NULL DEFAULT 0,

  -- Stats
  `HP` smallint(4) NOT NULL DEFAULT 0,
  `MP` smallint(4) NOT NULL DEFAULT 0,
  `STR` smallint(3) NOT NULL DEFAULT 0,
  `DEX` smallint(3) NOT NULL DEFAULT 0,
  `VIT` smallint(3) NOT NULL DEFAULT 0,
  `AGI` smallint(3) NOT NULL DEFAULT 0,
  `INT` smallint(3) NOT NULL DEFAULT 0,
  `MND` smallint(3) NOT NULL DEFAULT 0,
  `CHR` smallint(3) NOT NULL DEFAULT 0,

  -- Combat Stats
  `DEF` smallint(4) NOT NULL DEFAULT 0,
  `ATT` smallint(3) NOT NULL DEFAULT 0,
  `ACC` smallint(3) NOT NULL DEFAULT 0,
  `EVA` smallint(3) NOT NULL DEFAULT 0,

  PRIMARY KEY (`itemId`)
) ENGINE=Aria;
```

**Jobs Bitfield** (`jobs` column):
- Bit 0 (value 1): WAR (Warrior)
- Bit 1 (value 2): MNK (Monk)
- Bit 2 (value 4): WHM (White Mage)
- Bit 3 (value 8): BLM (Black Mage)
- Bit 4 (value 16): RDM (Red Mage)
- Bit 5 (value 32): THF (Thief)
- Bit 6 (value 64): PLD (Paladin)
- Bit 7 (value 128): DRK (Dark Knight)
- Bit 8 (value 256): BST (Beastmaster)
- Bit 9 (value 512): BRD (Bard)
- Bit 10 (value 1024): RNG (Ranger)
- Bit 11 (value 2048): SAM (Samurai)
- Bit 12 (value 4096): NIN (Ninja)
- Bit 13 (value 8192): DRG (Dragoon)
- Bit 14 (value 16384): SMN (Summoner)
- Bit 15 (value 32768): BLU (Blue Mage)
- Bit 16 (value 65536): COR (Corsair)
- Bit 17 (value 131072): PUP (Puppetmaster)
- Bit 18 (value 262144): DNC (Dancer)
- Bit 19 (value 524288): SCH (Scholar)
- Bit 20 (value 1048576): GEO (Geomancer)
- Bit 21 (value 2097152): RUN (Rune Fencer)

**Example: Find Equipment for WAR Level 50**
```sql
SELECT
  ib.itemid,
  ib.name,
  ie.level,
  ie.slot,
  ie.DEF,
  ie.HP,
  ie.STR
FROM item_basic ib
JOIN item_equipment ie ON ib.itemid = ie.itemId
WHERE ie.jobs & 1 > 0  -- WAR (bit 0)
  AND ie.level <= 50
  AND ie.slot = 5        -- Body slot
ORDER BY ie.level DESC, ie.DEF DESC;
```

**Working with Jobs Bitfield in Code**:

```typescript
// Job constants
const Jobs = {
  WAR: 1,      // 2^0
  MNK: 2,      // 2^1
  WHM: 4,      // 2^2
  BLM: 8,      // 2^3
  RDM: 16,     // 2^4
  THF: 32,     // 2^5
  PLD: 64,     // 2^6
  DRK: 128,    // 2^7
  BST: 256,    // 2^8
  BRD: 512,    // 2^9
  RNG: 1024,   // 2^10
  SAM: 2048,   // 2^11
  NIN: 4096,   // 2^12
  DRG: 8192,   // 2^13
  SMN: 16384,  // 2^14
  BLU: 32768,  // 2^15
  COR: 65536,  // 2^16
  PUP: 131072, // 2^17
  DNC: 262144, // 2^18
  SCH: 524288, // 2^19
  GEO: 1048576,   // 2^20
  RUN: 2097152    // 2^21
};

// Check if item can be equipped by job
function canJobEquip(jobsBitfield: number, job: number): boolean {
  return (jobsBitfield & job) !== 0;
}

// Example usage
const itemJobs = 15; // WAR + MNK + WHM + BLM (1 + 2 + 4 + 8)
console.log(canJobEquip(itemJobs, Jobs.WAR)); // true
console.log(canJobEquip(itemJobs, Jobs.THF)); // false

// Get all jobs that can equip an item
function getEquippableJobs(jobsBitfield: number): string[] {
  const jobs: string[] = [];
  const jobNames = Object.keys(Jobs) as (keyof typeof Jobs)[];

  for (const jobName of jobNames) {
    if (canJobEquip(jobsBitfield, Jobs[jobName])) {
      jobs.push(jobName);
    }
  }

  return jobs;
}

console.log(getEquippableJobs(15)); // ['WAR', 'MNK', 'WHM', 'BLM']

// Filter equipment by multiple jobs (WAR OR PLD)
const [rows] = await pool.execute(
  `SELECT * FROM item_equipment
   WHERE (jobs & ? > 0 OR jobs & ? > 0) AND level <= ?`,
  [Jobs.WAR, Jobs.PLD, 50]
);
```

### `item_weapon` - Weapon Stats
```sql
CREATE TABLE `item_weapon` (
  `itemId` smallint(5) unsigned NOT NULL,
  `damage` smallint(3) unsigned NOT NULL DEFAULT 0,
  `dmgType` tinyint(2) NOT NULL DEFAULT 0,
  `delay` smallint(4) NOT NULL DEFAULT 0,
  `skill` tinyint(2) unsigned NOT NULL DEFAULT 0,
  `hit` smallint(3) NOT NULL DEFAULT 0,
  `unlock_points` smallint(5) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`itemId`)
) ENGINE=Aria;
```

**Damage Types**:
- 0: None, 1: Piercing, 2: Slashing, 3: Blunt, 4: H2H
- 5: Ranged

**Weapon Skills**:
- 1: Hand-to-Hand, 2: Dagger, 3: Sword, 4: Great Sword
- 5: Axe, 6: Great Axe, 7: Scythe, 8: Polearm
- 9: Katana, 10: Great Katana, 11: Club, 12: Staff
- 25: Archery, 26: Marksmanship, 27: Throwing

**Example: Calculate DPS**
```sql
SELECT
  ib.itemid,
  ib.name,
  iw.damage,
  iw.delay,
  iw.skill,
  (iw.damage / (iw.delay / 1000.0)) as dps
FROM item_basic ib
JOIN item_weapon iw ON ib.itemid = iw.itemId
WHERE iw.skill = 3  -- Sword
ORDER BY dps DESC
LIMIT 20;
```

---

## Monster System

### Mob Table Structure

```
mob_pools (1) ──< (N) mob_spawn_points
               └──< (N) mob_groups ──< (1) mob_droplist ──< (N) item_basic
```

### `mob_spawn_points` - Spawn Locations
```sql
CREATE TABLE `mob_spawn_points` (
  `mobid` int(10) unsigned NOT NULL,
  `mobname` varchar(24) NOT NULL,
  `groupid` tinyint(2) unsigned NOT NULL,
  `poolid` smallint(4) unsigned NOT NULL,
  `pos_x` float NOT NULL DEFAULT 0,
  `pos_y` float NOT NULL DEFAULT 0,
  `pos_z` float NOT NULL DEFAULT 0,
  `pos_rot` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `respawn` int(10) unsigned NOT NULL DEFAULT 240,
  PRIMARY KEY (`mobid`)
) ENGINE=Aria;
```

**Example: Find Mobs in Zone**
```sql
-- Mob IDs are zone-based: zone * 1000000 + mob_number
SELECT mobid, mobname, pos_x, pos_y, pos_z, respawn
FROM mob_spawn_points
WHERE mobid BETWEEN 17195008 AND 17195999  -- Valkurm Dunes (zone 103)
ORDER BY mobname;
```

### `mob_pools` - Mob Stats & AI
```sql
CREATE TABLE `mob_pools` (
  `poolid` smallint(4) unsigned NOT NULL,
  `name` varchar(24) NOT NULL,
  `mJob` tinyint(2) unsigned NOT NULL DEFAULT 0,
  `sJob` tinyint(2) unsigned NOT NULL DEFAULT 0,
  `minLevel` tinyint(2) unsigned NOT NULL DEFAULT 1,
  `maxLevel` tinyint(2) unsigned NOT NULL DEFAULT 1,
  `allegiance` tinyint(2) unsigned NOT NULL DEFAULT 0,
  `systemid` smallint(4) unsigned NOT NULL DEFAULT 0,
  `behavior` smallint(5) unsigned NOT NULL DEFAULT 0,
  `aggro` tinyint(2) unsigned NOT NULL DEFAULT 0,
  `true_detection` tinyint(2) unsigned NOT NULL DEFAULT 0,
  `links` tinyint(2) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`poolid`)
) ENGINE=Aria;
```

**System ID**:
- 0: Normal mob
- 2: Notorious Monster (NM)
- 3: Battlefield/Instance mob

**Aggro Types**:
- 0x01: Sight, 0x02: Sound, 0x04: Scent
- 0x08: True Sight, 0x10: True Sound
- 0x20: Magic detection, 0x40: Heal detection

### `mob_droplist` & `mob_groups` - Drop Tables
```sql
CREATE TABLE `mob_droplist` (
  `dropid` mediumint(7) unsigned NOT NULL,
  `droptype` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `groupid` tinyint(2) unsigned NOT NULL DEFAULT 0,
  `itemid` smallint(5) unsigned NOT NULL DEFAULT 0,
  `itemRate` smallint(5) unsigned NOT NULL DEFAULT 1000,
  PRIMARY KEY (`dropid`,`droptype`,`groupid`,`itemid`)
) ENGINE=Aria;

CREATE TABLE `mob_groups` (
  `groupid` smallint(4) unsigned NOT NULL,
  `poolid` smallint(4) unsigned NOT NULL,
  `zoneid` smallint(3) unsigned NOT NULL,
  `dropid` mediumint(7) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`groupid`,`poolid`,`zoneid`)
) ENGINE=Aria;
```

**Drop Types**:
- 0: Normal drop
- 1: Steal
- 2: Desynthesis

**Item Rate**: Out of 1000 (10 = 1%, 100 = 10%, 1000 = 100%)

**Example: Get Mob Drops**
```sql
SELECT
  ml.itemid,
  ib.name,
  ml.itemRate,
  (ml.itemRate / 10.0) as drop_percent,
  CASE ml.droptype
    WHEN 0 THEN 'Normal'
    WHEN 1 THEN 'Steal'
    WHEN 2 THEN 'Desynth'
  END as drop_type
FROM mob_spawn_points msp
JOIN mob_groups mg ON msp.poolid = mg.poolid
JOIN mob_droplist ml ON mg.dropid = ml.dropid
JOIN item_basic ib ON ml.itemid = ib.itemid
WHERE msp.mobid = ?
ORDER BY ml.itemRate DESC;
```

**Example: Find Where Item Drops**
```sql
SELECT
  msp.mobname,
  ml.itemRate,
  (ml.itemRate / 10.0) as drop_percent,
  mp.minLevel,
  mp.maxLevel,
  FLOOR(msp.mobid / 1000000) as zone_id
FROM mob_droplist ml
JOIN mob_groups mg ON ml.dropid = mg.dropid
JOIN mob_spawn_points msp ON mg.poolid = msp.poolid
JOIN mob_pools mp ON msp.poolid = mp.poolid
WHERE ml.itemid = ?
ORDER BY ml.itemRate DESC;
```

---

## Economy & Auction House

### `auction_house` - Market Listings
```sql
CREATE TABLE `auction_house` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `seller` int(10) unsigned NOT NULL DEFAULT 0,
  `seller_name` varchar(15) NOT NULL,
  `buyer_name` varchar(15) DEFAULT NULL,
  `itemid` smallint(5) unsigned NOT NULL DEFAULT 0,
  `quantity` int(10) unsigned NOT NULL DEFAULT 0,
  `sell_price` int(10) unsigned NOT NULL DEFAULT 0,
  `date` int(10) unsigned NOT NULL DEFAULT 0,
  `sale` int(10) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `seller` (`seller`),
  KEY `itemid` (`itemid`,`sale`)
) ENGINE=InnoDB;
```

**Key Fields**:
- `date`: Unix timestamp when listed
- `sale`: Unix timestamp when sold (0 = still active)

**Example: Active Listings for Item**
```sql
SELECT
  id,
  seller_name,
  quantity,
  sell_price,
  (sell_price / quantity) as price_per_unit,
  FROM_UNIXTIME(date) as listed_at
FROM auction_house
WHERE itemid = ? AND sale = 0
ORDER BY sell_price ASC
LIMIT 20;
```

**Example: Price History**
```sql
SELECT
  sell_price,
  quantity,
  (sell_price / quantity) as price_per_unit,
  FROM_UNIXTIME(sale) as sold_at
FROM auction_house
WHERE itemid = ? AND sale > 0
ORDER BY sale DESC
LIMIT 100;
```

**Example: Market Summary**
```sql
SELECT
  COUNT(CASE WHEN sale = 0 THEN 1 END) as active_listings,
  MIN(CASE WHEN sale = 0 THEN sell_price END) as lowest_price,
  AVG(CASE WHEN sale > 0 AND sale > UNIX_TIMESTAMP(NOW() - INTERVAL 7 DAY)
      THEN sell_price END) as avg_price_7d,
  COUNT(CASE WHEN sale > UNIX_TIMESTAMP(NOW() - INTERVAL 7 DAY)
      THEN 1 END) as sales_7d,
  SUM(CASE WHEN sale > UNIX_TIMESTAMP(NOW() - INTERVAL 7 DAY)
      THEN sell_price END) as volume_7d
FROM auction_house
WHERE itemid = ?;
```

---

## Working with Binary Blobs

### Understanding Blob Fields

The `chars` table contains **12 blob fields** that store complex data structures:

- `missions` - Mission progress (all expansions)
- `assault` - Assault mission data
- `campaign` - Campaign progress
- `eminence` - Records of Eminence
- `quests` - Quest completion flags
- `keyitems` - Key item ownership
- `abilities` - Learned abilities
- `weaponskills` - Weapon skill unlocks
- `titles` - Title unlocks
- `zones` - Visited zones
- `set_blue_spells` - Blue mage spell sets
- `unlocked_weapons` - Relic/Mythic/Empyrean progress

### Blob Structure

Blobs are **bit-packed arrays** where each bit represents a flag:

```
Byte 0: [bit7][bit6][bit5][bit4][bit3][bit2][bit1][bit0]
Byte 1: [bit15][bit14][bit13][bit12][bit11][bit10][bit9][bit8]
...
```

**For ID 42**:
- Byte index = 42 / 8 = 5
- Bit index = 42 % 8 = 2

### Reading Blobs (Example: Python)

```python
def check_keyitem(blob: bytes, keyitem_id: int) -> bool:
    """Check if player has a key item"""
    if blob is None:
        return False

    byte_index = keyitem_id // 8
    bit_index = keyitem_id % 8

    if byte_index >= len(blob):
        return False

    return (blob[byte_index] & (1 << bit_index)) != 0

def add_keyitem(blob: bytes, keyitem_id: int) -> bytes:
    """Add a key item to the blob"""
    byte_index = keyitem_id // 8
    bit_index = keyitem_id % 8

    # Ensure blob is large enough
    if byte_index >= len(blob):
        blob = blob + b'\x00' * (byte_index - len(blob) + 1)

    blob_array = bytearray(blob)
    blob_array[byte_index] |= (1 << bit_index)
    return bytes(blob_array)
```

### Reading Blobs (Example: TypeScript)

```typescript
function checkKeyItem(blob: Buffer | null, keyItemId: number): boolean {
  if (!blob) return false;

  const byteIndex = Math.floor(keyItemId / 8);
  const bitIndex = keyItemId % 8;

  if (byteIndex >= blob.length) return false;

  return (blob[byteIndex] & (1 << bitIndex)) !== 0;
}

function addKeyItem(blob: Buffer, keyItemId: number): Buffer {
  const byteIndex = Math.floor(keyItemId / 8);
  const bitIndex = keyItemId % 8;

  // Ensure buffer is large enough
  if (byteIndex >= blob.length) {
    const newBlob = Buffer.alloc(byteIndex + 1);
    blob.copy(newBlob);
    blob = newBlob;
  }

  blob[byteIndex] |= (1 << bitIndex);
  return blob;
}

// Example: Get all key items a player has
function getKeyItems(blob: Buffer): number[] {
  const keyItems: number[] = [];

  for (let byte_idx = 0; byte_idx < blob.length; byte_idx++) {
    for (let bit_idx = 0; bit_idx < 8; bit_idx++) {
      if (blob[byte_idx] & (1 << bit_idx)) {
        keyItems.push(byte_idx * 8 + bit_idx);
      }
    }
  }

  return keyItems;
}
```

### ⚠️ Critical Warning About Blobs

**DO NOT modify blob fields directly unless you fully understand their structure!**

Reasons:
1. **Complex structure**: Not just simple bitfields - some have variable-length records
2. **Version-dependent**: Structure may change between LSB versions
3. **Data corruption risk**: Invalid data can crash the server or corrupt characters
4. **Mission dependencies**: Some blobs have interdependencies

**Recommended Approach**:
- Read blobs for display/querying (safe)
- Use LSB's Lua scripting for modifications
- Use GM commands for testing
- Never directly UPDATE blob fields in production

---

## Transactions & Data Integrity

### When to Use Transactions

LSB uses transactions for operations that span multiple tables:

1. **Character Creation** - Insert into `chars`, `char_stats`, `char_jobs`, `char_skills`, `char_profile`, `char_points`, `char_storage`, `char_unlocks`, `char_look`, `char_exp` (all auto-initialized via triggers)
2. **Item Transfers** - Update `char_inventory` for both sender and receiver
3. **Auction House Sales** - Update `auction_house`, create `delivery_box` record
4. **Character Deletion** - Delete from all 28 character-related tables (cascaded via `char_delete` trigger)

### Transaction Pattern (SQL)

```sql
START TRANSACTION;

-- Multiple operations
UPDATE chars SET hp = 0, deaths = deaths + 1 WHERE charid = ?;
INSERT INTO char_history (charid, event, timestamp) VALUES (?, 'death', NOW());

-- Check for errors
COMMIT; -- or ROLLBACK on error
```

### Transaction Pattern (Python)

```python
import mariadb

conn = mariadb.connect(
    host="127.0.0.1",
    user="xiserver",
    password="xiserver",
    database="xidb"
)

try:
    cursor = conn.cursor()

    # Disable autocommit
    conn.autocommit = False

    # Perform operations
    cursor.execute("UPDATE chars SET hp = 0 WHERE charid = %s", (charid,))
    cursor.execute("INSERT INTO char_history (charid, event) VALUES (%s, 'death')", (charid,))

    # Commit if all successful
    conn.commit()

except mariadb.Error as e:
    # Rollback on error
    conn.rollback()
    print(f"Transaction failed: {e}")

finally:
    cursor.close()
    conn.close()
```

### Transaction Pattern (TypeScript/Node.js)

```typescript
import mysql from 'mysql2/promise';

const pool = mysql.createPool({
  host: '127.0.0.1',
  user: 'xiserver',
  password: 'xiserver',
  database: 'xidb'
});

async function transferItem(
  fromCharId: number,
  toCharId: number,
  itemId: number,
  quantity: number
) {
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    // Remove from sender
    await connection.execute(
      `DELETE FROM char_inventory
       WHERE charid = ? AND itemId = ? AND quantity >= ?`,
      [fromCharId, itemId, quantity]
    );

    // Add to receiver (find empty slot first)
    const [slots] = await connection.execute(
      `SELECT MIN(s.slot) as slot FROM
       (SELECT 0 as slot UNION SELECT 1 /* ... up to 79 */) s
       LEFT JOIN char_inventory ci ON s.slot = ci.slot AND ci.charid = ?
       WHERE ci.slot IS NULL`,
      [toCharId]
    );

    await connection.execute(
      `INSERT INTO char_inventory (charid, location, slot, itemId, quantity)
       VALUES (?, 0, ?, ?, ?)`,
      [toCharId, slots[0].slot, itemId, quantity]
    );

    await connection.commit();
    return true;

  } catch (error) {
    await connection.rollback();
    console.error('Transaction failed:', error);
    return false;

  } finally {
    connection.release();
  }
}
```

### Database Triggers

LSB includes several important triggers in `sql/triggers.sql`:

#### `char_delete` - Cascading Character Deletion

Deletes from all 28 character-related tables:

```sql
DELIMITER $$
CREATE TRIGGER char_delete
BEFORE DELETE ON chars
FOR EACH ROW
BEGIN
  DELETE FROM char_stats WHERE charid = OLD.charid;
  DELETE FROM char_jobs WHERE charid = OLD.charid;
  DELETE FROM char_inventory WHERE charid = OLD.charid;
  DELETE FROM char_storage WHERE charid = OLD.charid;
  DELETE FROM char_equip WHERE charid = OLD.charid;
  DELETE FROM char_profile WHERE charid = OLD.charid;
  DELETE FROM char_skills WHERE charid = OLD.charid;
  DELETE FROM char_spells WHERE charid = OLD.charid;
  DELETE FROM char_points WHERE charid = OLD.charid;
  DELETE FROM char_look WHERE charid = OLD.charid;
  DELETE FROM char_unlocks WHERE charid = OLD.charid;
  DELETE FROM char_vars WHERE charid = OLD.charid;
  DELETE FROM char_effects WHERE charid = OLD.charid;
  DELETE FROM char_exp WHERE charid = OLD.charid;
  DELETE FROM char_pet WHERE charid = OLD.charid;
  DELETE FROM char_recast WHERE charid = OLD.charid;
  DELETE FROM char_merit WHERE charid = OLD.charid;
  DELETE FROM char_job_points WHERE charid = OLD.charid;
  DELETE FROM char_blacklist WHERE charid = OLD.charid;
  DELETE FROM char_monstrosity WHERE charid = OLD.charid;
  DELETE FROM char_style WHERE charid = OLD.charid;
  DELETE FROM char_equip_saved WHERE charid = OLD.charid;
  DELETE FROM char_chocobos WHERE charid = OLD.charid;
  DELETE FROM char_history WHERE charid = OLD.charid;
  DELETE FROM char_fishing_contest_history WHERE charid = OLD.charid;
  DELETE FROM char_flags WHERE charid = OLD.charid;
END$$
DELIMITER ;
```

#### `char_insert` - Auto-initialization

Initializes 10+ supporting tables when a character is created:

```sql
DELIMITER $$
CREATE TRIGGER char_insert
AFTER INSERT ON chars
FOR EACH ROW
BEGIN
  INSERT INTO char_stats (charid) VALUES (NEW.charid);
  INSERT INTO char_jobs (charid) VALUES (NEW.charid);
  INSERT INTO char_profile (charid) VALUES (NEW.charid);
  INSERT INTO char_skills (charid) VALUES (NEW.charid);
  INSERT INTO char_points (charid) VALUES (NEW.charid);
  INSERT INTO char_storage (charid) VALUES (NEW.charid);
  INSERT INTO char_unlocks (charid) VALUES (NEW.charid);
  INSERT INTO char_look (charid, race, face) VALUES (NEW.charid, 0, 0);
  INSERT INTO char_exp (charid) VALUES (NEW.charid);
  INSERT INTO char_style (charid) VALUES (NEW.charid);
  -- Additional tables initialized as needed
END$$
DELIMITER ;
```

---

## Common Query Patterns

### Character Queries

#### Get Character with Full Details
```sql
SELECT
  c.*,
  cs.str, cs.dex, cs.vit, cs.agi, cs.int, cs.mnd, cs.chr,
  cs.hp as max_hp, cs.mp as max_mp,
  cp.rank, cp.rankpoints,
  cp.fame_sandoria, cp.fame_bastok, cp.fame_windurst,
  cj.war, cj.mnk, cj.whm, cj.blm, cj.rdm, cj.thf,
  cj.pld, cj.drk, cj.bst, cj.brd, cj.rng, cj.sam,
  cj.nin, cj.drg, cj.smn, cj.blu, cj.cor, cj.pup,
  cj.dnc, cj.sch, cj.geo, cj.run,
  cl.race, cl.face, cl.head, cl.body
FROM chars c
LEFT JOIN char_stats cs ON c.charid = cs.charid
LEFT JOIN char_profile cp ON c.charid = cp.charid
LEFT JOIN char_jobs cj ON c.charid = cj.charid
LEFT JOIN char_look cl ON c.charid = cl.charid
WHERE c.charid = ?;
```

#### Search Characters
```sql
SELECT
  c.charid,
  c.charname,
  c.mjob,
  c.mlvl,
  c.nation,
  CASE
    WHEN s.charid IS NOT NULL THEN 'Online'
    ELSE 'Offline'
  END as status
FROM chars c
LEFT JOIN accounts_sessions s ON c.charid = s.charid
WHERE c.charname LIKE CONCAT('%', ?, '%')
ORDER BY c.charname
LIMIT 20;
```

#### Get Online Players by Zone
```sql
SELECT
  c.pos_zone,
  zs.name as zone_name,
  COUNT(*) as player_count,
  GROUP_CONCAT(c.charname ORDER BY c.charname SEPARATOR ', ') as players
FROM accounts_sessions s
JOIN chars c ON s.charid = c.charid
LEFT JOIN zone_settings zs ON c.pos_zone = zs.zoneid
GROUP BY c.pos_zone, zs.name
ORDER BY player_count DESC;
```

### Item Queries

#### Get Complete Item Data
```sql
SELECT
  ib.*,
  ie.jobs, ie.level, ie.races, ie.slot,
  ie.HP, ie.MP, ie.STR, ie.DEX, ie.VIT, ie.AGI, ie.INT, ie.MND, ie.CHR,
  ie.DEF, ie.ATT, ie.ACC, ie.EVA,
  iw.damage, iw.delay, iw.skill, iw.dmgType,
  CASE
    WHEN iw.itemId IS NOT NULL THEN 'weapon'
    WHEN ie.itemId IS NOT NULL THEN 'equipment'
    ELSE 'item'
  END as item_type
FROM item_basic ib
LEFT JOIN item_equipment ie ON ib.itemid = ie.itemId
LEFT JOIN item_weapon iw ON ib.itemid = iw.itemId
WHERE ib.itemid = ?;
```

#### Find Equipment for Job/Level
```sql
SELECT
  ib.itemid,
  ib.name,
  ie.level,
  ie.slot,
  ie.DEF,
  ie.HP,
  ie.STR,
  CASE ie.slot
    WHEN 0 THEN 'Main' WHEN 1 THEN 'Sub' WHEN 2 THEN 'Ranged'
    WHEN 3 THEN 'Ammo' WHEN 4 THEN 'Head' WHEN 5 THEN 'Body'
    WHEN 6 THEN 'Hands' WHEN 7 THEN 'Legs' WHEN 8 THEN 'Feet'
    WHEN 9 THEN 'Neck' WHEN 10 THEN 'Waist' WHEN 11 THEN 'Ear'
    WHEN 13 THEN 'Ring' WHEN 15 THEN 'Back'
  END as slot_name
FROM item_basic ib
JOIN item_equipment ie ON ib.itemid = ie.itemId
WHERE ie.jobs & ? > 0  -- Job bitfield: 1=WAR, 2=MNK, 4=WHM, 8=BLM, 16=RDM, 32=THF, 64=PLD, 128=DRK, 256=BST, 512=BRD, 1024=RNG, 2048=SAM, 4096=NIN, 8192=DRG, 16384=SMN, 32768=BLU, 65536=COR, 131072=PUP, 262144=DNC, 524288=SCH, 1048576=GEO, 2097152=RUN
  AND ie.level <= ?
  AND ie.level >= ?
ORDER BY ie.level DESC, ie.DEF DESC;
```

### Inventory Queries

#### Character Inventory Value
```sql
SELECT
  c.charid,
  c.charname,
  COUNT(ci.itemId) as item_count,
  SUM(ci.quantity) as total_items,
  SUM(ib.BaseSell * ci.quantity) as total_value
FROM chars c
LEFT JOIN char_inventory ci ON c.charid = ci.charid AND ci.location = 0
LEFT JOIN item_basic ib ON ci.itemId = ib.itemid
WHERE c.charid = ?
GROUP BY c.charid, c.charname;
```

#### Find Who Owns Item
```sql
SELECT
  c.charid,
  c.charname,
  ci.quantity,
  ci.location,
  CASE ci.location
    WHEN 0 THEN 'Inventory'
    WHEN 1 THEN 'Mog Safe'
    WHEN 2 THEN 'Storage'
    ELSE 'Other'
  END as container_name
FROM char_inventory ci
JOIN chars c ON ci.charid = c.charid
WHERE ci.itemId = ?
ORDER BY ci.quantity DESC
LIMIT 50;
```

---

## API Development Best Practices

### 1. Connection Management

**Use Connection Pooling**:
```typescript
// DON'T: Create new connection per request
async function getCharacter(id: number) {
  const conn = await mysql.createConnection({...});
  const result = await conn.query('SELECT * FROM chars WHERE charid = ?', [id]);
  await conn.end();
  return result;
}

// DO: Use connection pool
const pool = mysql.createPool({
  host: '127.0.0.1',
  user: 'xiserver',
  password: 'xiserver',
  database: 'xidb',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

async function getCharacter(id: number) {
  const [rows] = await pool.execute(
    'SELECT * FROM chars WHERE charid = ?',
    [id]
  );
  return rows[0];
}
```

### 2. Parameterized Queries

**Always use prepared statements** to prevent SQL injection:

```typescript
// ❌ NEVER DO THIS - SQL Injection vulnerability
async function searchCharacters(name: string) {
  const query = `SELECT * FROM chars WHERE charname LIKE '%${name}%'`;
  return await pool.query(query);
}

// ✅ ALWAYS DO THIS - Parameterized query
async function searchCharacters(name: string) {
  const [rows] = await pool.execute(
    'SELECT * FROM chars WHERE charname LIKE ?',
    [`%${name}%`]
  );
  return rows;
}
```

### 3. Data Validation

```typescript
interface CreateCharacterRequest {
  accid: number;
  charname: string;
  nation: number;
  mjob: number;
}

function validateCreateCharacter(data: any): CreateCharacterRequest {
  // Validate account exists
  if (!data.accid || typeof data.accid !== 'number') {
    throw new Error('Invalid account ID');
  }

  // Validate character name (1-15 chars, alphanumeric)
  if (!data.charname || data.charname.length > 15 ||
      !/^[a-zA-Z0-9]+$/.test(data.charname)) {
    throw new Error('Invalid character name');
  }

  // Validate nation (0-2)
  if (data.nation < 0 || data.nation > 2) {
    throw new Error('Invalid nation');
  }

  // Validate job (1-22)
  if (data.mjob < 1 || data.mjob > 22) {
    throw new Error('Invalid job');
  }

  return data as CreateCharacterRequest;
}
```

### 4. Error Handling

```typescript
async function getCharacter(charid: number) {
  try {
    const [rows] = await pool.execute(
      'SELECT * FROM chars WHERE charid = ?',
      [charid]
    );

    if (rows.length === 0) {
      return { error: 'Character not found', status: 404 };
    }

    return { data: rows[0], status: 200 };

  } catch (error) {
    console.error('Database error:', error);
    return { error: 'Internal server error', status: 500 };
  }
}
```

### 5. Pagination

```sql
-- Get page of results
SELECT charid, charname, mjob, mlvl
FROM chars
ORDER BY charid
LIMIT ? OFFSET ?;

-- Get total count for pagination
SELECT COUNT(*) as total FROM chars;
```

```typescript
interface PaginationParams {
  page: number;
  pageSize: number;
}

async function getCharactersPaginated(params: PaginationParams) {
  const offset = (params.page - 1) * params.pageSize;

  const [rows] = await pool.execute(
    'SELECT charid, charname, mjob, mlvl FROM chars ORDER BY charid LIMIT ? OFFSET ?',
    [params.pageSize, offset]
  );

  const [[{ total }]] = await pool.execute('SELECT COUNT(*) as total FROM chars');

  return {
    data: rows,
    pagination: {
      page: params.page,
      pageSize: params.pageSize,
      total: total,
      pages: Math.ceil(total / params.pageSize)
    }
  };
}
```

### 6. Caching Strategy

```typescript
import { createClient } from 'redis';

const redis = createClient();
await redis.connect();

async function getItem(itemId: number) {
  // Check cache first
  const cached = await redis.get(`item:${itemId}`);
  if (cached) {
    return JSON.parse(cached);
  }

  // Query database
  const [rows] = await pool.execute(
    `SELECT ib.*, ie.*, iw.*
     FROM item_basic ib
     LEFT JOIN item_equipment ie ON ib.itemid = ie.itemId
     LEFT JOIN item_weapon iw ON ib.itemid = iw.itemId
     WHERE ib.itemid = ?`,
    [itemId]
  );

  const item = rows[0];

  // Cache for 1 hour (items rarely change)
  await redis.setEx(`item:${itemId}`, 3600, JSON.stringify(item));

  return item;
}
```

### 7. Read-Only vs Write Operations

```typescript
// Use read-only user for query-only operations
const readPool = mysql.createPool({
  host: '127.0.0.1',
  user: 'xiserver_readonly',  // Limited permissions
  password: '...',
  database: 'xidb',
  connectionLimit: 20  // More connections for reads
});

// Use write user only when needed
const writePool = mysql.createPool({
  host: '127.0.0.1',
  user: 'xiserver',
  password: '...',
  database: 'xidb',
  connectionLimit: 5  // Fewer connections for writes
});

// Read operation
async function getCharacter(id: number) {
  return await readPool.execute('SELECT * FROM chars WHERE charid = ?', [id]);
}

// Write operation (admin only)
async function updateCharacter(id: number, data: any) {
  return await writePool.execute(
    'UPDATE chars SET pos_zone = ? WHERE charid = ?',
    [data.zone, id]
  );
}
```

### 8. Rate Limiting

```typescript
import rateLimit from 'express-rate-limit';

// Limit API requests
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // 100 requests per window
  message: 'Too many requests from this IP'
});

app.use('/api/', limiter);

// Stricter limits for write operations
const writeLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10, // Only 10 write operations per 15 minutes
});

app.use('/api/admin/', writeLimiter);
```

### 9. Audit Logging

```typescript
async function logAdminAction(
  adminId: number,
  action: string,
  targetId: number,
  details: string
) {
  await pool.execute(
    `INSERT INTO audit_gm (gmid, command, target, details, timestamp)
     VALUES (?, ?, ?, ?, NOW())`,
    [adminId, action, targetId, details]
  );
}

// Example usage
async function teleportCharacter(
  adminId: number,
  charid: number,
  zoneId: number
) {
  await pool.execute(
    'UPDATE chars SET pos_zone = ?, pos_x = 0, pos_y = 0, pos_z = 0 WHERE charid = ?',
    [zoneId, charid]
  );

  await logAdminAction(
    adminId,
    'TELEPORT',
    charid,
    `Teleported to zone ${zoneId}`
  );
}
```

### 10. Database Health Monitoring

```typescript
async function checkDatabaseHealth() {
  try {
    const [result] = await pool.execute('SELECT 1');

    const stats = {
      connected: true,
      activeConnections: pool.pool._allConnections.length,
      freeConnections: pool.pool._freeConnections.length,
      timestamp: new Date()
    };

    return stats;

  } catch (error) {
    return {
      connected: false,
      error: error.message,
      timestamp: new Date()
    };
  }
}

// Endpoint for monitoring
app.get('/health/database', async (req, res) => {
  const health = await checkDatabaseHealth();
  const status = health.connected ? 200 : 503;
  res.status(status).json(health);
});
```

---

## Performance Optimization

### Indexes

LSB includes these key indexes:

```sql
-- Character lookups
ALTER TABLE chars ADD INDEX idx_accid (accid);
ALTER TABLE chars ADD INDEX idx_name (charname);
ALTER TABLE chars ADD INDEX idx_mjob (mjob);

-- Inventory
ALTER TABLE char_inventory ADD INDEX idx_itemId (itemId);
ALTER TABLE char_inventory ADD INDEX idx_char_loc (charid, location);

-- Sessions
ALTER TABLE accounts_sessions ADD INDEX idx_charid (charid);

-- Auction house
ALTER TABLE auction_house ADD INDEX idx_item_sale (itemid, sale);
ALTER TABLE auction_house ADD INDEX idx_seller (seller);

-- Mob drops
ALTER TABLE mob_droplist ADD INDEX idx_itemid (itemid);
```

### Query Optimization Tips

1. **Use EXPLAIN** to analyze queries
```sql
EXPLAIN SELECT * FROM chars WHERE charname LIKE '%test%';
```

2. **Limit result sets**
```sql
SELECT * FROM auction_house WHERE itemid = ? LIMIT 100;
```

3. **Use covering indexes**
```sql
-- Index includes all queried columns
CREATE INDEX idx_char_summary ON chars(charid, charname, mjob, mlvl);
SELECT charid, charname, mjob, mlvl FROM chars WHERE charid = ?;
```

4. **Avoid SELECT ***
```sql
-- Bad: Returns all 80+ columns
SELECT * FROM chars WHERE charid = ?;

-- Good: Only get what you need
SELECT charid, charname, mjob, mlvl, pos_zone FROM chars WHERE charid = ?;
```

5. **Use JOIN instead of multiple queries**
```sql
-- Bad: 3 separate queries
SELECT * FROM chars WHERE charid = ?;
SELECT * FROM char_stats WHERE charid = ?;
SELECT * FROM char_jobs WHERE charid = ?;

-- Good: Single query with JOIN
SELECT c.*, cs.*, cj.*
FROM chars c
LEFT JOIN char_stats cs ON c.charid = cs.charid
LEFT JOIN char_jobs cj ON c.charid = cj.charid
WHERE c.charid = ?;
```

---

## Appendix: Table Quick Reference

See the [Database Organization](#database-organization) section at the top of this document for a complete listing of all 124 tables organized by category.

### Most Commonly Used Tables for API Development

**Character Data:**
- `chars` - Main character record (80+ columns including binary blobs)
- `char_stats` - Base attributes (STR, DEX, VIT, AGI, INT, MND, CHR, HP, MP)
- `char_jobs` - All 22 job levels & experience values
- `char_skills` - Combat, magic, and crafting skills
- `char_inventory` - Items in all containers (0=Inventory, 1=Mog Safe, 2=Storage, 3=Temporary, 4=Mog Locker, 5=Mog Satchel, 6=Mog Sack, 7=Mog Case, 8=Wardrobe, 9=Mog Safe 2, 10=Wardrobe 2, 11=Wardrobe 3, 12=Wardrobe 4)
- `char_equip` - Equipped items (16 equipment slots)
- `char_points` - 206 different currency types
- `char_profile` - Fame, ranks, nation affiliation
- `char_unlocks` - Teleports, homepoints, waypoints
- `char_vars` - Key-value storage for custom data

**Items:**
- `item_basic` - Core item data (name, stack size, price, flags)
- `item_equipment` - Equipment stats (HP, MP, STR, DEX, VIT, AGI, INT, MND, CHR, DEF, ATT, ACC, EVA, jobs, level, slots, races, slot)
- `item_weapon` - Weapon stats (damage, delay, skill, dmgType, hit, unlock_points)

**Monsters:**
- `mob_spawn_points` - Spawn locations with respawn times
- `mob_pools` - Base stats, AI behavior, aggro settings
- `mob_droplist` - Drop tables with rates (out of 1000)
- `mob_groups` - Links spawn points to drop tables

**Economy:**
- `auction_house` - Market listings and sales history
- `delivery_box` - Mail/delivery system

**Game Systems:**
- `zone_settings` - Zone configuration
- `accounts` - Player accounts
- `accounts_sessions` - Active login sessions
- `spell_list` - All spells in the game
- `abilities` - Job abilities
- `synth_recipes` - Crafting recipes

### Key Table Relationships

```
accounts (1:N) chars
  └─> char_stats (1:1)
  └─> char_jobs (1:1)
  └─> char_inventory (1:N)
  └─> char_equip (1:N)
  └─> accounts_sessions (1:1)

mob_spawn_points (N:1) mob_pools
  └─> mob_groups (N:1) mob_droplist (1:N) item_basic

char_inventory (N:1) item_basic
  └─> item_equipment (1:1)
  └─> item_weapon (1:1)

auction_house (N:1) item_basic
auction_house (N:1) chars (seller)
```

---

## Additional Resources

- **LSB Repository**: https://github.com/LandSandBoat/server
- **SQL Schema Files**: `/sql/` directory in LSB repo
- **Database Utilities**: `/src/common/database.h` and `.cpp`
- **Character Functions**: `/src/map/utils/charutils.h`
- **Triggers**: `/sql/triggers.sql`

---

## Summary

This guide covered:

✅ Complete database architecture overview (124 tables across 15 categories)
✅ Character system internals (28 tables, binary blob fields)
✅ Item system structure (9 tables: equipment, weapons, mods)
✅ Monster system (13 tables: spawns, drops, AI, resistances)
✅ Fishing system (13 dedicated tables)
✅ Game systems (24 tables: zones, conquest, campaign, unity, BCNMs, instances, NPCs, pets, monstrosity, experience tables, status effects, transport, weather)
✅ Economy & auction house (4 tables)
✅ Binary blob field handling (critical for missions, keyitems, abilities)
✅ Transaction patterns & data integrity
✅ Common query patterns with real examples
✅ API development best practices (10 key areas)
✅ Performance optimization

**Remember**:
- Always use parameterized queries
- Use transactions for multi-table operations
- Never modify blob fields directly
- Cache static game data
- Monitor database health
- Test on dev environment first

This database is production-ready and powers hundreds of FFXI private servers. Respect its complexity and follow these patterns for reliable API development.
