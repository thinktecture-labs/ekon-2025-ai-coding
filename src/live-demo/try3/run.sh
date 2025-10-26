#!/bin/bash

if [ ! -f bin/minesweeper ]; then
    echo "Error: bin/minesweeper not found. Run ./build.sh first."
    exit 1
fi

./bin/minesweeper
