# XI-AI: LandSandBoat Knowledge Base for AI Agents

An AI-friendly knowledge base and documentation repository for Final Fantasy XI private servers, specifically the [LandSandBoat](https://github.com/LandSandBoat/server) codebase.

## Purpose

This repository provides structured information and documentation to help AI agents:

- Understand LandSandBoat's architecture and internal systems
- Build tools and integrations (GM tools, APIs, web interfaces)
- Work with the database schema and game data
- Interface with server subsystems
- Develop custom content, modules, or modifications
- Create automation tools for server management

## Structure

- **`/docs/architecture/`** - Server components, multi-process architecture, IPC systems
- **`/docs/gameplay/`** - Combat mechanics, quests, NPCs, zones, game systems
- **`/docs/database/`** - Schema documentation, table relationships, data structures
- **`/docs/tools/`** - Available utilities, Python scripts, development tools
- **`/docs/api/`** - Network protocols, IPC, HTTP API, packet structures
- **`/docs/scripting/`** - Lua scripting guide, integration points, examples

## Quick Start for AI Agents

See `CLAUDE.md` for comprehensive guidance on working with this repository and the LandSandBoat codebase.

### LandSandBoat at a Glance

**Technology Stack:**
- C++20 (core engine), Lua/LuaJIT (gameplay scripting), MariaDB (database)
- ZeroMQ (IPC), CMake (build), Python 3 (tools)

**Server Components:**
- Login Server (authentication)
- Map Server(s) (gameplay engine)
- World Server (cross-zone features, optional HTTP API)
- Search Server (player search)
- MariaDB Database (persistent data)

**Key Directories in LandSandBoat:**
- `/src/` - C++ source code (common, map, world, login, search)
- `/scripts/` - Lua scripting layer (zones, quests, globals, enums)
- `/sql/` - 126 database schema files
- `/tools/` - Python utilities (dbtool.py, announce.py, etc.)
- `/settings/` - Lua configuration files

## Use Cases

This repository is designed to support AI agents building:

1. **GM Tools** - Web interfaces for game masters to manage servers, players, items
2. **APIs** - RESTful or GraphQL APIs to expose server data and functionality
3. **Monitoring Tools** - Server health, player activity, economy tracking
4. **Content Tools** - Quest editors, NPC managers, zone configuration
5. **Automation Scripts** - Event scheduling, maintenance tasks, backups
6. **Analytics** - Player statistics, economy analysis, gameplay metrics

## Target Audience

- AI agents (Claude, GPT, etc.) building LandSandBoat integrations
- Developers creating tools for FFXI private servers
- Server administrators seeking to understand LandSandBoat architecture
- Anyone building automation or management systems for LandSandBoat

## Contributing

This repository is intended to grow over time with additional documentation, examples, and reference materials. Contributions that improve AI agent understanding of LandSandBoat systems are welcome.

When adding documentation:
- Maintain clear directory structure
- Use markdown formatting
- Include code examples where applicable
- Reference specific file paths (e.g., `src/map/zone.cpp:142`)
- Focus on information useful for building integrations

## Resources

- **LandSandBoat Repository**: https://github.com/LandSandBoat/server
- **LandSandBoat Wiki**: Comprehensive guides on installation, configuration, development
- **FFXI Wikipedia**: Game mechanics and lore reference

## License

This repository contains documentation and reference materials for the LandSandBoat project. Please refer to the [LandSandBoat repository](https://github.com/LandSandBoat/server) for the actual source code and its license.
