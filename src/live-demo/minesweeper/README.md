# Minesweeper Game Logic

A complete, GUI-independent Minesweeper game engine implementation in FreePascal.

## Overview

This implementation provides a fully functional Minesweeper game logic engine that is completely independent of any GUI framework. It can be used with any UI layer (macOS Cocoa, Windows, GTK, console, etc.) or for testing and simulation.

## Features

- **Complete Game Logic**: Full implementation of classic Minesweeper rules
- **Multiple Difficulty Levels**: Beginner, Intermediate, and Expert modes with configurable mine counts
- **First-Click Safety**: First click is always safe - no mine under the first click or its 8 neighbors
- **Flood Reveal**: Automatic revealing of connected empty cells
- **Flag Support**: Mark suspected mine locations
- **Win/Loss Detection**: Automatic game state management
- **Timer Support**: Track game duration in seconds
- **Error Handling**: Robust validation and error messages
- **Comprehensive Tests**: 21 unit tests covering all functionality

## Architecture

### Key Design Principles

1. **GUI Independence**: The game logic is a pure Pascal class with no dependencies on UI frameworks
2. **Encapsulation**: All game state is self-contained within the `TGameData` class
3. **Immutability**: Cell data is accessed through read-only properties
4. **Testability**: Complete test coverage with extensive edge case testing

### File Structure

```
minesweeper/
├── src/
│   └── GameLogic.pas      # Core game engine
├── tests/
│   └── TestGameLogic.pas  # Comprehensive unit tests
├── bin/                   # Build output directory
├── build-test.sh          # Build and test script
└── README.md             # This file
```

## API Reference

### Types

#### `TGameMode`
Enumeration of game difficulty levels:
- `gmBeginner`: 9x9 grid with 8-12 mines
- `gmIntermediate`: 16x16 grid with 30-50 mines
- `gmExpert`: 16x30 grid with 80-120 mines

#### `TGameState`
Current state of the game:
- `gsNotStarted`: Game initialized but no moves made
- `gsPlaying`: Game in progress
- `gsWon`: All non-mine cells revealed
- `gsLost`: Mine was revealed

#### `TCell`
Represents a single cell in the grid:
```pascal
TCell = record
  HasMine: Boolean;       // True if this cell contains a mine
  IsRevealed: Boolean;    // True if this cell has been revealed
  IsFlagged: Boolean;     // True if this cell has been flagged by player
  AdjacentMines: Integer; // Number of mines in adjacent cells (0-8)
end;
```

### TGameData Class

#### Constructor & Destructor

```pascal
constructor Create;
destructor Destroy; override;
```

#### Initialization Methods

```pascal
// Initialize with predefined game mode
procedure InitGame(AMode: TGameMode); overload;

// Initialize with custom dimensions and mine count
procedure InitGame(ARows, ACols, AMines: Integer); overload;

// Reset game to initial state (keeps dimensions)
procedure Reset;
```

#### Game Play Methods

```pascal
// Reveal a cell at the specified position
// Returns True if a mine was hit, False otherwise
function RevealCell(ARow, ACol: Integer): Boolean;

// Toggle the flag state of a cell
procedure ToggleFlag(ARow, ACol: Integer);
```

#### Utility Methods

```pascal
// Get configuration for a specific game mode
class function GetModeConfig(AMode: TGameMode): TModeConfig;
```

#### Properties

```pascal
property Rows: Integer read FRows;                      // Board height
property Cols: Integer read FCols;                      // Board width
property MineCount: Integer read FMineCount;            // Total number of mines
property GameState: TGameState read FGameState;         // Current game state
property ElapsedSeconds: Integer read GetElapsedSeconds; // Time since first move
property Cell[ARow, ACol: Integer]: TCell read GetCell; // Access to cell data
property RevealedCount: Integer read FRevealedCount;    // Number of revealed cells
```

## Usage Examples

### Basic Usage

```pascal
uses GameLogic;

var
  Game: TGameData;
  HitMine: Boolean;
begin
  // Create and initialize game
  Game := TGameData.Create;
  try
    Game.InitGame(gmBeginner);

    // Make first move
    HitMine := Game.RevealCell(4, 4);

    if HitMine then
      WriteLn('Game Over!')
    else if Game.GameState = gsWon then
      WriteLn('You Won!')
    else
      WriteLn('Continue playing...');

    // Flag a suspected mine
    Game.ToggleFlag(2, 3);

    // Check game state
    WriteLn('Time elapsed: ', Game.ElapsedSeconds, ' seconds');
  finally
    Game.Free;
  end;
end;
```

### Custom Game Configuration

```pascal
var
  Game: TGameData;
begin
  Game := TGameData.Create;
  try
    // Create custom 20x20 board with 50 mines
    Game.InitGame(20, 20, 50);

    // Play game...
  finally
    Game.Free;
  end;
end;
```

### Accessing Cell Information

```pascal
var
  Game: TGameData;
  Cell: TCell;
  R, C: Integer;
begin
  Game := TGameData.Create;
  try
    Game.InitGame(gmBeginner);
    Game.RevealCell(0, 0);

    // Iterate through all cells
    for R := 0 to Game.Rows - 1 do
      for C := 0 to Game.Cols - 1 do
      begin
        Cell := Game.Cell[R, C];

        if Cell.IsRevealed then
        begin
          if Cell.HasMine then
            WriteLn('Mine at (', R, ',', C, ')')
          else if Cell.AdjacentMines > 0 then
            WriteLn('Number ', Cell.AdjacentMines, ' at (', R, ',', C, ')');
        end
        else if Cell.IsFlagged then
          WriteLn('Flag at (', R, ',', C, ')');
      end;
  finally
    Game.Free;
  end;
end;
```

