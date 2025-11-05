#!/bin/bash

# setup-reference.sh
# Downloads the LandSandBoat codebase into the reference/ directory

set -e

REPO_URL="https://github.com/LandSandBoat/server.git"
REFERENCE_DIR="reference"

echo "Setting up LandSandBoat reference codebase..."

if [ -d "$REFERENCE_DIR/.git" ]; then
    echo "Reference directory exists. Pulling latest changes..."
    cd "$REFERENCE_DIR"
    git pull
    cd ..
    echo "✓ Reference codebase updated successfully!"
else
    if [ -d "$REFERENCE_DIR" ]; then
        echo "Warning: reference/ directory exists but is not a git repository."
        echo "Please remove it manually and run this script again."
        exit 1
    fi

    echo "Cloning LandSandBoat repository..."
    git clone "$REPO_URL" "$REFERENCE_DIR"
    echo "✓ Reference codebase cloned successfully!"
fi

echo ""
echo "LandSandBoat codebase is ready in the reference/ directory."
echo "This directory is gitignored and will not be committed to this repository."
