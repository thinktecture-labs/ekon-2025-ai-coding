## Minesweeper Implementation Guide

### Architecture Overview

Use a hybrid architecture to work around FPC Objective-C limitations:
- **Regular Pascal class** (e.g., `TGameData` or `TBoard`): Holds game state and logic. Can use dynamic arrays and normal Pascal methods.
- **Objective-C class** (e.g., `TGameController` or custom `NSView` subclass): Handles Cocoa UI integration. All methods require `message` directives.

Example structure:
```pascal
// Regular Pascal class - normal methods, dynamic arrays allowed
TBoard = class
  FGrid: array of array of TCell;
  procedure InitGame(rows, cols, mines: Integer);
  procedure Reveal(x, y: Integer);
end;

// Objective-C class - all methods need message directives
TGameController = objcclass(NSObject, NSApplicationDelegateProtocol)
  FBoard: TBoard;  // Reference to Pascal object
  procedure cellClicked(sender: id); message 'cellClicked:';
  procedure applicationDidFinishLaunching(notification: NSNotification); 
    message 'applicationDidFinishLaunching:';
end;
```

### Rendering Approach

**Use Custom NSView Subclass with Direct Drawing** (NOT NSButton):
- Subclass NSView (e.g., `TMinesweeperView = objcclass(NSView)`)
- Override `drawRect:` to render cells using NSBezierPath
- Override `mouseDown:` and `rightMouseDown:` for click handling
- Use `NSBezierPath.fillRect()` for cell backgrounds
- Use `NSBezierPath.strokeRect()` for cell borders
- Draw text using `NSString.drawInRect_withAttributes()`

This creates sharp, rectangular cells without rounded corners.

### Critical Cocoa Integration Notes

**Menu Bar Management**:
- Store menu references (FMainMenu) in the controller to prevent autorelease
- Call `NSApp.setActivationPolicy(NSApplicationActivationPolicyRegular)` before `NSApp.run`
- Set menu item targets explicitly: NSApp for `terminate:`, controller instance for custom actions
- Assign keyboard shortcuts with `setKeyEquivalent()` and `setKeyEquivalentModifierMask()`

**Mouse Event Handling**:
- Override both `mouseDown:` and `rightMouseDown:` in your NSView subclass
- For Ctrl+Click support: Check `event.modifierFlags and NSControlKeyMask <> 0` in mouseDown
- Convert mouse coordinates: `self.convertPoint_fromView(event.locationInWindow, nil)`
- Call `self.setNeedsDisplayInRect(self.bounds)` after state changes to trigger redraw

Rebuild with `./build.sh` whenever changing Cocoa lifecycle code to catch Objective-C bridge mistakes immediately.

## Critical Implementation Issues & Solutions

### 1. Objective-C Method Declarations in objcclass

**Issue**: In FPC's `objcclass` with `{$modeswitch objectivec1}`, ALL methods must have Objective-C selector names specified via the `message` directive. Even internal helper methods cannot use standard Pascal method declarations.

**Error encountered**:
```
Error: Objective-C messages require their Objective-C selector name to be specified using the "message" directive.
Error: Mismatch between number of declared parameters and number of colons in message string.
```

**Attempted solutions that failed**:
- Using `private:` / `public:` sections in objcclass (not supported)
- Declaring methods without message directives (compiler error)
- Using different parameter signatures to match colons

**Working solution**: Use a hybrid architecture:
- Create a regular Pascal class (`TGameData`) to hold game state and logic with dynamic arrays
- Keep the `objcclass` (`TGameController`) minimal, only for Cocoa UI integration
- All `objcclass` methods must have message directives like `message 'methodName:'`

```pascal
// Regular Pascal class - can use normal methods
TGameData = class
  FGrid: array of array of TCell;  // Dynamic arrays work here
  procedure InitGame(AMode: TGameMode);  // No message directive needed
end;

// Objective-C class - all methods need message directives
TGameController = objcclass(NSObject, NSApplicationDelegateProtocol)
  FGameData: TGameData;  // Reference to Pascal object
  procedure cellClicked(sender: id); message 'cellClicked:';
end;
```

### 2. Dynamic Arrays Not Supported in objcclass

**Issue**: Dynamic arrays (`array of array of T`) are not supported in `objcclass` fields because they don't have Objective-C runtime equivalents.

**Error encountered**:
```
Error: The type "TGameController.{Dynamic} Array Of {Dynamic} Array Of TCell" is not supported
       for interaction with the Objective-C and the blocks runtime.
```

