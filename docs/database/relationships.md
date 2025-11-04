# LandSandBoat Database Relationships

## Overview

This document describes the relationships between database tables and provides practical JOIN queries for building comprehensive APIs.

## Entity Relationship Diagram

```
accounts (1) ──< (N) chars
                      │
                      ├──< (1) char_stats
                      ├──< (1) char_profile
                      ├──< (1) char_jobs
                      ├──< (1) char_skills
                      ├──< (1) char_look
                      ├──< (1) char_equip (per slot)
                      ├──< (N) char_inventory
                      └──< (1) accounts_sessions

chars >──< linkshell_members >──< linkshells

char_inventory >── (1) item_basic
                         │
                         ├──< (0-1) item_equipment
                         └──< (0-1) item_weapon

mob_spawn_points >── (1) mob_pools >──< mob_groups >── (1) mob_droplist >── (N) item_basic

synth_recipes >── (N) item_basic (ingredients)
              └── (1) item_basic (result)

auction_house >── (1) item_basic
              >── (1) chars (seller)
```

## Core Relationships

### Account → Characters
**One-to-Many**: One account can have multiple characters

```sql
-- Get all characters for an account
SELECT c.*
FROM chars c
WHERE c.accid = ?;

-- Get account with character count
SELECT a.id, a.login, COUNT(c.charid) as char_count
FROM accounts a
LEFT JOIN chars c ON a.accid = c.accid
WHERE a.id = ?
GROUP BY a.id;
```

### Character → Character Tables
**One-to-One**: Each character has one record in supporting tables

```sql
-- Complete character profile with all data
SELECT
  c.*,
  cs.str, cs.dex, cs.vit, cs.agi, cs.int, cs.mnd, cs.chr,
  cs.hp as max_hp, cs.mp as max_mp,
  cp.rank, cp.rankpoints,
  cp.fame_sandoria, cp.fame_bastok, cp.fame_windurst,
  cj.war, cj.mnk, cj.whm, cj.blm, cj.rdm, cj.thf,
  cl.race, cl.face
FROM chars c
LEFT JOIN char_stats cs ON c.charid = cs.charid
LEFT JOIN char_profile cp ON c.charid = cp.charid
LEFT JOIN char_jobs cj ON c.charid = cj.charid
LEFT JOIN char_look cl ON c.charid = cl.charid
WHERE c.charid = ?;
```

### Character → Inventory
**One-to-Many**: Each character has multiple inventory items

```sql
-- Get character's complete inventory with item details
SELECT
  ci.location,
  ci.slot,
  ci.itemId,
  ib.name,
  ci.quantity,
  ib.stackSize,
  ib.BaseSell,
  CASE
    WHEN ci.location = 0 THEN 'Inventory'
    WHEN ci.location = 1 THEN 'Mog Safe'
    WHEN ci.location = 2 THEN 'Storage'
    WHEN ci.location = 3 THEN 'Temporary'
    WHEN ci.location = 4 THEN 'Mog Locker'
    ELSE 'Other'
  END as container_name
FROM char_inventory ci
JOIN item_basic ib ON ci.itemId = ib.itemid
WHERE ci.charid = ?
ORDER BY ci.location, ci.slot;

-- Calculate total inventory value
SELECT
  ci.charid,
  SUM(ib.BaseSell * ci.quantity) as total_value
FROM char_inventory ci
JOIN item_basic ib ON ci.itemId = ib.itemid
WHERE ci.charid = ?
GROUP BY ci.charid;

-- Find characters owning specific item
SELECT DISTINCT
  c.charid,
  c.charname,
  ci.quantity
FROM char_inventory ci
JOIN chars c ON ci.charid = c.charid
WHERE ci.itemId = ?
ORDER BY ci.quantity DESC;
```

### Character → Equipment
**One-to-Many**: Character has up to 16 equipped items

