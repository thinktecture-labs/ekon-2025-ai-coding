# Minesweeper macOS GUI

A native macOS Minesweeper game implementation using Free Pascal with Cocoa framework integration.

## Architecture Overview

This implementation follows a clean separation between game logic and GUI presentation:

### Components

1. **GameLogic.pas** (Pascal class)
   - `TGameData` - Pure Pascal game logic class
   - Handles all game state, mine placement, cell revealing, flood-fill algorithm
   - Completely GUI-independent
   - Can use dynamic arrays and standard Pascal features

2. **minesweeper.pas** (Cocoa GUI)
   - `TMinesweeperView` - Custom NSView subclass for rendering
   - `TGameController` - NSApplicationDelegate for menu handling
   - Direct integration with Cocoa APIs using objcclass

## Visual Design Implementation

### Cell Rendering (Direct Drawing with NSBezierPath)

The GUI uses custom drawing rather than NSButton controls to achieve sharp, rectangular cells:

- **Unrevealed cells**: Light grey (`NSColor.lightGrayColor`)
- **Flagged cells**: Orange (`NSColor.orangeColor`)
- **Revealed empty cells**: Off-white (`NSColor.colorWithCalibratedWhite_alpha(0.92, 1.0)`)
- **Mine hit cells**: Red (`NSColor.redColor`)
- **Cell borders**: Subtle grid color (`NSColor.gridColor`)

### Number Colors (Adjacent Mine Counts)

- **1 mine**: Green
- **2 mines**: Dark green
- **3 mines**: Yellow
- **4 mines**: Orange
- **5+ mines**: Red

All numbers are centered within cells using `NSString.drawInRect_withAttributes()` with centered paragraph style.

### Timer Display

A 30-pixel high timer bar at the top of the window shows elapsed seconds. The timer updates every second using `NSTimer`.

### Game Over Overlays

- **Lost**: Semi-transparent black overlay with "Sorry, you lost" message
- **Won**: Semi-transparent black overlay with "Congratulations, you won!" message
- Window title updates to reflect game state

## Menu System

### Application Menu
- **Quit Minesweeper** (⌘Q) - Calls `NSApp.terminate:`

### Game Menu
- **New Game** (⌘N) - Restarts current game mode
- **Beginner (9x9)** (⌘1) - Switch to beginner mode
- **Intermediate (16x16)** (⌘2) - Switch to intermediate mode
- **Expert (30x16)** (⌘3) - Switch to expert mode

## Interaction Model

### Mouse Controls

- **Left Click**: Reveal cell
- **Right Click**: Toggle flag on cell
- **Ctrl+Click**: Also toggles flag (for trackpad users)

### Event Handling

Mouse events are handled by overriding `mouseDown:` and `rightMouseDown:` in `TMinesweeperView`. The implementation:

1. Converts window coordinates to view coordinates using `convertPoint_fromView`
2. Calculates grid position (with Y-axis flip for Cocoa coordinate system)
3. Calls appropriate game logic method (`RevealCell` or `ToggleFlag`)
4. Triggers redraw with `setNeedsDisplayInRect`

## Game Modes

| Mode         | Grid Size | Mines      |
|--------------|-----------|------------|
| Beginner     | 9x9       | 8-12       |
| Intermediate | 16x16     | 30-50      |
| Expert       | 30x16     | 80-120     |

The game starts in Beginner mode. Switching modes:
- Resizes the window dynamically
- Starts a new game in the selected mode
- Updates window size constraints to prevent manual resizing

## Technical Implementation Details

### Objective-C Bridge Pattern

Due to FPC limitations with `objcclass`:

- All methods in `objcclass` require `message` directives
- No properties allowed in `objcclass` (use accessor methods)
- Dynamic arrays not supported in `objcclass` fields
- Regular Pascal classes used for game logic

### Coordinate System

Cocoa uses bottom-left origin, while game logic uses top-left:

```pascal
// When converting mouse clicks to grid coordinates:
col := Trunc(point.x / FCellSize);
row := FGameData.Rows - 1 - Trunc(point.y / FCellSize);  // Y-axis flip

// When drawing cells:
cellRect := NSMakeRect(
  col * FCellSize,
  (FGameData.Rows - 1 - row) * FCellSize,  // Y-axis flip
  FCellSize - 1,
  FCellSize - 1
);
```

### Memory Management

- `FMainMenu` stored as strong reference in controller to prevent premature deallocation
- Timer invalidated in `TMinesweeperView.dealloc`
- `TGameData` freed in view's dealloc method
- Proper use of `autorelease` for temporary Cocoa objects

### Build System

The project uses the classic linker (`-ld_classic`) to work around FPC 3.2.2 compatibility issues with newer Apple linkers:

```bash
fpc -MObjFPC -Sh -Si -O2 -B \
    -Paarch64 -Tdarwin \
    -k-framework -kCocoa \
    -k-ld_classic \
    ...
```

## Building and Running

### Prerequisites

- macOS with Apple Silicon (ARM64) or Intel
- Free Pascal Compiler (FPC) 3.2.2 or later
- Xcode Command Line Tools

### Build Commands

```bash
# Build only
./build.sh

# Run only (requires prior build)
./run.sh

# Build and run
./build-run.sh
```

### Build Output

- Executable: `bin/Minesweeper`
- Compile units: `bin/units/*.o`, `bin/units/*.ppu`
- Assembly files: `bin/units/*.s`

## File Structure

```
src/live-demo/minesweeper/
├── src/
│   ├── GameLogic.pas       # Game logic (TGameData class)
│   └── minesweeper.pas     # GUI implementation
├── tests/
│   └── TestGameLogic.pas   # Unit tests for game logic
├── bin/                    # Build output (gitignored)
├── build.sh               # Build script
├── run.sh                 # Run script
├── build-run.sh           # Build and run script
├── .gitignore            # Build artifacts exclusion
└── GUI_README.md         # This file
```

## Key Implementation Files

### `/Users/sebastian/dev/tt/conf/ekon-2025-ai-coding/src/live-demo/minesweeper/src/minesweeper.pas`

The main GUI program containing:
- `TMinesweeperView` - Custom NSView with drawing and mouse handling
- `TGameController` - Application delegate with menu handlers
- `BuildMenus()` - Menu system construction
- Main program block - Application initialization

### `/Users/sebastian/dev/tt/conf/ekon-2025-ai-coding/src/live-demo/minesweeper/src/GameLogic.pas`

Pure Pascal game logic:
- `TGameData` - Main game state and logic
- `TCell` - Cell state record
- `TGameMode`, `TGameState` - Enumerations
- Mine placement, flood-reveal, win condition checking

## Keyboard Shortcuts Reference

| Key Combination | Action                    |
|-----------------|---------------------------|
| ⌘Q              | Quit application          |
| ⌘N              | New game                  |
| ⌘1              | Beginner mode             |
| ⌘2              | Intermediate mode         |
| ⌘3              | Expert mode               |
| Ctrl+Click      | Flag cell (alternative)   |

## Testing

Unit tests for the game logic are available in `tests/TestGameLogic.pas`. The GUI can be manually tested by:

1. Playing through a complete game (win/loss)
2. Testing all mouse interactions (left click, right click, Ctrl+click)
3. Switching between game modes
4. Verifying menu items and keyboard shortcuts
5. Checking timer updates
6. Verifying window title changes

## Known Limitations

- Window is not resizable during gameplay (intentional design)
- Timer continues running after game ends (displays final time)
- No high score tracking or game statistics
- No sound effects or animations
- Classic linker deprecation warning (Apple deprecation notice)

## Future Enhancements

Potential improvements:
- Add game statistics (mines remaining, games played, win rate)
- Implement custom window with mine counter
- Add difficulty progression or custom game sizes
- Include sound effects for mine hits, wins, flags
- Add animations for cell reveals
- Implement auto-reveal on middle-click of satisfied numbers
- Save/load game state
- High score table with best times

## References

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [FPC Objective-C Integration](https://wiki.freepascal.org/Objective-C)
- [CocoaAll Unit Documentation](https://www.freepascal.org/docs-html/current/fcl/cocoa/)
