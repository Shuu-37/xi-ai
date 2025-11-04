# LandSandBoat Database Tables Reference

## Overview

This document provides detailed information about the most commonly accessed database tables for building APIs and tools. All tables use MariaDB with UTF8mb4 encoding.

## Character Tables

### chars
**Primary character data table**

| Column | Type | Description | API Use |
|--------|------|-------------|---------|
| `charid` | INT UNSIGNED | Unique character ID | Primary key for all character lookups |
| `accid` | INT | Account ID reference | Link characters to accounts |
| `charname` | VARCHAR(15) | Character name | Display name, search |
| `nation` | TINYINT | Starting nation (0=San d'Oria, 1=Bastok, 2=Windurst) | Nation affiliation |
| `pos_zone` | SMALLINT | Current zone ID | Player location tracking |
| `pos_x`, `pos_y`, `pos_z` | FLOAT | Position coordinates | Exact location in zone |
| `pos_rot` | TINYINT | Rotation (0-255) | Facing direction |
| `mjob` | TINYINT | Main job ID (1-22) | Current job |
| `sjob` | TINYINT | Sub job ID | Support job |
| `mlvl` | TINYINT | Main job level (1-99) | Character power level |
| `slvl` | TINYINT | Sub job level | Support level |
| `gmlevel` | TINYINT | GM level (0=player, 1+=GM) | Admin permissions |
| `playtime` | INT | Total playtime in seconds | Activity tracking |
| `hp`, `mp` | SMALLINT | Current HP/MP | Character state |
| `deaths` | INT | Total deaths | Statistics |
| `title` | SMALLINT | Current title ID | Display title |
| `missions` | BLOB | Mission progress (binary flags) | Quest completion |
| `abilities` | BLOB | Learned abilities (binary flags) | Character capabilities |
| `weaponskills` | BLOB | Learned weapon skills (binary) | Combat options |
| `titles` | BLOB | Unlocked titles (binary) | Achievements |
| `keyitems` | BLOB | Key items (binary flags) | Quest items |
| `moghancement` | TINYINT | Mog house enhancement | Housing feature |

**Common Queries**:
```sql
-- Get character basic info
SELECT charid, charname, mjob, mlvl, nation, pos_zone
FROM chars
WHERE charid = ?;

-- Search characters by name
SELECT charid, charname, mjob, mlvl
FROM chars
WHERE charname LIKE ?
LIMIT 20;

-- Get online players (has active session)
SELECT c.charid, c.charname, c.pos_zone
FROM chars c
JOIN accounts_sessions s ON c.charid = s.charid
WHERE s.charid IS NOT NULL;

-- Get characters by job
SELECT charid, charname, mlvl
FROM chars
WHERE mjob = ?
ORDER BY mlvl DESC;
```

**API Endpoints**:
- `GET /characters/:id` - Get character details
- `GET /characters/search?name=` - Search by name
- `GET /characters/online` - List online players
- `PATCH /characters/:id` - Update character (admin only)

### char_jobs
**Job levels and experience**

| Column | Type | Description | API Use |
|--------|------|-------------|---------|
| `charid` | INT UNSIGNED | Character ID | Foreign key |
| `war`, `mnk`, `whm`, `blm`, `rdm`, `thf`, `pld`, `drk`, `bst`, `brd`, `rng`, `sam`, `nin`, `drg`, `smn`, `blu`, `cor`, `pup`, `dnc`, `sch`, `geo`, `run` | TINYINT | Job levels (1-99) | Character progression per job |
| `war_exp`, `mnk_exp`, etc. | INT | Experience points | Progress tracking |
| `unlocked` | INT | Unlocked jobs (bitfield) | Available jobs |

**Common Queries**:
```sql
-- Get all job levels for character
SELECT * FROM char_jobs WHERE charid = ?;

-- Get characters with specific job at level
SELECT cj.charid, c.charname, cj.war as level
FROM char_jobs cj
JOIN chars c ON cj.charid = c.charid
WHERE cj.war >= 99;

-- Get highest level job for character
SELECT charid,
  GREATEST(war, mnk, whm, blm, rdm, thf, pld, drk,
           bst, brd, rng, sam, nin, drg, smn, blu,
           cor, pup, dnc, sch, geo, run) as max_level
FROM char_jobs
WHERE charid = ?;
```

**API Endpoints**:
- `GET /characters/:id/jobs` - Get all job levels
- `GET /jobs/rankings?job=WAR` - Top players by job

### char_inventory
**Character items**

| Column | Type | Description | API Use |
|--------|------|-------------|---------|
| `charid` | INT UNSIGNED | Character ID | Owner |
| `location` | TINYINT | Container (0=inventory, 1=safe, 2=storage, etc.) | Storage location |
| `slot` | TINYINT | Slot number (0-79) | Position in container |
| `itemId` | SMALLINT | Item ID reference | What item |
| `quantity` | INT | Stack quantity | How many |
| `bazaar` | INT | Bazaar price (0=not for sale) | Player shop |
| `signature` | VARCHAR(27) | Crafter signature | Item history |
| `extra` | BLOB | Augment/trial data | Item modifications |

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
- 10-12: Wardrobe 2-4

**Common Queries**:
```sql
-- Get character inventory
SELECT ci.slot, ci.itemId, ci.quantity, ib.name
FROM char_inventory ci
JOIN item_basic ib ON ci.itemId = ib.itemid
WHERE ci.charid = ? AND ci.location = 0
ORDER BY ci.slot;

-- Count total items
SELECT COUNT(*) as total_items, SUM(quantity) as total_quantity
FROM char_inventory
WHERE charid = ? AND location = 0;

-- Find characters with specific item
SELECT DISTINCT ci.charid, c.charname, ci.quantity
FROM char_inventory ci
JOIN chars c ON ci.charid = c.charid
WHERE ci.itemId = ?
ORDER BY ci.quantity DESC;

-- Get all storage containers
SELECT location, COUNT(*) as used_slots
FROM char_inventory
WHERE charid = ?
GROUP BY location;
```

**API Endpoints**:
- `GET /characters/:id/inventory` - Get inventory items
- `GET /characters/:id/storage/:location` - Get specific container
- `POST /characters/:id/items` - Add item (admin)
- `DELETE /characters/:id/items/:slot` - Remove item (admin)

### char_stats
**Character statistics and attributes**

| Column | Type | Description | API Use |
|--------|------|-------------|---------|
| `charid` | INT UNSIGNED | Character ID | Foreign key |
| `str`, `dex`, `vit`, `agi`, `int`, `mnd`, `chr` | SMALLINT | Base stats | Character attributes |
| `hp`, `mp` | SMALLINT | Max HP/MP | Resource pools |
| `mhflag` | TINYINT | Mog house flag | Housing status |

**Common Queries**:
```sql
-- Get character stats
SELECT * FROM char_stats WHERE charid = ?;

-- Get characters by stat
SELECT cs.charid, c.charname, cs.str
FROM char_stats cs
JOIN chars c ON cs.charid = c.charid
WHERE cs.str > 100
ORDER BY cs.str DESC;
```

**API Endpoints**:
- `GET /characters/:id/stats` - Get character stats

### char_skills
**Character skill levels**

| Column | Type | Description | API Use |
|--------|------|-------------|---------|
| `charid` | INT UNSIGNED | Character ID | Foreign key |
| **Combat Skills** | | |
| `slashing`, `piercing`, `blunt`, `h2h` | SMALLINT | Melee weapon skills | Combat proficiency |
| `archery`, `marksmanship`, `throwing` | SMALLINT | Ranged weapon skills | Ranged proficiency |
| **Magic Skills** | | |
| `divine`, `healing`, `enhancing`, `enfeebling` | SMALLINT | White magic skills | Magic proficiency |
| `elemental`, `dark` | SMALLINT | Black magic skills | Offensive magic |
| `summoning`, `ninjutsu`, `singing`, `string`, `wind`, `blue` | SMALLINT | Job-specific magic | Specialized skills |
| **Crafting Skills** | | |
| `fishing`, `woodworking`, `smithing`, `goldsmithing` | SMALLINT | Crafting skills (0-110) | Crafting proficiency |
| `clothcraft`, `leathercraft`, `bonecraft`, `alchemy`, `cooking` | SMALLINT | Crafting skills | Production |

**Common Queries**:
```sql
-- Get all skills for character
SELECT * FROM char_skills WHERE charid = ?;

-- Get crafting skills only
SELECT charid, woodworking, smithing, goldsmithing,
       clothcraft, leathercraft, bonecraft, alchemy, cooking
FROM char_skills
WHERE charid = ?;

-- Find master crafters
SELECT cs.charid, c.charname, cs.smithing
FROM char_skills cs
JOIN chars c ON cs.charid = c.charid
WHERE cs.smithing >= 100
ORDER BY cs.smithing DESC;
```

**API Endpoints**:
- `GET /characters/:id/skills` - Get all skills
- `GET /characters/:id/skills/combat` - Combat skills only
- `GET /characters/:id/skills/crafting` - Crafting skills only

### char_equip
**Equipped items**

| Column | Type | Description | API Use |
|--------|------|-------------|---------|
| `charid` | INT UNSIGNED | Character ID | Foreign key |
| `equipslotid` | TINYINT | Equipment slot (0-15) | Body part |
| `slotid` | TINYINT | Inventory slot reference | Source item |
| `containerid` | TINYINT | Container ID | Source container |

**Equipment Slots**:
- 0: Main hand
- 1: Sub hand
- 2: Ranged
- 3: Ammo
- 4: Head
- 5: Body
- 6: Hands
- 7: Legs
- 8: Feet
- 9: Neck
- 10: Waist
- 11: Ear 1
- 12: Ear 2
- 13: Ring 1
- 14: Ring 2
- 15: Back

**Common Queries**:
```sql
-- Get equipped items with details
SELECT ce.equipslotid, ci.itemId, ib.name
FROM char_equip ce
JOIN char_inventory ci ON ce.charid = ci.charid
  AND ce.slotid = ci.slot
  AND ce.containerid = ci.location
JOIN item_basic ib ON ci.itemId = ib.itemid
WHERE ce.charid = ?
ORDER BY ce.equipslotid;

-- Get weapon loadout
SELECT ce.equipslotid, ib.name, iw.damage
FROM char_equip ce
JOIN char_inventory ci ON ce.charid = ci.charid
  AND ce.slotid = ci.slot
JOIN item_basic ib ON ci.itemId = ib.itemid
LEFT JOIN item_weapon iw ON ci.itemId = iw.itemId
WHERE ce.charid = ? AND ce.equipslotid IN (0, 1, 2)
ORDER BY ce.equipslotid;
```

**API Endpoints**:
- `GET /characters/:id/equipment` - Get equipped items
- `GET /characters/:id/equipment/weapons` - Weapons only

### char_profile
**Character profile and fame**

| Column | Type | Description | API Use |
|--------|------|-------------|---------|
| `charid` | INT UNSIGNED | Character ID | Foreign key |
| `rank` | TINYINT | Nation rank (1-10) | Military rank |
| `rankpoints` | INT | Conquest points | Nation currency |
| `fame_sandoria`, `fame_bastok`, `fame_windurst` | SMALLINT | Nation fame (0-9) | Reputation |
| `fame_norg`, `fame_jeuno` | SMALLINT | City fame | City reputation |
| `fame_aby_*` | SMALLINT | Abyssea fame values | Expansion reputation |
| `unity_leader` | TINYINT | Unity Concord leader | Unity affiliation |

**Common Queries**:
```sql
-- Get character profile
SELECT * FROM char_profile WHERE charid = ?;

-- Get high-ranking characters
SELECT cp.charid, c.charname, cp.rank, c.nation
FROM char_profile cp
JOIN chars c ON cp.charid = c.charid
WHERE cp.rank >= 10
ORDER BY cp.rank DESC;
```

**API Endpoints**:
- `GET /characters/:id/profile` - Get profile and fame
- `GET /characters/:id/fame` - Fame values only

## Account Tables

### accounts
**Player accounts**

| Column | Type | Description | API Use |
|--------|------|-------------|---------|
| `id` | INT | Account ID | Primary key |
| `login` | VARCHAR(16) | Username | Authentication |
| `password` | VARCHAR(255) | Hashed password | Security |
| `email` | VARCHAR(50) | Email address | Contact |
| `status` | TINYINT | Account status (0=normal, 1=banned) | Access control |
| `priv` | TINYINT | Privilege level (0=normal, 1+=GM) | Permissions |
| `charcount` | TINYINT | Number of characters | Account info |
| `timecreate` | TIMESTAMP | Creation time | Account age |
| `timelastmodify` | TIMESTAMP | Last modification | Activity |

**Common Queries**:
```sql
-- Get account info
SELECT id, login, email, status, priv, charcount, timecreate
FROM accounts
WHERE id = ?;

-- Get account characters
SELECT c.charid, c.charname, c.mjob, c.mlvl
FROM chars c
WHERE c.accid = ?
ORDER BY c.charid;

-- Get GM accounts
SELECT id, login, priv
FROM accounts
WHERE priv > 0
ORDER BY priv DESC;
```

**API Endpoints**:
- `GET /accounts/:id` - Get account info (admin/self)
- `GET /accounts/:id/characters` - List characters
- `PATCH /accounts/:id` - Update account (admin)

### accounts_sessions
**Active login sessions**

| Column | Type | Description | API Use |
|--------|------|-------------|---------|
| `accid` | INT | Account ID | Session owner |
| `charid` | INT | Character ID | Active character |
| `session_key` | BLOB | Session token | Authentication |
| `server_addr`, `server_port` | INT/SMALLINT | Server connection | Network info |
| `client_addr`, `client_port` | INT/SMALLINT | Client connection | Client info |

**Common Queries**:
```sql
-- Get online players
SELECT as.charid, c.charname, c.pos_zone
FROM accounts_sessions as
JOIN chars c ON as.charid = c.charid;

-- Count online by zone
SELECT c.pos_zone, z.name, COUNT(*) as player_count
FROM accounts_sessions as
JOIN chars c ON as.charid = c.charid
JOIN zone_settings z ON c.pos_zone = z.zoneid
GROUP BY c.pos_zone
ORDER BY player_count DESC;
```

**API Endpoints**:
- `GET /server/online` - List online players
- `GET /server/online/count` - Online player count

### accounts_banned
**Ban records**

| Column | Type | Description | API Use |
|--------|------|-------------|---------|
| `accid` | INT | Account ID | Banned account |
| `ban_type` | TINYINT | Ban type | Ban classification |
| `banned` | TIMESTAMP | Ban start time | When banned |
| `ban_expiry` | TIMESTAMP | Ban end (NULL=permanent) | Ban duration |
| `ban_reason` | TEXT | Reason for ban | Moderation info |

**Common Queries**:
```sql
-- Get active bans
SELECT ab.accid, a.login, ab.ban_reason, ab.ban_expiry
FROM accounts_banned ab
JOIN accounts a ON ab.accid = a.id
WHERE ab.ban_expiry IS NULL OR ab.ban_expiry > NOW();

-- Get ban history for account
SELECT * FROM accounts_banned WHERE accid = ?;
```

**API Endpoints**:
- `GET /admin/bans` - List active bans (admin)
- `POST /admin/bans` - Create ban (admin)
- `DELETE /admin/bans/:id` - Remove ban (admin)

### account_ip_record
**IP access history**

| Column | Type | Description | API Use |
|--------|------|-------------|---------|
| `accid` | INT | Account ID | Account reference |
| `charid` | INT | Character ID | Character used |
| `client_ip` | VARCHAR(45) | IP address | Network tracking |
| `login_time` | TIMESTAMP | Login timestamp | Activity tracking |

**Common Queries**:
```sql
-- Get recent logins for account
SELECT charid, client_ip, login_time
FROM account_ip_record
WHERE accid = ?
ORDER BY login_time DESC
LIMIT 20;

-- Detect multi-account from same IP
SELECT client_ip, COUNT(DISTINCT accid) as account_count
FROM account_ip_record
WHERE login_time > NOW() - INTERVAL 24 HOUR
GROUP BY client_ip
HAVING account_count > 1;
```

**API Endpoints**:
- `GET /admin/accounts/:id/logins` - Login history (admin)

## Item Tables

### item_basic
**Core item information**

| Column | Type | Description | API Use |
|--------|------|-------------|---------|
| `itemid` | SMALLINT UNSIGNED | Item ID | Primary key |
| `name` | VARCHAR(28) | Item name | Display name |
| `sortname` | VARCHAR(20) | Sorting name | Alphabetical sort |
| `stackSize` | SMALLINT | Max stack (1=not stackable) | Inventory management |
| `flags` | INT | Item flags (rare, ex, etc.) | Item properties |
| `aH` | TINYINT | Auction house category | Market category |
| `NoSale` | TINYINT | Cannot sell to NPCs | Economic flag |
| `BaseSell` | INT | Base NPC sell price | Value |

**Common Queries**:
```sql
-- Get item details
SELECT * FROM item_basic WHERE itemid = ?;

-- Search items by name
SELECT itemid, name, BaseSell
FROM item_basic
WHERE name LIKE ?
LIMIT 20;

-- Get stackable items
SELECT itemid, name, stackSize
FROM item_basic
WHERE stackSize > 1
ORDER BY name;

-- Get valuable items
SELECT itemid, name, BaseSell
FROM item_basic
WHERE BaseSell > 10000
ORDER BY BaseSell DESC;
```

**API Endpoints**:
- `GET /items/:id` - Get item details
- `GET /items/search?name=` - Search items
- `GET /items/category/:category` - Items by AH category

### item_equipment
**Equipment statistics**

| Column | Type | Description | API Use |
|--------|------|-------------|---------|
| `itemId` | SMALLINT UNSIGNED | Item ID | Foreign key |
| `jobs` | INT | Jobs that can equip (bitfield) | Job restrictions |
| `level` | TINYINT | Required level | Level requirement |
| `slots` | INT | Equipment slots (bitfield) | Where equippable |
| `races` | INT | Races that can equip (bitfield) | Race restrictions |
| `slot` | TINYINT | Primary equipment slot | Main slot |
| `HP`, `MP`, `STR`, `DEX`, `VIT`, `AGI`, `INT`, `MND`, `CHR` | SMALLINT | Stat bonuses | Equipment stats |
| `DEF`, `ATT`, `ACC`, `EVA` | SMALLINT | Combat stats | Combat bonuses |
| `shield_size` | TINYINT | Shield size | Shield type |
| `max_charges` | TINYINT | Rechargeable item charges | Usable items |

**Common Queries**:
```sql
-- Get equipment with item details
SELECT ib.itemid, ib.name, ie.level, ie.DEF, ie.HP
FROM item_basic ib
JOIN item_equipment ie ON ib.itemid = ie.itemId
WHERE ie.itemId = ?;

-- Find equipment for job and level
SELECT ib.itemid, ib.name, ie.level, ie.DEF
FROM item_basic ib
JOIN item_equipment ie ON ib.itemid = ie.itemId
WHERE ie.jobs & ? > 0  -- Job bitfield check
  AND ie.level <= ?
ORDER BY ie.level DESC, ie.DEF DESC;

-- Get best armor by slot
SELECT ib.itemid, ib.name, ie.level, ie.DEF
FROM item_basic ib
JOIN item_equipment ie ON ib.itemid = ie.itemId
WHERE ie.slot = ?  -- Equipment slot
ORDER BY ie.DEF DESC
LIMIT 10;
```

**API Endpoints**:
- `GET /items/:id/equipment` - Equipment stats
- `GET /equipment/job/:job/level/:level` - Equipment for job/level
- `GET /equipment/slot/:slot` - Equipment by slot

### item_weapon
**Weapon-specific data**

| Column | Type | Description | API Use |
|--------|------|-------------|---------|
| `itemId` | SMALLINT UNSIGNED | Item ID | Foreign key |
| `damage` | SMALLINT | Base damage | Weapon power |
| `dmgType` | TINYINT | Damage type (slashing/piercing/blunt/ranged) | Damage category |
| `delay` | SMALLINT | Weapon delay (milliseconds) | Attack speed |
| `skill` | TINYINT | Weapon skill type | Skill required |
| `subskill` | TINYINT | Sub skill | Additional skill |
| `hit` | TINYINT | Accuracy bonus | Hit rate |
| `unlock_points` | SMALLINT | Item level | Power scaling |

**Common Queries**:
```sql
-- Get weapon details
SELECT ib.itemid, ib.name, iw.damage, iw.delay, iw.skill
FROM item_basic ib
JOIN item_weapon iw ON ib.itemid = iw.itemId
WHERE iw.itemId = ?;

-- Find weapons by skill type
SELECT ib.itemid, ib.name, iw.damage, iw.delay
FROM item_basic ib
JOIN item_weapon iw ON ib.itemid = iw.itemId
WHERE iw.skill = ?
ORDER BY iw.damage DESC;

-- Calculate DPS
SELECT ib.itemid, ib.name, iw.damage, iw.delay,
       (iw.damage / (iw.delay / 1000.0)) as dps
FROM item_basic ib
JOIN item_weapon iw ON ib.itemid = iw.itemId
ORDER BY dps DESC;
```

**API Endpoints**:
- `GET /items/:id/weapon` - Weapon stats
- `GET /weapons/skill/:skill` - Weapons by skill
- `GET /weapons/rankings` - Weapon DPS rankings

## Mob Tables

### mob_spawn_points
**Monster spawn locations**

| Column | Type | Description | API Use |
|--------|------|-------------|---------|
| `mobid` | INT UNSIGNED | Mob ID | Primary key |
| `mobname` | VARCHAR(24) | Mob name | Display name |
| `groupid` | TINYINT | Spawn group | Spawn grouping |
| `poolid` | SMALLINT | Mob pool ID | Shared stats reference |
| `pos_x`, `pos_y`, `pos_z`, `pos_rot` | FLOAT | Spawn position | Location |
| `respawn` | INT | Respawn time (seconds) | Spawn timer |

**Common Queries**:
```sql
-- Get mob spawn info
SELECT * FROM mob_spawn_points WHERE mobid = ?;

-- Find mobs in zone
SELECT mobid, mobname, pos_x, pos_y, pos_z
FROM mob_spawn_points
WHERE mobid BETWEEN ? AND ?  -- Zone mob ID range
ORDER BY mobname;

-- Get NMs (notorious monsters)
SELECT msp.mobid, msp.mobname, mp.systemid
FROM mob_spawn_points msp
JOIN mob_pools mp ON msp.poolid = mp.poolid
WHERE mp.systemid = 2;  -- NM flag
```

**API Endpoints**:
- `GET /mobs/:id` - Mob spawn details
- `GET /zones/:id/mobs` - Mobs in zone
- `GET /mobs/nm` - Notorious monsters

### mob_pools
**Mob base stats and AI**

| Column | Type | Description | API Use |
|--------|------|-------------|---------|
| `poolid` | SMALLINT | Pool ID | Primary key |
| `name` | VARCHAR(24) | Mob name | Reference name |
| `mJob`, `sJob` | TINYINT | Main/sub job | Mob class |
| `minLevel`, `maxLevel` | TINYINT | Level range | Mob strength |
| `allegiance` | TINYINT | Faction | Enemy/ally |
| `systemid` | TINYINT | System flags | NM/special |
| `behavior` | SMALLINT | AI behavior flags | AI type |
| `aggro` | TINYINT | Aggro type (sight/sound/magic) | Aggro behavior |
| `true_detection` | TINYINT | True sight/sound | Detection type |
| `links` | TINYINT | Linking behavior | Social aggro |

**Common Queries**:
```sql
-- Get mob pool stats
SELECT * FROM mob_pools WHERE poolid = ?;

-- Find mobs by level range
SELECT poolid, name, minLevel, maxLevel
FROM mob_pools
WHERE minLevel >= ? AND maxLevel <= ?
ORDER BY minLevel;
```

**API Endpoints**:
- `GET /mobs/pools/:id` - Mob pool details
- `GET /mobs/level/:min/:max` - Mobs by level

### mob_droplist
**Monster drops**

| Column | Type | Description | API Use |
|--------|------|-------------|---------|
| `dropid` | MEDIUMINT UNSIGNED | Drop entry ID | Primary key |
| `droptype` | TINYINT | Drop type (0=normal, 1=steal, 2=desynth) | Drop category |
| `groupid` | TINYINT | Drop group | Group reference |
| `itemid` | SMALLINT | Item ID | Item dropped |
| `itemRate` | SMALLINT | Drop rate (out of 1000) | Drop chance |

**Common Queries**:
```sql
-- Get mob drops
SELECT ml.itemid, ib.name, ml.itemRate
FROM mob_droplist ml
JOIN mob_groups mg ON ml.dropid = mg.dropid
JOIN item_basic ib ON ml.itemid = ib.itemid
WHERE mg.poolid = ?
  AND ml.droptype = 0
ORDER BY ml.itemRate DESC;

-- Find where item drops
SELECT msp.mobname, msp.mobid, ml.itemRate
FROM mob_droplist ml
JOIN mob_groups mg ON ml.dropid = mg.dropid
JOIN mob_spawn_points msp ON mg.poolid = msp.poolid
JOIN item_basic ib ON ml.itemid = ib.itemid
WHERE ml.itemid = ?
ORDER BY ml.itemRate DESC;

-- Calculate drop percentage
SELECT ml.itemid, ib.name, (ml.itemRate / 10.0) as drop_percent
FROM mob_droplist ml
JOIN item_basic ib ON ml.itemid = ib.itemid
WHERE ml.dropid = ?;
```

**API Endpoints**:
- `GET /mobs/:id/drops` - Mob drop list
- `GET /items/:id/drops-from` - Where item drops

## Economy Tables

### auction_house
**Auction house listings**

| Column | Type | Description | API Use |
|--------|------|-------------|---------|
| `id` | INT UNSIGNED | Listing ID | Primary key |
| `seller` | INT UNSIGNED | Seller character ID | Who listed |
| `seller_name` | VARCHAR(15) | Seller name | Display name |
| `buyer_name` | VARCHAR(15) | Buyer name (when sold) | Transaction record |
| `itemid` | SMALLINT | Item ID | Item listed |
| `quantity` | INT | Quantity | Stack size |
| `sell_price` | INT | Asking price | Sale price |
| `date` | INT UNSIGNED | Listing timestamp | When listed |
| `sale` | INT UNSIGNED | Sale timestamp (0=not sold) | When sold |

**Common Queries**:
```sql
-- Get active listings for item
SELECT id, seller_name, quantity, sell_price
FROM auction_house
WHERE itemid = ? AND sale = 0
ORDER BY sell_price ASC;

-- Get price history
SELECT itemid, sell_price, quantity, FROM_UNIXTIME(sale) as sold_at
FROM auction_house
WHERE itemid = ? AND sale > 0
ORDER BY sale DESC
LIMIT 100;

-- Calculate average price
SELECT itemid,
       AVG(sell_price) as avg_price,
       MIN(sell_price) as min_price,
       MAX(sell_price) as max_price,
       COUNT(*) as sales
FROM auction_house
WHERE itemid = ?
  AND sale > UNIX_TIMESTAMP(NOW() - INTERVAL 7 DAY)
GROUP BY itemid;

-- Top sellers
SELECT seller_name, COUNT(*) as sales, SUM(sell_price) as total_gil
FROM auction_house
WHERE sale > UNIX_TIMESTAMP(NOW() - INTERVAL 30 DAY)
GROUP BY seller_name
ORDER BY total_gil DESC
LIMIT 10;
```

**API Endpoints**:
- `GET /auction/item/:id` - Active listings
- `GET /auction/item/:id/history` - Price history
- `GET /auction/item/:id/stats` - Price statistics
- `GET /auction/sellers/top` - Top sellers

## Crafting Tables

### synth_recipes
**Synthesis recipes**

| Column | Type | Description | API Use |
|--------|------|-------------|---------|
| `ID` | SMALLINT | Recipe ID | Primary key |
| `KeyItem` | SMALLINT | Required key item (0=none) | Unlock requirement |
| `Wood`, `Smith`, `Goldsmith`, `Cloth`, `Leather`, `Bone`, `Alchemy`, `Cook` | TINYINT | Skill requirements | Crafting level |
| `Crystal` | SMALLINT | Crystal required | Synthesis crystal |
| `Ingredient1` through `Ingredient8` | SMALLINT | Ingredient item IDs | Materials needed |
| `Result` | SMALLINT | Result item ID | Crafted item |
| `ResultHQ1`, `ResultHQ2`, `ResultHQ3` | SMALLINT | HQ results | High quality items |
| `ResultQty`, `ResultHQ1Qty`, etc. | TINYINT | Result quantities | Yield |

**Common Queries**:
```sql
-- Get recipe details
SELECT sr.*, ib.name as result_name
FROM synth_recipes sr
JOIN item_basic ib ON sr.Result = ib.itemid
WHERE sr.ID = ?;

-- Find recipes that create item
SELECT sr.ID, sr.Crystal, sr.Wood, sr.Smith
FROM synth_recipes sr
WHERE sr.Result = ? OR sr.ResultHQ1 = ? OR sr.ResultHQ2 = ? OR sr.ResultHQ3 = ?;

-- Get recipes by skill
SELECT sr.ID, ib.name as result_name, sr.Wood
FROM synth_recipes sr
JOIN item_basic ib ON sr.Result = ib.itemid
WHERE sr.Wood > 0
ORDER BY sr.Wood;

-- Get recipe ingredients
SELECT
  sr.ID,
  i1.name as ingredient1, i2.name as ingredient2,
  i3.name as ingredient3, i4.name as ingredient4
FROM synth_recipes sr
LEFT JOIN item_basic i1 ON sr.Ingredient1 = i1.itemid
LEFT JOIN item_basic i2 ON sr.Ingredient2 = i2.itemid
LEFT JOIN item_basic i3 ON sr.Ingredient3 = i3.itemid
LEFT JOIN item_basic i4 ON sr.Ingredient4 = i4.itemid
WHERE sr.ID = ?;
```

**API Endpoints**:
- `GET /recipes/:id` - Recipe details
- `GET /recipes/item/:id` - Recipes for item
- `GET /recipes/skill/:skill` - Recipes by craft

## Zone Tables

### zone_settings
**Zone configuration**

| Column | Type | Description | API Use |
|--------|------|-------------|---------|
| `zoneid` | SMALLINT UNSIGNED | Zone ID | Primary key |
| `name` | VARCHAR(50) | Zone name | Display name |
| `zonetype` | TINYINT | Zone type | Classification |
| `zoneip` | INT | Server IP | Network info |
| `zoneport` | SMALLINT | Server port | Connection |
| `tax` | FLOAT | AH tax rate | Economy |
| `misc` | INT | Misc flags | Features |
| `music_day`, `music_night` | TINYINT | BGM IDs | Soundtrack |

**Common Queries**:
```sql
-- Get zone info
SELECT * FROM zone_settings WHERE zoneid = ?;

-- List all zones
SELECT zoneid, name, zonetype
FROM zone_settings
ORDER BY name;

-- Get zones by type
SELECT zoneid, name
FROM zone_settings
WHERE zonetype = ?  -- 0=outdoor, 1=dungeon, 2=city, etc.
ORDER BY name;
```

**API Endpoints**:
- `GET /zones` - List all zones
- `GET /zones/:id` - Zone details
- `GET /zones/type/:type` - Zones by type

## API Data Aggregation Examples

### Character Summary
```sql
-- Complete character profile
SELECT
  c.charid, c.charname, c.mjob, c.mlvl, c.sjob, c.slvl,
  c.nation, c.pos_zone, c.playtime,
  cp.rank, cp.fame_sandoria, cp.fame_bastok, cp.fame_windurst,
  cj.*,
  cs.str, cs.dex, cs.vit, cs.agi, cs.int, cs.mnd, cs.chr
FROM chars c
LEFT JOIN char_profile cp ON c.charid = cp.charid
LEFT JOIN char_jobs cj ON c.charid = cj.charid
LEFT JOIN char_stats cs ON c.charid = cs.charid
WHERE c.charid = ?;
```

### Market Data
```sql
-- Item market summary
SELECT
  ib.itemid, ib.name, ib.BaseSell,
  COUNT(CASE WHEN ah.sale = 0 THEN 1 END) as active_listings,
  MIN(CASE WHEN ah.sale = 0 THEN ah.sell_price END) as lowest_price,
  AVG(CASE WHEN ah.sale > 0 THEN ah.sell_price END) as avg_sold_price,
  COUNT(CASE WHEN ah.sale > 0 THEN 1 END) as total_sales
FROM item_basic ib
LEFT JOIN auction_house ah ON ib.itemid = ah.itemid
WHERE ib.itemid = ?
GROUP BY ib.itemid;
```

### Server Statistics
```sql
-- Server activity overview
SELECT
  (SELECT COUNT(*) FROM accounts) as total_accounts,
  (SELECT COUNT(*) FROM chars) as total_characters,
  (SELECT COUNT(*) FROM accounts_sessions) as online_players,
  (SELECT COUNT(*) FROM auction_house WHERE sale = 0) as active_auctions,
  (SELECT COUNT(*) FROM auction_house WHERE sale > 0) as completed_sales;
```

## Performance Indexes

### Recommended Indexes

```sql
-- Character lookups
CREATE INDEX idx_chars_accid ON chars(accid);
CREATE INDEX idx_chars_name ON chars(charname);
CREATE INDEX idx_chars_zone ON chars(pos_zone);

-- Inventory lookups
CREATE INDEX idx_inventory_item ON char_inventory(itemId);
CREATE INDEX idx_inventory_char_loc ON char_inventory(charid, location);

-- Auction house
CREATE INDEX idx_ah_item_sale ON auction_house(itemid, sale);
CREATE INDEX idx_ah_seller ON auction_house(seller);

-- Sessions
CREATE INDEX idx_sessions_char ON accounts_sessions(charid);

-- Mob drops
CREATE INDEX idx_drops_item ON mob_droplist(itemid);
```
