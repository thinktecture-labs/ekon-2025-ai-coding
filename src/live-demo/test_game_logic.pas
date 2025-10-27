program test_game_logic;

{$mode objfpc}{$H+}

uses
  SysUtils, game_logic;

var
  TotalTests: Integer = 0;
  PassedTests: Integer = 0;
  FailedTests: Integer = 0;

{ Test assertion helper }
procedure AssertTrue(const TestName: string; Condition: Boolean; const Message: string = '');
begin
  Inc(TotalTests);
  Write('  [TEST] ', TestName, '...');
  if Condition then
  begin
    WriteLn(' PASS');
    Inc(PassedTests);
  end
  else
  begin
    WriteLn(' FAIL');
    if Message <> '' then
      WriteLn('    Expected: True');
    WriteLn('    Message: ', Message);
    Inc(FailedTests);
  end;
end;

procedure AssertEquals(const TestName: string; Expected, Actual: Integer; const Message: string = '');
begin
  Inc(TotalTests);
  Write('  [TEST] ', TestName, '...');
  if Expected = Actual then
  begin
    WriteLn(' PASS');
    Inc(PassedTests);
  end
  else
  begin
    WriteLn(' FAIL');
    WriteLn('    Expected: ', Expected);
    WriteLn('    Actual: ', Actual);
    if Message <> '' then
      WriteLn('    Message: ', Message);
    Inc(FailedTests);
  end;
end;

procedure AssertFalse(const TestName: string; Condition: Boolean; const Message: string = '');
begin
  AssertTrue(TestName, not Condition, Message);
end;

{ Test Suite 1: Initialization Tests }
procedure TestInitialization;
var
  game: TGameData;
begin
  WriteLn('=== Testing Initialization ===');
  game := TGameData.Create;
  try
    // Test beginner mode
    game.InitGame(gmBeginner);
    AssertEquals('Beginner rows = 9', 9, game.Rows);
    AssertEquals('Beginner cols = 9', 9, game.Cols);
    AssertTrue('Beginner mines in range 8-12', (game.Mines >= 8) and (game.Mines <= 12));
    AssertEquals('Initial revealed count = 0', 0, game.RevealedCount);
    AssertFalse('Game not won initially', game.GameWon);
    AssertFalse('Game not lost initially', game.GameLost);

    // Test intermediate mode
    game.InitGame(gmIntermediate);
    AssertEquals('Intermediate rows = 16', 16, game.Rows);
    AssertEquals('Intermediate cols = 16', 16, game.Cols);
    AssertTrue('Intermediate mines in range 30-50', (game.Mines >= 30) and (game.Mines <= 50));

    // Test expert mode
    game.InitGame(gmExpert);
    AssertEquals('Expert rows = 30', 30, game.Rows);
    AssertEquals('Expert cols = 16', 16, game.Cols);
    AssertTrue('Expert mines in range 70-99', (game.Mines >= 70) and (game.Mines <= 99));
  finally
    game.Free;
  end;
end;

{ Test Suite 2: Mine Placement Tests }
procedure TestMinePlacement;
var
  game: TGameData;
  i, j: Integer;
  mineCount: Integer;
  cell: TCell;
  firstX, firstY: Integer;
  isSafe: Boolean;
  dx, dy: Integer;
begin
  WriteLn('=== Testing Mine Placement ===');
  game := TGameData.Create;
  try
    game.InitGame(gmBeginner);

    // Place mines with first click at (4, 4) - center
    firstX := 4;
    firstY := 4;
    game.PlaceMines(10, firstX, firstY);

    // Count total mines
    mineCount := 0;
    for i := 0 to game.Rows - 1 do
      for j := 0 to game.Cols - 1 do
      begin
        cell := game.GetCell(i, j);
        if cell.IsMine then
          Inc(mineCount);
      end;

    AssertEquals('Correct number of mines placed', 10, mineCount);

    // Check first click position and neighbors are safe
    isSafe := True;
    for dx := -1 to 1 do
      for dy := -1 to 1 do
      begin
        i := firstX + dx;
        j := firstY + dy;
        if (i >= 0) and (i < game.Rows) and (j >= 0) and (j < game.Cols) then
        begin
          cell := game.GetCell(i, j);
          if cell.IsMine then
            isSafe := False;
        end;
      end;

    AssertTrue('First click area is safe', isSafe);
    AssertTrue('Mines placed flag set', game.MinesPlaced);
  finally
    game.Free;
  end;
