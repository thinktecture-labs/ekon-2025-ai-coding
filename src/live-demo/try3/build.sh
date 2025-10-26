#!/bin/bash

# Clean build artifacts
rm -rf bin/*.o bin/*.ppu bin/*.rsj bin/ppas.sh bin/link*.res bin/minesweeper

# Create bin directory if it doesn't exist
mkdir -p bin

# Compile
fpc -Paarch64 -Cn -WM11.0 -k'-framework' -k'Cocoa' -k-ld_classic \
    -FEbin -ominesweeper minesweeper.pas

# FPC doesn't automatically run the linker script, so run it manually
if [ -f bin/ppas.sh ]; then
    sh bin/ppas.sh
fi

# Check if executable was created
if [ -f bin/minesweeper ]; then
    echo "Build successful: bin/minesweeper"
else
    echo "Build failed: executable not created"
    exit 1
fi
