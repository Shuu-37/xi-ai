# LandSandBoat Actual External Interfaces

## Overview

This document describes the **actual interfaces** that exist in LandSandBoat for external tools and integrations. Unlike example API designs, these are **real, built-in features** of LandSandBoat.

## 1. Direct Database Access (Primary Method)

### MariaDB Database
**Port**: 3306 (default)
**Configuration**: `/settings/network.lua`

This is the **primary and most common method** for building external tools.

**Connection Details**:
```lua
-- From settings/network.lua
mysql_host = "127.0.0.1"
mysql_port = 3306
mysql_login = "xiserver"
mysql_password = "xiserver"
mysql_database = "xidb"
```

**What You Can Do**:
- Read all game data (characters, items, mobs, etc.)
- Modify character data (inventory, position, stats)
- Query auction house, crafting recipes, drop rates
- Access account information
- View server statistics

**Example - Python**:
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
cursor.execute("SELECT charid, charname, mjob, mlvl FROM chars WHERE charid = ?", (1,))
result = cursor.fetchone()
print(f"Character: {result[1]}, Job: {result[2]}, Level: {result[3]}")
```

**Example - Node.js**:
```javascript
const mysql = require('mysql2/promise');

const connection = await mysql.createConnection({
  host: '127.0.0.1',
  port: 3306,
  user: 'xiserver',
  password: 'xiserver',
  database: 'xidb'
});

const [rows] = await connection.execute(
  'SELECT charid, charname, mjob, mlvl FROM chars WHERE charid = ?',
  [1]
);
console.log(`Character: ${rows[0].charname}, Job: ${rows[0].mjob}, Level: ${rows[0].mlvl}`);
```

**Security Notes**:
- Database is typically bound to localhost only
- Use secure credentials
- Never expose database directly to public internet
- Build your own API layer for web access

## 2. Python Tools (Built-in)

### dbtool.py
**Location**: `/tools/dbtool.py`
**Purpose**: Database management

**Commands**:
```bash
# Backup database
python tools/dbtool.py --backup

# Update database schema
python tools/dbtool.py --update express
python tools/dbtool.py --update full

# Migrate character data
python tools/dbtool.py --migrate
```

**Integration**: Can be called from shell scripts or other automation

### announce.py
**Location**: `/tools/announce.py`
**Purpose**: Send announcements to all online players

**Usage**:
```bash
python tools/announce.py "Server restart in 10 minutes"
```

**How It Works**:
- Connects to World Server via IPC
- Broadcasts message to all map servers
- All online players receive the message

**Integration**: Can be called from:
- Cron jobs for scheduled announcements
- Web interfaces for admin panels
- Discord bots
- Other automation scripts

### Other Python Tools

**price_checker.py**: Validate shop pricing
```bash
python tools/price_checker.py
```

**give_items.py**: Distribute items to players
```bash
python tools/give_items.py --item 4509 --quantity 12
```

## 3. ZeroMQ IPC (Inter-Process Communication)

### Overview
**Port**: 54003 (localhost only)
**Protocol**: ZeroMQ Dealer/Router
**Purpose**: Communication between server processes

**Configuration**:
```lua
-- From settings/network.lua
msg_server_ip = "127.0.0.1"
msg_server_port = 54003
```

### Message Structure
**C++ Definition** (`/src/common/ipc.h`):
```cpp
struct IPC_Message {
    uint16_t type;      // Message type
    uint16_t size;      // Message size
    uint32_t source;    // Source server ID
    uint32_t target;    // Target server ID (0 = broadcast)
    uint8_t data[];     // Message payload
};
```

### Common Message Types
- Zone transfer coordination
- Cross-zone chat (tells, linkshells)
- Party/alliance updates
- Server announcements
- Auction house synchronization
- World state updates

### Example - Python Integration
```python
import zmq
import struct

context = zmq.Context()
socket = context.socket(zmq.DEALER)
socket.connect("tcp://127.0.0.1:54003")

# Example: Send announcement (simplified)
message_type = 0x01  # Announcement type
text = "Hello World!"
data = text.encode('utf-8')

packet = struct.pack('<HHII', message_type, len(data), 0, 0) + data
socket.send(packet)

# Receive response
response = socket.recv()
```

**Use Cases**:
- Custom server announcements
- Monitoring server events
- Cross-zone coordination
- External tool integration

**Limitations**:
- Localhost only (security)
- Requires understanding of IPC message format
- Not documented extensively (need to read C++ source)

## 4. World Server HTTP API (Optional, Limited)

### Overview
**Status**: Disabled by default
**Port**: 8088 (localhost only when enabled)
**Protocol**: HTTP/1.1

### Enabling
In `/settings/network.lua`:
```lua
world_http_api_enabled = true
world_http_api_port = 8088
```

**⚠️ Security Warning**: Only enable on secure networks, localhost only

### Available Functionality
The World Server HTTP API is **very limited** and provides basic functionality:
- Server status queries
- Player announcements (possibly)
- World state information

**Note**: Exact endpoints are not well-documented. You would need to examine the World Server source code (`/src/world/`) to see what's actually implemented.

### Usage Example
```bash
# Basic status query (if implemented)
curl http://localhost:8088/status

