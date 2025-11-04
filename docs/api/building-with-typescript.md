# Building LandSandBoat Tools with TypeScript

## Overview

This guide shows how to build web tools and APIs for LandSandBoat using **TypeScript**. Examples work with **TanStack Start**, but the patterns apply to any TypeScript framework (Next.js, Remix, Express, Fastify, etc.).

## ⚠️ Important: What LSB Actually Provides

LandSandBoat does NOT include a built-in REST API. You need to build your own:

**What LSB Provides:**
- ✅ MariaDB database (port 3306) - **This is what you'll use**
- ✅ Python tools (dbtool.py, announce.py)
- ✅ ZeroMQ IPC (port 54003, localhost only)
- ✅ Optional World Server HTTP API (limited, disabled by default)

**What You Build:**
- Your own TypeScript API/backend
- Web interfaces and dashboards
- Mobile APIs
- Discord bot integrations

## Database Setup

### 1. Install Dependencies

```bash
npm install mysql2
npm install -D @types/node
```

### 2. Database Connection

```typescript
// lib/db.ts
import mysql from 'mysql2/promise';

export const pool = mysql.createPool({
  host: process.env.DB_HOST || '127.0.0.1',
  port: parseInt(process.env.DB_PORT || '3306'),
  user: process.env.DB_USER || 'xiserver',
  password: process.env.DB_PASSWORD || 'xiserver',
  database: process.env.DB_NAME || 'xidb',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

export async function query<T>(sql: string, params?: any[]): Promise<T> {
  const [rows] = await pool.execute(sql, params);
  return rows as T;
}
```

### 3. TypeScript Types

```typescript
// types/character.ts
export interface Character {
  charid: number;
  accid: number;
  charname: string;
  nation: number;
  pos_zone: number;
  pos_x: number;
  pos_y: number;
  pos_z: number;
  pos_rot: number;
  mjob: number;
  sjob: number;
  mlvl: number;
  slvl: number;
  hp: number;
  mp: number;
  playtime: number;
  deaths: number;
  gmlevel: number;
}

export interface CharacterStats {
  charid: number;
  str: number;
  dex: number;
  vit: number;
  agi: number;
  int: number;
  mnd: number;
  chr: number;
  hp: number;
  mp: number;
}

export interface CharacterJobs {
  charid: number;
  war: number;
  mnk: number;
  whm: number;
  blm: number;
  rdm: number;
  thf: number;
  pld: number;
  drk: number;
  bst: number;
  brd: number;
  rng: number;
  sam: number;
  nin: number;
  drg: number;
  smn: number;
  blu: number;
  cor: number;
  pup: number;
  dnc: number;
  sch: number;
  geo: number;
  run: number;
}

export interface InventoryItem {
  charid: number;
  location: number;
  slot: number;
  itemId: number;
  quantity: number;
  bazaar: number;
  signature: string;
  extra: Buffer;
}

export interface Item {
  itemid: number;
  name: string;
  sortname: string;
  stackSize: number;
  flags: number;
  aH: number;
  NoSale: number;
  BaseSell: number;
}

// Extended interface with visual data
export interface ItemWithVisuals extends Item {
  iconUrl: string;          // URL to item icon image
  modelId?: number;         // 3D model ID for equipment
  description?: string;     // Item description text
}

// Helper to add icon URLs to items using FFXIAH CDN
export function enrichItemWithVisuals(item: Item): ItemWithVisuals {
  return {
    ...item,
    // FFXIAH hosts all item icons at a predictable URL
    iconUrl: `https://static.ffxiah.com/images/icon/${item.itemid}.png`
  };
}

// Get icon URL for any item ID
export function getItemIconUrl(itemId: number): string {
  return `https://static.ffxiah.com/images/icon/${itemId}.png`;
}

export interface ItemEquipment extends Item {
  jobs: number;
  level: number;
  slots: number;
  races: number;
  slot: number;
  HP: number;
  MP: number;
  STR: number;
  DEX: number;
  VIT: number;
  AGI: number;
  INT: number;
  MND: number;
  CHR: number;
  DEF: number;
  ATT: number;
  ACC: number;
  EVA: number;
}

export interface MobSpawn {
  mobid: number;
  mobname: string;
  groupid: number;
  poolid: number;
  pos_x: number;
  pos_y: number;
  pos_z: number;
  pos_rot: number;
  respawn: number;
}

