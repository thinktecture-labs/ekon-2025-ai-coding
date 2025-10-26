#!/bin/bash

# Minesweeper macOS GUI Run Script
# This script launches the compiled Minesweeper application

set -e  # Exit on error

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Define paths
BIN_DIR="bin"
EXECUTABLE="$BIN_DIR/Minesweeper"

# Check if executable exists
if [ ! -f "$EXECUTABLE" ]; then
    echo "Error: Executable not found at $EXECUTABLE"
    echo "Please run ./build.sh first"
    exit 1
fi

# Run the application
echo "Launching Minesweeper..."
exec "$EXECUTABLE"