end;

{ Test Suite 3: Adjacent Mine Calculation Tests }
procedure TestAdjacentMineCalculation;
var
  game: TGameData;
  i, j: Integer;
  cell: TCell;
  allValid: Boolean;
begin
  WriteLn('=== Testing Adjacent Mine Calculation ===');
  game := TGameData.Create;
  try
    game.InitGame(gmBeginner);
    game.PlaceMines(game.Mines, 0, 0);
    game.CalculateAdjacentMines;

    // Check all non-mine cells have valid adjacent counts (0-8)
    allValid := True;
    for i := 0 to game.Rows - 1 do
      for j := 0 to game.Cols - 1 do
      begin
        cell := game.GetCell(i, j);
        if not cell.IsMine then
        begin
          if (cell.AdjacentMines < 0) or (cell.AdjacentMines > 8) then
            allValid := False;
        end;
      end;

    AssertTrue('All adjacent mine counts are valid (0-8)', allValid);

    // Test corner cell (max 3 neighbors)
    cell := game.GetCell(0, 0);
    if not cell.IsMine then
      AssertTrue('Corner cell has <= 3 adjacent', cell.AdjacentMines <= 3);

    // Test edge cell (max 5 neighbors)
    cell := game.GetCell(0, 4);
    if not cell.IsMine then
      AssertTrue('Edge cell has <= 5 adjacent', cell.AdjacentMines <= 5);
  finally
    game.Free;
  end;
end;

{ Test Suite 4: Cell Reveal Tests }
procedure TestCellReveal;
var
  game: TGameData;
  result: Boolean;
  cell: TCell;
  i, j: Integer;
  foundMine: Boolean;
begin
  WriteLn('=== Testing Cell Reveal ===');
  game := TGameData.Create;
  try
    game.InitGame(gmBeginner);

    // Test revealing a safe cell
    result := game.RevealCell(4, 4);
    AssertTrue('Reveal safe cell succeeds', result);
    AssertTrue('Mines placed after first click', game.MinesPlaced);
    cell := game.GetCell(4, 4);
    AssertTrue('Cell is revealed', cell.IsRevealed);
    AssertFalse('Cell is not a mine', cell.IsMine);
    AssertTrue('Revealed count > 0', game.RevealedCount > 0);

    // Test revealing already revealed cell (should succeed but not change state)
    result := game.RevealCell(4, 4);
    AssertTrue('Reveal already revealed cell succeeds', result);
  finally
    game.Free;
  end;

  // Test revealing flagged cell (should not reveal) - use fresh game
  game := TGameData.Create;
  try
    game.InitGame(gmBeginner);
    // Flag a cell before any reveals
    game.ToggleFlag(0, 0);
    result := game.RevealCell(0, 0);
    AssertTrue('Reveal flagged cell succeeds but doesnt reveal', result);
    cell := game.GetCell(0, 0);
    AssertFalse('Flagged cell not revealed', cell.IsRevealed);
  finally
    game.Free;
  end;

  // Test revealing mines - use fresh game
  game := TGameData.Create;
  try
    game.InitGame(gmBeginner);
    // First reveal to place mines
    game.RevealCell(4, 4);

    // Find a mine and reveal it
    foundMine := False;
    for i := 0 to game.Rows - 1 do
    begin
      for j := 0 to game.Cols - 1 do
      begin
        cell := game.GetCell(i, j);
        if cell.IsMine and not cell.IsRevealed then
        begin
          result := game.RevealCell(i, j);
          AssertFalse('Revealing mine returns False', result);
          AssertTrue('Game lost after mine reveal', game.GameLost);
          foundMine := True;
          Break;
        end;
      end;
      if foundMine then Break;
    end;
  finally
    game.Free;
  end;
end;

{ Test Suite 5: Cascade Reveal Tests }
procedure TestCascadeReveal;
var
  game: TGameData;
  i, j: Integer;
  cell: TCell;
  hasZeroAdjacentRevealed: Boolean;
