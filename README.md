# XI-AI: LandSandBoat Knowledge Base

An AI-friendly documentation repository for [LandSandBoat](https://github.com/LandSandBoat/server), a Final Fantasy XI private server emulator.

## What is this?

This repository provides structured documentation and reference materials to help AI agents (like Claude) understand and work with LandSandBoat's codebase. It's designed to support building tools, integrations, APIs, and utilities for FFXI private servers.

The repository includes a `CLAUDE.md` file that provides comprehensive guidance for AI agents - no additional initialization needed.

## Setup

### 1. Clone into your project

Clone this repository anywhere in your project structure:

```bash
# Example: Clone into your FFXI project
cd /path/to/your-ffxi-project
git clone https://github.com/Shuu-37/xi-ai.git
```

The `xi-ai` repository can live alongside your other project directories (server, tools, website, etc.).

### 2. Set up LandSandBoat Reference

From within the `xi-ai` directory, run the setup script:

```bash
cd xi-ai
./scripts/setup-reference.sh
```

This clones the [LandSandBoat repository](https://github.com/LandSandBoat/server) into `xi-ai/reference/` for AI agents to reference.

### 3. Using with AI Agents

All path references in the documentation use the pattern `xi-ai/path/to/file`, making them work regardless of where you cloned the repository. AI agents like Claude can reference files using these paths from anywhere in your project.

## Documentation

The `xi-ai/docs/` directory contains comprehensive AI-friendly documentation:

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
