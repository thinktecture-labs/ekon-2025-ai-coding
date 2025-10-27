#!/bin/bash

# Build script for Minesweeper
# Clean rebuild every time to avoid linking old files

set -e  # Exit on error

echo "Building Minesweeper..."

# Clean previous build artifacts
echo "Cleaning old build artifacts..."
rm -rf bin/*.o bin/*.ppu bin/*.rsj bin/ppas.sh bin/link*.res bin/minesweeper

# Create bin directory if it doesn't exist
mkdir -p bin

# Compile game_logic.pas first (as a unit)
echo "Compiling game_logic.pas..."
fpc -Paarch64 -MObjFPC -Sh -Si -O2 -B \
    -Cn -WM11.0 \
    -FUbin \
    game_logic.pas

# Compile main program
echo "Compiling minesweeper.pas..."
fpc -Paarch64 -MObjFPC -Sh -Si -O2 -B \
    -Cn -WM11.0 \
    -k'-framework' -k'Cocoa' -k-ld_classic \
    -FUbin -FEbin \
    -ominesweeper \
    minesweeper.pas

# FPC doesn't automatically run the linker script with certain flag combinations
# Run it manually to ensure linking completes
if [ -f bin/ppas.sh ]; then
    echo "Running linker script..."
    sh bin/ppas.sh
fi

# Check if executable was created
if [ -f bin/minesweeper ]; then
    echo "Build successful: bin/minesweeper"
    echo "Run with: ./run.sh"
else
    echo "Build failed: executable not created"
    exit 1
fi
