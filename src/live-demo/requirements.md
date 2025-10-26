# Minesweeper

We build a Minesweeper game.
It's a native MacOS application using native MacOS UI elements.
We write it in freepascal / fpc. fpc compiler is already installed.

Make sure to have the specific sub-agents for the build system, the game logic and the game UI work on their specific parts.

## Game

The UI is a minesweeper playing field.

### Visual Design (Critical)

**Cell Rendering**: Cells MUST be rendered using direct drawing (NSBezierPath fillRect/strokeRect), NOT NSButton controls. This creates sharp, rectangular cells without rounded corners. Do not use NSRoundedBezelStyle or any button bezel styles.

**Cell Colors**:
- Unclicked/unrevealed rectangles: light grey (NSColor.lightGrayColor)
- Right-clicked/flagged (marked as "here's probably a mine"): orange (NSColor.orangeColor)
- Clicked and free spaces (revealed empty): very light grey/off-white (e.g. NSColor.colorWithCalibratedWhite_alpha(0.92, 1.0))
- When we click a mine: red (NSColor.redColor)
- Cell borders: Use a subtle grid color (NSColor.gridColor) with strokeRect

**Number Colors** (for adjacent mine counts on revealed cells):
- 1 adjacent mine: green (readable on white background)
- 2 adjacent mines: dark green
- 3 adjacent mines: yellow (readable on white background)
- 4 adjacent mines: orange
- 5 or more adjacent mines: red

**Text Rendering**: All text (numbers on cells) must be centered within the cell rectangles. Calculate the center position properly for the cell size.

**Layout**: There is a time counter displayed at the top of the playing field.

### Game Interactions

Right-click can also be done by pressing CTRL/Control during click (detect via NSControlKeyMask modifier flag), as a touchpad might be inaccurate when left-clicking a mine you want to mark.

**Game Over States**:
- When a mine is hit: The game becomes read-only. Display a semi-transparent overlay with "Sorry, you lost" or "Game Over" message. Update the window title to reflect the game state.
- When all mines are correctly marked: Show "Congratulations, you won" or "You Win!" message with a button to start a new game. Update the window title to reflect the win state.

### Menu System

The application must have a macOS-style main menu bar at the top of the screen (using NSMenu and NSMenuItem).

**Menu Structure**:
- Application menu: Quit option (Cmd+Q keyboard shortcut, calls NSApp.terminate)
- Game menu: 
  - New Game / Restart option
  - Game mode selection: Beginner, Intermediate, Expert

The menu bar must remain active and populated. To ensure this:
- Store menu references (FMainMenu) in the controller to prevent autorelease
- Call `NSApp.setActivationPolicy(NSApplicationActivationPolicyRegular)` before entering the run loop
- Set targets explicitly for menu items (NSApp for terminate, controller for game actions)
- Assign keyboard shortcuts using setKeyEquivalent and setKeyEquivalentModifierMask

### Game Modes

We offer the following game sizes:
Beginner: 9x9 with about 10 mines (randomize from 8 to 12)
Intermediate: 16x16 with about 40 mines (randomize from 30 to 50)
Expert: 30x16 with a higher mine density
We always start a new instance with beginner, and the game modes are available for selection in the main menu.


## Infrastructure

Don't use external depencencies / libraries / packages. We only use freepascal, and the mac we're running on.
Create a gitignore that ignores our build artefacts.


## Building and running

Create a script that builds the project. 
This script should do a clean rebuild every time, cleaning up all previous build artifacts so that we never try to use/link old files.

Create another script that launches the executable from its bin folder.
Create another script that builds using the build script and launches via the launch script.

They should be called ./build.sh ./run.sh ./build-run.sh

Make sure to read infos.md also, for technical infos that are important.
