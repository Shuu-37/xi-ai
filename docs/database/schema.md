# LandSandBoat Database Schema

## Overview

LandSandBoat uses **MariaDB** as its database backend with **UTF8mb4** character encoding. The schema consists of 126 SQL files covering all aspects of the game.

**Connection Details**:
- Default port: 3306
- Configuration: `/settings/network.lua`
- Character set: utf8mb4
- Collation: utf8mb4_general_ci

## Database Structure

### Schema Location

All SQL schema files are located in `/sql/` directory of the LandSandBoat repository.

## Core Tables

### Account Management

#### accounts
**Purpose**: Player account information

**Key Columns**:
- `id` (INT, PRIMARY KEY): Unique account ID
- `login` (VARCHAR): Username
- `password` (VARCHAR): Hashed password
- `email` (VARCHAR): Account email
- `status` (TINYINT): Account status (active, banned, etc.)
- `priv` (TINYINT): Privilege level (normal, GM levels)
- `charcount` (TINYINT): Number of characters
- `timecreate` (TIMESTAMP): Account creation time
- `timelastmodify` (TIMESTAMP): Last modification time

**Related Tables**:
- `accounts_banned`: Ban records
- `accounts_sessions`: Active session tracking
- `account_ip_record`: IP access history

#### accounts_banned
**Purpose**: Track banned accounts and IPs

**Key Columns**:
- `accid` (INT): Account ID reference
- `ban_type` (TINYINT): Ban type (account, IP, etc.)
- `banned` (TIMESTAMP): Ban start time
- `ban_expiry` (TIMESTAMP): Ban expiration (NULL = permanent)
- `ban_reason` (TEXT): Reason for ban

#### accounts_sessions
**Purpose**: Track active login sessions

**Key Columns**:
- `accid` (INT): Account ID
- `charid` (INT): Character ID
- `session_key` (BLOB): Session token
- `server_addr` (INT): Server IP
- `server_port` (SMALLINT): Server port
- `client_addr` (INT): Client IP
- `client_port` (SMALLINT): Client port

#### account_ip_record
**Purpose**: Track IP addresses used by accounts

**Key Columns**:
- `accid` (INT): Account ID
- `charid` (INT): Character ID
- `client_ip` (VARCHAR): IP address
- `login_time` (TIMESTAMP): Login timestamp

### Character Data

#### chars
**Purpose**: Core character information

