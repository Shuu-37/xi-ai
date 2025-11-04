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
/docs/
  /architecture/     - Server components, processes, and system design
  /gameplay/         - Combat, quests, NPCs, zones, and game mechanics
  /database/         - Schema documentation, table relationships, data structures
  /tools/            - Available utilities, scripts, and development tools
  /api/              - Network protocols, IPC, HTTP API, packet structures
  /scripting/        - Lua scripting guide, integration points, examples
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

### Key Source Directories
- `/src/common/` - Shared utilities, IPC, database access
- `/src/map/` - Core gameplay engine (151 files)
  - `/src/map/entities/` - Entity system (chars, mobs, NPCs, pets, trusts)
  - `/src/map/ai/` - AI controllers and state machines
  - `/src/map/packets/` - Network protocol (c2s and s2c)
- `/scripts/` - Lua scripting layer
  - `/scripts/zones/` - 297 zone directories with NPCs, mobs, quests
  - `/scripts/globals/` - 127 shared functionality files
  - `/scripts/enum/` - 110 enumeration files (game constants)

### Database Schema
126 SQL files organized by system:
- Character data: `chars`, `char_jobs`, `char_skills`, `char_inventory`, etc.
- Accounts: `accounts`, `accounts_banned`, `accounts_sessions`
- Game systems: `abilities`, `spell_list`, `mob_spawn_points`, `auction_house`, `synth_recipes`
- Content: Fishing, crafting, BCNM, instances, status effects

### Configuration System
All configuration uses Lua format (`/settings/default/`):
- `main.lua` - Core server settings (expansions, rates, content toggles)
- `network.lua` - Network ports, database connection, DDoS protection
- `map.lua` - Map server configuration
- `login.lua` - Authentication settings

### Python Tools
Located in `/tools/`:
- `dbtool.py` - Database management, backups, migrations
- `announce.py` - Broadcast messages to all online players
- `price_checker.py` - Validate NPC/guild shop pricing

## Common Development Tasks

### Building Tools for LandSandBoat

When building integrations or tools:

1. **Database Access**: Connect to MariaDB (default port 3306), credentials in `settings/network.lua`
2. **HTTP API**: Optional World Server HTTP API on localhost:8088 (disabled by default)
3. **IPC Integration**: ZeroMQ on port 54003 (localhost only), use IPC structures from `src/common/ipc.h`
4. **Lua Scripting**: Place custom scripts in `/scripts/` directory, use existing patterns from `/scripts/globals/`
5. **Module System**: Create modules in `/modules/custom/` for extending functionality

### Working with Game Data

- **Zone Information**: `/documentation/zone_ids.txt` - Zone ID reference
- **Item Data**: Query `item_equipment`, `item_armor`, `item_weapon` tables
- **Mob Data**: Query `mob_spawn_points`, `mob_droplist`, `mob_resistances`
- **Quest/Mission Status**: See `/documentation/mission_status.txt`

### Understanding Game Mechanics

- **Combat System**: Implemented in `/src/map/` (C++) with formulas in `/scripts/globals/` (Lua)
- **Status Effects**: `status_effect_container.cpp` (C++) and `/scripts/effects/` (Lua)
- **Entity Management**: Entity base classes in `/src/map/entities/`
- **AI Behavior**: Controllers and states in `/src/map/ai/`

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

- FFXI uses custom binary protocol, packet definitions in `/src/map/packets/`
- Modifying packets requires understanding client expectations
- For server-to-server communication, prefer ZeroMQ IPC
- For external tools, use database access or HTTP API

## Important Considerations

### Data Integrity

- Character data is complex with many interdependencies
- Binary blob fields require careful parsing/modification
- Always backup database before bulk operations
- Test changes on development environment first

### Game Balance

- Server rates and multipliers configured in `main.lua`
- Custom modifications should respect era-specific settings
- Module system allows customization without core changes

### Security

- Database credentials in `settings/network.lua`
- DDoS protection settings in network configuration
- IPC bound to localhost only
- HTTP API disabled by default for security

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

When adding documentation to this repository:

1. Maintain the directory structure under `/docs/`
2. Use clear markdown formatting
3. Include code examples where applicable
4. Reference specific file paths with line numbers when relevant (e.g., `src/map/zone.cpp:142`)
5. Keep documentation focused on information useful for building tools and integrations
6. Update this CLAUDE.md if major structural changes occur
