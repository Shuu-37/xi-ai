# LandSandBoat Server Architecture

## Overview

LandSandBoat is a multi-process server emulator for Final Fantasy XI, designed with a modular architecture that separates concerns across different server processes communicating via ZeroMQ.

## Server Components

### 1. Login Server

**Ports**: 54001 (view), 54230 (data), 54231 (auth), 51220 (config)

**Responsibilities**:
- Player authentication
- Account validation
- Session management
- Character selection
- Initial connection handling

**Source Location**: `/src/login/`

**Key Features**:
- Account creation and management
- Ban system integration
- IP logging and security
- Multiple character support per account

### 2. Map Server(s)

**Port**: 54230 (UDP)

**Responsibilities**:
- Core gameplay engine
- Zone management and entity processing
- Combat calculations and AI
- Player movement and interaction
- Quest and event scripting
- Inventory management
- Real-time gameplay state

**Source Location**: `/src/map/` (151 files)

**Key Subsystems**:
- **Entity System** (`/entities/`): Characters, mobs, NPCs, pets, trusts
- **AI System** (`/ai/`): Controllers, states, helpers
- **Combat System**: Abilities, attacks, weapon skills, mob skills
- **Status Effects**: Effect containers, latent effects
- **Inventory**: Item containers, trade containers
- **Party/Social**: Party, alliance, linkshell management
- **World Systems**: Conquest, campaign, besieged
- **Progression**: Merits, job points, traits

**Architecture Pattern**:
- C++ engine provides core functionality
- Lua scripts handle content-specific logic
- Hot-reloadable Lua scripts (no restart needed)
- Multiple map servers can run for load distribution

### 3. World Server

**Port**: 8088 (HTTP API, optional, localhost only)

**Responsibilities**:
- Cross-zone functionality
- Linkshell management
- Party and alliance coordination
- Global messaging and announcements
- Auction house synchronization
- Server-wide events

**Source Location**: `/src/world/`

**Key Features**:
- Optional HTTP API for external integrations
- ZeroMQ integration with other servers
- Global state management

### 4. Search Server

**Port**: 54002

**Responsibilities**:
- Player search functionality
- Friend list management
- Online status tracking

**Source Location**: `/src/search/`

### 5. Database

**Technology**: MariaDB
**Port**: 3306
**Character Encoding**: UTF8mb4

**Responsibilities**:
- Persistent data storage
- Character information
- Game configuration data
- World state persistence

**Schema**: 126 SQL files in `/sql/`

## Inter-Process Communication (IPC)

### ZeroMQ Message Queue

**Port**: 54003 (localhost only)

**Pattern**: Dealer/Router wrapper

**Purpose**:
- High-performance message passing between server processes
- Asynchronous communication
- Distributed architecture support

**Implementation**:
- Core IPC structures in `/src/common/ipc.h` and `ipc_structs.h`
- Auto-generated IPC stubs via Python scripts during build
- Messages include: zone transfers, global announcements, party updates

**Security**: Bound to localhost only for security

## Technology Stack

### Core Languages

1. **C++20** (25.7% of codebase)
   - Core server engine
   - Performance-critical systems
   - Entity management
   - Network protocol handling

2. **Lua/LuaJIT** (63.4% of codebase)
   - Gameplay scripting
   - Content implementation
   - Quest logic
   - NPC behaviors

3. **C** (9.8% of codebase)
   - Low-level systems
   - Performance-critical operations

4. **Python 3**
   - Development tools
   - Code generation
   - Database management
   - Server administration utilities

### Major Dependencies

**Core Libraries**:
- **LuaJIT**: High-performance Lua execution
- **MariaDB C++ Connector**: Database access
- **ZeroMQ (ZMQ)**: Inter-process messaging
- **OpenSSL**: Cryptography (libcrypto, libssl)

**Utilities**:
- **sol2**: C++/Lua binding framework (all safety checks enabled)
- **spdlog**: Structured logging framework
- **Tracy**: Optional profiling support
- **Recast Navigation**: Pathfinding via navmeshes

**Build System**:
- **CMake 3.25+**: Build configuration
- **Binutils**: Unix/Linux compilation
- **Python 3**: Code generation scripts

## Directory Structure

### Source Code (`/src/`)

```
/src/
  /common/          - Shared utilities across all servers
    - Database access layer
    - IPC communication
    - Logging infrastructure
    - Encryption/security
    - Utility functions

  /login/           - Login server implementation

  /map/             - Map server (core gameplay engine)
    /ai/            - Artificial intelligence
      - Controllers
      - States
      - Helpers
    /entities/      - Game entities
      - baseentity, battleentity
      - charentity (players)
      - mobentity (monsters)
      - npcentity (NPCs)
      - petentity, trustentity, automatonentity
    /items/         - Item system
    /packets/       - Network protocol
      /c2s/         - Client-to-server packets
      /s2c/         - Server-to-client packets
    /lua/           - Lua integration layer
    /utils/         - Helper functions

  /world/           - World server implementation

  /search/          - Search server implementation

  /test/            - Testing framework
```