export interface AuctionListing {
  id: number;
  seller: number;
  seller_name: string;
  buyer_name: string;
  itemid: number;
  quantity: number;
  sell_price: number;
  date: number;
  sale: number;
}
```

## Database Query Functions

### Character Queries

```typescript
// lib/characters.ts
import { query } from './db';
import type { Character, CharacterStats, CharacterJobs, InventoryItem } from '../types';

export async function getCharacter(charid: number) {
  const [char] = await query<Character[]>(
    `SELECT * FROM chars WHERE charid = ?`,
    [charid]
  );
  return char;
}

export async function getCharacterWithDetails(charid: number) {
  const [char, stats, jobs] = await Promise.all([
    query<Character[]>('SELECT * FROM chars WHERE charid = ?', [charid]),
    query<CharacterStats[]>('SELECT * FROM char_stats WHERE charid = ?', [charid]),
    query<CharacterJobs[]>('SELECT * FROM char_jobs WHERE charid = ?', [charid])
  ]);

  return {
    character: char[0],
    stats: stats[0],
    jobs: jobs[0]
  };
}

export async function searchCharacters(name: string, limit = 20) {
  return await query<Character[]>(
    `SELECT charid, charname, mjob, mlvl, nation
     FROM chars
     WHERE charname LIKE ?
     ORDER BY charname
     LIMIT ?`,
    [`%${name}%`, limit]
  );
}

export async function getOnlineCharacters() {
  return await query<Character[]>(
    `SELECT c.*
     FROM accounts_sessions s
     JOIN chars c ON s.charid = c.charid
     ORDER BY c.charname`
  );
}

export async function getCharacterInventory(charid: number, location = 0) {
  return await query<(InventoryItem & Item)[]>(
    `SELECT ci.*, ib.name, ib.stackSize, ib.flags
     FROM char_inventory ci
     JOIN item_basic ib ON ci.itemId = ib.itemid
     WHERE ci.charid = ? AND ci.location = ?
     ORDER BY ci.slot`,
    [charid, location]
  );
}
```

### Item Queries

```typescript
// lib/items.ts
import { query } from './db';
import type { Item, ItemEquipment } from '../types';

export async function getItem(itemId: number) {
  const [item] = await query<ItemEquipment[]>(
    `SELECT ib.*, ie.*, iw.*
     FROM item_basic ib
     LEFT JOIN item_equipment ie ON ib.itemid = ie.itemId
     LEFT JOIN item_weapon iw ON ib.itemid = iw.itemId
     WHERE ib.itemid = ?`,
    [itemId]
  );
  return item;
}

export async function searchItems(name: string, limit = 50) {
  return await query<Item[]>(
    `SELECT itemid, name, BaseSell, stackSize
     FROM item_basic
     WHERE name LIKE ?
     ORDER BY name
     LIMIT ?`,
    [`%${name}%`, limit]
  );
}

export async function getItemMarketData(itemId: number) {
  const [stats] = await query<any[]>(
    `SELECT
       COUNT(CASE WHEN sale = 0 THEN 1 END) as active_listings,
       MIN(CASE WHEN sale = 0 THEN sell_price END) as lowest_price,
       AVG(CASE WHEN sale > 0 THEN sell_price END) as avg_price,
       COUNT(CASE WHEN sale > 0 THEN 1 END) as total_sales
     FROM auction_house
     WHERE itemid = ?`,
    [itemId]
  );
  return stats;
}
```

### Mob Queries

```typescript
// lib/mobs.ts
import { query } from './db';
import type { MobSpawn } from '../types';

export async function getMob(mobId: number) {
  const [mob] = await query<any[]>(
    `SELECT msp.*, mp.minLevel, mp.maxLevel, mp.mJob, mp.sJob
     FROM mob_spawn_points msp
     JOIN mob_pools mp ON msp.poolid = mp.poolid
     WHERE msp.mobid = ?`,
    [mobId]
  );
  return mob;
}

export async function getMobDrops(mobId: number) {
  return await query<any[]>(
    `SELECT ml.itemid, ib.name, ml.itemRate, ml.droptype
     FROM mob_spawn_points msp
     JOIN mob_groups mg ON msp.poolid = mg.poolid
     JOIN mob_droplist ml ON mg.dropid = ml.dropid
     JOIN item_basic ib ON ml.itemid = ib.itemid
     WHERE msp.mobid = ?
     ORDER BY ml.itemRate DESC`,
    [mobId]
  );
}
```

## TanStack Start Implementation

### Server Functions (Type-Safe RPCs)

```typescript
// app/server-functions/characters.ts
import { createServerFn } from '@tanstack/start';
import { getCharacterWithDetails, searchCharacters, getOnlineCharacters } from '~/lib/characters';