## Game Rules Implementation

### First-Click Safety

When `RevealCell` is called for the first time:
1. Mines are placed randomly on the board
2. The clicked cell and its 8 neighbors are guaranteed to be mine-free
3. This ensures the first click is always safe

### Flood Reveal

When a cell with 0 adjacent mines is revealed:
1. All 8 neighboring cells are automatically revealed
2. If any of those cells also have 0 adjacent mines, the process continues recursively
3. The flood stops at cells that have adjacent mines (showing numbers)

### Win Condition

The game is won when:
- All non-mine cells have been revealed
- The number of revealed cells equals (total cells - mine count)

### Loss Condition

The game is lost when:
- A cell containing a mine is revealed

## Testing

### Running Tests

```bash
./build-test.sh
```

This script will:
1. Clean previous build artifacts
2. Compile the GameLogic unit
3. Compile the test program
4. Run all 21 unit tests
5. Report results

### Test Coverage

The test suite covers:

**Initialization Tests:**
- Game creation and initialization
- All three difficulty modes
- Custom game configurations
- Invalid input validation

**Mine Placement Tests:**
- Correct mine count
- First-click exclusion
- Neighbor exclusion
- Adjacent mine calculation

**Game Play Tests:**
- Safe cell revealing
- Mine revealing
- Flood reveal behavior
- Flag toggling
- Already-revealed cells
- Invalid cell access

**Game State Tests:**
- Win condition detection
- Loss condition detection
- State transitions
- Post-game behavior

**Utility Tests:**
- Timer functionality
- Reset functionality
- Sequential games

### Test Results

```
==========================================
Test Results:
  Total Tests: 21
  Passed:      21
  Failed:      0
==========================================

SUCCESS: All tests passed!
```

## Building

### Prerequisites

- FreePascal Compiler (FPC) 3.2.2 or later
- macOS (for the build script, though the logic is platform-independent)

### Compilation Flags

The build script uses:
```bash
fpc -MObjFPC -Sh -Si -O2 -FUbin -FEbin src/GameLogic.pas
```

- `-MObjFPC`: Object Pascal mode
- `-Sh`: Use ansistrings
- `-Si`: Support for inline
- `-O2`: Optimization level 2
- `-FUbin`: Unit output directory
- `-FEbin`: Executable output directory

## Integration with GUI

To integrate with a GUI framework:

```pascal
type
  TGameController = objcclass(NSObject)  // or any GUI class
  private
    FGameData: TGameData;  // The game engine
  public
    procedure HandleCellClick(Row, Col: Integer); message 'handleCellClick:';
    procedure HandleCellRightClick(Row, Col: Integer); message 'handleCellRightClick:';
  end;

procedure TGameController.HandleCellClick(Row, Col: Integer);
var
  HitMine: Boolean;
begin
  if FGameData.GameState <> gsPlaying then
    Exit;

  HitMine := FGameData.RevealCell(Row, Col);

  // Update GUI based on game state
  RefreshDisplay;

  if HitMine then
    ShowGameOverDialog
  else if FGameData.GameState = gsWon then
    ShowWinDialog;
end;

procedure TGameController.HandleCellRightClick(Row, Col: Integer);
begin
  if FGameData.GameState <> gsPlaying then
    Exit;

  FGameData.ToggleFlag(Row, Col);
  RefreshDisplay;
end;
```

## Performance Characteristics

- **Memory**: O(rows * cols) - stores only essential cell data
- **Mine Placement**: O(mines) - uses rejection sampling
- **Adjacent Mine Calculation**: O(rows * cols) - one pass after placement
- **Flood Reveal**: O(rows * cols) worst case - bounded by board size
- **Cell Access**: O(1) - direct array access

## Error Handling

The implementation includes robust error handling:

- **Invalid Dimensions**: Raises exception for non-positive dimensions
- **Invalid Mine Count**: Raises exception for negative or excessive mine count
- **Out of Bounds Access**: Raises exception for invalid cell coordinates
- **Graceful Degradation**: Invalid operations (e.g., revealing out-of-bounds) return false/do nothing

## Constants

Game mode configurations:

```pascal
const
  BEGINNER_ROWS = 9;
  BEGINNER_COLS = 9;
  BEGINNER_MIN_MINES = 8;
  BEGINNER_MAX_MINES = 12;

  INTERMEDIATE_ROWS = 16;
  INTERMEDIATE_COLS = 16;
  INTERMEDIATE_MIN_MINES = 30;
  INTERMEDIATE_MAX_MINES = 50;

  EXPERT_ROWS = 16;
  EXPERT_COLS = 30;
  EXPERT_MIN_MINES = 80;
  EXPERT_MAX_MINES = 120;
```

## License

This implementation is provided as-is for educational and development purposes.

## Author

Generated by Claude Code - An AI-powered FreePascal game logic implementation.

## Version History

**Version 1.0.0** (Current)
- Initial implementation
- Complete Minesweeper logic
- Comprehensive test coverage
- Full documentation
