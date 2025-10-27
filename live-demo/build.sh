#!/bin/bash
#
# FreePascal Minesweeper Build Script for Apple Silicon macOS
#
# This script compiles a FreePascal Objective-C application for Apple Silicon (ARM64)
# with proper Cocoa framework linking and compatibility workarounds for FPC 3.2.2
#

set -e  # Exit on any error

# Color output for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== FreePascal Minesweeper Build System ===${NC}"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Configuration
SOURCE_FILE="minesweeper.pas"
OUTPUT_NAME="minesweeper"
BIN_DIR="bin"
FPC_COMPILER="fpc"

# Verify source file exists
if [ ! -f "$SOURCE_FILE" ]; then
    echo -e "${RED}ERROR: Source file '$SOURCE_FILE' not found!${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 1: Cleaning previous build artifacts...${NC}"
rm -rf "$BIN_DIR"/*
echo -e "${GREEN}  ✓ Cleaned${NC}"

echo -e "${YELLOW}Step 2: Creating bin directory...${NC}"
mkdir -p "$BIN_DIR"
echo -e "${GREEN}  ✓ Created${NC}"

echo ""
echo -e "${YELLOW}Step 3: Compiling $SOURCE_FILE...${NC}"
echo "  Compiler: $FPC_COMPILER"
echo "  Target Architecture: ARM64 (Apple Silicon)"
echo "  Mode: Objective-C compatible"
echo "  Framework: Cocoa"
echo ""

# Compile with FPC
# Critical flags explained:
#   -MObjFPC: Use ObjectFPC mode with Objective-C extensions
#   -Sh: Use ansistrings
#   -Si: Support C++ style inline
#   -O2: Optimization level 2
#   -B: Rebuild all units
#   -Paarch64: Target Apple Silicon ARM64 architecture
#   -Tdarwin: Target Darwin (macOS) operating system
#   -k-framework -kCocoa: Link against Cocoa framework (required for macOS GUI)
#   -k-ld_classic: CRITICAL - Use classic linker for FPC 3.2.2 compatibility
#                  (FPC 3.2.2 has issues with Apple's new ld linker)
#   -FEbin: Output files to bin directory
#   -ominesweeper: Output executable name
#   -vewnhi: Verbose output (errors, warnings, notes, hints, info)

$FPC_COMPILER \
    -MObjFPC -Sh -Si \
    -O2 -B \
    -Paarch64 -Tdarwin \
    -k-framework -kCocoa \
    -k-ld_classic \
    -FE"$BIN_DIR" \
    -o"$OUTPUT_NAME" \
    -vewnhi \
    "$SOURCE_FILE"

COMPILE_EXIT_CODE=$?

if [ $COMPILE_EXIT_CODE -ne 0 ]; then
    echo ""
    echo -e "${RED}ERROR: Compilation failed with exit code $COMPILE_EXIT_CODE${NC}"
    exit $COMPILE_EXIT_CODE
fi

echo -e "${GREEN}  ✓ Compilation successful${NC}"

# Step 4: Check for and execute ppas.sh
# FPC sometimes generates a ppas.sh script for additional linking steps
# but doesn't always execute it automatically. We must ensure it runs.
echo ""
echo -e "${YELLOW}Step 4: Checking for ppas.sh linker script...${NC}"

if [ -f "$BIN_DIR/ppas.sh" ]; then
    echo -e "  Found ppas.sh - executing linker script..."
    cd "$BIN_DIR"
    sh ppas.sh
    PPAS_EXIT_CODE=$?
    cd "$SCRIPT_DIR"

    if [ $PPAS_EXIT_CODE -ne 0 ]; then
        echo -e "${RED}ERROR: ppas.sh execution failed with exit code $PPAS_EXIT_CODE${NC}"
        exit $PPAS_EXIT_CODE
    fi
    echo -e "${GREEN}  ✓ ppas.sh executed successfully${NC}"
else
    echo -e "  No ppas.sh found (linking completed during compilation)"
fi

# Step 5: Verify the executable exists
echo ""
echo -e "${YELLOW}Step 5: Verifying build output...${NC}"

EXECUTABLE_PATH="$BIN_DIR/$OUTPUT_NAME"

if [ ! -f "$EXECUTABLE_PATH" ]; then
    echo -e "${RED}ERROR: Executable '$EXECUTABLE_PATH' was not created!${NC}"
    exit 1
fi

# Check if executable has execute permissions
if [ ! -x "$EXECUTABLE_PATH" ]; then
    echo -e "${YELLOW}  Setting execute permissions...${NC}"
    chmod +x "$EXECUTABLE_PATH"
fi

# Get file info
FILE_SIZE=$(ls -lh "$EXECUTABLE_PATH" | awk '{print $5}')
FILE_ARCH=$(file "$EXECUTABLE_PATH")

echo -e "${GREEN}  ✓ Executable created successfully${NC}"
echo ""
echo "  Location: $EXECUTABLE_PATH"
echo "  Size: $FILE_SIZE"
echo "  Architecture: $FILE_ARCH"

echo ""
echo -e "${GREEN}=== Build completed successfully! ===${NC}"
echo ""
echo "To run the application:"
echo "  ./run.sh"
echo "  or directly: ./$EXECUTABLE_PATH"
echo ""
