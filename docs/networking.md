# LandSandBoat API and Networking

## Overview

LandSandBoat uses multiple network interfaces and protocols for client-server communication, inter-process communication, and external integrations.

## Network Architecture

### Port Layout

**Client-Facing Ports**:
- **54001** (TCP): Login Server - View Server (initial connection)
- **54230** (TCP): Login Server - Data Server
- **54230** (UDP): Map Server - Gameplay
- **54231** (TCP): Login Server - Auth Server
- **51220** (TCP): Login Server - Config Server
- **54002** (TCP): Search Server

**Internal Ports**:
- **54003** (TCP): ZeroMQ IPC (localhost only)
- **3306** (TCP): MariaDB Database
- **8088** (HTTP): World Server HTTP API (optional, disabled by default, localhost only)

### Configuration

Network settings are configured in `/settings/network.lua`:

```lua
-- Server binding
map_ip = "127.0.0.1"
map_port = 54230

login_view_port = 54001
login_data_port = 54230
login_auth_port = 54231
login_cfg_port = 51220

search_port = 54002

-- Database
mysql_host = "127.0.0.1"
mysql_port = 3306
mysql_login = "xiserver"
mysql_password = "xiserver"
mysql_database = "xidb"

-- IPC
msg_server_ip = "127.0.0.1"
msg_server_port = 54003

-- World Server HTTP API (optional)
world_http_api_enabled = false
world_http_api_port = 8088
```

## Client Protocol

### FFXI Network Protocol

LandSandBoat implements the proprietary Final Fantasy XI client protocol.

**Protocol Type**: Custom binary protocol
**Transport**: TCP for login/auth, UDP for gameplay
**Location**: `/src/map/packets/`

### Packet Structure

**Packet Organization**:
- `/src/map/packets/c2s/` - Client-to-server packets
- `/src/map/packets/s2c/` - Server-to-client packets

**Common Packet Types**:

**Client to Server (c2s)**:
- Login/authentication packets
- Character selection
- Movement updates
- Action commands (attack, ability, spell)
- Chat messages
- Trade requests
- Menu selections

**Server to Client (s2c)**:
- Character data
- Zone information
- Entity updates (players, mobs, NPCs)
- Combat results
- Chat messages
- Inventory updates
- Status effects

### Key Packets

**action.cpp**: Combat actions and results
**char_sync.cpp**: Character synchronization
**entity_update.cpp**: Entity position and state
**pet_sync.cpp**: Pet information
**inventory_assign.cpp**: Inventory updates
**message_standard.cpp**: System messages
**chat_message.cpp**: Player chat

### Packet Validation

All incoming packets are validated:
1. Size check
2. Packet ID verification
3. Parameter range validation
4. State validation (e.g., player must be in zone)
5. Permission checks (GM commands, etc.)

**Security Features**:
- DDoS protection with rate limiting
- IP allow/deny lists
- Stall timeout (60 seconds)
- Connection lockout (10 attempts in 3 seconds = 10 minute ban)

### DDoS Protection

Configured in `/settings/network.lua`:

```lua
-- Connection protection
max_connection_attempts = 10
connection_attempt_window = 3  -- seconds
connection_lockout_duration = 600  -- seconds

-- Stall timeout
stall_timeout = 60  -- seconds

-- IP filtering (CIDR notation)
allowed_ips = {
    "192.168.1.0/24",
    "10.0.0.0/8"
}

blocked_ips = {
    "1.2.3.4/32"
}
```

## Inter-Process Communication (IPC)

### ZeroMQ Architecture

**Technology**: ZeroMQ (ZMQ)
**Pattern**: Dealer/Router
**Port**: 54003 (localhost only)
**Security**: Bound to localhost, no external access

### IPC Message Types

**Location**: `/src/common/ipc.h`, `/src/common/ipc_structs.h`

**Common IPC Messages**:
- Character zone transfers
- Cross-zone chat (tell, linkshell)
- Party/alliance updates
- World announcements
- Auction house synchronization
- Conquest/campaign updates

### IPC Message Structure

```cpp
struct IPC_Message {
    uint16_t type;      // Message type
    uint16_t size;      // Message size
    uint32_t source;    // Source server ID
    uint32_t target;    // Target server ID (0 = broadcast)
    uint8_t data[];     // Message payload
};
```

### IPC Message Flow

**Zone Transfer Example**:
1. Player triggers zone change on Map Server A
2. Map Server A saves character state to database
3. Map Server A sends IPC message to World Server
4. World Server forwards to Map Server B
5. Map Server B loads character from database
6. Character appears in new zone

