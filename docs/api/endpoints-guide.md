# LandSandBoat API Endpoints Guide

## Overview

This guide provides practical API endpoint designs for building web services around the LandSandBoat database. All examples use RESTful design patterns with JSON responses.

## Base API Structure

```
Base URL: http://localhost:5000/api/v1
Authentication: Bearer token (JWT recommended)
Content-Type: application/json
```

## Authentication Endpoints

### POST /auth/login
**Login to get API token**

**Request**:
```json
{
  "username": "player123",
  "password": "secret"
}
```

**Response**:
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "account": {
    "id": 1,
    "username": "player123",
    "priv": 0
  }
}
```

**SQL Query**:
```sql
SELECT id, login, priv, status
FROM accounts
WHERE login = ? AND password = ?;
```

### GET /auth/verify
**Verify token validity**

**Headers**: `Authorization: Bearer {token}`

**Response**:
```json
{
  "valid": true,
  "account_id": 1,
  "expires": "2025-11-05T00:00:00Z"
}
```

## Character Endpoints

### GET /characters/:id
**Get character details**

**Response**:
```json
{
  "charid": 1,
  "charname": "Adventurer",
  "nation": 0,
  "nation_name": "San d'Oria",
  "race": 1,
  "race_name": "Hume",
  "job": {
    "main": {
      "id": 1,
      "name": "WAR",
      "level": 75
    },
    "sub": {
      "id": 2,
      "name": "MNK",
      "level": 37
    }
  },
  "stats": {
    "hp": 1850,
    "mp": 450,
    "str": 85,
    "dex": 72,
    "vit": 88,
    "agi": 68,
    "int": 55,
    "mnd": 60,
    "chr": 50
  },
  "location": {
    "zone_id": 230,
    "zone_name": "Southern San d'Oria",
    "position": {
      "x": 10.5,
      "y": 0.0,
      "z": -45.2
    }
  },
  "profile": {
    "rank": 10,
    "fame": {
      "sandoria": 9,
      "bastok": 5,
      "windurst": 6
    }
  },
  "playtime": 3600000,
  "playtime_formatted": "1000h 0m",
  "deaths": 42,
  "gmlevel": 0
}
```

**SQL Query**:
```sql
SELECT
  c.charid, c.charname, c.nation, c.mjob, c.mlvl,
  c.sjob, c.slvl, c.pos_zone, c.pos_x, c.pos_y, c.pos_z,
  c.playtime, c.deaths, c.gmlevel,
  cs.hp, cs.mp, cs.str, cs.dex, cs.vit, cs.agi,
  cs.int, cs.mnd, cs.chr,
  cp.rank, cp.fame_sandoria, cp.fame_bastok, cp.fame_windurst,
  cl.race
FROM chars c
LEFT JOIN char_stats cs ON c.charid = cs.charid
LEFT JOIN char_profile cp ON c.charid = cp.charid
LEFT JOIN char_look cl ON c.charid = cl.charid
WHERE c.charid = ?;
```

### GET /characters/search
**Search characters by name**

**Query Parameters**:
- `name` (string, required): Character name (supports wildcards)
- `limit` (int, default=20): Results limit
- `offset` (int, default=0): Pagination offset

**Example**: `/characters/search?name=Adven%&limit=10`

**Response**:
```json
{
  "results": [
    {
      "charid": 1,
      "charname": "Adventurer",
      "mjob": "WAR",
      "mlvl": 75,
      "nation": "San d'Oria"
    }
  ],
  "total": 1,
  "limit": 10,
  "offset": 0
}
```

**SQL Query**:
```sql
SELECT c.charid, c.charname, c.mjob, c.mlvl, c.nation
FROM chars c
WHERE c.charname LIKE ?
ORDER BY c.charname
LIMIT ? OFFSET ?;
```

### GET /characters/:id/jobs
**Get all job levels for character**

**Response**:
```json
{
  "charid": 1,
  "jobs": {
    "war": {"level": 75, "exp": 0},
    "mnk": {"level": 37, "exp": 12500},
    "whm": {"level": 50, "exp": 5000},
    "blm": {"level": 1, "exp": 0}
  },
  "unlocked": ["war", "mnk", "whm", "blm", "rdm", "thf"]
}
```

**SQL Query**:
```sql
SELECT * FROM char_jobs WHERE charid = ?;
```

### GET /characters/:id/inventory
**Get character inventory**

**Query Parameters**:
- `location` (int, optional): Container ID (0=inventory, 1=safe, etc.)

**Response**:
```json
{
  "charid": 1,
  "location": 0,
  "location_name": "Inventory",
  "capacity": 80,
  "used": 45,
  "items": [
    {
      "slot": 0,
      "item_id": 4509,
      "name": "Phoenix Down",
      "quantity": 12,
      "icon_id": 3591,
      "stackable": true,
      "stack_size": 12
    },
    {
      "slot": 1,
      "item_id": 13446,
      "name": "Bronze Sword",
      "quantity": 1,
      "icon_id": 1234,
      "stackable": false,
      "signature": "Blacksmith Joe"
    }
  ]
}
```

**SQL Query**:
```sql
SELECT
  ci.slot, ci.itemId, ci.quantity, ci.signature,
  ib.name, ib.stackSize, ib.flags
