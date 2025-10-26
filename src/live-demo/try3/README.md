# Minesweeper for macOS

A native macOS Minesweeper game written in Free Pascal using Cocoa framework.

## Features

- Three difficulty levels:
  - **Beginner**: 9×9 grid with 8-12 mines
  - **Intermediate**: 16×16 grid with 30-50 mines
  - **Expert**: 30×16 grid with 99 mines
  
- Native macOS UI with menu bar integration
- Timer tracking game duration
- Color-coded mine proximity numbers:
  - 1 adjacent mine: green
  - 2 adjacent mines: dark green
  - 3 adjacent mines: yellow
  - 4 adjacent mines: orange
  - 5+ adjacent mines: red

- Right-click or Ctrl+click to flag suspected mines
- Automatic reveal of empty adjacent cells
- Win/loss detection with restart option

## Building

Run the build script to compile the application:

```bash
./build.sh
```

This will create the executable in the `bin/` directory.

## Running

After building, run the application:

```bash
./run.sh
```

Or build and run in one command:

```bash
./build-run.sh
```

## Controls

- **Left-click**: Reveal a cell
- **Right-click** or **Ctrl+Left-click**: Flag/unflag a cell as a mine
- **Cmd+Q**: Quit application
- **Cmd+N**: Start new game with current difficulty
- **Cmd+1/2/3**: Start beginner/intermediate/expert game

## Requirements

- macOS (tested on Apple Silicon)
- Free Pascal Compiler (fpc) 3.2.2 or later
- Xcode Command Line Tools (for the linker)

## Technical Details

The application uses:
- FreePascal's Objective-C bridge (`{$modeswitch objectivec1}`)
- Cocoa framework for native macOS UI
- Hybrid architecture with regular Pascal classes for game logic and objcclass for UI
- Classic linker (`-ld_classic`) for compatibility with FPC 3.2.2

Build artifacts are ignored via `.gitignore`.