**Broadcast Example**:
1. Admin uses `announce.py` tool
2. Tool connects to World Server
3. World Server broadcasts IPC message to all Map Servers
4. Each Map Server displays message to all players in zone

### IPC Integration

**Python Example**:
```python
import zmq
import struct

context = zmq.Context()
socket = context.socket(zmq.DEALER)
socket.connect("tcp://127.0.0.1:54003")

# Send announcement IPC message
message_type = 0x01  # Example: ANNOUNCE
message = "Server restart in 5 minutes".encode('utf-8')

packet = struct.pack(
    '<HHII',
    message_type,
    len(message),
    0,  # Source (0 = external)
    0   # Target (0 = broadcast)
) + message

socket.send(packet)

# Receive response
response = socket.recv()
```

**C++ Example**:
```cpp
#include <zmq.hpp>

zmq::context_t context(1);
zmq::socket_t socket(context, zmq::socket_type::dealer);
socket.connect("tcp://127.0.0.1:54003");

// Prepare message
IPC_Message msg;
msg.type = IPC_TYPE_ANNOUNCE;
msg.size = sizeof(msg) + strlen(text);
msg.source = 0;
msg.target = 0;
strcpy((char*)msg.data, text);

// Send message
zmq::message_t request(msg.size);
memcpy(request.data(), &msg, msg.size);
socket.send(request, zmq::send_flags::none);

// Receive response
zmq::message_t reply;
socket.recv(reply, zmq::recv_flags::none);
```

## HTTP API (World Server)

### ⚠️ Recommendation for Tool Development

**For most use cases, do NOT use this HTTP API. Instead:**

✅ **Preferred Approach**: Connect directly to the MariaDB database
- Full access to all game data (124 tables)
- No 60-second cache delay
- More flexible queries
- Better performance
- See [Database Documentation](database.md) for details

✅ **Alternative**: Build your own RESTful API
- Wrap the database with your own API server
- Add authentication, rate limiting, custom endpoints
- Use any tech stack (Node.js, Python, Go, etc.)
- Complete control over functionality

❌ **This HTTP API is limited to**:
- Basic server monitoring (session counts, zone populations)
- Read-only operations
- No player/character management
- No item management
- No administrative actions
- 60-second cache (stale data)

**Use this HTTP API only for**: Simple monitoring dashboards or status displays where 60-second staleness is acceptable.

### Overview

**Process**: Runs in the World Server (`xi_world` executable)
**Status**: Optional, disabled by default
**Port**: 8088 (localhost only)
**Protocol**: HTTP/1.1
**Format**: JSON
**Implementation**: `/src/world/http_server.cpp` (cpp-httplib library)
**Thread**: Runs on separate async thread (non-blocking)
**Scope**: Limited monitoring endpoints only

### How It Works

The HTTP API is part of the World Server process, not a standalone service:

1. **Initialization**: When `xi_world` starts, it creates an `HTTPServer` instance
2. **Conditional Start**: HTTP server only initializes if `network.ENABLE_HTTP = true`
3. **Separate Thread**: HTTP server runs on a dedicated async thread to avoid blocking World Server operations
4. **Data Caching**: Queries database on-demand, caches results for 60 seconds to reduce database load
5. **Thread Safety**: Uses synchronized shared memory for thread-safe data access
6. **Lifecycle**: Automatically starts with World Server, stops when World Server shuts down

**Architecture Flow**:
```
xi_world (main thread)
  ├─> WorldEngine
  │     ├─> IPCServer (ZeroMQ)
  │     ├─> PartySystem
  │     ├─> ConquestSystem
  │     └─> HTTPServer (async thread) ─> cpp-httplib listener
  │                                          ├─> GET /api/*
  │                                          └─> Queries MariaDB (60s cache)
  └─> Other systems...
```

**Cache Behavior**:
- First request triggers database query and populates cache
- Subsequent requests within 60 seconds use cached data
- After 60 seconds, next request refreshes cache from database
- Thread-safe: Multiple simultaneous requests handled correctly

### Enabling HTTP API

In `/settings/network.lua`:
```lua
ENABLE_HTTP = true,  -- Set to true to enable
HTTP_HOST   = 'localhost',
HTTP_PORT   = 8088,
```

**Security Warning**:
- HTTP API is disabled by default for security
- Binds to localhost only (not accessible from network)
- Enable only on secure networks
- No authentication built-in (add reverse proxy if exposing publicly)