```sql
-- Get equipped items with full details
SELECT
  ce.equipslotid,
  CASE ce.equipslotid
    WHEN 0 THEN 'Main'
    WHEN 1 THEN 'Sub'
    WHEN 2 THEN 'Ranged'
    WHEN 3 THEN 'Ammo'
    WHEN 4 THEN 'Head'
    WHEN 5 THEN 'Body'
    WHEN 6 THEN 'Hands'
    WHEN 7 THEN 'Legs'
    WHEN 8 THEN 'Feet'
    WHEN 9 THEN 'Neck'
    WHEN 10 THEN 'Waist'
    WHEN 11 THEN 'Ear1'
    WHEN 12 THEN 'Ear2'
    WHEN 13 THEN 'Ring1'
    WHEN 14 THEN 'Ring2'
    WHEN 15 THEN 'Back'
  END as slot_name,
  ci.itemId,
  ib.name,
  ie.DEF, ie.HP, ie.MP, ie.STR, ie.DEX, ie.VIT, ie.AGI,
  ie.INT, ie.MND, ie.CHR, ie.ATT, ie.ACC,
  iw.damage, iw.delay
FROM char_equip ce
JOIN char_inventory ci ON ce.charid = ci.charid
  AND ce.slotid = ci.slot
  AND ce.containerid = ci.location
JOIN item_basic ib ON ci.itemId = ib.itemid
LEFT JOIN item_equipment ie ON ci.itemId = ie.itemId
LEFT JOIN item_weapon iw ON ci.itemId = iw.itemId
WHERE ce.charid = ?
ORDER BY ce.equipslotid;

-- Calculate total equipment stats
SELECT
  ce.charid,
  SUM(COALESCE(ie.HP, 0)) as total_hp,
  SUM(COALESCE(ie.MP, 0)) as total_mp,
  SUM(COALESCE(ie.STR, 0)) as total_str,
  SUM(COALESCE(ie.DEX, 0)) as total_dex,
  SUM(COALESCE(ie.DEF, 0)) as total_def,
  SUM(COALESCE(ie.ATT, 0)) as total_att,
  SUM(COALESCE(ie.ACC, 0)) as total_acc
FROM char_equip ce
JOIN char_inventory ci ON ce.charid = ci.charid
  AND ce.slotid = ci.slot
  AND ce.containerid = ci.location
LEFT JOIN item_equipment ie ON ci.itemId = ie.itemId
WHERE ce.charid = ?
GROUP BY ce.charid;
```

### Characters → Linkshells
**Many-to-Many**: Characters can be in multiple linkshells

```sql
-- Get character's linkshells
SELECT
  l.linkshellid,
  l.name,
  l.color,
  lm.rank,
  CASE lm.rank
    WHEN 0 THEN 'Holder'
    WHEN 1 THEN 'Sack'
    WHEN 2 THEN 'Pearl'
  END as rank_name
FROM linkshell_members lm
JOIN linkshells l ON lm.linkshellid = l.linkshellid
WHERE lm.charid = ?;

-- Get linkshell members
SELECT
  c.charid,
  c.charname,
  c.mjob,
  c.mlvl,
  lm.rank
FROM linkshell_members lm
JOIN chars c ON lm.charid = c.charid
WHERE lm.linkshellid = ?
ORDER BY lm.rank, c.charname;

-- Find common linkshells between two characters
SELECT l.linkshellid, l.name
FROM linkshell_members lm1
JOIN linkshell_members lm2 ON lm1.linkshellid = lm2.linkshellid
JOIN linkshells l ON lm1.linkshellid = l.linkshellid
WHERE lm1.charid = ? AND lm2.charid = ?;
```

## Item Relationships

### Item Basic → Equipment/Weapon
**One-to-Zero-or-One**: Items may have equipment or weapon stats

```sql
-- Get complete item data
SELECT
  ib.*,
  ie.jobs, ie.level, ie.races, ie.slot,
  ie.HP, ie.MP, ie.DEF, ie.ATT,
  iw.damage, iw.delay, iw.skill, iw.dmgType
FROM item_basic ib
LEFT JOIN item_equipment ie ON ib.itemid = ie.itemId
LEFT JOIN item_weapon iw ON ib.itemid = iw.itemId
WHERE ib.itemid = ?;

-- Find equipment for specific job and level
SELECT
  ib.itemid,
  ib.name,
  ie.level,
  ie.slot,
  ie.DEF,
  iw.damage
FROM item_basic ib
JOIN item_equipment ie ON ib.itemid = ie.itemId
LEFT JOIN item_weapon iw ON ib.itemid = iw.itemId
WHERE ie.jobs & ? > 0  -- Job bitfield check
  AND ie.level <= ?
  AND ie.slot = ?
ORDER BY ie.level DESC, COALESCE(iw.damage, 0) DESC, ie.DEF DESC;
```

