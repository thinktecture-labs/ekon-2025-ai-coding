# Repository Guidelines

This Pascal Minesweeper targets macOS (Apple Silicon) using native Cocoa APIs with Free Pascal only—no third‑party libraries beyond OS frameworks.

## Project Structure & Module Organization
- `src/core/`: Game logic (e.g., `uBoard.pas`, `uGame.pas`).
- `src/macOS/`: Cocoa UI and app entry (e.g., `Main.pas`).
- `tests/`: fpcunit tests mirroring `src/core/`.
- `assets/`: Images/sounds used by the app bundle.
- `build/Minesweeper.app/`: Generated app bundle (`Contents/MacOS`, `Contents/Resources`).

## Build, Test, and Development Commands
- Build (Apple Silicon, Cocoa):
  - `mkdir -p build/Minesweeper.app/Contents/{MacOS,Resources}`
  - `fpc -MObjFPC -Sh -Si -O2 -B -Fusrc -Fusrc/core -Fusrc/macOS -Tdarwin -Paarch64 -k-framework -kCocoa -FEbuild/Minesweeper.app/Contents/MacOS src/macOS/Main.pas`
  - `mv build/Minesweeper.app/Contents/MacOS/Main build/Minesweeper.app/Contents/MacOS/minesweeper`
- Create `Info.plist` (once): place a minimal plist at `build/Minesweeper.app/Contents/Info.plist` with `CFBundleExecutable` = `minesweeper`.
- Run app: `open build/Minesweeper.app`
- Tests: `fpc tests/test_all.pas -Fu./src -Fu./src/core -Fu./tests -o build/tests && build/tests`

## Coding Style & Naming Conventions
- Indentation: 2 spaces, no tabs; ~100 char lines.
- Units: one per file; filename matches unit (`uBoard.pas` → `unit uBoard;`).
- Types: `TBoard`, `TCell`; interfaces: `IClock`.
- Fields/vars: `lowerCamelCase` (e.g., `mineCount`). Constants: `ALL_CAPS`.
- Cocoa: `{$mode objfpc}{$H+}` and `{$modeswitch objectivec2}`; `uses CocoaAll` in macOS units only. Keep ObjC bridges thin; keep logic in `src/core/`.

## Testing Guidelines
- Framework: fpcunit. Tests live in `tests/` mirroring `src/core/`.
- Naming: `test_<unit>.pas` with suites like `TBoardTests`.
- Coverage focus: board generation, adjacency counts, flood fill, edge cases (borders, 0/full mines).

## Commit & Pull Request Guidelines
- Commits: Conventional Commits, e.g., `feat(board): add flood fill`.
- PRs: description, linked issues, test notes, and screenshots for UI changes.
- Pre‑PR: build app, run tests locally; ensure no external deps were added.

## Cocoa & Security Notes
- Native only: rely on system frameworks (Cocoa, Foundation). No third‑party libs.
- Codesign (optional for local dev): `codesign --force -s - build/Minesweeper.app` if macOS blocks launching.