### Scripts (`/scripts/`)

```
/scripts/
  /zones/           - 297 zone directories
    /[zone_name]/   - Each zone contains:
      - NPCs
      - Mobs
      - Quests
      - Events
      - Zone-specific logic

  /quests/          - Quest implementations by region
    /bastok/
    /jeuno/
    /sandoria/
    /windurst/
    /aht_urhgan/
    /abyssea/
    /adoulin/

  /missions/        - Mission frameworks

  /globals/         - 127 shared functionality files
    - Combat mechanics
    - Crafting systems
    - Pet systems
    - Shop handling
    - Teleportation
    - Chocobo systems
    - Job utilities

  /enum/            - 110 enumeration files (game constants)
  /actions/         - Player/NPC actions
  /battlefields/    - Battle system logic
  /commands/        - In-game commands
  /effects/         - Status effects
  /items/           - Item behaviors
  /mixins/          - Reusable components
  /utils/           - Helper functions
```

## Data Flow

### Player Login Flow

1. Client connects to **Login Server** (port 54001)
2. Login Server validates credentials against `accounts` table
3. Login Server presents character list from `chars` table
4. Player selects character
5. Login Server sends zone assignment
6. Client connects to **Map Server** (port 54230 UDP)
7. Map Server loads character data from database
8. Map Server initializes entity in zone
9. Gameplay begins

### Zone Transfer Flow

1. Player triggers zone transfer (door, teleport, etc.)
2. **Map Server** saves character state to database
3. Map Server sends IPC message to **World Server** via ZeroMQ
4. World Server coordinates zone change
5. Target Map Server receives IPC message
6. Client connects to new zone
7. New Map Server loads character data
8. Player appears in new zone

### Combat Flow

1. Player initiates action (attack, ability, spell)
2. **Map Server** validates action via C++ engine
3. Engine calculates damage/effects using formulas
4. Lua scripts may modify calculations (job abilities, traits)
5. Status effects applied via `status_effect_container`
6. Results sent to client via packets (`/src/map/packets/s2c/`)
7. AI updates for affected entities (`/src/map/ai/`)

### Quest/Event Flow

1. Player interacts with NPC
2. **Map Server** calls Lua script (`/scripts/zones/[zone]/npcs/[npc].lua`)
3. Lua script checks quest state (database or character flags)
4. Event triggered based on conditions
5. Dialog, cutscenes, or battles initiated
6. Quest state updated in database
7. Rewards distributed (items, gil, experience)

## Configuration System

All configuration files use **Lua** format for flexibility.

### Location: `/settings/default/`

**Files**:
- `main.lua` - Core server settings
  - Expansion toggles
  - EXP/drop rate multipliers
  - Content availability
  - Character progression parameters

- `network.lua` - Network configuration
  - Server ports
  - Database connection (host, port, credentials)
  - IPC settings
  - DDoS protection (rate limiting, IP allow/deny)

- `map.lua` - Map server specific settings
- `login.lua` - Login server settings
- `search.lua` - Search server settings
- `logging.lua` - Log levels and output

### Custom Configurations

Copy files from `/settings/default/` to `/settings/` and modify. Server reads from `/settings/` first, falls back to defaults.

## Module System

### Location: `/modules/`

**Purpose**: Extend server functionality without modifying core code

**Types**:
- **Lua Modules**: Gameplay modifications
- **C++ Modules**: Engine extensions
- **SQL Modules**: Database schema additions

**Structure**:
```
/modules/
  /custom/          - Custom implementations
  /era/             - Era-specific features
  /example/         - Module templates
  /testing/         - Test modules
  init.txt          - Module loading order
```

**Loading**: Modules listed in `modules/init.txt` are loaded at server startup

## Build Process

1. **CMake Configuration**: Generates build files from CMakeLists.txt
2. **IPC Stub Generation**: Python scripts generate IPC communication stubs
3. **C++ Compilation**: Compiles C++20 source code
4. **Lua Integration**: Links LuaJIT for runtime scripting
5. **Dependency Linking**: Links MariaDB, ZeroMQ, OpenSSL, etc.
6. **Output**: Separate executables for each server component

### Build Commands

```bash
# Generate build files
cmake -B build

# Compile
cmake --build build

# Or use make directly
cd build && make -j$(nproc)
```

## Deployment Options

