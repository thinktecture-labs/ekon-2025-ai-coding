# Minesweeper GUI - Quick Reference

## Build and Run

```bash
cd /Users/sebastian/dev/tt/conf/ekon-2025-ai-coding/src/live-demo/minesweeper

# Build, run, or both
./build.sh          # Compile only
./run.sh            # Run only (must build first)
./build-run.sh      # Build and run
```

## Main Files

| File | Lines | Purpose |
|------|-------|---------|
| `src/minesweeper.pas` | 565 | Complete GUI implementation |
| `src/GameLogic.pas` | 458 | Game logic (pre-existing) |

## Key Classes

### TMinesweeperView (objcclass NSView)
- Custom drawing with NSBezierPath
- Mouse event handling (left/right/ctrl+click)
- Timer callback for elapsed time display
- 565 total lines including TGameController

### TGameController (objcclass NSObject)
- Application delegate
- Menu action handlers
- Window management and resizing
- Title updates

### TGameData (regular Pascal class)
- Game state and logic
- Mine placement and reveal
- Flood-fill algorithm
- Win/loss detection

## Visual Design

### Cell Colors
```pascal
Unrevealed:     NSColor.lightGrayColor
Flagged:        NSColor.orangeColor
Revealed empty: NSColor.colorWithCalibratedWhite_alpha(0.92, 1.0)
Mine hit:       NSColor.redColor
Borders:        NSColor.gridColor
```

### Number Colors
```pascal
1: green          (0.0, 0.6, 0.0)
2: dark green     (0.0, 0.4, 0.0)
3: yellow         (0.8, 0.8, 0.0)
4: orange         NSColor.orangeColor
5+: red           NSColor.redColor
```

### Layout
- Cell size: 32x32 pixels
- Timer bar: 30 pixels at top
- Window size adjusts per game mode

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| ⌘Q | Quit |
| ⌘N | New Game |
| ⌘1 | Beginner (9x9) |
| ⌘2 | Intermediate (16x16) |
| ⌘3 | Expert (30x16) |
| Ctrl+Click | Flag cell |

## Mouse Controls

- **Left Click**: Reveal cell
- **Right Click**: Toggle flag
- **Ctrl+Left Click**: Toggle flag (trackpad friendly)

## Game Modes

| Mode | Size | Mines | Window Size |
|------|------|-------|-------------|
| Beginner | 9×9 | 8-12 | 288×318 px |
| Intermediate | 16×16 | 30-50 | 512×542 px |
| Expert | 30×16 | 80-120 | 960×542 px |

## Architecture Pattern

```
┌─────────────────────────────────────┐
│  minesweeper.pas (Cocoa GUI)        │
│  ┌─────────────────────────────┐    │
│  │  TMinesweeperView           │    │
│  │  - drawRect: (rendering)    │    │
│  │  - mouseDown: (input)       │    │
│  │  - rightMouseDown:          │    │
│  └──────────┬──────────────────┘    │
│             │ owns                   │
│             ▼                        │
│  ┌─────────────────────────────┐    │
│  │  TGameController            │    │
│  │  - menu handlers            │    │
│  │  - window management        │    │
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
                │
                │ owns & calls
                ▼
┌─────────────────────────────────────┐
│  GameLogic.pas (Pure Pascal)        │
│  ┌─────────────────────────────┐    │
│  │  TGameData                  │    │
│  │  - game state               │    │
│  │  - mine placement           │    │
│  │  - reveal & flag logic      │    │
│  │  - win/loss detection       │    │
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
```

## Key Methods

### TMinesweeperView
```pascal
initWithFrame_controller()  // Initialize with game data
drawRect()                  // Custom cell rendering
mouseDown()                 // Handle clicks and Ctrl+click
rightMouseDown()            // Handle right-click flags
startNewGame()              // Reset for new mode
updateTimerDisplay()        // Timer callback
```

### TGameController
```pascal
applicationDidFinishLaunching()  // Setup window and view
newGame()                        // Restart current mode
beginnerMode()                   // Switch to 9x9
intermediateMode()               // Switch to 16x16
expertMode()                     // Switch to 30x16
updateWindowTitle()              // Update based on state
resizeWindowForMode()            // Adjust window size
```

### TGameData (from GameLogic.pas)
```pascal
InitGame(mode)              // Initialize grid and mines
RevealCell(row, col)        // Reveal cell, returns true if mine
ToggleFlag(row, col)        // Toggle flag state
PlaceMines(excludeRow, excludeCol)  // Place mines avoiding first click
```

## Drawing Flow