export const getCharacter = createServerFn({ method: 'GET' })
  .validator((data: number) => data)
  .handler(async ({ data: charid }) => {
    return await getCharacterWithDetails(charid);
  });

export const searchChars = createServerFn({ method: 'GET' })
  .validator((data: string) => data)
  .handler(async ({ data: name }) => {
    return await searchCharacters(name);
  });

export const getOnline = createServerFn({ method: 'GET' })
  .handler(async () => {
    return await getOnlineCharacters();
  });
```

### Using Server Functions in Components

```typescript
// app/routes/character/$id.tsx
import { createFileRoute } from '@tanstack/react-router';
import { getCharacter } from '~/server-functions/characters';
import { useQuery } from '@tanstack/react-query';

export const Route = createFileRoute('/character/$id')({
  component: CharacterPage
});

function CharacterPage() {
  const { id } = Route.useParams();

  const { data, isLoading } = useQuery({
    queryKey: ['character', id],
    queryFn: () => getCharacter(parseInt(id))
  });

  if (isLoading) return <div>Loading...</div>;
  if (!data) return <div>Character not found</div>;

  const { character, stats, jobs } = data;

  return (
    <div className="character-profile">
      <h1>{character.charname}</h1>

      <section className="job-info">
        <div>Main Job: {character.mjob} Lv.{character.mlvl}</div>
        <div>Sub Job: {character.sjob} Lv.{character.slvl}</div>
      </section>

      <section className="stats">
        <h2>Stats</h2>
        <div className="stat-grid">
          <div>HP: {stats.hp}</div>
          <div>MP: {stats.mp}</div>
          <div>STR: {stats.str}</div>
          <div>DEX: {stats.dex}</div>
          <div>VIT: {stats.vit}</div>
          <div>AGI: {stats.agi}</div>
          <div>INT: {stats.int}</div>
          <div>MND: {stats.mnd}</div>
          <div>CHR: {stats.chr}</div>
        </div>
      </section>

      <section className="jobs">
        <h2>Job Levels</h2>
        <div className="job-list">
          <div>WAR: {jobs.war}</div>
          <div>MNK: {jobs.mnk}</div>
          <div>WHM: {jobs.whm}</div>
          <div>BLM: {jobs.blm}</div>
          {/* ... more jobs */}
        </div>
      </section>
    </div>
  );
}
```

### API Routes (Alternative Pattern)

```typescript
// app/routes/api/characters/[id].ts
import { json } from '@tanstack/start';
import { getCharacterWithDetails } from '~/lib/characters';

export async function GET({ params }: { params: { id: string } }) {
  const charid = parseInt(params.id);

  if (isNaN(charid)) {
    return json({ error: 'Invalid character ID' }, { status: 400 });
  }

  const data = await getCharacterWithDetails(charid);

  if (!data.character) {
    return json({ error: 'Character not found' }, { status: 404 });
  }

  return json(data);
}
```

## Practical Examples

### 1. GM Dashboard - Online Players

```typescript
// app/routes/admin/online.tsx
import { createFileRoute } from '@tanstack/react-router';
import { getOnline } from '~/server-functions/characters';
import { useQuery } from '@tanstack/react-query';

export const Route = createFileRoute('/admin/online')({
  component: OnlinePlayersPage
});

