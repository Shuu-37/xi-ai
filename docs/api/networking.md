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

### Overview

**Status**: Optional, disabled by default
**Port**: 8088 (localhost only)
**Protocol**: HTTP/1.1
**Format**: JSON

### Enabling HTTP API

In `/settings/network.lua`:
```lua
world_http_api_enabled = true
world_http_api_port = 8088
```

**Security Warning**: HTTP API is disabled by default. Enable only on secure networks, localhost only.

### API Endpoints

**Note**: Exact endpoints depend on server version. Common patterns:

#### GET /status
Get server status

**Response**:
```json
{
    "online": true,
    "players": 42,
    "uptime": 3600,
    "version": "1.0.0"
}
```

#### POST /announce
Broadcast message to all players

**Request**:
```json
{
    "message": "Server restart in 10 minutes"
}
```

**Response**:
```json
{
    "success": true,
    "sent": 42
}
```

#### GET /players
Get online player list

**Response**:
```json
{
    "players": [
        {"charid": 1, "name": "PlayerOne", "zone": 230},
        {"charid": 2, "name": "PlayerTwo", "zone": 231}
    ]
}
```

### HTTP API Client Example

**Python**:
```python
import requests

base_url = "http://localhost:8088"

# Get server status
response = requests.get(f"{base_url}/status")
print(response.json())

# Send announcement
response = requests.post(f"{base_url}/announce", json={
    "message": "Double EXP event now active!"
})
print(response.json())
```

**JavaScript (Node.js)**:
```javascript
const axios = require('axios');

const baseURL = 'http://localhost:8088';

// Get server status
axios.get(`${baseURL}/status`)
    .then(response => console.log(response.data));

// Send announcement
axios.post(`${baseURL}/announce`, {
    message: 'Double EXP event now active!'
})
    .then(response => console.log(response.data));
```

**curl**:
```bash
# Get status
curl http://localhost:8088/status

# Send announcement
curl -X POST http://localhost:8088/announce \
    -H "Content-Type: application/json" \
    -d '{"message":"Server restart in 10 minutes"}'
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

## Building External Integrations

### RESTful API Wrapper

Build a RESTful API around LandSandBoat's database:

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