1. `drawRect:` called by system
2. Draw timer bar at top (30px)
3. Loop through grid rows/cols
4. For each cell:
   - Determine color based on state
   - Draw filled rectangle
   - Draw border
   - Draw number if revealed and has adjacent mines
5. If game over, draw overlay and message

## Coordinate Conversion

Cocoa uses bottom-left origin, game logic uses top-left:

```pascal
// Mouse click → Grid position
col := Trunc(point.x / FCellSize);
row := FGameData.Rows - 1 - Trunc(point.y / FCellSize);  // Flip Y

// Grid position → Drawing rectangle
cellRect := NSMakeRect(
  col * FCellSize,
  (FGameData.Rows - 1 - row) * FCellSize,  // Flip Y
  FCellSize - 1,
  FCellSize - 1
);
```

## Build Flags

```bash
fpc -MObjFPC -Sh -Si -O2 -B \
    -Paarch64 -Tdarwin \
    -Fu"src" -Fi"src" \
    -FE"bin" -FU"bin/units" \
    -k-framework -kCocoa \
    -k-ld_classic \
    src/minesweeper.pas
```

### Flag Meanings
- `-MObjFPC`: Object Pascal mode with Objective-C
- `-Sh -Si`: String and integer extensions
- `-O2`: Optimization level 2
- `-B`: Build all (clean rebuild)
- `-Paarch64 -Tdarwin`: Target Apple Silicon macOS
- `-Fu -Fi`: Unit and include paths
- `-FE -FU`: Executable and unit output directories
- `-k-framework -kCocoa`: Link Cocoa framework
- `-k-ld_classic`: Use classic linker (FPC 3.2.2 compatibility)

## Memory Management

- **Timer**: Invalidated in `TMinesweeperView.dealloc`
- **TGameData**: Freed in view's dealloc
- **FMainMenu**: Strong reference prevents autorelease
- **Temporary objects**: Use `.autorelease` for Cocoa allocations

## Testing Procedure

1. ✅ Build succeeds without errors
2. ✅ Application launches and shows window
3. ✅ Menu bar visible at top of screen
4. ✅ Beginner mode (9×9) shows on launch
5. ✅ Timer updates every second
6. ✅ Left click reveals cells
7. ✅ Right click flags cells
8. ✅ Ctrl+click flags cells
9. ✅ Numbers show correct colors
10. ✅ Clicking mine shows overlay
11. ✅ Winning shows congratulations
12. ✅ All keyboard shortcuts work
13. ✅ Mode switching resizes window
14. ✅ Window title updates correctly

## Common Issues

### Build fails with "malformed method list"
- Solution: Use `-k-ld_classic` flag (already in build.sh)

### Properties don't work in objcclass
- Solution: Use accessor methods with message directive

### Dynamic arrays not supported
- Solution: Use regular Pascal class for data structures

### Menu disappears
- Solution: Store strong reference (FMainMenu field)

## Documentation Files

- **GUI_README.md**: Comprehensive architecture and implementation guide
- **IMPLEMENTATION_NOTES.md**: Feature checklist and compliance matrices
- **QUICK_REFERENCE.md**: This file - quick lookup
- **README.md**: Project overview
- **requirements.md**: Original requirements
- **infos.md**: Technical guidelines

## File Paths (Full)

```
Main GUI:
/Users/sebastian/dev/tt/conf/ekon-2025-ai-coding/src/live-demo/minesweeper/src/minesweeper.pas

Game Logic:
/Users/sebastian/dev/tt/conf/ekon-2025-ai-coding/src/live-demo/minesweeper/src/GameLogic.pas

Build Scripts:
/Users/sebastian/dev/tt/conf/ekon-2025-ai-coding/src/live-demo/minesweeper/build.sh
/Users/sebastian/dev/tt/conf/ekon-2025-ai-coding/src/live-demo/minesweeper/run.sh
/Users/sebastian/dev/tt/conf/ekon-2025-ai-coding/src/live-demo/minesweeper/build-run.sh

Executable:
/Users/sebastian/dev/tt/conf/ekon-2025-ai-coding/src/live-demo/minesweeper/bin/Minesweeper
```

## Version Info

- **FPC Version**: 3.2.2
- **Platform**: macOS ARM64 (Apple Silicon)
- **Target OS**: Darwin (macOS)
- **Framework**: Cocoa
- **Objective-C Mode**: objectivec2
- **Total Lines**: 565 (GUI) + 458 (logic) = 1,023 lines

## Quick Debug

```bash
# Check if executable exists
ls -lh bin/Minesweeper

# Check build artifacts
ls -la bin/units/

# Run directly
./bin/Minesweeper

# Clean and rebuild
rm -rf bin/* && ./build.sh
```