# Announcement (if implemented)
curl -X POST http://localhost:8088/announce \
  -H "Content-Type: application/json" \
  -d '{"message":"Server maintenance in 5 minutes"}'
```

**Reality**: Most users will NOT use this API and will instead:
1. Use direct database access
2. Use Python tools
3. Build their own API layer

## 5. FFXI Client Protocol (Game Client Only)

### Overview
**Ports**: 54001 (login), 54230 (map server UDP), 54002 (search)
**Protocol**: Proprietary FFXI binary protocol

**Purpose**: Communication between FFXI game client and server

**NOT for external tools** - This is the game protocol, not an API for building tools.

## What Does NOT Exist in LandSandBoat

❌ **Built-in REST API** - No GET /characters/:id or similar endpoints
❌ **GraphQL API** - Not included
❌ **WebSocket API** - Not built-in
❌ **JSON-RPC API** - Not available
❌ **gRPC API** - Not included
❌ **Admin Web Interface** - You must build this yourself

## Recommended Approach for Building Tools

### For Web Applications
1. **Build your own API server** (Express, Flask, FastAPI)
2. **Connect to MariaDB database** directly
3. **Implement REST/GraphQL endpoints** as needed
4. **Use ZeroMQ** for real-time server communication (optional)
5. **Call Python tools** for specific operations

### Architecture Example
```
Web Browser
    ↓ HTTP/HTTPS
Your API Server (Node.js/Python/etc.)
    ↓ SQL
MariaDB Database (LandSandBoat)
    ↓ ZMQ (optional)
LandSandBoat Servers
```

### For Discord Bots
1. **Connect bot to MariaDB** for data queries
2. **Call Python tools** for announcements
3. **Poll database** for online players, status

### For Mobile Apps
1. **Build API backend** (same as web)
2. **Use REST API** from mobile app
3. **Never expose database** directly to mobile

## Security Considerations

### Database Access
- **Localhost only** by default
- Use **SSH tunneling** for remote access
- **Never expose** port 3306 to public internet
- Use **read-only database users** for query-only tools

### API Layer
- Always build **authentication** (JWT, OAuth)
- Implement **rate limiting**
- Use **HTTPS** for public access
- **Validate all inputs** (SQL injection prevention)

### IPC Access
- **Localhost only** (cannot be changed)
- Already secured by binding

## Documentation References

### Database Schema
- See `/sql/` directory in LandSandBoat repository
- See `docs/database/` in this repository

### Python Tools
- See `/tools/` directory in LandSandBoat repository
- See `docs/tools/utilities.md` in this repository

### IPC Messages
- See `/src/common/ipc.h` in LandSandBoat repository
- See `docs/api/networking.md` in this repository

### Source Code
- **Login Server**: `/src/login/`
- **Map Server**: `/src/map/`
- **World Server**: `/src/world/`
- **Search Server**: `/src/search/`

## Quick Start Examples

### Query Online Players (Python)
```python
import mariadb

conn = mariadb.connect(
    host="127.0.0.1", port=3306,
    user="xiserver", password="xiserver",
    database="xidb"
)

cursor = conn.cursor()
cursor.execute("""
    SELECT c.charname, c.mjob, c.mlvl, c.pos_zone
    FROM accounts_sessions s
    JOIN chars c ON s.charid = c.charid
""")

for (name, job, level, zone) in cursor:
    print(f"{name} - {job} {level} in zone {zone}")
```

### Send Announcement (Shell)
```bash
#!/bin/bash
MESSAGE="Double EXP event now active!"
python /path/to/landsandboat/tools/announce.py "$MESSAGE"
```

### Simple Web API (Node.js/Express)
```javascript
const express = require('express');
const mysql = require('mysql2/promise');

const app = express();

const pool = mysql.createPool({
  host: '127.0.0.1',
  user: 'xiserver',
  password: 'xiserver',
  database: 'xidb'
});

app.get('/api/characters/:id', async (req, res) => {
  const [rows] = await pool.execute(
    'SELECT charid, charname, mjob, mlvl FROM chars WHERE charid = ?',
    [req.params.id]
  );

  if (rows.length === 0) {
    return res.status(404).json({ error: 'Character not found' });
  }

  res.json(rows[0]);
});

app.listen(5000, () => console.log('API running on port 5000'));
```

## Summary

**What LandSandBoat Actually Provides:**
1. ✅ Direct MariaDB database access (primary method)
2. ✅ Python management tools
3. ✅ ZeroMQ IPC for inter-process communication
4. ✅ Optional, limited World Server HTTP API

**What You Need to Build:**
1. Custom REST/GraphQL APIs
2. Web interfaces and dashboards
3. Mobile applications
4. Discord bots
5. External integrations

**Best Practice**: Build your own API layer that connects to the LandSandBoat database and provides the endpoints you need for your specific use case.
