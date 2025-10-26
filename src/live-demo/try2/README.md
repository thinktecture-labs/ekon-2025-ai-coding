# Minesweeper for macOS

A native macOS Minesweeper game written in Free Pascal using Cocoa.

## Features

- Three difficulty levels:
  - **Beginner**: 9×9 grid with 8-12 mines
  - **Intermediate**: 16×16 grid with 30-50 mines
  - **Expert**: 30×16 grid with ~21% mine density

- Color-coded gameplay:
  - Grey: Unclicked cells
  - Orange: Flagged cells (right-click or Ctrl+click)
  - Light blue: Safe revealed cells
  - Red: Mines
  - Numbers colored by adjacent mine count (green → dark green → yellow → orange → red)

- Timer tracking gameplay duration
- First-click safety (mines placed after first click)
- Automatic reveal of adjacent empty cells
- Win/loss detection with dialog prompts
- macOS menu bar with keyboard shortcuts

## Building

```bash
./build.sh
```

**Note**: The build uses `-ld_classic` flag due to compatibility issues between FPC 3.2.2 and newer macOS linkers. The script automatically runs the linker after compilation.

## Running

```bash
./run.sh
```

Or build and run in one command:

```bash
./build-run.sh
```

## Controls

- **Left Click**: Reveal cell
- **Right Click** or **Ctrl+Left Click**: Flag/unflag cell
- **Cmd+N**: New game
- **Cmd+1/2/3**: Switch difficulty level
- **Cmd+Q**: Quit application

## Requirements

- Free Pascal Compiler (FPC) 3.2.2 or later
- macOS 11.0 or later
- Xcode Command Line Tools

## Technical Notes

- Uses hybrid architecture: regular Pascal class (TGameData) for game state to avoid objcclass limitations with dynamic arrays
- Implements NSApplicationDelegate protocol for proper Cocoa integration
- Manual menu retention prevents menu bar disappearance (as noted in infos.md)
- Proper activation policy ensures correct menu behavior
