# Minesweeper - Quick Start Guide

## Build and Run

```bash
# Navigate to the directory
cd /Users/sebastian/dev/tt/conf/ekon-2025-ai-coding/src/live-demo

# Build and run in one command
./build-run.sh

# Or separately
./build.sh
./run.sh
```

## How to Play

### Mouse Controls
- **Left Click**: Reveal a cell
- **Right Click**: Toggle flag on a cell
- **Ctrl + Click**: Alternative way to toggle flag (useful for trackpads)

### Keyboard Shortcuts
- **⌘N**: New Game (restart current difficulty)
- **⌘1**: Start Beginner mode (9×9 grid)
- **⌘2**: Start Intermediate mode (16×16 grid)
- **⌘3**: Start Expert mode (30×16 grid)
- **⌘Q**: Quit application

### Game Modes
- **Beginner**: 9×9 grid with 8-12 mines
- **Intermediate**: 16×16 grid with 30-50 mines
- **Expert**: 30×16 grid with 70-99 mines

### Objective
Reveal all cells that don't contain mines without clicking on a mine.

### Symbols
- **Numbers (1-8)**: Show how many mines are adjacent to that cell
- **🚩 Flag**: Mark cells you think contain mines
- **💣 Bomb**: Revealed mine (game over)
- **Empty cells**: No adjacent mines

### Tips
- The first click is always safe (mines are placed after)
- Clicking an empty cell (no adjacent mines) automatically reveals surrounding cells
- Use flags to mark suspected mines
- The timer starts when you make your first click

## File Structure

```
live-demo/
├── minesweeper.pas        # Main application (643 lines)
├── game_logic.pas         # Game logic (450 lines)
├── build.sh               # Build script
├── run.sh                 # Run script
├── build-run.sh           # Combined build+run
├── README.md              # Full documentation
├── IMPLEMENTATION.md      # Technical details
├── QUICK_START.md         # This file
└── bin/
    └── minesweeper        # Executable (created by build.sh)
```

## Troubleshooting

### Build fails with "command not found: fpc"
You need to install FreePascal Compiler:
```bash
brew install fpc
```

### Build fails with linker errors
Make sure you have Xcode command line tools:
```bash
xcode-select --install
```

### Application doesn't show menu bar
This is handled automatically by calling `NSApp.setActivationPolicy(NSApplicationActivationPolicyRegular)`.
If you still don't see it, try clicking on the application icon in the Dock.

### Colors don't match specification
The implementation uses the exact colors from requirements.md:
- Unrevealed: `NSColor.lightGrayColor`
- Flagged: `NSColor.orangeColor`
- Revealed empty: `NSColor.colorWithCalibratedWhite_alpha(0.92, 1.0)`
- Mine: `NSColor.redColor`

## What's Implemented

✅ Native macOS UI using Cocoa bindings
✅ Custom NSView with direct drawing (NSBezierPath)
✅ Sharp rectangular cells (no rounded corners)
✅ All three difficulty modes
✅ Proper menu bar with keyboard shortcuts
✅ Mouse event handling (left/right/Ctrl+click)
✅ First-click safety (mines placed after first click)
✅ Flood fill algorithm for empty cells
✅ Timer display
✅ Mine counter display
✅ Win/loss detection with alerts
✅ Color-coded numbers (1=green, 2=dark green, 3=yellow, 4=orange, 5+=red)
✅ Window title updates on game state
✅ Clean separation of game logic and UI
✅ Proper memory management

## Architecture Highlights

### Hybrid Pattern
- **Regular Pascal class** (`TGameData`): Handles all game state and logic
- **Objective-C classes**: Handle only macOS UI integration
  - `TMinesweeperView`: Custom NSView for rendering
  - `TGameController`: Application controller

### Why Hybrid?
FreePascal's Objective-C support has limitations:
- All methods in objcclass must have `message` directives
- Dynamic arrays not supported in objcclass fields
- Solution: Keep game logic in regular Pascal class, UI in objcclass

### Custom Drawing
The game board is rendered using:
- `NSBezierPath.fillRect()` for cell backgrounds
- `NSBezierPath.strokeRect()` for cell borders
- `NSString.drawInRect_withAttributes()` for centered text
- No NSButton controls (as required)

## Next Steps

For more details, see:
- **README.md**: Complete user documentation
- **IMPLEMENTATION.md**: Technical implementation details
- **requirements.md**: Original requirements
- **infos.md**: Technical notes and solutions to common issues