FROM char_inventory ci
JOIN item_basic ib ON ci.itemId = ib.itemid
WHERE ci.charid = ? AND ci.location = ?
ORDER BY ci.slot;
```

### GET /characters/:id/equipment
**Get equipped items**

**Response**:
```json
{
  "charid": 1,
  "equipment": {
    "main": {
      "slot_id": 0,
      "item_id": 13446,
      "name": "Bronze Sword",
      "damage": 15,
      "delay": 264
    },
    "sub": {
      "slot_id": 1,
      "item_id": 12345,
      "name": "Round Shield",
      "def": 10
    },
    "head": {
      "slot_id": 4,
      "item_id": 12345,
      "name": "Leather Cap",
      "def": 8,
      "hp": 15
    }
  },
  "total_stats": {
    "hp": 150,
    "mp": 50,
    "str": 10,
    "def": 45,
    "att": 25
  }
}
```

**SQL Query**:
```sql
SELECT
  ce.equipslotid,
  ci.itemId,
  ib.name,
  ie.HP, ie.MP, ie.STR, ie.DEX, ie.DEF, ie.ATT,
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
```

### GET /characters/:id/skills
**Get character skills**

**Query Parameters**:
- `type` (string, optional): Filter by type (combat, magic, crafting)

**Response**:
```json
{
  "charid": 1,
  "combat": {
    "slashing": 250,
    "piercing": 180,
    "hand_to_hand": 150,
    "archery": 100
  },
  "magic": {
    "divine": 0,
    "healing": 80,
    "enhancing": 120,
    "elemental": 50
  },
  "crafting": {
    "smithing": 60,
    "goldsmithing": 45,
    "cooking": 30
  }
}
```

**SQL Query**:
```sql
SELECT * FROM char_skills WHERE charid = ?;
```

### POST /characters/:id/items
**Add item to character inventory (Admin)**

**Request**:
```json
{
  "item_id": 4509,
  "quantity": 12,
  "location": 0
}
```

**Response**:
```json
{
  "success": true,
  "charid": 1,
  "slot": 45,
  "item_id": 4509,
  "quantity": 12,
  "message": "Added 12x Phoenix Down to inventory"
}
```

**SQL Query**:
```sql
-- Find empty slot
SELECT MIN(t.slot) as empty_slot
FROM (
  SELECT s.slot
  FROM (SELECT 0 as slot UNION ALL SELECT 1 UNION ALL ... SELECT 79) s
  LEFT JOIN char_inventory ci ON s.slot = ci.slot
    AND ci.charid = ? AND ci.location = ?
  WHERE ci.slot IS NULL
) t;

-- Insert item
INSERT INTO char_inventory (charid, location, slot, itemId, quantity)
VALUES (?, ?, ?, ?, ?);
```

### PATCH /characters/:id
**Update character data (Admin)**

**Request**:
```json
{
  "pos_zone": 231,
  "pos_x": 0.0,
  "pos_y": 0.0,
  "pos_z": 0.0,
  "hp": 1850,
  "mp": 450
}
```

**Response**:
```json
{
  "success": true,
  "charid": 1,
  "updated_fields": ["pos_zone", "pos_x", "pos_y", "pos_z", "hp", "mp"]
}
```

## Server Status Endpoints

### GET /server/status
**Get server status**

**Response**:
```json
{
  "online": true,
  "uptime": 3600,
  "uptime_formatted": "1h 0m",
  "players": {
    "online": 42,
    "peak_today": 67,
    "total_accounts": 1234,
    "total_characters": 2345
  },
  "zones": {
    "active_zones": 25,
    "players_by_zone": {
      "230": 12,
      "231": 8,
      "232": 5
    }
  }
}
```

**SQL Queries**:
```sql
-- Online players
SELECT COUNT(*) FROM accounts_sessions;

