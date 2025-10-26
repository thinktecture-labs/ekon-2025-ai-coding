#!/bin/bash

# Minesweeper macOS GUI Build and Run Script
# This script builds and then runs the Minesweeper application

set -e  # Exit on error

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Build the application
./build.sh

# Run the application
./run.sh