### Prerequisites

To use the HTTP API, you must:
1. Have the **World Server** (`xi_world`) running
2. Set `ENABLE_HTTP = true` in `/settings/network.lua`
3. Ensure World Server can connect to the database

**Important**: The HTTP API is **not available** from Login Server or Map Servers - only World Server.

### Quick Start

**1. Enable in settings** (`/settings/network.lua`):
```lua
ENABLE_HTTP = true,
```

**2. Restart World Server**:
```bash
# Stop and restart xi_world
./xi_world
```

**3. Test the API**:
```bash
# Should return "Hello LSB API"
curl http://localhost:8088/api

# Get active sessions
curl http://localhost:8088/api/sessions
```

**Expected Console Output** (when World Server starts):
```
[Info] Starting HTTP Server on http://localhost:8088/api
```

If you see this message, the HTTP API is running successfully.

### API Endpoints

**Implementation**: `/src/world/http_server.cpp`
**Library**: cpp-httplib (embedded HTTP server)
**Data Source**: MariaDB via prepared statements
**Cache TTL**: 60 seconds (automatic refresh on next request)

#### GET /api
Health check endpoint

**Response**:
```
Hello LSB API
```

#### GET /api/sessions
Get active session count

**Response**:
```json
42
```

#### GET /api/ips
Get unique IP count (distinct connections)

**Response**:
```json
15
```

#### GET /api/zones
Get player counts for all zones

**Response**:
```json
{
    "230": 12,
    "231": 8,
    "235": 5
}
```

**Note**: Keys are zone IDs, values are player counts

#### GET /api/zones/:id
Get player count for specific zone

**Example**: `/api/zones/230`

**Response**:
```json
12
```

**Error**: Returns 404 if zone ID is invalid (> MAX_ZONEID)

#### GET /api/settings
Get server settings (filtered)

**Response**:
```json
{
    "main.EXP_RATE": 1.0,
    "main.CURRENCY_RATE": 1.0,
    "main.ALL_JOBS": false,
    "main.UNLOCK_SUBJOB": false,
    ...
}
```

**Note**: Excludes `network.*`, `logging.*`, and any key containing `password`

### HTTP API Client Example

**Python**:
```python
import requests

base_url = "http://localhost:8088"

# Health check
response = requests.get(f"{base_url}/api")
print(response.text)  # "Hello LSB API"

# Get active sessions
response = requests.get(f"{base_url}/api/sessions")
print(f"Active sessions: {response.json()}")

# Get unique IPs
response = requests.get(f"{base_url}/api/ips")
print(f"Unique IPs: {response.json()}")

# Get zone player counts
response = requests.get(f"{base_url}/api/zones")
zones = response.json()
print(f"Zones: {zones}")

# Get specific zone
response = requests.get(f"{base_url}/api/zones/230")
print(f"Players in zone 230: {response.json()}")

# Get server settings
response = requests.get(f"{base_url}/api/settings")
settings = response.json()
print(f"EXP Rate: {settings.get('main.EXP_RATE')}")
```

**JavaScript (Node.js)**:
```javascript
const axios = require('axios');

const baseURL = 'http://localhost:8088';

async function queryAPI() {
    // Health check
    const health = await axios.get(`${baseURL}/api`);
    console.log(health.data); // "Hello LSB API"

    // Get active sessions
    const sessions = await axios.get(`${baseURL}/api/sessions`);
    console.log(`Active sessions: ${sessions.data}`);

    // Get zone player counts
    const zones = await axios.get(`${baseURL}/api/zones`);
    console.log('Zone populations:', zones.data);

    // Get server settings
    const settings = await axios.get(`${baseURL}/api/settings`);
    console.log('EXP Rate:', settings.data['main.EXP_RATE']);
}

queryAPI();
```

**curl**:
```bash
# Health check
curl http://localhost:8088/api

# Get active sessions
curl http://localhost:8088/api/sessions

# Get unique IPs
curl http://localhost:8088/api/ips

# Get all zone populations
curl http://localhost:8088/api/zones

# Get specific zone population
curl http://localhost:8088/api/zones/230

# Get server settings
curl http://localhost:8088/api/settings
```

## Database Access

### Direct Database Connection

**Recommended for external tools**

**Advantages**:
- Full access to all game data
- No protocol implementation needed
- Well-documented SQL schema
- Supports transactions

**Disadvantages**:
- Requires database credentials
- Must respect game constraints
- No real-time server integration

### Connection Examples