-- Total accounts/characters
SELECT
  (SELECT COUNT(*) FROM accounts) as accounts,
  (SELECT COUNT(*) FROM chars) as characters;

-- Players by zone
SELECT c.pos_zone, COUNT(*) as count
FROM accounts_sessions s
JOIN chars c ON s.charid = c.charid
GROUP BY c.pos_zone;
```

### GET /server/online
**Get list of online players**

**Query Parameters**:
- `zone_id` (int, optional): Filter by zone

**Response**:
```json
{
  "online_count": 42,
  "players": [
    {
      "charid": 1,
      "charname": "Adventurer",
      "mjob": "WAR",
      "mlvl": 75,
      "zone_id": 230,
      "zone_name": "Southern San d'Oria"
    }
  ]
}
```

**SQL Query**:
```sql
SELECT c.charid, c.charname, c.mjob, c.mlvl, c.pos_zone
FROM accounts_sessions s
JOIN chars c ON s.charid = c.charid
WHERE (? IS NULL OR c.pos_zone = ?)
ORDER BY c.charname;
```

## Item Endpoints

### GET /items/:id
**Get item details**

**Response**:
```json
{
  "item_id": 4509,
  "name": "Phoenix Down",
  "description": "Revives a KO'd party member.",
  "stack_size": 12,
  "flags": ["rare", "ex"],
  "npc_sell_price": 1000,
  "auction_house": {
    "category": 1,
    "category_name": "Medicines"
  },
  "equipment": null,
  "weapon": null
}
```

**SQL Query**:
```sql
SELECT
  ib.*,
  ie.*,
  iw.*
FROM item_basic ib
LEFT JOIN item_equipment ie ON ib.itemid = ie.itemId
LEFT JOIN item_weapon iw ON ib.itemid = iw.itemId
WHERE ib.itemid = ?;
```

### GET /items/search
**Search items**

**Query Parameters**:
- `name` (string): Item name search
- `category` (int): AH category
- `min_level` (int): Minimum equip level
- `max_level` (int): Maximum equip level

**Response**:
```json
{
  "results": [
    {
      "item_id": 13446,
      "name": "Bronze Sword",
      "level": 10,
      "jobs": ["WAR", "RDM", "THF", "PLD", "DRK"],
      "damage": 15,
      "delay": 264
    }
  ],
  "total": 1
}
```

**SQL Query**:
```sql
SELECT
  ib.itemid, ib.name,
  ie.level, ie.jobs,
  iw.damage, iw.delay
FROM item_basic ib
LEFT JOIN item_equipment ie ON ib.itemid = ie.itemId
LEFT JOIN item_weapon iw ON ib.itemid = iw.itemId
WHERE ib.name LIKE ?
  AND (? IS NULL OR ib.aH = ?)
  AND (? IS NULL OR ie.level >= ?)
  AND (? IS NULL OR ie.level <= ?)
LIMIT 50;
```

### GET /items/:id/market
**Get item market data**

**Response**:
```json
{
  "item_id": 4509,
  "name": "Phoenix Down",
  "market": {
    "active_listings": 15,
    "lowest_price": 950,
    "average_price": 1050,
    "highest_price": 1200,
    "recent_sales": [
      {
        "price": 1000,
        "quantity": 12,
        "sold_at": "2025-11-04T12:00:00Z"
      }
    ],
    "price_history_7d": {
      "average": 1025,
      "min": 900,
      "max": 1150,
      "total_sales": 150
    }
  }
}
```

**SQL Queries**:
```sql
-- Active listings
SELECT COUNT(*) as active, MIN(sell_price) as lowest
FROM auction_house
WHERE itemid = ? AND sale = 0;

-- Recent sales
SELECT sell_price, quantity, FROM_UNIXTIME(sale) as sold_at
FROM auction_house
WHERE itemid = ? AND sale > 0
ORDER BY sale DESC
LIMIT 10;

