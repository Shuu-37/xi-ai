# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This repository serves as an **AI-friendly knowledge base** for Final Fantasy XI private servers, specifically the [LandSandBoat](https://github.com/LandSandBoat/server) codebase. It provides structured documentation and information to help AI agents:

- Understand LandSandBoat's architecture and systems
- Build tools and integrations (GM tools, APIs, utilities)
- Work with the database schema
- Interface with the server's various subsystems
- Develop custom content or modifications

## Repository Structure

```
/docs/                         - AI-friendly documentation (164 KB)
  architecture-overview.md     - Server components, processes, and system design
  gameplay-systems.md          - Combat, quests, NPCs, zones, and game mechanics
  database.md                  - Schema documentation, table relationships, data structures (56 KB)
  utilities.md                 - Available utilities, scripts, and development tools
  networking.md                - Network protocols, IPC, HTTP API, packet structures (28 KB)
  scripting.md                 - Lua scripting guide, integration points, examples

/reference/                    - Full LandSandBoat codebase clone (gitignored, set up via scripts/setup-reference.sh)
  src/                         - C++20 source code (common, map, world, login, search)
  scripts/                     - Lua scripting layer (zones, globals, enums)
  sql/                         - 126+ SQL schema files
  tools/                       - Python development tools
  settings/                    - Lua configuration files
  documentation/               - LandSandBoat reference documentation
```

## LandSandBoat Quick Reference

### Technology Stack
- **C++20**: Core server engine (~26% of codebase)
- **Lua/LuaJIT**: Gameplay scripting (~63% of codebase)
- **MariaDB**: Database backend
- **ZeroMQ**: Inter-process communication
- **CMake**: Build system
- **Python 3**: Development tools

### Server Architecture
LandSandBoat is a multi-process server emulator:

1. **Login Server** (ports 54001, 54230-54231, 51220): Authentication and account management
2. **Map Server(s)** (port 54230 UDP): Core gameplay engine handling zones, entities, combat, AI
3. **World Server** (optional HTTP API port 8088): Cross-zone functionality, linkshells, parties
4. **Search Server** (port 54002): Player search functionality
5. **Database** (port 3306): MariaDB for persistent data
6. **IPC** (port 54003): ZeroMQ message queue for inter-process communication

### Key Source Directories (in /reference/)
- `/reference/src/common/` - Shared utilities, IPC, database access
- `/reference/src/map/` - Core gameplay engine (151 files)
  - `/reference/src/map/entities/` - Entity system (chars, mobs, NPCs, pets, trusts)
  - `/reference/src/map/ai/` - AI controllers and state machines
  - `/reference/src/map/packets/` - Network protocol (c2s and s2c)
- `/reference/scripts/` - Lua scripting layer
  - `/reference/scripts/zones/` - 297 zone directories with NPCs, mobs, quests
  - `/reference/scripts/globals/` - 127 shared functionality files
  - `/reference/scripts/enum/` - 110 enumeration files (game constants)

### Database Schema
126 SQL files organized by system:
- Character data: `chars`, `char_jobs`, `char_skills`, `char_inventory`, etc.
- Accounts: `accounts`, `accounts_banned`, `accounts_sessions`
- Game systems: `abilities`, `spell_list`, `mob_spawn_points`, `auction_house`, `synth_recipes`
- Content: Fishing, crafting, BCNM, instances, status effects

### Configuration System
All configuration uses Lua format (`/reference/settings/default/`):
- `main.lua` - Core server settings (expansions, rates, content toggles)
- `network.lua` - Network ports, database connection, DDoS protection
- `map.lua` - Map server configuration
- `login.lua` - Authentication settings

### Python Tools
Located in `/reference/tools/`:
- `dbtool.py` - Database management, backups, migrations
- `announce.py` - Broadcast messages to all online players
- `price_checker.py` - Validate NPC/guild shop pricing
- `give_items.py` - Item distribution to characters
- Plus 20+ additional development and CI tools

## Common Development Tasks

### Building Tools for LandSandBoat

When building integrations or tools:

1. **Database Access**: Connect to MariaDB (default port 3306), credentials in `/reference/settings/network.lua`
2. **HTTP API**: Optional World Server HTTP API on localhost:8088 (disabled by default, see `/docs/networking.md`)
3. **IPC Integration**: ZeroMQ on port 54003 (localhost only), use IPC structures from `/reference/src/common/ipc.h`
4. **Lua Scripting**: Place custom scripts in `/reference/scripts/` directory, use existing patterns from `/reference/scripts/globals/`
5. **Module System**: Create modules in `/reference/modules/custom/` for extending functionality

