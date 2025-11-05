# XI-AI: LandSandBoat Knowledge Base

An AI-friendly documentation repository for [LandSandBoat](https://github.com/LandSandBoat/server), a Final Fantasy XI private server emulator.

## What is this?

This repository provides structured documentation and reference materials to help AI agents (like Claude) understand and work with LandSandBoat's codebase. It's designed to support building tools, integrations, APIs, and utilities for FFXI private servers.

The repository includes a `CLAUDE.md` file that provides comprehensive guidance for AI agents - no additional initialization needed.

## Setup

### 1. Clone this repository

```bash
git clone https://github.com/Shuu-37/xi-ai.git
cd xi-ai
```

**Important**: Always work from the `xi-ai` repository root directory. All path references in the documentation (like `/reference/src/map/` or `/docs/database.md`) are relative to this root directory.

### 2. Set up LandSandBoat Reference

From the repository root, run:

```bash
./scripts/setup-reference.sh
```

This will clone the [LandSandBoat repository](https://github.com/LandSandBoat/server) into a `reference/` directory. This directory is gitignored and used by AI agents as a reference when working with the documentation.

### 3. Using with Claude Code

When using Claude Code, make sure to launch it from the repository root:

```bash
cd xi-ai
claude
```

This ensures all path references in `CLAUDE.md` work correctly.

## Documentation

The `/docs/` directory contains comprehensive AI-friendly documentation:

- **`architecture-overview.md`** - Server components, multi-process architecture, and system design
- **`database.md`** - Complete database schema, table relationships, and data structures
- **`gameplay-systems.md`** - Combat mechanics, quests, NPCs, zones, and game systems
- **`networking.md`** - Network protocols, IPC, HTTP API, and packet structures
- **`scripting.md`** - Lua scripting guide, integration points, and examples
- **`utilities.md`** - Python tools and development utilities

## Quick Start

Run `claude` in your terminal, and see **`CLAUDE.md`** for comprehensive guidance on working with this repository and the LandSandBoat codebase.

## Links

- [LandSandBoat Repository](https://github.com/LandSandBoat/server)
- [LandSandBoat Wiki](https://github.com/LandSandBoat/server/wiki)