### Items → Crafting Recipes
**Many-to-Many**: Items can be ingredients or results of multiple recipes

```sql
-- Find recipes that create an item
SELECT
  sr.ID as recipe_id,
  sr.Crystal,
  sr.Wood, sr.Smith, sr.Goldsmith, sr.Cloth,
  sr.Leather, sr.Bone, sr.Alchemy, sr.Cook,
  CASE
    WHEN sr.Result = ? THEN 'NQ'
    WHEN sr.ResultHQ1 = ? THEN 'HQ1'
    WHEN sr.ResultHQ2 = ? THEN 'HQ2'
    WHEN sr.ResultHQ3 = ? THEN 'HQ3'
  END as quality,
  sr.ResultQty as quantity
FROM synth_recipes sr
WHERE sr.Result = ?
   OR sr.ResultHQ1 = ?
   OR sr.ResultHQ2 = ?
   OR sr.ResultHQ3 = ?;

-- Find recipes using an item as ingredient
SELECT
  sr.ID as recipe_id,
  result_item.name as result_name,
  sr.Crystal,
  GREATEST(sr.Wood, sr.Smith, sr.Goldsmith, sr.Cloth,
           sr.Leather, sr.Bone, sr.Alchemy, sr.Cook) as skill_level
FROM synth_recipes sr
JOIN item_basic result_item ON sr.Result = result_item.itemid
WHERE sr.Ingredient1 = ?
   OR sr.Ingredient2 = ?
   OR sr.Ingredient3 = ?
   OR sr.Ingredient4 = ?
   OR sr.Ingredient5 = ?
   OR sr.Ingredient6 = ?
   OR sr.Ingredient7 = ?
   OR sr.Ingredient8 = ?;

-- Get full recipe with all ingredients
SELECT
  sr.ID,
  result.name as result_name,
  crystal.name as crystal_name,
  ing1.name as ingredient1, ing2.name as ingredient2,
  ing3.name as ingredient3, ing4.name as ingredient4,
  ing5.name as ingredient5, ing6.name as ingredient6,
  ing7.name as ingredient7, ing8.name as ingredient8,
  hq1.name as hq1_name, hq2.name as hq2_name, hq3.name as hq3_name
FROM synth_recipes sr
JOIN item_basic result ON sr.Result = result.itemid
LEFT JOIN item_basic crystal ON sr.Crystal = crystal.itemid
LEFT JOIN item_basic ing1 ON sr.Ingredient1 = ing1.itemid
LEFT JOIN item_basic ing2 ON sr.Ingredient2 = ing2.itemid
LEFT JOIN item_basic ing3 ON sr.Ingredient3 = ing3.itemid
LEFT JOIN item_basic ing4 ON sr.Ingredient4 = ing4.itemid
LEFT JOIN item_basic ing5 ON sr.Ingredient5 = ing5.itemid
LEFT JOIN item_basic ing6 ON sr.Ingredient6 = ing6.itemid
LEFT JOIN item_basic ing7 ON sr.Ingredient7 = ing7.itemid
LEFT JOIN item_basic ing8 ON sr.Ingredient8 = ing8.itemid
LEFT JOIN item_basic hq1 ON sr.ResultHQ1 = hq1.itemid
LEFT JOIN item_basic hq2 ON sr.ResultHQ2 = hq2.itemid
LEFT JOIN item_basic hq3 ON sr.ResultHQ3 = hq3.itemid
WHERE sr.ID = ?;
```

## Mob Relationships

### Mob Spawn Points → Mob Pools
**Many-to-One**: Multiple spawn points can share a mob pool

```sql
-- Get mob with stats
SELECT
  msp.mobid,
  msp.mobname,
  msp.pos_x, msp.pos_y, msp.pos_z,
  msp.respawn,
  mp.minLevel, mp.maxLevel,
  mp.mJob, mp.sJob,
  mp.allegiance, mp.behavior,
  mp.aggro, mp.true_detection, mp.links
FROM mob_spawn_points msp
JOIN mob_pools mp ON msp.poolid = mp.poolid
WHERE msp.mobid = ?;

-- Find all spawns using same mob pool
SELECT
  msp.mobid,
  msp.mobname,
  msp.pos_x, msp.pos_y, msp.pos_z
FROM mob_spawn_points msp
WHERE msp.poolid = ?;
```