### Working with Game Data

- **Zone Information**: `/reference/documentation/ZoneIDs.txt` - Zone ID reference
- **Item Data**: Query `item_equipment`, `item_armor`, `item_weapon` tables (see `/docs/database.md`)
- **Mob Data**: Query `mob_spawn_points`, `mob_droplist`, `mob_resistances` (see `/docs/database.md`)
- **Quest/Mission Status**: See `/reference/documentation/CoP MissionStatus.md`
- **Database Schema**: Complete reference in `/docs/database.md` (56 KB)

### Understanding Game Mechanics

- **Combat System**: Implemented in `/reference/src/map/` (C++) with formulas in `/reference/scripts/globals/` (Lua)
- **Status Effects**: `/reference/src/map/status_effect_container.cpp` (C++) and `/reference/scripts/effects/` (Lua)
- **Entity Management**: Entity base classes in `/reference/src/map/entities/`
- **AI Behavior**: Controllers and states in `/reference/src/map/ai/`
- **Gameplay Documentation**: See `/docs/gameplay-systems.md` for comprehensive coverage

## Building GM Tools or APIs

### Common Use Cases

1. **Player Management**: Query `chars` table, modify character stats, inventory, position
2. **Item Distribution**: Insert into `char_inventory` with proper item IDs and quantities
3. **Server Announcements**: Use `announce.py` or integrate with World Server
4. **Economy Monitoring**: Query `auction_house`, track transactions
5. **World State**: Access zone status, conquest, campaign, besieged systems

### Database Access Patterns

- Always use transactions when modifying multiple related tables
- Character binary blobs: missions, abilities, key_items, weapon_skills stored as binary
- Use proper foreign key relationships (charid references chars.charid)
- Respect game constraints (inventory slots, item stacking limits)

### Network Protocol Considerations

- FFXI uses custom binary protocol, packet definitions in `/reference/src/map/packets/`
- Modifying packets requires understanding client expectations
- For server-to-server communication, prefer ZeroMQ IPC
- For external tools, use database access or HTTP API (see `/docs/networking.md`)
- **Recommended approach**: TypeScript + TanStack Query for modern API development

## Important Considerations

### Data Integrity

- Character data is complex with many interdependencies
- Binary blob fields require careful parsing/modification
- Always backup database before bulk operations
- Test changes on development environment first

### Game Balance

- Server rates and multipliers configured in `/reference/settings/default/main.lua`
- Custom modifications should respect era-specific settings
- Module system allows customization without core changes

### Security

- Database credentials in `/reference/settings/default/network.lua`
- DDoS protection settings in network configuration
- IPC bound to localhost only
- HTTP API disabled by default for security (see `/docs/networking.md`)

### Performance

- Lua scripts are hot-reloadable (no server restart needed)
- Database queries should be optimized (indexed columns)
- ZeroMQ provides high-performance IPC
- Multiple map servers can run for load distribution

## Additional Resources

- **LandSandBoat Repository**: https://github.com/LandSandBoat/server
- **GitHub Wiki**: 48+ pages on installation, configuration, development
- **Module Guide**: Writing Lua, C++, and SQL modules
- **Development Guide**: Contributing and building features

## Working in This Repository

### Documentation Structure
This repository uses a **flat-file documentation structure** under `/docs/` for easy navigation:
- `architecture-overview.md` - Server architecture and processes
- `gameplay-systems.md` - Combat, quests, NPCs, zones
- `database.md` - Complete schema reference (largest file)
- `utilities.md` - Python tools and development utilities
- `networking.md` - API, IPC, and networking protocols
- `scripting.md` - Lua scripting guide

### Reference Directory
The `/reference/` directory contains the complete LandSandBoat codebase and is **gitignored**:
- Set up locally by running `./scripts/setup-reference.sh`
- Contains full C++20 source code
- All 297 zone scripts
- Complete SQL schema
- Python development tools
- Configuration files and documentation

This directory serves as a reference for AI agents to examine actual LandSandBoat code while working with the documentation.

### Contributing Guidelines

When adding or updating documentation:

1. **File Organization**: Add new documentation to `/docs/` as flat markdown files
2. **Formatting**: Use clear markdown with code blocks and examples
3. **Path References**: Reference files with line numbers (e.g., `/reference/src/map/zone.cpp:142`)
4. **Focus**: Keep content focused on building tools and integrations
5. **Updates**: Update this CLAUDE.md when structure or major content changes occur
