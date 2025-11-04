# LandSandBoat Tools and Utilities

## Overview

LandSandBoat provides various Python-based tools and utilities for server administration, database management, and development. These tools are located in the `/tools/` directory.

**Requirements**:
- Python 3.x
- Python packages: MariaDB, GitPython, PyYAML, Colorama, ZeroMQ, Pylint, Black

## Database Management

### dbtool.py

**Location**: `/tools/dbtool.py`

**Purpose**: Comprehensive database management tool

#### Features

**1. Database Backups**

Create full or lite database backups:

```bash
# Full backup (all tables)
python tools/dbtool.py --backup

# Lite backup (schema + essential data only)
python tools/dbtool.py --backup lite
```

**Backup Location**: `/sql/backups/`

**Backup Contents**:
- Full: All database tables and data
- Lite: Schema + core game data (no character data)

**2. Database Updates**

Apply schema updates and migrations:

```bash
# Express update (quick, essential updates only)
python tools/dbtool.py --update express

# Full update (comprehensive, all migrations)
python tools/dbtool.py --update full
```

**Update Process**:
1. Reads migration scripts from `/sql/migrations/`
2. Checks which migrations have been applied
3. Applies pending migrations in order
4. Records completed migrations

**3. Character Data Migration**

Migrate character data between schema versions:

```bash
python tools/dbtool.py --migrate
```

**Use Cases**:
- Schema changes affecting character tables
- Data format updates
- Version upgrades

#### Configuration

Database connection settings are read from `/settings/network.lua`:

```lua
-- Example network.lua
mysql_login     = "xiserver"
mysql_password  = "xiserver"
mysql_host      = "127.0.0.1"
mysql_port      = 3306
mysql_database  = "xidb"
```

#### Usage Examples

**Backup before major changes**:
```bash
python tools/dbtool.py --backup
```

**Update after pulling new code**:
```bash
git pull
python tools/dbtool.py --update express
```

**Full database refresh**:
```bash
python tools/dbtool.py --backup
python tools/dbtool.py --update full
```

## Server Administration

### announce.py

**Location**: `/tools/announce.py`

**Purpose**: Broadcast messages to all online players across all zones

#### Usage

```bash
python tools/announce.py "<message>"
```

#### Examples

```bash
# Server maintenance warning
python tools/announce.py "Server restart in 10 minutes. Please log out."

# Event announcement
python tools/announce.py "Double EXP event now active!"

# GM announcement
python tools/announce.py "[GM] Server maintenance completed. Thank you for your patience."
```

#### How It Works

1. Connects to the World Server
2. Sends IPC message to broadcast to all map servers
3. Map servers display message to all players in their zones

#### Requirements

- World Server must be running
- Requires network configuration from `/settings/network.lua`

### price_checker.py

**Location**: `/tools/price_checker.py`

**Purpose**: Validate NPC shop and guild shop pricing consistency

#### Usage

```bash
python tools/price_checker.py
```

#### Validation Checks

- Compares NPC shop prices with item base prices
- Identifies pricing inconsistencies
- Flags items with unusual markup/markdown
- Reports potential data errors

#### Output

- List of items with pricing issues
- Suggested corrections
- CSV export option for bulk fixes

### give_items.py (Festive Moogle)

**Location**: `/tools/give_items.py`

**Purpose**: Distribute special items, cosmetics, or collectibles to players

#### Usage

```bash
# Give item to all characters
python tools/give_items.py --item <item_id> --quantity <qty>

# Give item to specific characters
python tools/give_items.py --item <item_id> --quantity <qty> --chars <char1,char2,char3>

# Give item to online players only
python tools/give_items.py --item <item_id> --quantity <qty> --online
```

#### Use Cases

- Holiday event rewards
- Apology gifts for downtime
- Special commemorative items
- GM events

#### Safety Features

- Dry-run mode (preview without executing)
- Inventory space checks
- Item ID validation
- Transaction rollback on error

## Development Tools

### Code Quality Tools

#### run_clang_format.sh

**Location**: `/tools/run_clang_format.sh`

**Purpose**: Format C++ code according to project standards

**Usage**:
```bash
bash tools/run_clang_format.sh
```

**Features**:
- Formats all `.cpp` and `.h` files
- Uses `.clang-format` configuration
- In-place formatting
- Git integration (format changed files only)

#### ClangTidy Integration

**Purpose**: Static analysis for C++ code