### Mobs → Drops
**Many-to-Many**: Mobs can drop multiple items

```sql
-- Get all drops for a mob
SELECT
  ml.itemid,
  ib.name,
  ml.itemRate,
  (ml.itemRate / 10.0) as drop_percent,
  ml.droptype,
  CASE ml.droptype
    WHEN 0 THEN 'Normal'
    WHEN 1 THEN 'Steal'
    WHEN 2 THEN 'Desynth'
  END as drop_type_name
FROM mob_spawn_points msp
JOIN mob_groups mg ON msp.poolid = mg.poolid
JOIN mob_droplist ml ON mg.dropid = ml.dropid
JOIN item_basic ib ON ml.itemid = ib.itemid
WHERE msp.mobid = ?
ORDER BY ml.itemRate DESC;

-- Find mobs that drop specific item
SELECT
  msp.mobid,
  msp.mobname,
  ml.itemRate,
  (ml.itemRate / 10.0) as drop_percent,
  mp.minLevel, mp.maxLevel,
  FLOOR(msp.mobid / 1000) * 1000 as zone_range
FROM mob_droplist ml
JOIN mob_groups mg ON ml.dropid = mg.dropid
JOIN mob_spawn_points msp ON mg.poolid = msp.poolid
JOIN mob_pools mp ON msp.poolid = mp.poolid
WHERE ml.itemid = ?
ORDER BY ml.itemRate DESC;

-- Best drop rates for an item
SELECT
  msp.mobname,
  ml.itemRate,
  (ml.itemRate / 10.0) as drop_percent,
  mp.minLevel, mp.maxLevel,
  COUNT(*) as spawn_count
FROM mob_droplist ml
JOIN mob_groups mg ON ml.dropid = mg.dropid
JOIN mob_spawn_points msp ON mg.poolid = msp.poolid
JOIN mob_pools mp ON msp.poolid = mp.poolid
WHERE ml.itemid = ?
GROUP BY msp.mobname, ml.itemRate, mp.minLevel, mp.maxLevel
ORDER BY ml.itemRate DESC;
```

## Economy Relationships

### Auction House → Items and Characters
**Many-to-One**: Multiple listings for same item/seller

```sql
-- Get auction house data with item and seller info
SELECT
  ah.id,
  ah.itemid,
  ib.name as item_name,
  ah.quantity,
  ah.sell_price,
  (ah.sell_price / ah.quantity) as price_per_unit,
  ah.seller,
  ah.seller_name,
  FROM_UNIXTIME(ah.date) as listed_at,
  CASE
    WHEN ah.sale = 0 THEN 'Active'
    ELSE 'Sold'
  END as status,
  CASE
    WHEN ah.sale > 0 THEN FROM_UNIXTIME(ah.sale)
    ELSE NULL
  END as sold_at
FROM auction_house ah
JOIN item_basic ib ON ah.itemid = ib.itemid
WHERE ah.itemid = ?
ORDER BY ah.sale DESC, ah.sell_price ASC;

-- Get seller's auction history
SELECT
  ah.itemid,
  ib.name,
  ah.quantity,
  ah.sell_price,
  FROM_UNIXTIME(ah.date) as listed_at,
  CASE WHEN ah.sale > 0 THEN 'Sold' ELSE 'Active' END as status
FROM auction_house ah
JOIN item_basic ib ON ah.itemid = ib.itemid
WHERE ah.seller = ?
ORDER BY ah.date DESC;

-- Market summary for item
SELECT
  ib.itemid,
  ib.name,
  COUNT(CASE WHEN ah.sale = 0 THEN 1 END) as active_listings,
  MIN(CASE WHEN ah.sale = 0 THEN ah.sell_price END) as lowest_price,
  AVG(CASE WHEN ah.sale > 0 THEN ah.sell_price END) as avg_sold_price,
  COUNT(CASE WHEN ah.sale > 0 THEN 1 END) as total_sales,
  SUM(CASE WHEN ah.sale > 0 THEN ah.sell_price END) as total_volume
FROM item_basic ib
LEFT JOIN auction_house ah ON ib.itemid = ah.itemid
WHERE ib.itemid = ?
GROUP BY ib.itemid, ib.name;
```

## Session and Activity Relationships

### Active Sessions → Characters
**One-to-One**: Each active session has one character