### 1. Docker Compose (Recommended for Development)

**File**: `/docker/dev.docker-compose.yml`

**Advantages**:
- Isolated environment
- Easy setup
- Consistent across platforms
- Includes database container

### 2. systemd Service (Linux Production)

**Script**: `/tools/install-systemd-service.sh`

**Advantages**:
- Auto-start on boot
- Process management
- Log integration
- Production-ready

### 3. Manual Execution

Run each server component separately:
```bash
./xi_login
./xi_map
./xi_world
./xi_search
```

## Performance Considerations

### Scalability

- **Multiple Map Servers**: Can run multiple map servers for load distribution
- **Database Optimization**: Proper indexing on frequently queried columns
- **Lua Script Caching**: Scripts compiled and cached by LuaJIT
- **ZeroMQ Performance**: High-throughput IPC with minimal latency

### Resource Usage

- **Map Server**: Most resource-intensive (handles gameplay calculations)
- **Database**: I/O bound, benefits from SSD storage
- **Network**: UDP for real-time gameplay, TCP for session management

### Optimization Techniques

- **Entity Pooling**: Reuse entity objects to reduce allocations
- **Packet Batching**: Combine multiple updates into single packets
- **Database Transactions**: Batch related operations
- **Spatial Indexing**: Efficient zone entity lookups

## Security Features

### Network Protection

- **DDoS Mitigation**: Connection rate limiting, IP filtering
- **IPC Isolation**: ZeroMQ bound to localhost only
- **HTTP API**: Disabled by default, localhost only when enabled
- **Packet Validation**: All client packets validated before processing

### Account Security

- **Password Hashing**: Secure password storage
- **Ban System**: IP and account bans
- **Session Management**: Token-based sessions
- **IP Logging**: Track account access patterns

### Data Protection

- **SQL Injection Prevention**: Parameterized queries
- **Input Validation**: All player input sanitized
- **Transaction Integrity**: ACID compliance for database operations

## Extension Points for External Tools

### 1. Database Access

**Direct SQL queries** to MariaDB on port 3306:
- Read character data
- Modify inventory
- Query auction house
- Track server statistics

### 2. HTTP API (World Server)

**Optional REST-like interface** on localhost:8088:
- Server announcements
- World state queries
- Cross-zone operations

### 3. ZeroMQ IPC

**Message queue integration** on port 54003:
- Send IPC messages between processes
- Custom server components
- External monitoring tools

### 4. Lua Scripting

**Custom scripts** in `/scripts/` directory:
- Quest implementation
- NPC behaviors
- Custom commands
- Event triggers

### 5. Module System

**Loadable modules** in `/modules/custom/`:
- C++ engine extensions
- Lua gameplay modifications
- SQL schema additions

## Monitoring and Debugging

### Logging

**spdlog framework** with configurable levels:
- Debug, Info, Warning, Error, Critical
- Console and file output
- Per-component log filtering

**Configuration**: `/settings/logging.lua`

### Profiling

**Tracy support** (optional):
- Performance profiling
- Frame timing
- Memory allocation tracking

### Database Monitoring

- Query performance analysis
- Connection pool monitoring
- Transaction tracking

## Common Integration Patterns

### GM Tool Development

1. Connect to MariaDB database
2. Query player/character data
3. Build web interface (React, Vue, etc.)
4. Execute administrative commands via database updates
5. Optionally use HTTP API for real-time operations

### API Development

1. Create REST/GraphQL API server
2. Connect to LandSandBoat database
3. Expose read-only game data (items, mobs, zones)
4. Implement authentication for write operations
5. Use transactions for data consistency

### Monitoring Dashboard

1. Connect to database for metrics
2. Track player counts, economy, server health
3. Historical data analysis
4. Alert on anomalies
5. Visualization with charts/graphs

### Automation Scripts

1. Use Python with MariaDB connector
2. Schedule tasks (cron, systemd timers)
3. Database backups with `dbtool.py`
4. Event scheduling (special events, maintenance)
5. Data cleanup and maintenance

## Best Practices for Integrations

1. **Use Transactions**: Always use database transactions for related changes
2. **Respect Game Logic**: Understand game constraints before modifying data
3. **Test on Development Server**: Never test on production databases
4. **Backup Before Bulk Operations**: Use `dbtool.py` for backups
5. **Follow Naming Conventions**: Match LandSandBoat's coding standards
6. **Document Custom Modules**: Add clear documentation for maintainability
7. **Handle Binary Data Carefully**: Character blobs require proper encoding
8. **Monitor Performance**: Index database queries, optimize hotpaths
9. **Security First**: Validate all inputs, use parameterized queries
10. **Version Control**: Track configuration and module changes