begin
  WriteLn('=== Testing Cascade Reveal ===');
  game := TGameData.Create;
  try
    // Use beginner mode which is more likely to have cells with 0 adjacent mines
    game.InitGame(gmBeginner);
    game.PlaceMines(game.Mines, 4, 4);
    game.CalculateAdjacentMines;

    // Find and reveal a cell with 0 adjacent mines
    hasZeroAdjacentRevealed := False;
    for i := 0 to game.Rows - 1 do
      for j := 0 to game.Cols - 1 do
      begin
        cell := game.GetCell(i, j);
        if (not cell.IsMine) and (cell.AdjacentMines = 0) then
        begin
          game.RevealCell(i, j);
          hasZeroAdjacentRevealed := True;
          Break;
        end;
        if hasZeroAdjacentRevealed then Break;
      end;

    if hasZeroAdjacentRevealed then
    begin
      AssertTrue('Cascade reveal reveals multiple cells', game.RevealedCount > 1);
    end
    else
    begin
      WriteLn('  [INFO] No cells with 0 adjacent mines found for cascade test');
    end;
  finally
    game.Free;
  end;
end;

{ Test Suite 6: Flag Toggle Tests }
procedure TestFlagToggle;
var
  game: TGameData;
  cell: TCell;
begin
  WriteLn('=== Testing Flag Toggle ===');
  game := TGameData.Create;
  try
    game.InitGame(gmBeginner);

    // Toggle flag on unrevealed cell
    game.ToggleFlag(3, 3);
    cell := game.GetCell(3, 3);
    AssertTrue('Cell is flagged', cell.IsFlagged);

    // Toggle flag again (unflag)
    game.ToggleFlag(3, 3);
    cell := game.GetCell(3, 3);
    AssertFalse('Cell is unflagged', cell.IsFlagged);

    // Reveal a cell then try to flag it
    game.RevealCell(4, 4);
    game.ToggleFlag(4, 4);
    cell := game.GetCell(4, 4);
    AssertFalse('Cannot flag revealed cell', cell.IsFlagged);
  finally
    game.Free;
  end;
end;

{ Test Suite 7: Win Condition Tests }
procedure TestWinCondition;
var
  game: TGameData;
  i, j: Integer;
  cell: TCell;
begin
  WriteLn('=== Testing Win Condition ===');
  game := TGameData.Create;
  try
    game.InitGame(gmBeginner);
    game.PlaceMines(game.Mines, 0, 0);
    game.CalculateAdjacentMines;

    // Reveal all non-mine cells
    for i := 0 to game.Rows - 1 do
      for j := 0 to game.Cols - 1 do
      begin
        cell := game.GetCell(i, j);
        if not cell.IsMine then
          game.RevealCell(i, j);
      end;

    AssertTrue('Game won after revealing all safe cells', game.GameWon);
    AssertFalse('Game not lost', game.GameLost);

    // Verify revealed count equals safe cells
    AssertEquals('Revealed count = total - mines',
                 (game.Rows * game.Cols) - game.Mines,
                 game.RevealedCount);
  finally
    game.Free;
  end;
end;

{ Test Suite 8: Bounds Checking Tests }
procedure TestBoundsChecking;
var
  game: TGameData;
  cell: TCell;
begin
  WriteLn('=== Testing Bounds Checking ===');
  game := TGameData.Create;
  try
    game.InitGame(gmBeginner);

    // Test out of bounds access returns safe empty cell
    cell := game.GetCell(-1, 0);
    AssertFalse('Out of bounds cell not a mine', cell.IsMine);
    AssertFalse('Out of bounds cell not revealed', cell.IsRevealed);

    cell := game.GetCell(0, -1);
    AssertFalse('Out of bounds cell not a mine', cell.IsMine);

    cell := game.GetCell(game.Rows, 0);
    AssertFalse('Out of bounds cell not a mine', cell.IsMine);

    cell := game.GetCell(0, game.Cols);
    AssertFalse('Out of bounds cell not a mine', cell.IsMine);

    // Test revealing out of bounds does nothing
    game.RevealCell(-1, -1);
    game.RevealCell(game.Rows, game.Cols);
    AssertEquals('Revealed count still 0 after invalid reveals', 0, game.RevealedCount);
  finally
    game.Free;
  end;
end;

{ Test Suite 9: Edge Cases }
procedure TestEdgeCases;
var
  game: TGameData;
  result: Boolean;
  i, j: Integer;
  cell: TCell;
