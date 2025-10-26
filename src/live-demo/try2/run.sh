#!/bin/bash

# Launch the executable
if [ -f bin/minesweeper ]; then
    echo "Launching Minesweeper..."
    ./bin/minesweeper
else
    echo "Error: Executable not found. Please run build.sh first."
    exit 1
fi
