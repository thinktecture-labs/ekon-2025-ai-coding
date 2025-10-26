# Minesweeper Game Logic - Quick Start Guide

## 5-Minute Integration Guide

### Step 1: Include the Unit

```pascal
uses
  GameLogic;
```

### Step 2: Create Game Instance

```pascal
type
  TYourController = class  // or objcclass for Cocoa
  private
    FGame: TGameData;
  end;

// In your initialization
FGame := TGameData.Create;
FGame.InitGame(gmBeginner);  // or gmIntermediate, gmExpert
```

### Step 3: Handle User Actions

```pascal
// Left-click on cell
procedure HandleCellClick(Row, Col: Integer);
var
  HitMine: Boolean;
begin
  HitMine := FGame.RevealCell(Row, Col);

  RefreshDisplay;

  if HitMine then
    ShowGameOver
  else if FGame.GameState = gsWon then
    ShowVictory;
end;

// Right-click on cell
procedure HandleCellRightClick(Row, Col: Integer);
begin
  FGame.ToggleFlag(Row, Col);
  RefreshDisplay;
end;
```

### Step 4: Display Cells

```pascal
procedure RefreshDisplay;
var
  R, C: Integer;
  Cell: TCell;
begin
  for R := 0 to FGame.Rows - 1 do
    for C := 0 to FGame.Cols - 1 do
    begin
      Cell := FGame.Cell[R, C];

      if Cell.IsFlagged then
        DrawFlag(R, C)
      else if Cell.IsRevealed then
      begin
        if Cell.HasMine then
          DrawMine(R, C)
        else if Cell.AdjacentMines > 0 then
          DrawNumber(R, C, Cell.AdjacentMines)
        else
          DrawEmpty(R, C);
      end
      else
        DrawUnrevealed(R, C);
    end;
end;
```

### Step 5: Display Timer

```pascal
procedure UpdateTimer;
begin
  TimerLabel.SetText(Format('Time: %d', [FGame.ElapsedSeconds]));
end;
```

## Common Patterns

### New Game / Restart

```pascal
procedure NewGame;
begin
  FGame.Reset;
  FGame.InitGame(gmBeginner);
  RefreshDisplay;
end;
```

### Change Difficulty

```pascal
procedure ChangeDifficulty(Mode: TGameMode);
begin
  FGame.InitGame(Mode);
  RefreshDisplay;
end;
```

### Check Game Status

```pascal
case FGame.GameState of
  gsNotStarted: StatusLabel.SetText('Click to start');
  gsPlaying:    StatusLabel.SetText('Playing...');
  gsWon:        StatusLabel.SetText('You Won!');
  gsLost:       StatusLabel.SetText('Game Over');
end;
```

## Cell Colors (Recommended)

```pascal
function GetCellColor(Cell: TCell): TColor;
begin
  if Cell.IsFlagged then
    Result := Orange
  else if Cell.IsRevealed then
  begin
    if Cell.HasMine then
      Result := Red
    else
      Result := LightGray;
  end
  else
    Result := DarkGray;
end;
```

## Number Colors (Recommended)

```pascal
function GetNumberColor(Count: Integer): TColor;
begin
  case Count of
    1: Result := Green;
    2: Result := DarkGreen;
    3: Result := Yellow;
    4: Result := Orange;
    else Result := Red;
  end;
end;
```

## Complete Minimal Example

```pascal
program MinimalMinesweeper;

uses
  GameLogic;

var
  Game: TGameData;
  Row, Col: Integer;
  Cell: TCell;
  Input: Char;

procedure DisplayBoard;
var
  R, C: Integer;
begin
  for R := 0 to Game.Rows - 1 do
  begin
    for C := 0 to Game.Cols - 1 do
    begin
      Cell := Game.Cell[R, C];
      if Cell.IsFlagged then
        Write('F ')
      else if Cell.IsRevealed then
      begin
        if Cell.HasMine then
          Write('* ')
        else if Cell.AdjacentMines > 0 then
          Write(Cell.AdjacentMines, ' ')
        else
          Write('. ');
      end
      else
        Write('# ');
    end;
    WriteLn;
  end;
  WriteLn('Time: ', Game.ElapsedSeconds, 's');
  WriteLn;
end;

begin
  Game := TGameData.Create;
  try
    Game.InitGame(gmBeginner);

    repeat
      DisplayBoard;

      case Game.GameState of
        gsWon:
        begin
          WriteLn('YOU WON!');
          Break;
        end;
        gsLost:
        begin
          WriteLn('GAME OVER!');
          Break;
        end;
      end;

      Write('Enter row col (or f row col to flag): ');
      ReadLn(Input);

      if Input = 'f' then
      begin
        ReadLn(Row, Col);
        Game.ToggleFlag(Row, Col);
      end
      else
      begin
        Row := Ord(Input) - Ord('0');
        ReadLn(Col);
        Game.RevealCell(Row, Col);
      end;

    until False;

  finally
    Game.Free;
  end;
end.
```

## Testing Your Integration

```bash
# Build the test suite
./build-test.sh

# All 21 tests should pass
```

## Troubleshooting

**Problem**: First click hits a mine
- **Solution**: This shouldn't happen - file a bug if it does!

**Problem**: Flood reveal doesn't stop
- **Solution**: Make sure you're checking `Cell.IsRevealed` before calling reveal

**Problem**: Can reveal flagged cells
- **Solution**: Check `Cell.IsFlagged` before allowing reveal

**Problem**: Game state doesn't change to Won
- **Solution**: Use `RevealCell`, not direct grid access - it handles win detection

**Problem**: Timer shows 0 even after playing
- **Solution**: Timer starts on first `RevealCell` call, not on `InitGame`

## File Locations

- **Game Logic**: `/Users/sebastian/dev/tt/conf/ekon-2025-ai-coding/src/live-demo/minesweeper/src/GameLogic.pas`
- **Tests**: `/Users/sebastian/dev/tt/conf/ekon-2025-ai-coding/src/live-demo/minesweeper/tests/TestGameLogic.pas`
- **Documentation**: `/Users/sebastian/dev/tt/conf/ekon-2025-ai-coding/src/live-demo/minesweeper/README.md`

## Need Help?

Refer to:
1. `README.md` - Full API documentation
2. `IMPLEMENTATION_SUMMARY.md` - Implementation details and test results
3. `tests/TestGameLogic.pas` - Usage examples in test code