begin
  WriteLn('=== Testing Edge Cases ===');
  game := TGameData.Create;
  try
    game.InitGame(gmBeginner);

    // Test multiple reveal attempts on same cell
    result := game.RevealCell(4, 4);
    AssertTrue('First reveal succeeds', result);
    result := game.RevealCell(4, 4);
    AssertTrue('Second reveal on same cell succeeds', result);

    // Test flagging then unflagging then revealing
    game.ToggleFlag(5, 5);
    game.ToggleFlag(5, 5); // Unflag
    result := game.RevealCell(5, 5);
    AssertTrue('Can reveal after flag/unflag', result);

    // Test game over state (try operations after loss)
    game.InitGame(gmBeginner);
    game.PlaceMines(game.Mines, 0, 0);
    game.CalculateAdjacentMines;

    // Find and hit a mine
    for i := 0 to game.Rows - 1 do
      for j := 0 to game.Cols - 1 do
      begin
        cell := game.GetCell(i, j);
        if cell.IsMine then
        begin
          game.RevealCell(i, j);
          Break;
        end;
      end;

    AssertTrue('Game lost', game.GameLost);

    // Try operations after game lost
    result := game.RevealCell(0, 0);
    AssertFalse('Cannot reveal after game lost', result);

    game.ToggleFlag(1, 1);
    // Flag should not be set after game over
    // (our implementation doesn't allow flagging after game over)
  finally
    game.Free;
  end;
end;

{ Test Suite 10: Reset and Reinitialization }
procedure TestResetAndReinit;
var
  game: TGameData;
begin
  WriteLn('=== Testing Reset and Reinitialization ===');
  game := TGameData.Create;
  try
    // Initialize and play
    game.InitGame(gmBeginner);
    game.RevealCell(4, 4);
    AssertTrue('Game has revealed cells', game.RevealedCount > 0);

    // Reset
    game.ResetGame;
    AssertEquals('Rows reset to 0', 0, game.Rows);
    AssertEquals('Cols reset to 0', 0, game.Cols);
    AssertEquals('Revealed count reset', 0, game.RevealedCount);
    AssertFalse('Game won flag reset', game.GameWon);
    AssertFalse('Game lost flag reset', game.GameLost);
    AssertFalse('Mines placed flag reset', game.MinesPlaced);

    // Re-initialize
    game.InitGame(gmIntermediate);
    AssertEquals('Reinitialized with correct rows', 16, game.Rows);
    AssertEquals('Reinitialized with correct cols', 16, game.Cols);
  finally
    game.Free;
  end;
end;

{ Test Suite 11: Time Tracking }
procedure TestTimeTracking;
var
  game: TGameData;
  elapsed: Integer;
begin
  WriteLn('=== Testing Time Tracking ===');
  game := TGameData.Create;
  try
    game.InitGame(gmBeginner);

    // Time should be approximately 0 at start
    elapsed := game.GetElapsedTime;
    AssertTrue('Elapsed time is small at start', elapsed >= 0);

    // Sleep briefly and check time increased
    Sleep(1100); // Sleep for 1.1 seconds
    elapsed := game.GetElapsedTime;
    AssertTrue('Elapsed time increased after delay', elapsed >= 1);
  finally
    game.Free;
  end;
end;

{ Main test runner }
procedure RunAllTests;
begin
  WriteLn('');
  WriteLn('===============================================');
  WriteLn('  Minesweeper Game Logic - Unit Tests');
  WriteLn('===============================================');
  WriteLn('');

  Randomize; // Initialize random number generator

  TestInitialization;
  WriteLn('');

  TestMinePlacement;
  WriteLn('');

  TestAdjacentMineCalculation;
  WriteLn('');

  TestCellReveal;
  WriteLn('');

  TestCascadeReveal;
  WriteLn('');

  TestFlagToggle;
  WriteLn('');

  TestWinCondition;
  WriteLn('');

  TestBoundsChecking;
  WriteLn('');

  TestEdgeCases;
  WriteLn('');

  TestResetAndReinit;
  WriteLn('');

  TestTimeTracking;
  WriteLn('');

  WriteLn('===============================================');
  WriteLn('  Test Results Summary');
  WriteLn('===============================================');
  WriteLn('  Total Tests:  ', TotalTests);
  WriteLn('  Passed:       ', PassedTests, ' (', (PassedTests * 100) div TotalTests, '%)');
  WriteLn('  Failed:       ', FailedTests);
  WriteLn('===============================================');
  WriteLn('');

  if FailedTests = 0 then
  begin
    WriteLn('SUCCESS: All tests passed!');
    ExitCode := 0;
  end
  else
  begin
    WriteLn('FAILURE: Some tests failed!');
    ExitCode := 1;
  end;
end;

begin
  RunAllTests;
end.