**Usage**:
```bash
# Run on entire codebase
clang-tidy src/**/*.cpp

# Run on specific file
clang-tidy src/map/zone.cpp
```

**Checks**:
- Code quality issues
- Performance problems
- Modernization suggestions
- Bug patterns

### IPC Stub Generation

**Purpose**: Auto-generate ZeroMQ IPC communication stubs

**Location**: Python scripts in `/tools/` directory

**Process**:
1. Parse IPC definitions from `/src/common/ipc.h`
2. Generate C++ wrapper code
3. Create message serialization/deserialization

**Invocation**: Automatically called during CMake build process

### Fuzzing Support

**Location**: `/src/test/fuzzer.cpp`

**Purpose**: Fuzz testing for server components

**Usage**:
```bash
# Build fuzzer
cmake -DENABLE_FUZZING=ON -B build
cmake --build build --target fuzzer

# Run fuzzer
./build/fuzzer <input_corpus>
```

**Targets**:
- Packet parsing
- Lua script execution
- Database queries
- Input validation

## Deployment Tools

### install-systemd-service.sh

**Location**: `/tools/install-systemd-service.sh`

**Purpose**: Install LandSandBoat as a systemd service on Linux

**Usage**:
```bash
sudo bash tools/install-systemd-service.sh
```

**Creates**:
- systemd service files in `/etc/systemd/system/`
- Service units for login, map, world, search servers
- Auto-start on boot

**Service Management**:
```bash
# Start all services
sudo systemctl start xiserver.target

# Stop all services
sudo systemctl stop xiserver.target

# Check status
sudo systemctl status xiserver.target

# View logs
sudo journalctl -u xiserver-map.service -f
```

### Docker Compose

**Location**: `/docker/dev.docker-compose.yml`

**Purpose**: Containerized development environment

**Services**:
- MariaDB database
- Login server
- Map server
- World server
- Search server

**Usage**:
```bash
# Start all services
docker-compose -f docker/dev.docker-compose.yml up

# Start in background
docker-compose -f docker/dev.docker-compose.yml up -d

# Stop services
docker-compose -f docker/dev.docker-compose.yml down

# View logs
docker-compose -f docker/dev.docker-compose.yml logs -f
```

**Advantages**:
- Isolated environment
- Consistent setup across platforms
- Easy teardown and rebuild
- Volume persistence for database

## Custom Tool Development

### Connecting to LandSandBoat

#### Python Database Connection

```python
import mariadb
import yaml

# Load database config from network.lua (or parse manually)
config = {
    'host': '127.0.0.1',
    'port': 3306,
    'user': 'xiserver',
    'password': 'xiserver',
    'database': 'xidb'
}

# Connect to database
conn = mariadb.connect(**config)
cursor = conn.cursor()

# Query example
cursor.execute("SELECT charid, charname FROM chars")
for charid, charname in cursor:
    print(f"{charid}: {charname}")

# Close connection
cursor.close()
conn.close()
```

#### Node.js Database Connection

```javascript
const mysql = require('mysql2/promise');

async function connect() {
    const pool = mysql.createPool({
        host: '127.0.0.1',
        port: 3306,
        user: 'xiserver',
        password: 'xiserver',
        database: 'xidb',
        waitForConnections: true,
        connectionLimit: 10
    });

    // Query example
    const [rows] = await pool.query('SELECT charid, charname FROM chars');
    console.log(rows);

    return pool;
}

connect();
```

#### ZeroMQ IPC Integration

```python
import zmq

context = zmq.Context()
socket = context.socket(zmq.DEALER)
socket.connect("tcp://127.0.0.1:54003")

# Send IPC message
message = {
    'type': 'ANNOUNCE',
    'text': 'Hello from custom tool!'
}

socket.send_json(message)

# Receive response
response = socket.recv_json()
print(response)
```

### Tool Template

```python
#!/usr/bin/env python3
"""
Custom LandSandBoat Tool Template
"""

import mariadb
import argparse
import sys

def load_config():
    """Load database config from network.lua or config file"""
    # TODO: Parse /settings/network.lua or use hardcoded values
    return {
        'host': '127.0.0.1',
        'port': 3306,
        'user': 'xiserver',
        'password': 'xiserver',
        'database': 'xidb'
    }

def connect_db(config):
    """Connect to MariaDB database"""
    try:
        conn = mariadb.connect(**config)
        return conn
    except mariadb.Error as e:
        print(f"Error connecting to database: {e}")
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description='Custom LandSandBoat Tool')
    parser.add_argument('--dry-run', action='store_true', help='Preview without executing')
    args = parser.parse_args()

    config = load_config()
    conn = connect_db(config)
    cursor = conn.cursor()

    try:
        # Your tool logic here
        cursor.execute("SELECT COUNT(*) FROM chars")
        count = cursor.fetchone()[0]
        print(f"Total characters: {count}")

        if not args.dry_run:
            # Perform operations
            conn.commit()
        else:
            print("Dry run mode - no changes made")

    except Exception as e:
        print(f"Error: {e}")
        conn.rollback()
    finally:
        cursor.close()
        conn.close()

if __name__ == '__main__':
    main()
```