**Python**:
```python
import mariadb

conn = mariadb.connect(
    host="127.0.0.1",
    port=3306,
    user="xiserver",
    password="xiserver",
    database="xidb"
)

cursor = conn.cursor()
cursor.execute("SELECT charid, charname FROM chars WHERE gmlevel > 0")

for charid, charname in cursor:
    print(f"GM: {charname} (ID: {charid})")

cursor.close()
conn.close()
```

**Node.js**:
```javascript
const mysql = require('mysql2/promise');

async function main() {
    const connection = await mysql.createConnection({
        host: '127.0.0.1',
        port: 3306,
        user: 'xiserver',
        password: 'xiserver',
        database: 'xidb'
    });

    const [rows] = await connection.execute(
        'SELECT charid, charname FROM chars WHERE gmlevel > 0'
    );

    rows.forEach(row => {
        console.log(`GM: ${row.charname} (ID: ${row.charid})`);
    });

    await connection.end();
}

main();
```

**PHP**:
```php
<?php
$host = '127.0.0.1';
$port = 3306;
$db = 'xidb';
$user = 'xiserver';
$pass = 'xiserver';

$dsn = "mysql:host=$host;port=$port;dbname=$db;charset=utf8mb4";
$pdo = new PDO($dsn, $user, $pass);

$stmt = $pdo->query('SELECT charid, charname FROM chars WHERE gmlevel > 0');

while ($row = $stmt->fetch()) {
    echo "GM: {$row['charname']} (ID: {$row['charid']})\n";
}
?>
```

## Lua Scripting Interface

### Lua-C++ Bridge

**Technology**: sol2 library
**Safety**: All safety checks enabled

### Accessing C++ from Lua

Lua scripts can call C++ functions for:
- Database queries
- Entity manipulation
- Combat calculations
- Zone management
- Player interaction

**Example** (`/scripts/zones/example/npcs/Example_NPC.lua`):
```lua
require("scripts/globals/npc_util")

local entity = {}

entity.onTrade = function(player, npc, trade)
    -- Check traded items
    if npcUtil.tradeHas(trade, 4509) then  -- Phoenix Down
        player:messageSpecial(zones[player:getZoneID()].text.ITEM_OBTAINED, 4509)
        player:addItem(65535)  -- Gil
        player:messageSpecial(zones[player:getZoneID()].text.GIL_OBTAINED, 1000)
        player:confirmTrade()
    end
end

entity.onTrigger = function(player, npc)
    player:startEvent(100)  -- Start cutscene
end

entity.onEventFinish = function(player, csid, option)
    if csid == 100 and option == 1 then
        -- Player chose option 1
        player:addKeyItem(xi.ki.EXAMPLE_KEY_ITEM)
    end
end

return entity
```

### C++ Functions Available in Lua

**Player Methods**:
- `player:getID()` - Get character ID
- `player:getName()` - Get character name
- `player:getMainJob()` - Get main job
- `player:getMainLvl()` - Get main level
- `player:getHP()`, `player:getMP()` - Get current HP/MP
- `player:setPos(x, y, z, rot, zone)` - Set position
- `player:addItem(itemId, quantity)` - Add item to inventory
- `player:delItem(itemId, quantity)` - Remove item
- `player:hasItem(itemId)` - Check if player has item
- `player:addGil(amount)` - Add gil
- `player:getGil()` - Get gil amount
- `player:addExp(amount)` - Add experience
- `player:addKeyItem(keyItemId)` - Add key item
- `player:hasKeyItem(keyItemId)` - Check for key item
- `player:messageSpecial(textId, ...)` - Display message
- `player:startEvent(eventId)` - Start cutscene
- `player:setCharVar(name, value)` - Set character variable
- `player:getCharVar(name)` - Get character variable

**Entity Methods**:
- `entity:getZone()` - Get zone
- `entity:getPos()` - Get position
- `entity:setPos(x, y, z, rot)` - Set position
- `entity:getHP()`, `entity:getMP()`, `entity:getTP()` - Get stats
- `entity:setHP(value)`, `entity:setMP(value)`, `entity:setTP(value)` - Set stats
- `entity:addStatusEffect(effect, power, tick, duration)` - Add status effect
- `entity:delStatusEffect(effect)` - Remove status effect
- `entity:hasStatusEffect(effect)` - Check for status effect

**Zone Methods**:
- `zone:getID()` - Get zone ID
- `zone:getPlayers()` - Get all players in zone
- `zone:getMobs()` - Get all mobs in zone
- `zone:getNPCs()` - Get all NPCs in zone
- `zone:insertDynamicEntity(entity)` - Spawn dynamic entity