-- 7-day stats
SELECT
  AVG(sell_price) as avg_price,
  MIN(sell_price) as min_price,
  MAX(sell_price) as max_price,
  COUNT(*) as sales
FROM auction_house
WHERE itemid = ?
  AND sale > UNIX_TIMESTAMP(NOW() - INTERVAL 7 DAY);
```

### GET /items/:id/crafting
**Get crafting recipes for item**

**Response**:
```json
{
  "item_id": 13446,
  "name": "Bronze Sword",
  "recipes": [
    {
      "recipe_id": 100,
      "skill": "smithing",
      "skill_level": 10,
      "crystal": "Fire Crystal",
      "ingredients": [
        {"item_id": 640, "name": "Bronze Ingot", "quantity": 2},
        {"item_id": 698, "name": "Leather", "quantity": 1}
      ],
      "result": {
        "normal": {"item_id": 13446, "quantity": 1},
        "hq1": {"item_id": 13447, "quantity": 1},
        "hq2": null,
        "hq3": null
      }
    }
  ]
}
```

**SQL Query**:
```sql
SELECT
  sr.ID, sr.Crystal,
  sr.Wood, sr.Smith, sr.Goldsmith, sr.Cloth,
  sr.Leather, sr.Bone, sr.Alchemy, sr.Cook,
  sr.Ingredient1, sr.Ingredient2, sr.Ingredient3,
  sr.Ingredient4, sr.Ingredient5, sr.Ingredient6,
  sr.Ingredient7, sr.Ingredient8,
  sr.Result, sr.ResultQty,
  sr.ResultHQ1, sr.ResultHQ1Qty,
  sr.ResultHQ2, sr.ResultHQ2Qty,
  sr.ResultHQ3, sr.ResultHQ3Qty
FROM synth_recipes sr
WHERE sr.Result = ?
   OR sr.ResultHQ1 = ?
   OR sr.ResultHQ2 = ?
   OR sr.ResultHQ3 = ?;
```

## Mob Endpoints

### GET /mobs/:id
**Get mob details**

**Response**:
```json
{
  "mob_id": 17719500,
  "mob_name": "Orcish Fighter",
  "pool_id": 1234,
  "level": {
    "min": 20,
    "max": 23
  },
  "job": {
    "main": "WAR",
    "sub": "MNK"
  },
  "spawn": {
    "zone_id": 230,
    "zone_name": "Southern San d'Oria",
    "position": {
      "x": 100.5,
      "y": 0.0,
      "z": -45.2
    },
    "respawn_time": 300
  },
  "behavior": {
    "aggro": "sight",
    "links": true,
    "true_sight": false
  },
  "drops": [
    {
      "item_id": 4509,
      "name": "Phoenix Down",
      "drop_rate": 15.5,
      "drop_type": "normal"
    }
  ]
}
```

**SQL Queries**:
```sql
-- Mob spawn data
SELECT
  msp.mobid, msp.mobname, msp.poolid,
  msp.pos_x, msp.pos_y, msp.pos_z, msp.respawn,
  mp.minLevel, mp.maxLevel, mp.mJob, mp.sJob,
  mp.aggro, mp.links, mp.true_detection
FROM mob_spawn_points msp
JOIN mob_pools mp ON msp.poolid = mp.poolid
WHERE msp.mobid = ?;

-- Mob drops
SELECT ml.itemid, ib.name, ml.itemRate, ml.droptype
FROM mob_droplist ml
JOIN mob_groups mg ON ml.dropid = mg.dropid
JOIN item_basic ib ON ml.itemid = ib.itemid
JOIN mob_spawn_points msp ON mg.poolid = msp.poolid
WHERE msp.mobid = ?
ORDER BY ml.itemRate DESC;
```

### GET /mobs/zone/:zone_id
**Get all mobs in zone**

**Query Parameters**:
- `nm_only` (bool): Only notorious monsters

**Response**:
```json
{
  "zone_id": 230,
  "zone_name": "Southern San d'Oria",
  "mob_count": 45,
  "mobs": [
    {
      "mob_id": 17719500,
      "mob_name": "Orcish Fighter",
      "level": "20-23",
      "is_nm": false
    }
  ]
}
```

### GET /mobs/nm
**Get all notorious monsters**

**Response**:
```json
{
  "total_nms": 234,
  "nms": [
    {
      "mob_id": 17719600,
      "mob_name": "Argus",
      "zone_id": 230,
      "zone_name": "Southern San d'Oria",
      "level": 75,
      "respawn_time": 79200
    }
  ]
}
```

**SQL Query**:
```sql
SELECT
  msp.mobid, msp.mobname, msp.respawn,
  mp.minLevel, mp.maxLevel,
  FLOOR(msp.mobid / 1000) * 1000 as zone_range
