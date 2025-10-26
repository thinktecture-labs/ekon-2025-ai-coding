#!/bin/bash

# Minesweeper macOS GUI Build Script
# This script compiles the Minesweeper GUI application using Free Pascal

set -e  # Exit on error

echo "==================================="
echo "Building Minesweeper macOS GUI"
echo "==================================="

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Define paths
SRC_DIR="src"
BIN_DIR="bin"
MAIN_FILE="$SRC_DIR/minesweeper.pas"
OUTPUT_NAME="Minesweeper"

# Clean previous build artifacts
echo "Cleaning previous build artifacts..."
rm -rf "$BIN_DIR"/*
mkdir -p "$BIN_DIR"
mkdir -p "$BIN_DIR/units"

# Check if main source file exists
if [ ! -f "$MAIN_FILE" ]; then
    echo "Error: Source file not found: $MAIN_FILE"
    exit 1
fi

# Compile the application
echo "Compiling $MAIN_FILE..."
fpc -MObjFPC -Sh -Si -O2 -B \
    -Paarch64 -Tdarwin \
    -Fu"$SRC_DIR" \
    -Fi"$SRC_DIR" \
    -FE"$BIN_DIR" \
    -FU"$BIN_DIR/units" \
    -o"$OUTPUT_NAME" \
    -k-framework -kCocoa \
    -k-ld_classic \
    "$MAIN_FILE"

# Check if FPC generated a linker script that needs manual execution
if [ -f "$BIN_DIR/ppas.sh" ]; then
    echo "Executing linker script..."
    cd "$BIN_DIR"
    sh ppas.sh
    cd "$SCRIPT_DIR"
fi

# Verify the executable was created
if [ ! -f "$BIN_DIR/$OUTPUT_NAME" ]; then
    echo "Error: Build failed - executable not found at $BIN_DIR/$OUTPUT_NAME"
    exit 1
fi

# Make executable
chmod +x "$BIN_DIR/$OUTPUT_NAME"

echo ""
echo "==================================="
echo "Build successful!"
echo "Executable: $BIN_DIR/$OUTPUT_NAME"
echo "==================================="
echo ""
echo "Run with: ./run.sh"
echo "Or: ./build-run.sh to build and run"
