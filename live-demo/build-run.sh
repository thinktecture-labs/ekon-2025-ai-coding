#!/bin/bash
#
# FreePascal Minesweeper Build & Run Script
#
# Combined script that builds and then immediately runs the application
# if the build is successful.
#

set -e  # Exit on any error

# Color output for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  FreePascal Minesweeper - Build & Run                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Step 1: Build
echo -e "${YELLOW}Phase 1: Building application...${NC}"
echo ""

./build.sh

BUILD_EXIT_CODE=$?

if [ $BUILD_EXIT_CODE -ne 0 ]; then
    echo ""
    echo -e "${RED}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  Build failed! Not running application.               ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════╝${NC}"
    exit $BUILD_EXIT_CODE
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Build successful! Starting application...            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Brief pause for readability
sleep 1

# Step 2: Run
echo -e "${YELLOW}Phase 2: Running application...${NC}"
echo ""

./run.sh

RUN_EXIT_CODE=$?

echo ""
if [ $RUN_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Completed successfully!                              ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
else
    echo -e "${RED}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  Application exited with error code $RUN_EXIT_CODE                ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════╝${NC}"
fi

exit $RUN_EXIT_CODE
