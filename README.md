# XI-AI: LandSandBoat Knowledge Base

An AI-friendly documentation repository for [LandSandBoat](https://github.com/LandSandBoat/server), a Final Fantasy XI private server emulator.

## What is this?

This repository provides structured documentation and reference materials to help AI agents (like Claude) understand and work with LandSandBoat's codebase. It's designed to support building tools, integrations, APIs, and utilities for FFXI private servers.

## Setup

### 1. Initialize Claude Code

If you're using Claude Code, initialize the project:

```bash
claude code
```

Then run the `/init` command to set up your local Claude Code configuration.

### 2. Set up LandSandBoat Reference

To get the complete LandSandBoat reference codebase locally, run:

```bash
./scripts/setup-reference.sh
```

This will clone the [LandSandBoat repository](https://github.com/LandSandBoat/server) into a `reference/` directory. This directory is gitignored and used by AI agents as a reference when working with the documentation.

## Documentation

The `/docs/` directory contains comprehensive AI-friendly documentation:

- **`architecture-overview.md`** - Server components, multi-process architecture, and system design
- **`database.md`** - Complete database schema, table relationships, and data structures
- **`gameplay-systems.md`** - Combat mechanics, quests, NPCs, zones, and game systems
- **`networking.md`** - Network protocols, IPC, HTTP API, and packet structures
- **`scripting.md`** - Lua scripting guide, integration points, and examples
- **`utilities.md`** - Python tools and development utilities

## Quick Start

See **`CLAUDE.md`** for comprehensive guidance on working with this repository and the LandSandBoat codebase.

## Links

- [LandSandBoat Repository](https://github.com/LandSandBoat/server)
- [LandSandBoat Wiki](https://github.com/LandSandBoat/server/wiki)