```sql
-- Get online players with location
SELECT
  s.charid,
  c.charname,
  c.mjob, c.mlvl,
  c.pos_zone,
  zs.name as zone_name,
  INET_NTOA(s.client_addr) as client_ip
FROM accounts_sessions s
JOIN chars c ON s.charid = c.charid
LEFT JOIN zone_settings zs ON c.pos_zone = zs.zoneid
ORDER BY c.charname;

-- Count online players by zone
SELECT
  c.pos_zone,
  zs.name as zone_name,
  COUNT(*) as player_count
FROM accounts_sessions s
JOIN chars c ON s.charid = c.charid
LEFT JOIN zone_settings zs ON c.pos_zone = zs.zoneid
GROUP BY c.pos_zone, zs.name
ORDER BY player_count DESC;

-- Get account's active sessions
SELECT
  s.charid,
  c.charname,
  c.pos_zone,
  INET_NTOA(s.client_addr) as client_ip,
  INET_NTOA(s.server_addr) as server_ip
FROM accounts_sessions s
JOIN chars c ON s.charid = c.charid
WHERE s.accid = ?;
```

### Login History → Characters
**Many-to-One**: Multiple login records per character

```sql
-- Get character login history
SELECT
  air.charid,
  c.charname,
  air.client_ip,
  air.login_time
FROM account_ip_record air
JOIN chars c ON air.charid = c.charid
WHERE air.charid = ?
ORDER BY air.login_time DESC
LIMIT 50;

-- Find accounts with suspicious activity (same IP, different accounts)
SELECT
  air.client_ip,
  COUNT(DISTINCT air.accid) as account_count,
  GROUP_CONCAT(DISTINCT a.login) as accounts
FROM account_ip_record air
JOIN accounts a ON air.accid = a.id
WHERE air.login_time > NOW() - INTERVAL 7 DAY
GROUP BY air.client_ip
HAVING account_count > 1
ORDER BY account_count DESC;
```

## Complex Aggregation Queries

### Character Wealth Analysis
```sql
-- Calculate total character wealth (gil + inventory value)
SELECT
  c.charid,
  c.charname,
  COALESCE(cp.gil, 0) as gil,
  COALESCE(SUM(ib.BaseSell * ci.quantity), 0) as inventory_value,
  COALESCE(cp.gil, 0) + COALESCE(SUM(ib.BaseSell * ci.quantity), 0) as total_wealth
FROM chars c
LEFT JOIN char_points cp ON c.charid = cp.charid
LEFT JOIN char_inventory ci ON c.charid = ci.charid
LEFT JOIN item_basic ib ON ci.itemId = ib.itemid
WHERE c.charid = ?
GROUP BY c.charid, c.charname, cp.gil;
```

### Market Trend Analysis
```sql
-- 30-day price trends for item
SELECT
  DATE(FROM_UNIXTIME(ah.sale)) as sale_date,
  COUNT(*) as sales,
  AVG(ah.sell_price) as avg_price,
  MIN(ah.sell_price) as min_price,
  MAX(ah.sell_price) as max_price,
  SUM(ah.sell_price * ah.quantity) as total_volume
FROM auction_house ah
WHERE ah.itemid = ?
  AND ah.sale > UNIX_TIMESTAMP(NOW() - INTERVAL 30 DAY)
GROUP BY sale_date
ORDER BY sale_date DESC;
```

### Player Activity Metrics
```sql
-- Server activity summary
SELECT
  DATE(air.login_time) as login_date,
  COUNT(DISTINCT air.accid) as unique_accounts,
  COUNT(DISTINCT air.charid) as unique_characters,
  COUNT(*) as total_logins
FROM account_ip_record air
WHERE air.login_time > NOW() - INTERVAL 30 DAY
GROUP BY login_date
ORDER BY login_date DESC;
```

### Item Popularity
```sql
-- Most owned items
SELECT
  ci.itemId,
  ib.name,
  COUNT(DISTINCT ci.charid) as owner_count,
  SUM(ci.quantity) as total_quantity
FROM char_inventory ci
JOIN item_basic ib ON ci.itemId = ib.itemid
GROUP BY ci.itemId, ib.name
ORDER BY owner_count DESC
LIMIT 100;

-- Most actively traded items
SELECT
  ah.itemid,
  ib.name,
  COUNT(*) as transaction_count,
  AVG(ah.sell_price) as avg_price,
  SUM(ah.sell_price * ah.quantity) as total_volume
FROM auction_house ah
JOIN item_basic ib ON ah.itemid = ib.itemid
WHERE ah.sale > UNIX_TIMESTAMP(NOW() - INTERVAL 7 DAY)
GROUP BY ah.itemid, ib.name
ORDER BY transaction_count DESC
LIMIT 100;
```

