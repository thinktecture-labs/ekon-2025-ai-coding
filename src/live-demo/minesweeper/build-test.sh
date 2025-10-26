#!/bin/bash

# Build script for Minesweeper game logic tests
# This script compiles and runs the unit tests

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Building Minesweeper Game Logic Tests...${NC}"
echo ""

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Clean previous build artifacts
echo "Cleaning previous build artifacts..."
rm -rf bin/*.o bin/*.ppu bin/*.a bin/TestGameLogic
mkdir -p bin

# Compile the game logic unit
echo -e "${YELLOW}Compiling GameLogic.pas...${NC}"
fpc -MObjFPC -Sh -Si \
    -O2 \
    -FUbin \
    -FEbin \
    src/GameLogic.pas

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to compile GameLogic.pas${NC}"
    exit 1
fi

echo -e "${GREEN}GameLogic.pas compiled successfully${NC}"
echo ""

# Compile the test program
echo -e "${YELLOW}Compiling TestGameLogic.pas...${NC}"
fpc -MObjFPC -Sh -Si \
    -O2 \
    -Fisrc \
    -Fusrc \
    -FUbin \
    -FEbin \
    -oTestGameLogic \
    tests/TestGameLogic.pas

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to compile TestGameLogic.pas${NC}"
    exit 1
fi

echo -e "${GREEN}TestGameLogic.pas compiled successfully${NC}"
echo ""

# Run the tests
echo -e "${YELLOW}Running tests...${NC}"
echo ""

./bin/TestGameLogic

if [ $? -eq 0 ]; then
    echo -e "${GREEN}All tests passed successfully!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
