#!/bin/bash

# Clean up previous build artifacts
echo "Cleaning previous build artifacts..."
rm -rf bin/*
rm -f *.o
rm -f *.ppu
rm -f link.res
rm -f ppas.sh

# Create bin directory if it doesn't exist
mkdir -p bin

# Build the application
echo "Building Minesweeper..."
fpc -Paarch64 -Cn -WM11.0 -k'-framework' -k'Cocoa' -k-ld_classic \
    -FEbin \
    -ominesweeper \
    minesweeper.pas

# FPC doesn't automatically run the linker script, so we need to run it manually
if [ -f bin/ppas.sh ]; then
    sh bin/ppas.sh
fi

if [ -f bin/minesweeper ]; then
    echo "Build successful! Executable is in bin/minesweeper"
else
    echo "Build failed!"
    exit 1
fi