**Attempted solutions that failed**:
- Using pointers to static arrays with large bounds `array[0..1000]` (complex index calculations required)
- Trying to cast or wrap arrays in records

**Working solution**: Store game state in a separate regular Pascal class instance:
```pascal
TGameController = objcclass(NSObject, NSApplicationDelegateProtocol)
  FGameData: TGameData;  // Regular Pascal class can use dynamic arrays
```

### 3. FPC 3.2.2 + macOS Linker Incompatibility

**Issue**: FPC 3.2.2 generates Objective-C metadata that is incompatible with the newer Apple `ld` linker (Xcode 15+). The linker fails with a "malformed method list atom" error.

**Error encountered**:
```
ld: malformed method list atom 'ltmp7' (/path/to/minesweeper.o),
    fixups found beyond the number of method entries
An error occurred while linking bin/minesweeper
```

**Root cause**: The modern Apple linker has stricter validation of Objective-C metadata structures. FPC 3.2.2's codegen creates method list atoms that don't pass this validation.

**Attempted solutions that failed**:
- Disabling optimizations (`-O-`)
- Changing macOS target version (`-WM11.0`, `-WM15.0`)
- Removing the symbol order file from linker command
- Using internal linker (`-s` flag - skips linking entirely)

**Working solution**: Use the deprecated classic linker with `-k-ld_classic`:

```bash
fpc -Paarch64 -Cn -WM11.0 -k'-framework' -k'Cocoa' -k-ld_classic \
    -FEbin -ominesweeper minesweeper.pas
```

**Important notes**:
- The `-ld_classic` flag invokes the older linker that doesn't have strict Objective-C validation
- Apple has deprecated `ld_classic` but it still works in current Xcode versions
- The compiler writes a `ppas.sh` script but doesn't execute it automatically - must run manually
- Long-term fix: Upgrade to FPC 3.2.3+ or FPC trunk which has better macOS linker support

### 4. FPC Linker Script Not Auto-Executing

**Issue**: With certain compiler flag combinations, FPC generates the `ppas.sh` linker script but doesn't execute it, leaving only object files without creating the final executable.

**Symptom**: Compilation succeeds, but `bin/minesweeper` executable doesn't exist, only `.o` files.

**Build script solution**:
```bash
# Compile
fpc -Paarch64 -Cn -WM11.0 -k'-framework' -k'Cocoa' -k-ld_classic \
    -FEbin -ominesweeper minesweeper.pas

# FPC doesn't automatically run the linker script, so run it manually
if [ -f bin/ppas.sh ]; then
    sh bin/ppas.sh
fi
```

This ensures the linking phase completes even when FPC doesn't auto-execute the script.

## Quick Reference: Build Process

### Compilation Command

```bash
fpc -MObjFPC -Sh -Si -O2 -B \
    -Paarch64 -Tdarwin \
    -k-framework -kCocoa \
    -k-ld_classic \
    -FE<output_dir> \
    <source_file.pas>
```

**Key Flags**:
- `-MObjFPC -Sh -Si`: Enable Objective-C mode and string/integer features
- `-O2`: Optimization level 2
- `-B`: Build all (clean rebuild)
- `-Paarch64 -Tdarwin`: Target Apple Silicon macOS
- `-k-framework -kCocoa`: Link against Cocoa framework
- `-k-ld_classic`: Use classic linker (required for FPC 3.2.2)
- `-FE<dir>`: Output directory for executable

### Build Script Structure

Your `build.sh` should:
1. Clean previous build artifacts (`rm -rf bin/*` or similar)
2. Create output directory (`mkdir -p bin`)
3. Run fpc with appropriate flags
4. Check for and execute `ppas.sh` linker script if generated:
   ```bash
   if [ -f bin/ppas.sh ]; then
       sh bin/ppas.sh
   fi
   ```
5. Verify the executable exists

### Run Script

Simple launcher (`run.sh`):
```bash
#!/bin/bash
exec ./bin/minesweeper
```

### Combined Script

`build-run.sh`:
```bash
#!/bin/bash
./build.sh && ./run.sh
```

### Build Process Flow

1. **Compile**: FPC generates assembly → assembles to `.o` files → writes `ppas.sh` linker script
2. **Link**: Execute `ppas.sh` which invokes `ld -ld_classic` with proper framework flags
3. **Verify**: Check that `bin/<executable>` exists and is executable

The two-stage process (compile then explicitly link) is necessary due to linker compatibility issues with FPC 3.2.2 and modern macOS toolchains.