**Key Columns**:
- `charid` (INT UNSIGNED, PRIMARY KEY): Unique character ID
- `accid` (INT): Account ID reference
- `charname` (VARCHAR): Character name (15 char limit)
- `nation` (TINYINT): Starting nation (0=San d'Oria, 1=Bastok, 2=Windurst)
- `pos_zone` (SMALLINT): Current zone ID
- `pos_x`, `pos_y`, `pos_z` (FLOAT): Position coordinates
- `pos_rot` (TINYINT): Rotation
- `mjob` (TINYINT): Main job
- `sjob` (TINYINT): Sub job
- `mlvl` (TINYINT): Main job level
- `slvl` (TINYINT): Sub job level
- `gmlevel` (TINYINT): GM level (0=normal player)
- `playtime` (INT): Total playtime in seconds
- `hp` (SMALLINT): Current HP
- `mp` (SMALLINT): Current MP
- `deaths` (INT): Death count
- `title` (SMALLINT): Current title ID
- `missions` (BLOB): Mission progress (binary)
- `abilities` (BLOB): Learned abilities (binary)
- `weaponskills` (BLOB): Learned weapon skills (binary)
- `titles` (BLOB): Unlocked titles (binary)
- `keyitems` (BLOB): Key items (binary flags)
- `moghancement` (TINYINT): Mog house enhancement

**Binary Blob Fields**:
- Store flags/bits for unlocked content
- Each bit represents a specific mission/ability/title/key item
- Requires bitwise operations to read/write

#### char_profile
**Purpose**: Character profile information

**Key Columns**:
- `charid` (INT UNSIGNED, PRIMARY KEY)
- `rank` (TINYINT): Nation rank
- `rankpoints` (INT): Conquest points
- `fame_sandoria` (SMALLINT): San d'Oria fame
- `fame_bastok` (SMALLINT): Bastok fame
- `fame_windurst` (SMALLINT): Windurst fame
- `fame_norg` (SMALLINT): Norg fame
- `fame_jeuno` (SMALLINT): Jeuno fame
- `fame_aby_konschtat`, etc.: Abyssea fame values
- `unity_leader` (TINYINT): Unity Concord leader

#### char_look
**Purpose**: Character appearance

**Key Columns**:
- `charid` (INT UNSIGNED, PRIMARY KEY)
- `race` (TINYINT): Race (Hume, Elvaan, Tarutaru, etc.)
- `gender` (TINYINT): Gender
- `face` (TINYINT): Face style
- `head` (SMALLINT): Head equipment model
- `body` (SMALLINT): Body equipment model
- `hands` (SMALLINT): Hands equipment model
- `legs` (SMALLINT): Legs equipment model
- `feet` (SMALLINT): Feet equipment model
- `main` (SMALLINT): Main weapon model
- `sub` (SMALLINT): Sub weapon model
- `ranged` (SMALLINT): Ranged weapon model

#### char_stats
**Purpose**: Character base statistics

**Key Columns**:
- `charid` (INT UNSIGNED, PRIMARY KEY)
- `str`, `dex`, `vit`, `agi`, `int`, `mnd`, `chr` (SMALLINT): Base stats
- `hp` (SMALLINT): Max HP
- `mp` (SMALLINT): Max MP
- `mhflag` (TINYINT): Mog house flag
- `hmcs` (TINYINT): Home Mog house CS
- `mjob` through `mjob_exp` (INT): Job levels and experience

#### char_jobs
**Purpose**: Job levels and experience

**Key Columns**:
- `charid` (INT UNSIGNED, PRIMARY KEY)
- `war`, `mnk`, `whm`, `blm`, etc. (TINYINT): Job levels (1-99)
- `war_exp`, `mnk_exp`, etc. (INT): Job experience points
- `unlocked` (INT): Unlocked jobs bitfield

#### char_skills
**Purpose**: Skill levels

**Key Columns**:
- `charid` (INT UNSIGNED, PRIMARY KEY)
- Combat skills: `slashing`, `piercing`, `blunt`, `h2h`, `archery`, `marksmanship`, `throwing`
- Magic skills: `divine`, `healing`, `enhancing`, `enfeebling`, `elemental`, `dark`, `summoning`, `ninjutsu`, `singing`, `string`, `wind`, `blue`
- Crafting skills: `fishing`, `woodworking`, `smithing`, `goldsmithing`, `clothcraft`, `leathercraft`, `bonecraft`, `alchemy`, `cooking`
- Each skill: `(SMALLINT)` - Skill level (0-1000+)

#### char_inventory
**Purpose**: Character inventory items

**Key Columns**:
- `charid` (INT UNSIGNED): Character ID
- `location` (TINYINT): Container (0=inventory, 1=mogsafe, 2=storage, etc.)
- `slot` (TINYINT): Slot number (0-79)
- `itemId` (SMALLINT): Item ID reference
- `quantity` (INT): Item quantity (stackable items)
- `bazaar` (INT): Bazaar price (if selling)
- `signature` (VARCHAR): Crafter signature
- `extra` (BLOB): Augment/trial data (binary)

**Container IDs**:
- 0: Inventory
- 1: Mog Safe
- 2: Storage
- 3: Temporary
- 4: Mog Locker
- 5: Mog Satchel
- 6: Mog Sack
- 7: Mog Case
- 8: Wardrobe
- 9: Mog Safe 2
- 10: Wardrobe 2
- 11: Wardrobe 3
- 12: Wardrobe 4

#### char_equip
**Purpose**: Equipped items

**Key Columns**:
- `charid` (INT UNSIGNED, PRIMARY KEY)
- `equipslotid` (TINYINT): Equipment slot
  - 0: Main
  - 1: Sub
  - 2: Ranged
  - 3: Ammo
  - 4: Head
  - 5: Body
  - 6: Hands
  - 7: Legs
  - 8: Feet
  - 9: Neck
  - 10: Waist
  - 11: Ear1
  - 12: Ear2
  - 13: Ring1
  - 14: Ring2
  - 15: Back
- `slotid` (TINYINT): Inventory slot where item is stored
- `containerid` (TINYINT): Container ID

#### char_spells
**Purpose**: Learned spells

**Key Columns**:
- `charid` (INT UNSIGNED): Character ID
- `spellid` (SMALLINT): Spell ID

**Note**: One row per spell learned

#### char_points
**Purpose**: Merit and job points

**Key Columns**:
- `charid` (INT UNSIGNED, PRIMARY KEY)
- `merit_points` (SMALLINT): Available merit points
- `limit_points` (INT): Limit points (for merit unlocking)
- Various merit category points and upgrades

#### char_unlocks
**Purpose**: Content unlocks

**Key Columns**:
- `charid` (INT UNSIGNED, PRIMARY KEY)
- `outpost_sandy`, `outpost_bastok`, `outpost_windy` (BLOB): Outpost teleport unlocks
- `campaign_sandy`, `campaign_bastok`, `campaign_windy` (BLOB): Campaign unlocks
- `homepoint` (BLOB): Home point unlocks
- `waypoints` (BLOB): Waypoint unlocks

### Party and Social

#### chars_parties
**Purpose**: Track party membership

**Key Columns**:
- `partyid` (INT UNSIGNED): Party ID
- `charid` (INT UNSIGNED): Character ID
- `allianceid` (TINYINT): Alliance ID (if in alliance)
- `partyflag` (INT): Party settings flags

#### linkshells
**Purpose**: Linkshell information

**Key Columns**:
- `linkshellid` (INT UNSIGNED, PRIMARY KEY): Linkshell ID
- `name` (VARCHAR): Linkshell name
- `color` (SMALLINT): Linkshell pearl color
- `poster` (VARCHAR): Message board text
- `broken` (TINYINT): Is linkshell broken/disbanded
- `message` (VARCHAR): Linkshell message

#### linkshell_members
**Purpose**: Linkshell membership

**Key Columns**:
- `linkshellid` (INT UNSIGNED): Linkshell ID
- `charid` (INT UNSIGNED): Character ID
- `rank` (TINYINT): Member rank (0=holder, 1=sack, 2=pearl)

## Game Data Tables

### Items

#### item_basic
**Purpose**: Basic item information

**Key Columns**:
- `itemid` (SMALLINT UNSIGNED, PRIMARY KEY): Item ID
- `name` (VARCHAR): Item name
- `sortname` (VARCHAR): Sorting name
- `stackSize` (SMALLINT): Max stack size (1 for non-stackable)
- `flags` (INT): Item flags (rare, ex, tradeable, etc.)
- `aH` (TINYINT): Auction house category
- `NoSale` (TINYINT): Cannot be sold to NPCs
- `BaseSell` (INT): Base NPC sell price

#### item_equipment
**Purpose**: Equipment stats

**Key Columns**:
- `itemId` (SMALLINT UNSIGNED, PRIMARY KEY): Item ID
- `jobs` (INT): Jobs that can equip (bitfield)
- `level` (TINYINT): Required level
- `slots` (INT): Equipment slots (bitfield)
- `races` (INT): Races that can equip (bitfield)
- `slot` (TINYINT): Primary equipment slot
- Various stat modifiers (HP, MP, STR, DEX, VIT, etc.)
- `shield_size` (TINYINT): Shield size for shield equipment
- `max_charges` (TINYINT): For rechargeable items

#### item_weapon
**Purpose**: Weapon-specific data

**Key Columns**:
- `itemId` (SMALLINT UNSIGNED, PRIMARY KEY): Item ID
- `damage` (SMALLINT): Base damage
- `dmgType` (TINYINT): Damage type (slashing, piercing, etc.)
- `delay` (SMALLINT): Weapon delay (in 100ths of second)
- `skill` (TINYINT): Weapon skill type
- `subskill` (TINYINT): Sub skill
- `hit` (TINYINT): Accuracy bonus
- `unlock_points` (SMALLINT): Item level

#### item_armor
**Purpose**: Armor-specific data

**Key Columns**:
- `itemId` (SMALLINT UNSIGNED, PRIMARY KEY): Item ID
- `level` (TINYINT): Required level
- `jobs` (INT): Jobs that can equip
- `DEF` (SMALLINT): Defense rating
- `shield_size` (TINYINT): Shield size

### Monsters

#### mob_spawn_points
**Purpose**: Monster spawn locations

**Key Columns**:
- `mobid` (INT UNSIGNED, PRIMARY KEY): Mob ID
- `mobname` (VARCHAR): Mob name
- `groupid` (TINYINT): Spawn group
- `poolid` (SMALLINT): Mob pool ID
- `pos_x`, `pos_y`, `pos_z`, `pos_rot` (FLOAT): Spawn position
- `respawn` (INT): Respawn time (seconds)

#### mob_pools
**Purpose**: Mob base stats and properties

**Key Columns**:
- `poolid` (SMALLINT, PRIMARY KEY): Pool ID
- `name` (VARCHAR): Mob name
- `mJob` (TINYINT): Main job
- `sJob` (TINYINT): Sub job
- `minLevel`, `maxLevel` (TINYINT): Level range
- `allegiance` (TINYINT): Faction
- `systemid` (TINYINT): System (unused, normal, notorious, etc.)
- `behavior` (SMALLINT): AI behavior flags
- `aggro` (TINYINT): Aggro type (sight, sound, magic, etc.)
- `true_detection` (TINYINT): True sight/sound
- `links` (TINYINT): Linking behavior
- Various modifiers and stats

#### mob_droplist
**Purpose**: Mob drop tables

**Key Columns**:
- `dropid` (MEDIUMINT UNSIGNED, PRIMARY KEY): Drop entry ID
- `droptype` (TINYINT): Drop type (normal, steal, desynth)
- `groupid` (TINYINT): Drop group
- `itemid` (SMALLINT): Item ID
- `itemRate` (SMALLINT): Drop rate (out of 1000)

#### mob_groups
**Purpose**: Link drops to mob pools

**Key Columns**:
- `groupid` (SMALLINT): Group ID
- `poolid` (SMALLINT): Mob pool ID
- `zoneid` (SMALLINT): Zone ID
- `dropid` (MEDIUMINT): Drop list ID

#### mob_resistances
**Purpose**: Mob elemental resistances

**Key Columns**:
- `mob_id` (INT): Mob ID
- `fire`, `ice`, `wind`, `earth`, `lightning`, `water`, `light`, `dark` (SMALLINT): Resistance values

#### mob_skills
**Purpose**: Mob TP moves

**Key Columns**:
- `mob_skill_id` (SMALLINT, PRIMARY KEY): Skill ID
- `mob_skill_name` (VARCHAR): Skill name
- `mob_anim_id` (SMALLINT): Animation ID
- `mob_skill_aoe` (TINYINT): AoE type
- `mob_skill_distance` (FLOAT): Range
- `mob_skill_flag` (TINYINT): Flags
- `mob_skill_param` (SMALLINT): Parameters

### Spells and Abilities

#### spell_list
**Purpose**: All spells in game

**Key Columns**:
- `spellid` (SMALLINT, PRIMARY KEY): Spell ID
- `name` (VARCHAR): Spell name
- `jobs` (INT): Jobs that can learn (bitfield)
- `level` (TINYINT): Level required
- `validTargets` (SMALLINT): Valid targets (self, party, enemy, etc.)
- `skill` (TINYINT): Magic skill type
- `mp_cost` (SMALLINT): MP cost
- `cast_time` (INT): Cast time (milliseconds)
- `recast_time` (INT): Recast time (milliseconds)
- `element` (TINYINT): Elemental type
- `message1`, `message2` (SMALLINT): Battle messages

#### abilities
**Purpose**: Job abilities

**Key Columns**:
- `abilityid` (SMALLINT, PRIMARY KEY): Ability ID
- `name` (VARCHAR): Ability name
- `job` (TINYINT): Job
- `level` (TINYINT): Level required
- `validTargets` (SMALLINT): Valid targets
- `recastTime` (INT): Recast time (seconds)
- `message1`, `message2` (SMALLINT): Battle messages

#### weapon_skills
**Purpose**: Weapon skills

**Key Columns**:
- `weaponskillid` (TINYINT, PRIMARY KEY): WS ID
- `name` (VARCHAR): WS name
- `jobs` (INT): Jobs that can use (bitfield)
- `type` (TINYINT): Weapon type
- `skilllevel` (SMALLINT): Skill level required
- `element` (TINYINT): Element

#### blue_spell_list
**Purpose**: Blue magic spells

**Key Columns**:
- `spellid` (SMALLINT, PRIMARY KEY): Spell ID
- `blu_spell_id` (SMALLINT): Blue spell ID
- `set_points` (TINYINT): Points cost to set
- `trait_category`, `trait_category_weight` (TINYINT): Trait contribution

### Economy

#### auction_house
**Purpose**: Auction house listings

**Key Columns**:
- `id` (INT UNSIGNED, PRIMARY KEY, AUTO_INCREMENT): Listing ID
- `seller` (INT UNSIGNED): Seller character ID
- `seller_name` (VARCHAR): Seller name
- `buyer_name` (VARCHAR): Buyer name (when sold)
- `itemid` (SMALLINT): Item ID
- `quantity` (INT): Quantity
- `sell_price` (INT): Asking price
- `date` (INT UNSIGNED): Listing timestamp
- `sale` (INT UNSIGNED): Sale timestamp (0 if not sold)

#### guild_shops
**Purpose**: Guild shop inventory

**Key Columns**:
- `shopid` (INT): Shop ID
- `itemid` (SMALLINT): Item ID
- `stack_size` (TINYINT): Quantity sold
- `price` (MEDIUMINT): Sale price
- `restock_interval` (INT): Restock time (seconds)
- `guild_id` (TINYINT): Guild ID

### Crafting

#### synth_recipes
**Purpose**: Synthesis recipes

**Key Columns**:
- `ID` (SMALLINT, PRIMARY KEY): Recipe ID
- `KeyItem` (SMALLINT): Required key item
- `Wood`, `Smith`, `Goldsmith`, `Cloth`, `Leather`, `Bone`, `Alchemy`, `Cook` (TINYINT): Skill levels
- `Crystal` (SMALLINT): Crystal required
- `Ingredient1` through `Ingredient8` (SMALLINT): Ingredient item IDs
- `Result` (SMALLINT): Crafted item ID
- `ResultHQ1`, `ResultHQ2`, `ResultHQ3` (SMALLINT): HQ results
- `ResultQty`, `ResultHQ1Qty`, etc. (TINYINT): Result quantities

#### synergy_recipes
**Purpose**: Synergy recipes (group crafting)

**Key Columns**:
- `ID` (SMALLINT, PRIMARY KEY): Recipe ID
- `crystal` (SMALLINT): Synergy fewell
- `primary_skill` (TINYINT): Primary crafting skill
- `primary_rank` (TINYINT): Rank threshold
- Ingredient columns (similar to synth_recipes)
- Result columns

#### gardening_results
**Purpose**: Mog house gardening

**Key Columns**:
- `seed_id` (SMALLINT): Seed item ID
- `result_id` (SMALLINT): Harvested item ID
- `result_qty` (TINYINT): Quantity
- `result_rate` (TINYINT): Success rate

### Fishing

**Multiple specialized tables**:
- `fishing_bait`: Bait types
- `fishing_catch`: Fish data
- `fishing_fish`: Fish-bait compatibility
- `fishing_ground`: Fishing zones
- `fishing_mob`: Mob fishing results
- `fishing_rod`: Rod data
- `fishing_zone`: Zone-specific fishing data

### Zones

#### zone_settings
**Purpose**: Zone configuration

**Key Columns**:
- `zoneid` (SMALLINT UNSIGNED, PRIMARY KEY): Zone ID
- `name` (VARCHAR): Zone name
- `zonetype` (TINYINT): Type (normal, dungeon, city, etc.)
- `zoneip` (INT): Server IP
- `zoneport` (SMALLINT): Server port
- `tax` (FLOAT): Tax rate for AH
- `misc` (INT): Misc flags
- `music_day`, `music_night` (TINYINT): BGM IDs

### Conquest and World Systems

#### conquest_system
**Purpose**: Conquest region data

**Key Columns**:
- `region_id` (TINYINT, PRIMARY KEY): Region ID
- `region_control` (TINYINT): Controlling nation
- `sandoria_influence`, `bastok_influence`, `windurst_influence` (INT): Influence points

#### campaign_system
**Purpose**: Campaign (WotG) data

**Key Columns**:
- `region_id` (TINYINT, PRIMARY KEY): Region ID
- `region_control` (TINYINT): Controlling side
- Various campaign-specific data

#### besieged_system
**Purpose**: Besieged (ToAU) data

**Key Columns**:
- `id` (INT, PRIMARY KEY): Record ID
- `zone` (SMALLINT): Zone ID
- `status` (TINYINT): Besieged status
- `time` (INT): Time remaining

### Quests and Missions

Quest and mission progress is stored in:
- `chars.missions` (BLOB): Binary flags for mission progress
- Character flags and variables
- Key items in `chars.keyitems` (BLOB)

**No dedicated quest tables** - quest states are tracked via character flags and in-memory state.

### Special Systems

#### bcnm_info
**Purpose**: Battle content (BCNM, ENM, etc.)

**Key Columns**:
- `bcnmid` (SMALLINT, PRIMARY KEY): BCNM ID
- `name` (VARCHAR): BCNM name
- `fastestTime` (INT): Record time
- `fastestParty` (VARCHAR): Record holders
- `fastestTime_solo` (INT): Solo record

#### instance_list
**Purpose**: Active instance tracking

**Key Columns**:
- `id` (INT, PRIMARY KEY): Instance ID
- `bcnmid` (SMALLINT): BCNM ID
- `zone_id` (SMALLINT): Zone ID
- `created` (TIMESTAMP): Creation time

## Database Access Patterns

### Reading Character Data

```sql
-- Get character basic info
SELECT * FROM chars WHERE charid = ?;

-- Get character inventory
SELECT * FROM char_inventory
WHERE charid = ? AND location = 0
ORDER BY slot;

-- Get equipped items
SELECT ce.*, ci.itemId, ci.quantity
FROM char_equip ce
JOIN char_inventory ci ON ce.slotid = ci.slot AND ce.charid = ci.charid
WHERE ce.charid = ?;

-- Get character skills
SELECT * FROM char_skills WHERE charid = ?;
```

### Modifying Character Data

```sql
-- Update character position
UPDATE chars
SET pos_zone = ?, pos_x = ?, pos_y = ?, pos_z = ?, pos_rot = ?
WHERE charid = ?;

-- Add item to inventory
INSERT INTO char_inventory
(charid, location, slot, itemId, quantity)
VALUES (?, 0, ?, ?, ?);

-- Update character job level
UPDATE chars
SET mjob = ?, mlvl = ?
WHERE charid = ?;
```

### Querying Game Data

```sql
-- Get item information
SELECT ib.*, ie.*, iw.*
FROM item_basic ib
LEFT JOIN item_equipment ie ON ib.itemid = ie.itemId
LEFT JOIN item_weapon iw ON ib.itemid = iw.itemId
WHERE ib.itemid = ?;

-- Get mob drops
SELECT ml.itemid, ml.itemRate
FROM mob_droplist ml
JOIN mob_groups mg ON ml.groupid = mg.groupid
WHERE mg.poolid = ? AND ml.droptype = 0;

-- Get auction house listings
SELECT * FROM auction_house
WHERE itemid = ? AND sale = 0
ORDER BY sell_price ASC;
```

## Binary Blob Fields

Several character fields use binary blobs to store flags:

### Format

- **missions**, **abilities**, **weaponskills**, **titles**, **keyitems**: Binary data
- Each bit represents a specific item/unlock
- Bit positions correspond to game-defined IDs

### Working with Blobs

**Read** (check if bit is set):
```python
# Check if mission ID 42 is complete
missions_blob = get_blob_from_db(charid, 'missions')
byte_index = 42 // 8
bit_index = 42 % 8
is_complete = (missions_blob[byte_index] & (1 << bit_index)) != 0
```

**Write** (set bit):
```python
# Mark mission ID 42 as complete
byte_index = 42 // 8
bit_index = 42 % 8
missions_blob[byte_index] |= (1 << bit_index)
update_blob_in_db(charid, 'missions', missions_blob)
```

## Transaction Best Practices

### Use Transactions for Related Changes

```sql
START TRANSACTION;

-- Deduct gil from buyer
UPDATE char_points SET gil = gil - ? WHERE charid = ?;

-- Add gil to seller
UPDATE char_points SET gil = gil + ? WHERE charid = ?;

-- Transfer item
UPDATE char_inventory SET charid = ? WHERE charid = ? AND slot = ?;

COMMIT;
```

### Error Handling

```sql
START TRANSACTION;

-- Perform operations
UPDATE ...
INSERT ...
DELETE ...

-- Check for errors, rollback if needed
ROLLBACK; -- on error
-- or
COMMIT; -- on success
```

## Indexing

### Primary Keys

Most tables have primary keys on:
- `id` or `*id` columns
- `charid` for character-specific tables
- Composite keys for junction tables

### Foreign Keys

Foreign key relationships (not always enforced):
- `accounts.id` → `chars.accid`
- `chars.charid` → `char_*` tables
- `item_basic.itemid` → `item_equipment.itemId`, `item_weapon.itemId`, etc.
- `mob_pools.poolid` → `mob_spawn_points.poolid`

### Recommended Indexes

For performance, consider indexes on:
- `chars.accid` (account lookups)
- `char_inventory.charid` + `location` (inventory queries)
- `auction_house.itemid` + `sale` (AH searches)
- `mob_spawn_points.mobname` (spawn lookups)

## Database Maintenance

### Backup

Use `dbtool.py`:
```bash
python tools/dbtool.py --backup
```

### Updates and Migrations

```bash
# Express update (quick)
python tools/dbtool.py --update express

# Full update (comprehensive)
python tools/dbtool.py --update full
```

### Character Migration

```bash
python tools/dbtool.py --migrate
```

## Security Considerations

### SQL Injection Prevention

**Always use parameterized queries**:

```python
# GOOD
cursor.execute("SELECT * FROM chars WHERE charid = %s", (charid,))

# BAD - vulnerable to SQL injection
cursor.execute(f"SELECT * FROM chars WHERE charid = {charid}")
```

### Credentials

Store database credentials securely:
- Use `/settings/network.lua` for configuration
- Never commit credentials to version control
- Use strong passwords
- Restrict database user permissions

### Data Validation

Before inserting/updating:
- Validate item IDs exist
- Check quantity limits
- Verify foreign key relationships
- Enforce game constraints (max gil, inventory slots, etc.)

## Common Pitfalls

### Binary Blob Modifications

- Never directly edit blobs without understanding bit structure
- Always backup before bulk blob updates
- Test on development database first

### Character Inventory

- Respect container slot limits (typically 0-79)
- Check item stack sizes before adding
- Validate item IDs against `item_basic` table

### Gil and Currency

- Use transactions when transferring currency
- Check for integer overflow
- Validate amounts are non-negative

### Character Jobs and Levels

- Validate job IDs (1-22 for standard jobs)
- Enforce level caps (typically 1-99)
- Update both main job and experience when leveling

## Tools and Libraries

### Python

**MariaDB Connector**:
```python
import mariadb

conn = mariadb.connect(
    host="localhost",
    port=3306,
    user="xiserver",
    password="xiserver",
    database="xidb"
)
```

### Node.js

**mysql2**:
```javascript
const mysql = require('mysql2/promise');

const pool = mysql.createPool({
    host: 'localhost',
    user: 'xiserver',
    password: 'xiserver',
    database: 'xidb',
    waitForConnections: true,
    connectionLimit: 10
});
```

### Direct SQL

Use MariaDB client:
```bash
mysql -h localhost -u xiserver -pxiserver xidb
```

## Performance Optimization

### Query Optimization

- Use `EXPLAIN` to analyze query plans
- Add indexes on frequently queried columns
- Limit result sets with `LIMIT`
- Use `JOIN` instead of multiple queries

### Connection Pooling

- Reuse database connections
- Configure pool size based on load
- Close connections properly

### Caching

- Cache frequently accessed data (items, spells, zones)
- Invalidate cache on updates
- Use in-memory cache (Redis, Memcached) for hot data

## Reference Documentation

- SQL files in `/sql/` directory
- Database documentation in LandSandBoat wiki
- `/documentation/` folder for game data references