FROM mob_spawn_points msp
JOIN mob_pools mp ON msp.poolid = mp.poolid
WHERE mp.systemid = 2
ORDER BY msp.mobname;
```

## Auction House Endpoints

### GET /auction/categories
**Get AH categories**

**Response**:
```json
{
  "categories": [
    {"id": 1, "name": "Medicines", "item_count": 234},
    {"id": 2, "name": "Weapons", "item_count": 567}
  ]
}
```

### GET /auction/listings
**Get current auction house listings**

**Query Parameters**:
- `item_id` (int): Filter by item
- `category` (int): Filter by AH category
- `max_price` (int): Maximum price
- `limit` (int): Results limit

**Response**:
```json
{
  "total": 150,
  "listings": [
    {
      "listing_id": 12345,
      "item_id": 4509,
      "item_name": "Phoenix Down",
      "quantity": 12,
      "price": 1000,
      "price_per_unit": 83.33,
      "seller": "PlayerName",
      "listed_at": "2025-11-04T10:00:00Z"
    }
  ]
}
```

**SQL Query**:
```sql
SELECT
  ah.id, ah.itemid, ib.name, ah.quantity,
  ah.sell_price, ah.seller_name,
  FROM_UNIXTIME(ah.date) as listed_at
FROM auction_house ah
JOIN item_basic ib ON ah.itemid = ib.itemid
WHERE ah.sale = 0
  AND (? IS NULL OR ah.itemid = ?)
  AND (? IS NULL OR ib.aH = ?)
  AND (? IS NULL OR ah.sell_price <= ?)
ORDER BY ah.sell_price ASC
LIMIT ?;
```

### GET /auction/history
**Get auction house price history**

**Query Parameters**:
- `item_id` (int, required): Item to查询
- `days` (int, default=7): Days of history

**Response**:
```json
{
  "item_id": 4509,
  "item_name": "Phoenix Down",
  "period_days": 7,
  "statistics": {
    "total_sales": 150,
    "average_price": 1025,
    "median_price": 1000,
    "min_price": 900,
    "max_price": 1200,
    "std_deviation": 75.5
  },
  "daily_averages": [
    {"date": "2025-11-04", "avg_price": 1050, "sales": 25},
    {"date": "2025-11-03", "avg_price": 1000, "sales": 20}
  ]
}
```

**SQL Query**:
```sql
-- Statistics
SELECT
  COUNT(*) as sales,
  AVG(sell_price) as avg_price,
  MIN(sell_price) as min_price,
  MAX(sell_price) as max_price,
  STDDEV(sell_price) as std_dev
FROM auction_house
WHERE itemid = ?
  AND sale > UNIX_TIMESTAMP(NOW() - INTERVAL ? DAY);

-- Daily averages
SELECT
  DATE(FROM_UNIXTIME(sale)) as sale_date,
  AVG(sell_price) as avg_price,
  COUNT(*) as sales
FROM auction_house
WHERE itemid = ?
  AND sale > UNIX_TIMESTAMP(NOW() - INTERVAL ? DAY)