function OnlinePlayersPage() {
  const { data: players, isLoading } = useQuery({
    queryKey: ['online-players'],
    queryFn: () => getOnline(),
    refetchInterval: 30000 // Refresh every 30 seconds
  });

  if (isLoading) return <div>Loading...</div>;

  return (
    <div>
      <h1>Online Players ({players?.length || 0})</h1>
      <table>
        <thead>
          <tr>
            <th>Character</th>
            <th>Job/Level</th>
            <th>Zone</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {players?.map(player => (
            <tr key={player.charid}>
              <td>
                <a href={`/character/${player.charid}`}>
                  {player.charname}
                </a>
              </td>
              <td>{player.mjob} {player.mlvl}</td>
              <td>Zone {player.pos_zone}</td>
              <td>
                <button onClick={() => teleportPlayer(player.charid)}>
                  Teleport
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

async function teleportPlayer(charid: number) {
  // Would call a server function to update database
  const zoneId = prompt('Enter zone ID:');
  if (!zoneId) return;

  await teleportCharacter(charid, parseInt(zoneId), 0, 0, 0);
  alert('Player teleported!');
}
```

### 2. Market Price Tracker

```typescript
// app/routes/market/$itemId.tsx
import { createFileRoute } from '@tanstack/react-router';
import { getItemMarketData, getItem } from '~/server-functions/items';
import { useQuery } from '@tanstack/react-query';
import { LineChart, Line, XAxis, YAxis, Tooltip } from 'recharts';

export const Route = createFileRoute('/market/$itemId')({
  component: MarketPage
});

function MarketPage() {
  const { itemId } = Route.useParams();
  const id = parseInt(itemId);

  const { data: item } = useQuery({
    queryKey: ['item', id],
    queryFn: () => getItem(id)
  });

  const { data: market } = useQuery({
    queryKey: ['market', id],
    queryFn: () => getItemMarketData(id)
  });

  if (!item) return <div>Loading...</div>;

  return (
    <div className="market-page">
      <h1>{item.name}</h1>

      <section className="market-stats">
        <div className="stat">
          <label>Active Listings</label>
          <value>{market?.active_listings || 0}</value>
        </div>
        <div className="stat">
          <label>Lowest Price</label>
          <value>{market?.lowest_price?.toLocaleString() || '—'} gil</value>
        </div>
        <div className="stat">
          <label>Average Price</label>
          <value>{market?.avg_price?.toFixed(0) || '—'} gil</value>
        </div>
        <div className="stat">
          <label>Total Sales (7d)</label>
          <value>{market?.total_sales || 0}</value>
        </div>
      </section>

      <CurrentListings itemId={id} />
      <PriceHistory itemId={id} />
    </div>
  );
}
```

### 3. Character Search

```typescript
// app/routes/search.tsx
import { createFileRoute } from '@tanstack/react-router';
import { searchChars } from '~/server-functions/characters';
import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';

export const Route = createFileRoute('/search')({
  component: SearchPage
});

function SearchPage() {
  const [query, setQuery] = useState('');
  const [searchTerm, setSearchTerm] = useState('');

  const { data: results, isLoading } = useQuery({
    queryKey: ['search', searchTerm],
    queryFn: () => searchChars(searchTerm),
    enabled: searchTerm.length > 0
  });

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    setSearchTerm(query);
  };

  return (
    <div>
      <h1>Character Search</h1>

      <form onSubmit={handleSearch}>
        <input
          type="text"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Search characters..."
        />
        <button type="submit">Search</button>
      </form>

      {isLoading && <div>Searching...</div>}

      {results && (
        <div className="results">
          {results.map(char => (
            <div key={char.charid} className="character-card">
              <a href={`/character/${char.charid}`}>
                <h3>{char.charname}</h3>
                <div>{char.mjob} Lv.{char.mlvl}</div>
              </a>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
```

## Admin Operations

### Teleport Character

```typescript
// app/server-functions/admin.ts
import { createServerFn } from '@tanstack/start';
import { query } from '~/lib/db';

export const teleportCharacter = createServerFn({ method: 'POST' })
  .validator((data: { charid: number; zoneId: number; x: number; y: number; z: number }) => data)
  .handler(async ({ data }) => {
    await query(
      `UPDATE chars
       SET pos_zone = ?, pos_x = ?, pos_y = ?, pos_z = ?
       WHERE charid = ?`,
      [data.zoneId, data.x, data.y, data.z, data.charid]
    );

    return { success: true };
  });
```

### Give Item

```typescript
// app/server-functions/admin.ts
export const giveItem = createServerFn({ method: 'POST' })
  .validator((data: { charid: number; itemId: number; quantity: number }) => data)
  .handler(async ({ data }) => {
    // Find empty slot
    const [emptySlot] = await query<{ slot: number }[]>(
      `SELECT MIN(s.slot) as slot
       FROM (
         SELECT 0 as slot UNION SELECT 1 UNION SELECT 2 /* ... up to 79 */
       ) s
       LEFT JOIN char_inventory ci ON s.slot = ci.slot
         AND ci.charid = ? AND ci.location = 0
       WHERE ci.slot IS NULL`,
      [data.charid]
    );

    if (emptySlot.slot === null) {
      throw new Error('Inventory full');
    }

    // Insert item
    await query(
      `INSERT INTO char_inventory (charid, location, slot, itemId, quantity)
       VALUES (?, 0, ?, ?, ?)`,
      [data.charid, emptySlot.slot, data.itemId, data.quantity]
    );

    return { success: true, slot: emptySlot.slot };
  });
```

## Best Practices

### 1. Use Connection Pooling

```typescript
// Already shown in lib/db.ts
// Pool handles connection reuse automatically
```

### 2. Type Safety

```typescript
// Always type your database responses
interface QueryResult<T> {
  rows: T[];
}

// Use generic types
async function getEntity<T>(table: string, id: number): Promise<T | null> {
  const [row] = await query<T[]>(`SELECT * FROM ${table} WHERE id = ?`, [id]);
  return row || null;
}
```

### 3. Error Handling

```typescript
export const getCharacterSafe = createServerFn({ method: 'GET' })
  .validator((data: number) => data)
  .handler(async ({ data: charid }) => {
    try {
      const result = await getCharacterWithDetails(charid);
      return { success: true, data: result };
    } catch (error) {
      console.error('Error fetching character:', error);
      return { success: false, error: 'Failed to fetch character' };
    }
  });
```

### 4. Caching

```typescript
// Use React Query's caching
const { data } = useQuery({
  queryKey: ['character', id],
  queryFn: () => getCharacter(id),
  staleTime: 5 * 60 * 1000, // 5 minutes
  cacheTime: 10 * 60 * 1000 // 10 minutes
});
```

### 5. Environment Variables

```typescript
// .env
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=xiserver
DB_PASSWORD=xiserver
DB_NAME=xidb
```

## Deployment

### Production Considerations

1. **Use environment variables** for sensitive data
2. **Enable SSL/TLS** for database connections
3. **Implement rate limiting**
4. **Add authentication/authorization**
5. **Monitor database connection pool**
6. **Set up proper logging**
7. **Use transactions** for multi-step operations

### Example with Authentication

```typescript
// middleware/auth.ts
import { createMiddleware } from '@tanstack/start';
import jwt from 'jsonwebtoken';

export const authMiddleware = createMiddleware({
  id: 'auth',
  middleware: async ({ req, next }) => {
    const token = req.headers.get('Authorization')?.replace('Bearer ', '');

    if (!token) {
      return new Response('Unauthorized', { status: 401 });
    }

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET!);
      req.user = decoded;
      return next();
    } catch {
      return new Response('Invalid token', { status: 401 });
    }
  }
});

// Use in server functions
export const adminFunction = createServerFn({ method: 'POST' })
  .middleware([authMiddleware])
  .handler(async ({ req }) => {
    // req.user is available here
    // Check if user.isAdmin, etc.
  });
```

## Working with Visual Assets (Icons, Models)

### Item Icons

**Important**: LandSandBoat's database does NOT store item icons or visual assets.

**Recommended Solution: Use FFXIAH CDN** ✨

FFXIAH hosts all FFXI item icons on their CDN with a simple, predictable URL pattern:

```
https://static.ffxiah.com/images/icon/{itemId}.png
```

**Examples**:
- Duskdim Stone +1 (ID 8955): https://static.ffxiah.com/images/icon/8955.png
- Pils Tuille (ID 3490): https://static.ffxiah.com/images/icon/3490.png

```typescript
// lib/icons.ts
export function getItemIconUrl(itemId: number): string {
  return `https://static.ffxiah.com/images/icon/${itemId}.png`;
}

// With fallback to default icon
export function getItemIconUrlSafe(itemId: number): string {
  // FFXIAH has icons for all items, but you can add fallback logic
  return `https://static.ffxiah.com/images/icon/${itemId}.png`;
}
```

**Alternative Options** (if you need local hosting):

**Option 1: Cache FFXIAH Icons Locally**
```typescript
// Download and cache icons from FFXIAH
async function cacheIcon(itemId: number) {
  const url = `https://static.ffxiah.com/images/icon/${itemId}.png`;
  const response = await fetch(url);
  const buffer = await response.arrayBuffer();
  // Save to your local storage/CDN
  await saveToLocal(`icons/${itemId}.png`, buffer);
}
```

**Option 2: Extract from FFXI Client**
```bash
# Use tools to extract DAT files from FFXI client
# Icons are stored in ROM/x/y.DAT files
# Requires FFXI client installation and extraction tools
# Only needed if you want complete control over assets
```

#### Usage in Components

```typescript
// app/components/ItemIcon.tsx
interface ItemIconProps {
  itemId: number;
  name: string;
  size?: 'sm' | 'md' | 'lg';
}

export function ItemIcon({ itemId, name, size = 'md' }: ItemIconProps) {
  const sizes = {
    sm: 24,
    md: 32,
    lg: 48
  };

  return (
    <img
      src={`https://static.ffxiah.com/images/icon/${itemId}.png`}
      alt={name}
      width={sizes[size]}
      height={sizes[size]}
      className="item-icon"
      loading="lazy"
      onError={(e) => {
        // Fallback to a default icon if FFXIAH is down or icon doesn't exist
        e.currentTarget.src = '/icons/default.png';
      }}
    />
  );
}

// Usage
<ItemIcon itemId={8955} name="Duskdim Stone +1" size="md" />
```

**With Image Optimization (Next.js/TanStack Start)**:

```typescript
// app/components/ItemIcon.tsx
import Image from 'next/image'; // or your framework's Image component

export function ItemIcon({ itemId, name, size = 'md' }: ItemIconProps) {
  const sizes = {
    sm: 24,
    md: 32,
    lg: 48
  };

  return (
    <Image
      src={`https://static.ffxiah.com/images/icon/${itemId}.png`}
      alt={name}
      width={sizes[size]}
      height={sizes[size]}
      className="item-icon"
      unoptimized // FFXIAH images are already optimized
    />
  );
}
```

### Character Models and Equipment Visuals

```typescript
// types/visuals.ts
export interface EquipmentVisuals {
  modelId: number;
  race: number;
  gender: number;
  // Equipment appearance varies by race/gender
}

// lib/equipment-models.ts
export function getEquipmentModel(
  itemId: number,
  race: number,
  gender: number
): EquipmentVisuals | null {
  // You'll need to maintain this mapping or
  // extract from FFXI client DAT files
  return {
    modelId: getModelId(itemId, race, gender),
    race,
    gender
  };
}
```

### Icon Data Sources

**Primary Source:**
- **FFXIAH CDN**: `https://static.ffxiah.com/images/icon/{itemId}.png` - Hosts all FFXI item icons

**Other Community Resources:**
- **FFXIAH.com**: Complete item database with additional data
- **FFXIclopedia**: Wiki with item information
- **GitHub**: FFXI data repositories

**Legal Note**: Icon images are copyrighted by Square Enix. Using FFXIAH's hosted icons is commonly accepted for private server tools and fan projects, but be mindful when creating commercial services.

### Example: Complete Item Display

```typescript
// app/components/ItemCard.tsx
import { ItemIcon } from './ItemIcon';
import { getItemMarketData } from '~/server-functions/items';
import { useQuery } from '@tanstack/react-query';

interface ItemCardProps {
  item: ItemWithVisuals;
}

export function ItemCard({ item }: ItemCardProps) {
  const { data: market } = useQuery({
    queryKey: ['market', item.itemid],
    queryFn: () => getItemMarketData(item.itemid)
  });

  return (
    <div className="item-card">
      <ItemIcon itemId={item.itemid} name={item.name} size="lg" />

      <div className="item-info">
        <h3>{item.name}</h3>

        {item.description && (
          <p className="description">{item.description}</p>
        )}

        <div className="item-meta">
          <span>Stack: {item.stackSize}</span>
          <span>NPC: {item.BaseSell.toLocaleString()} gil</span>
        </div>

        {market && (
          <div className="market-info">
            <span>AH: {market.lowest_price?.toLocaleString() || '—'} gil</span>
          </div>
        )}
      </div>
    </div>
  );
}
```

## Summary

This guide showed how to build LandSandBoat tools with TypeScript and TanStack Start:

1. ✅ Database connection with type safety
2. ✅ TypeScript interfaces for all data types
3. ✅ Server functions for type-safe RPCs
4. ✅ React components with TanStack Router
5. ✅ Practical examples (GM dashboard, market tracker, search)
6. ✅ Admin operations (teleport, give items)
7. ✅ Best practices (caching, error handling, auth)

**Key Takeaway**: You build the API layer yourself using TypeScript + TanStack Start, connecting directly to the LandSandBoat MariaDB database.