**Database Queries**:
```lua
-- Query database
local query = "SELECT * FROM chars WHERE charid = ?"
local result = db:query(query, player:getID())

if result then
    for row in result:rows() do
        print(row.charname)
    end
end
```

### Custom Lua Scripts

**Location**: `/scripts/`

Scripts can extend functionality without modifying C++ code:
- Custom NPCs
- Quest implementations
- Custom commands
- Special events
- Battle logic

## Comparison: HTTP API vs Database Access

### Why Direct Database Access is Better

| Feature | LSB HTTP API | Direct Database Access |
|---------|--------------|------------------------|
| **Data Freshness** | 60-second cache | Real-time |
| **Available Endpoints** | 6 basic endpoints | 124 tables, unlimited queries |
| **Character Management** | ❌ Not available | ✅ Full CRUD operations |
| **Item Management** | ❌ Not available | ✅ Full inventory access |
| **Custom Queries** | ❌ Fixed endpoints | ✅ Any SQL query |
| **Performance** | Cache-dependent | Direct, optimized |
| **Authentication** | ❌ None | ✅ Database user permissions |
| **Availability** | Requires World Server running | Always available |
| **Setup Complexity** | Requires ENABLE_HTTP setting | Just connection string |

### Example: Getting Character Information

**❌ Using HTTP API** (not possible):
```bash
# HTTP API cannot get character info
curl http://localhost:8088/api/characters/1
# 404 - endpoint doesn't exist
```

**✅ Using Direct Database Access**:
```python
import mariadb

conn = mariadb.connect(
    host="127.0.0.1",
    user="xiserver",
    password="xiserver",
    database="xidb"
)

# Get full character details
cursor = conn.cursor()
cursor.execute("""
    SELECT c.*, cs.*, cj.*, cp.*
    FROM chars c
    JOIN char_stats cs ON c.charid = cs.charid
    JOIN char_jobs cj ON c.charid = cj.charid
    JOIN char_profile cp ON c.charid = cp.charid
    WHERE c.charid = ?
""", (1,))

character = cursor.fetchone()
# Full character data including stats, jobs, profile, etc.
```

### When to Use Each Approach

**Use HTTP API when**:
- Building a simple server status widget
- Don't need real-time data (60s delay acceptable)
- Only need session/zone population counts
- Don't want to manage database credentials

**Use Direct Database Access when**:
- Building admin tools or GM panels
- Managing characters, items, or inventory
- Need real-time data
- Building player-facing features (market, character lookup, etc.)
- Creating custom reports or analytics
- Modifying game data

**Bottom line**: The HTTP API is useful for basic monitoring only. For any serious tool development, use direct database access.

## Building External Integrations

### RESTful API Wrapper (Recommended)

Build your own RESTful API around LandSandBoat's database:

**Architecture**:
```
External Clients (web, mobile)
    ↓ HTTP/REST
API Server (Flask/Express/FastAPI)
    ↓ SQL
MariaDB (LandSandBoat)
    ↑ IPC (optional)
ZeroMQ (LandSandBoat servers)
```

**Features**:
- Character lookup
- Inventory management
- Market data
- Server statistics
- Real-time announcements (via IPC)

### GraphQL API

Provide flexible query interface:

**Schema Example**:
```graphql
type Character {
    id: Int!
    name: String!
    job: Job!
    level: Int!
    nation: Nation!
    inventory: [InventoryItem!]!
}

type InventoryItem {
    slot: Int!
    item: Item!
    quantity: Int!
}

type Item {
    id: Int!
    name: String!
    description: String
}

type Query {
    character(id: Int!): Character
    characters(name: String): [Character!]!
    item(id: Int!): Item
    items(search: String): [Item!]!
}

type Mutation {
    addItemToCharacter(characterId: Int!, itemId: Int!, quantity: Int!): Character
    updateCharacterPosition(characterId: Int!, x: Float!, y: Float!, z: Float!): Character
}
```

### WebSocket Integration

Real-time updates for web clients:

**Use Cases**:
- Live server status
- Player activity feed
- Chat relay
- Event notifications