## GM Tools Development

### Web-Based GM Tool Example

**Tech Stack**:
- Backend: Python Flask / Node.js Express
- Frontend: React / Vue / vanilla JS
- Database: Direct MariaDB connection

**Architecture**:
```
Browser (React/Vue)
    ↓ HTTP
Flask/Express API Server
    ↓ SQL
MariaDB Database (LandSandBoat)
```

**Features**:
- Player search and management
- Inventory editing
- Position teleport
- Item distribution
- Server announcements
- Ban management
- Audit logging

### Example API Endpoint (Flask)

```python
from flask import Flask, jsonify, request
import mariadb

app = Flask(__name__)

def get_db():
    return mariadb.connect(
        host='127.0.0.1',
        port=3306,
        user='xiserver',
        password='xiserver',
        database='xidb'
    )

@app.route('/api/characters', methods=['GET'])
def get_characters():
    """Get all characters"""
    conn = get_db()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT charid, charname, mjob, mlvl FROM chars")
    characters = cursor.fetchall()
    cursor.close()
    conn.close()
    return jsonify(characters)

@app.route('/api/characters/<int:charid>/inventory', methods=['GET'])
def get_inventory(charid):
    """Get character inventory"""
    conn = get_db()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT ci.slot, ci.itemId, ci.quantity, ib.name
        FROM char_inventory ci
        JOIN item_basic ib ON ci.itemId = ib.itemid
        WHERE ci.charid = ? AND ci.location = 0
        ORDER BY ci.slot
    """, (charid,))
    inventory = cursor.fetchall()
    cursor.close()
    conn.close()
    return jsonify(inventory)

@app.route('/api/characters/<int:charid>/items', methods=['POST'])
def add_item(charid):
    """Add item to character inventory"""
    data = request.json
    item_id = data['itemId']
    quantity = data['quantity']

    conn = get_db()
    cursor = conn.cursor()

    try:
        # Find empty slot
        cursor.execute("""
            SELECT MIN(slot) FROM (
                SELECT slot FROM char_inventory
                WHERE charid = ? AND location = 0
            ) AS used_slots
            RIGHT JOIN (
                SELECT slot FROM (
                    SELECT 0 AS slot UNION ALL SELECT 1 UNION ALL ...
                ) AS all_slots
            ) AS all_slots ON used_slots.slot = all_slots.slot
            WHERE used_slots.slot IS NULL
        """, (charid,))
        slot = cursor.fetchone()[0]

        if slot is None:
            return jsonify({'error': 'Inventory full'}), 400

        # Insert item
        cursor.execute("""
            INSERT INTO char_inventory (charid, location, slot, itemId, quantity)
            VALUES (?, 0, ?, ?, ?)
        """, (charid, slot, item_id, quantity))

        conn.commit()
        return jsonify({'success': True, 'slot': slot})

    except Exception as e:
        conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        conn.close()

if __name__ == '__main__':
    app.run(debug=True, port=5000)
```

## Monitoring and Analytics

### Server Monitoring Tool Example

