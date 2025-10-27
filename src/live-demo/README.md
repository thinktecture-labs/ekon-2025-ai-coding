# Minesweeper - Native macOS Implementation

A complete native macOS Minesweeper game implementation using FreePascal Cocoa bindings.

## Architecture

This implementation uses a **hybrid architecture** to work around FreePascal Objective-C limitations:

### Game Logic Layer
- **`game_logic.pas`**: Regular Pascal class `TGameData` that handles all game state and logic
  - Supports dynamic arrays for the game grid
  - Implements mine placement, cell revealing, flood fill algorithm
  - Tracks game state (won/lost), elapsed time, and mine counts
  - Three difficulty modes: Beginner (9x9), Intermediate (16x16), Expert (30x16)

### UI Layer
- **`minesweeper.pas`**: Objective-C classes for native macOS UI
  - **`TMinesweeperView`**: Custom NSView subclass for direct drawing with NSBezierPath
  - **`TGameController`**: Main application controller (NSApplicationDelegate)

## Key Features

### Custom Drawing (Not NSButton)
The game board is rendered using a custom `NSView` subclass with direct drawing:
- Uses `NSBezierPath.fillRect()` for cell backgrounds
- Uses `NSBezierPath.strokeRect()` for cell borders
- Draws text using `NSString.drawInRect_withAttributes()` for numbers and symbols
- Creates sharp, rectangular cells without rounded corners

### Color Scheme
- **Unrevealed cells**: Light grey (`NSColor.lightGrayColor`)
- **Flagged cells**: Orange (`NSColor.orangeColor`)
- **Revealed empty**: Off-white (`NSColor.colorWithCalibratedWhite_alpha(0.92, 1.0)`)
- **Revealed mines**: Red (`NSColor.redColor`)
- **Cell borders**: Grid color (`NSColor.gridColor`)

### Number Colors (Adjacent Mine Counts)
- **1**: Green
- **2**: Dark green
- **3**: Yellow
- **4**: Orange
- **5+**: Red

### Mouse Interaction
- **Left click**: Reveal cell
- **Right click**: Toggle flag
- **Ctrl+Click**: Alternative way to toggle flag (for trackpad users)

### Menu System
Proper macOS menu bar with:
- **Application Menu**: Quit (Cmd+Q)
- **Game Menu**:
  - New Game (Cmd+N)
  - Beginner Mode (Cmd+1)
  - Intermediate Mode (Cmd+2)
  - Expert Mode (Cmd+3)

### Game Features
- Automatic flood reveal for cells with no adjacent mines
- First-click safety (mines are placed after first click, ensuring safe start)
- Timer showing elapsed time
- Mine counter display
- Win/loss detection with alert dialogs
- Window title updates to reflect game state

## Building and Running

### Prerequisites
- macOS (Apple Silicon or Intel)
- FreePascal Compiler (fpc) 3.2.2 or later
- Xcode command line tools (for the linker)

### Build Commands

```bash
# Clean build
./build.sh

# Run the game
./run.sh

# Build and run
./build-run.sh
```

### Build Process Details

The build script:
1. Cleans previous build artifacts
2. Compiles `game_logic.pas` as a unit
3. Compiles `minesweeper.pas` linking against Cocoa framework
4. Uses `-ld_classic` linker flag (required for FPC 3.2.2 compatibility)
5. Manually executes the `ppas.sh` linker script if generated

## Technical Implementation Details

### Hybrid Architecture Pattern

**Why this approach?**
- FPC's `objcclass` with `{$modeswitch objectivec1}` has limitations:
  - All methods MUST have `message` directives
  - Dynamic arrays are not supported in objcclass fields
  - Limited to Objective-C compatible types

**Solution:**
- Separate game logic into regular Pascal class (`TGameData`)
- Keep Objective-C classes minimal, only for UI integration
- Store reference to Pascal object in Objective-C controller

### Custom NSView Rendering

**Drawing cycle:**
1. Override `drawRect:` message to render cells
2. Calculate cell positions based on view bounds and grid size
3. Use NSBezierPath for efficient rectangle drawing
4. Draw text centered in cells using NSMutableDictionary for attributes

**Mouse handling:**
1. Override `mouseDown:` and `rightMouseDown:` messages
2. Convert window coordinates to view coordinates
3. Calculate cell coordinates from pixel position
4. Check for Ctrl modifier to treat left-click as right-click
5. Call controller callback to update game state
6. Trigger redraw with `setNeedsDisplayInRect()`

### Menu Bar Integration

**Critical setup for menu bar to appear:**
1. Call `NSApp.setActivationPolicy(NSApplicationActivationPolicyRegular)` before `NSApp.run`
2. Store `FMainMenu` reference to prevent autorelease
3. Set menu item targets explicitly (NSApp for terminate, controller for game actions)
4. Assign keyboard shortcuts with `setKeyEquivalent` and `setKeyEquivalentModifierMask`

### Timer Updates

- Uses `NSTimer.scheduledTimerWithTimeInterval_target_selector_userInfo_repeats()`
- Updates every 1 second
- Calls `FGameData.GetElapsedTime` for current game time
- Stops when game ends (won or lost)

### Memory Management

- Proper cleanup in `dealloc` method
- Invalidates timer before deallocation
- Releases menu references
- Frees Pascal object instances

## File Structure

```
live-demo/
├── game_logic.pas         # Game logic (regular Pascal class)
├── minesweeper.pas        # Main application (Objective-C UI)
├── build.sh               # Build script
├── run.sh                 # Run script
├── build-run.sh           # Combined build and run
├── .gitignore             # Git ignore file
├── README.md              # This file
└── bin/                   # Build output (created by build.sh)
    ├── minesweeper        # Executable
    ├── *.o                # Object files
    └── *.ppu              # Compiled units
```

## Known Limitations

1. **FPC 3.2.2 Linker Compatibility**: Requires `-ld_classic` flag due to Objective-C metadata incompatibility with newer Apple linker
2. **No Dynamic Arrays in objcclass**: Game state must be stored in regular Pascal classes
3. **All objcclass methods require message directives**: Cannot use standard Pascal method declarations

## Future Enhancements

Potential improvements:
- Custom difficulty settings
- High score tracking
- Sound effects
- Preferences dialog
- Custom themes/skins
- Statistics tracking

## References

- [FreePascal Documentation](https://www.freepascal.org/docs.html)
- [Apple Cocoa Documentation](https://developer.apple.com/documentation/appkit)
- [FPC Objective-C Support](https://wiki.freepascal.org/Objective-C)
