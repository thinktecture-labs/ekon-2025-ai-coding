#!/bin/bash
#
# FreePascal Minesweeper Run Script
#
# Simple script to execute the compiled Minesweeper application
#

set -e  # Exit on any error

# Color output for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Configuration
EXECUTABLE_PATH="bin/minesweeper"

echo -e "${YELLOW}=== Running Minesweeper ===${NC}"
echo ""

# Check if executable exists
if [ ! -f "$EXECUTABLE_PATH" ]; then
    echo -e "${RED}ERROR: Executable not found at '$EXECUTABLE_PATH'${NC}"
    echo ""
    echo "Please build the application first:"
    echo "  ./build.sh"
    echo ""
    exit 1
fi

# Check if executable has execute permissions
if [ ! -x "$EXECUTABLE_PATH" ]; then
    echo -e "${YELLOW}Setting execute permissions...${NC}"
    chmod +x "$EXECUTABLE_PATH"
fi

# Execute the application
echo -e "${GREEN}Starting Minesweeper...${NC}"
echo ""

"./$EXECUTABLE_PATH"

# Capture exit code
EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}Application exited normally${NC}"
else
    echo -e "${RED}Application exited with code $EXIT_CODE${NC}"
fi

exit $EXIT_CODE