```python
#!/usr/bin/env python3
"""
LandSandBoat Server Monitor
"""

import mariadb
import time
from datetime import datetime

def get_db():
    return mariadb.connect(
        host='127.0.0.1',
        port=3306,
        user='xiserver',
        password='xiserver',
        database='xidb'
    )

def get_online_players():
    """Get count of online players"""
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM accounts_sessions")
    count = cursor.fetchone()[0]
    cursor.close()
    conn.close()
    return count

def get_server_stats():
    """Get various server statistics"""
    conn = get_db()
    cursor = conn.cursor()

    stats = {}

    # Total characters
    cursor.execute("SELECT COUNT(*) FROM chars")
    stats['total_chars'] = cursor.fetchone()[0]

    # Active accounts (logged in within 24h)
    cursor.execute("""
        SELECT COUNT(DISTINCT accid) FROM account_ip_record
        WHERE login_time > NOW() - INTERVAL 24 HOUR
    """)
    stats['active_accounts_24h'] = cursor.fetchone()[0]

    # Auction house listings
    cursor.execute("SELECT COUNT(*) FROM auction_house WHERE sale = 0")
    stats['ah_listings'] = cursor.fetchone()[0]

    cursor.close()
    conn.close()
    return stats

def monitor_loop():
    """Continuously monitor server"""
    while True:
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        online = get_online_players()
        stats = get_server_stats()

        print(f"[{timestamp}] Online: {online} | "
              f"Total Chars: {stats['total_chars']} | "
              f"Active 24h: {stats['active_accounts_24h']} | "
              f"AH Listings: {stats['ah_listings']}")

        time.sleep(60)  # Update every minute

if __name__ == '__main__':
    print("LandSandBoat Server Monitor")
    print("=" * 50)
    try:
        monitor_loop()
    except KeyboardInterrupt:
        print("\nMonitoring stopped.")
```

## Best Practices

### Database Operations

1. **Always use transactions** for related changes
2. **Validate input data** before database operations
3. **Handle errors gracefully** with try/except and rollback
4. **Close connections** properly (use context managers)
5. **Use parameterized queries** to prevent SQL injection

### Tool Development

1. **Dry-run mode**: Add `--dry-run` flag for previewing changes
2. **Logging**: Log all operations for audit trail
3. **Backups**: Remind users to backup before destructive operations
4. **Validation**: Validate all inputs against game constraints
5. **Documentation**: Document tool usage and examples

### Performance

1. **Connection pooling**: Reuse database connections
2. **Batch operations**: Group multiple updates into transactions
3. **Indexes**: Ensure frequently queried columns are indexed
4. **Limit result sets**: Use `LIMIT` for large queries

### Security

1. **Credentials**: Never hardcode credentials in tools
2. **Input validation**: Sanitize all user inputs
3. **Permissions**: Use least-privilege database users
4. **Audit logging**: Log administrative actions

## Common Tool Ideas

### Player Management
- Character search and lookup
- Inventory viewer/editor
- Position teleporter
- Job/level editor
- Ban management

### Economy Tools
- Auction house monitor
- Price history tracker
- Currency distribution
- Gil fountain detection

### Content Management
- Quest progress viewer
- Mission completion tracker
- Key item editor
- Title unlocking

### Server Administration
- Broadcast announcements
- Server statistics dashboard
- Player activity reports
- Database maintenance automation

### Development Tools
- Item database browser
- Spell/ability reference
- Zone map viewer
- Drop rate calculator

## Testing Tools

Always test tools on a development database:

```python
# Use separate test database
TEST_CONFIG = {
    'host': '127.0.0.1',
    'port': 3306,
    'user': 'xiserver',
    'password': 'xiserver',
    'database': 'xidb_test'  # Test database
}

# Clone production database for testing
# mysqldump xidb | mysql xidb_test
```

## Useful Queries for Tools

### Player Activity
```sql
-- Most active players (by playtime)
SELECT charname, playtime / 3600 AS hours
FROM chars
ORDER BY playtime DESC
LIMIT 10;

-- Recent logins
SELECT c.charname, air.login_time
FROM account_ip_record air
JOIN chars c ON air.charid = c.charid
ORDER BY air.login_time DESC
LIMIT 20;
```

### Economy Monitoring
```sql
-- AH price history
SELECT itemid, AVG(sell_price) AS avg_price, COUNT(*) AS sales
FROM auction_house
WHERE sale > 0
GROUP BY itemid
ORDER BY sales DESC;

-- Top gil holders
SELECT charname, gil
FROM chars
JOIN char_points ON chars.charid = char_points.charid
ORDER BY gil DESC
LIMIT 10;
```

### Server Health
```sql
-- Character distribution by job
SELECT mjob, COUNT(*) AS count
FROM chars
GROUP BY mjob
ORDER BY count DESC;

-- Level distribution
SELECT mlvl, COUNT(*) AS count
FROM chars
GROUP BY mlvl
ORDER BY mlvl;
```

## Resources

- Python MariaDB documentation: https://mariadb.com/docs/
- ZeroMQ Python bindings: https://pyzmq.readthedocs.io/
- Flask framework: https://flask.palletsprojects.com/
- LandSandBoat tools directory: `/tools/`