### Job Distribution
```sql
-- Character job distribution
SELECT
  c.mjob,
  COUNT(*) as char_count,
  AVG(c.mlvl) as avg_level,
  COUNT(CASE WHEN c.mlvl = 99 THEN 1 END) as max_level_count
FROM chars c
GROUP BY c.mjob
ORDER BY char_count DESC;

-- Multi-job progression
SELECT
  cj.charid,
  c.charname,
  (cj.war + cj.mnk + cj.whm + cj.blm + cj.rdm + cj.thf +
   cj.pld + cj.drk + cj.bst + cj.brd + cj.rng + cj.sam +
   cj.nin + cj.drg + cj.smn + cj.blu + cj.cor + cj.pup +
   cj.dnc + cj.sch + cj.geo + cj.run) as total_levels,
  (CASE WHEN cj.war > 0 THEN 1 ELSE 0 END +
   CASE WHEN cj.mnk > 0 THEN 1 ELSE 0 END +
   CASE WHEN cj.whm > 0 THEN 1 ELSE 0 END +
   CASE WHEN cj.blm > 0 THEN 1 ELSE 0 END) as jobs_unlocked
FROM char_jobs cj
JOIN chars c ON cj.charid = c.charid
ORDER BY total_levels DESC
LIMIT 100;
```

## Data Integrity Queries

### Orphaned Records
```sql
-- Characters without accounts (should not exist)
SELECT c.*
FROM chars c
LEFT JOIN accounts a ON c.accid = a.id
WHERE a.id IS NULL;

-- Inventory items with invalid item IDs
SELECT ci.*
FROM char_inventory ci
LEFT JOIN item_basic ib ON ci.itemId = ib.itemid
WHERE ib.itemid IS NULL;

-- Equipment referencing non-existent inventory slots
SELECT ce.*
FROM char_equip ce
LEFT JOIN char_inventory ci ON ce.charid = ci.charid
  AND ce.slotid = ci.slot
  AND ce.containerid = ci.location
WHERE ci.charid IS NULL;
```

### Data Consistency Checks
```sql
-- Characters with inconsistent job data
SELECT c.charid, c.charname, c.mjob, cj.war
FROM chars c
LEFT JOIN char_jobs cj ON c.charid = cj.charid
WHERE c.mjob = 1 AND (cj.war IS NULL OR cj.war != c.mlvl);

-- Check for duplicate sessions (should not happen)
SELECT charid, COUNT(*) as session_count
FROM accounts_sessions
GROUP BY charid
HAVING session_count > 1;
```

## Performance Considerations

### Indexing Strategy
```sql
-- Character lookups
CREATE INDEX idx_chars_accid ON chars(accid);
CREATE INDEX idx_chars_name ON chars(charname);
CREATE INDEX idx_chars_job ON chars(mjob);

-- Inventory operations
CREATE INDEX idx_inventory_char_loc ON char_inventory(charid, location);
CREATE INDEX idx_inventory_item ON char_inventory(itemId);

-- Market data
CREATE INDEX idx_ah_item_sale ON auction_house(itemid, sale);
CREATE INDEX idx_ah_sale_date ON auction_house(sale);

-- Session tracking
CREATE INDEX idx_sessions_char ON accounts_sessions(charid);
CREATE INDEX idx_sessions_acc ON accounts_sessions(accid);

-- Login history
CREATE INDEX idx_ip_record_time ON account_ip_record(login_time);
CREATE INDEX idx_ip_record_char ON account_ip_record(charid);
```

### Query Optimization Tips

1. **Use EXPLAIN** to analyze query plans
2. **Limit JOINs** to necessary tables only
3. **Add WHERE clauses** before JOINs when possible
4. **Use LIMIT** for large result sets
5. **Cache frequently accessed data** in application layer
6. **Use covering indexes** for common queries
7. **Avoid SELECT *** - specify needed columns
8. **Use prepared statements** for repeated queries