GROUP BY sale_date
ORDER BY sale_date DESC;
```

## Leaderboard Endpoints

### GET /leaderboards/levels
**Character level rankings**

**Query Parameters**:
- `job` (string): Filter by job
- `limit` (int): Results limit

**Response**:
```json
{
  "job": "all",
  "leaderboard": [
    {
      "rank": 1,
      "charid": 1,
      "charname": "Adventurer",
      "mjob": "WAR",
      "mlvl": 99,
      "nation": "San d'Oria"
    }
  ]
}
```

**SQL Query**:
```sql
SELECT c.charid, c.charname, c.mjob, c.mlvl, c.nation
FROM chars c
WHERE (? IS NULL OR c.mjob = ?)
ORDER BY c.mlvl DESC, c.charname ASC
LIMIT ?;
```

### GET /leaderboards/wealth
**Gil rankings**

**Response**:
```json
{
  "leaderboard": [
    {
      "rank": 1,
      "charid": 1,
      "charname": "Richguy",
      "gil": 99999999
    }
  ]
}
```

### GET /leaderboards/crafting
**Crafting skill rankings**

**Query Parameters**:
- `skill` (string, required): Crafting skill name

**Response**:
```json
{
  "skill": "smithing",
  "leaderboard": [
    {
      "rank": 1,
      "charid": 1,
      "charname": "MasterSmith",
      "skill_level": 110
    }
  ]
}
```

**SQL Query**:
```sql
SELECT cs.charid, c.charname, cs.smithing
FROM char_skills cs
JOIN chars c ON cs.charid = c.charid
ORDER BY cs.smithing DESC
LIMIT 100;
```

## Admin Endpoints

### POST /admin/announce
**Broadcast server announcement**

**Request**:
```json
{
  "message": "Server restart in 10 minutes!"
}
```

**Response**:
```json
{
  "success": true,
  "message": "Announcement sent to all players",
  "recipient_count": 42
}
```

**Implementation**: Uses ZeroMQ IPC or HTTP API to World Server

### PATCH /admin/characters/:id/teleport
**Teleport character**

**Request**:
```json
{
  "zone_id": 231,
  "x": 0.0,
  "y": 0.0,
  "z": 0.0
}
```

**Response**:
```json
{
  "success": true,
  "charid": 1,
  "new_location": {
    "zone_id": 231,
    "zone_name": "Northern San d'Oria",
    "position": {"x": 0.0, "y": 0.0, "z": 0.0}
  }
}
```

**SQL Query**:
```sql
UPDATE chars
SET pos_zone = ?, pos_x = ?, pos_y = ?, pos_z = ?
WHERE charid = ?;
```

### POST /admin/bans
**Ban account or character**

**Request**:
```json
{
  "account_id": 123,
  "ban_type": 1,
  "duration_hours": 24,
  "reason": "Spamming"
}
```

**Response**:
```json
{
  "success": true,
  "ban_id": 456,
  "expires_at": "2025-11-05T12:00:00Z"
}
```

## Pagination Pattern

All list endpoints support pagination:

**Query Parameters**:
- `page` (int, default=1): Page number
- `per_page` (int, default=20, max=100): Items per page

**Response Format**:
```json
{
  "data": [...],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total_items": 150,
    "total_pages": 8,
    "has_next": true,
    "has_prev": false
  }
}
```

## Error Responses

All endpoints use consistent error format:

```json
{
  "error": true,
  "code": "NOT_FOUND",
  "message": "Character not found",
  "details": {
    "charid": 99999
  }
}
```

**Common Error Codes**:
- `UNAUTHORIZED` (401): Invalid or missing token
- `FORBIDDEN` (403): Insufficient permissions
- `NOT_FOUND` (404): Resource not found
- `BAD_REQUEST` (400): Invalid parameters
- `SERVER_ERROR` (500): Internal error

## Rate Limiting

**Headers**:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1699027200
```

**Rate Limit Response** (429):
```json
{
  "error": true,
  "code": "RATE_LIMIT_EXCEEDED",
  "message": "Too many requests",
  "retry_after": 60
}
```

## Caching Headers

**Recommended cache headers**:
```
Cache-Control: public, max-age=300
ETag: "abc123xyz"
Last-Modified: Mon, 04 Nov 2025 12:00:00 GMT
```

## WebSocket Endpoints

### WS /ws/server
**Real-time server updates**

**Events**:
- `player_online`: Player logs in
- `player_offline`: Player logs out
- `zone_change`: Player changes zones
- `announcement`: Server announcement

**Example Message**:
```json
{
  "event": "player_online",
  "data": {
    "charid": 1,
    "charname": "Adventurer",
    "timestamp": "2025-11-04T12:00:00Z"
  }
}
```

## Best Practices

1. **Use proper HTTP methods**: GET (read), POST (create), PATCH (update), DELETE (delete)
2. **Include API versioning**: `/api/v1/`
3. **Implement authentication**: JWT tokens
4. **Add rate limiting**: Prevent abuse
5. **Use pagination**: For large result sets
6. **Cache responses**: Reduce database load
7. **Validate inputs**: Sanitize all user input
8. **Log API calls**: For debugging and audit
9. **Document errors**: Clear error messages
10. **Monitor performance**: Track slow queries
