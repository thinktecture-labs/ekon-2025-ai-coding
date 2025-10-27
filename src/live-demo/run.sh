#!/bin/bash

# Run script for Minesweeper
# Executes the compiled binary from the bin directory

if [ ! -f bin/minesweeper ]; then
    echo "Error: bin/minesweeper not found"
    echo "Please run ./build.sh first"
    exit 1
fi

exec ./bin/minesweeper