**Implementation**:
```javascript
const WebSocket = require('ws');
const mariadb = require('mariadb');

const wss = new WebSocket.Server({ port: 8080 });

// Poll database for changes
setInterval(() => {
    // Query for online players
    const players = await queryOnlinePlayers();

    // Broadcast to all WebSocket clients
    wss.clients.forEach(client => {
        if (client.readyState === WebSocket.OPEN) {
            client.send(JSON.stringify({
                type: 'PLAYER_UPDATE',
                data: players
            }));
        }
    });
}, 5000);
```

## Security Considerations

### Network Security

1. **Firewall Rules**: Only expose necessary ports
2. **Localhost Binding**: IPC and HTTP API bound to localhost
3. **Authentication**: Implement auth for external APIs
4. **Rate Limiting**: Prevent API abuse
5. **Input Validation**: Sanitize all inputs

### Database Security

1. **Credentials**: Store securely, never commit to version control
2. **Least Privilege**: Use restricted database users
3. **Parameterized Queries**: Prevent SQL injection
4. **Connection Encryption**: Use SSL/TLS for database connections
5. **Audit Logging**: Log all administrative actions

### API Security

1. **Authentication**: JWT, OAuth, or API keys
2. **Authorization**: Role-based access control
3. **HTTPS**: Encrypt traffic with TLS
4. **CORS**: Configure allowed origins
5. **Input Validation**: Validate and sanitize all inputs

**Example API Security (Flask)**:
```python
from flask import Flask, request, jsonify
from functools import wraps
import jwt

app = Flask(__name__)
app.config['SECRET_KEY'] = 'your-secret-key'

def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get('Authorization')

        if not token:
            return jsonify({'error': 'Token missing'}), 401

        try:
            token = token.split()[1]  # Remove "Bearer " prefix
            data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
        except:
            return jsonify({'error': 'Invalid token'}), 401

        return f(*args, **kwargs)

    return decorated

@app.route('/api/characters', methods=['GET'])
@token_required
def get_characters():
    # Protected endpoint
    pass
```

## Performance Optimization

### Connection Pooling

Reuse database connections:

```python
from mariadb.pooling import ConnectionPool

pool = ConnectionPool(
    pool_name='lsb_pool',
    pool_size=10,
    host='127.0.0.1',
    port=3306,
    user='xiserver',
    password='xiserver',
    database='xidb'
)

# Get connection from pool
conn = pool.get_connection()
cursor = conn.cursor()

# Use connection
cursor.execute("SELECT * FROM chars")

# Return to pool
cursor.close()
conn.close()
```

### Caching

Cache frequently accessed data:

```python
from functools import lru_cache
import time

@lru_cache(maxsize=1000)
def get_item_info(item_id):
    """Cache item data for 5 minutes"""
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM item_basic WHERE itemid = ?", (item_id,))
    result = cursor.fetchone()
    cursor.close()
    conn.close()
    return result

# Or use Redis for distributed caching
import redis

redis_client = redis.Redis(host='localhost', port=6379, db=0)

def get_cached_item(item_id):
    cached = redis_client.get(f'item:{item_id}')
    if cached:
        return json.loads(cached)

    # Fetch from database
    item = fetch_item_from_db(item_id)

    # Cache for 5 minutes
    redis_client.setex(f'item:{item_id}', 300, json.dumps(item))

    return item
```

### Batch Operations

Group multiple operations:

```python
# Bad: Multiple individual queries
for item in items:
    cursor.execute("INSERT INTO char_inventory (...) VALUES (?)", item)
    conn.commit()

# Good: Batch insert
cursor.executemany("INSERT INTO char_inventory (...) VALUES (?)", items)
conn.commit()
```

## Debugging and Monitoring

### Network Traffic Analysis

**Wireshark**: Capture and analyze FFXI protocol packets
**tcpdump**: Monitor server traffic

```bash
# Capture traffic on port 54230
tcpdump -i any -n port 54230 -w capture.pcap
```

### IPC Message Logging

Enable IPC message logging in LandSandBoat:
- Log IPC sends/receives
- Monitor message types and frequency
- Debug cross-server communication

### API Logging

Log all API requests:

```python
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    filename='api.log'
)

@app.before_request
def log_request():
    logging.info(f"{request.method} {request.path} from {request.remote_addr}")

@app.after_request
def log_response(response):
    logging.info(f"Response: {response.status_code}")
    return response
```

## Resources

- LandSandBoat packet definitions: `/src/map/packets/`
- IPC structures: `/src/common/ipc.h`
- Network configuration: `/settings/network.lua`
- Lua scripting examples: `/scripts/`
- ZeroMQ documentation: https://zeromq.org/
- MariaDB connector documentation: https://mariadb.com/docs/
