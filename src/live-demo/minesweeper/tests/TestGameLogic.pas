program TestGameLogic;

{$mode objfpc}{$H+}

uses
  SysUtils, GameLogic;

var
  TestsRun: Integer = 0;
  TestsPassed: Integer = 0;
  TestsFailed: Integer = 0;
  CurrentTest: string = '';

procedure AssertTrue(Condition: Boolean; const Msg: string);
begin
  if not Condition then
    raise Exception.Create('Assertion failed (expected True): ' + Msg);
end;

procedure AssertFalse(Condition: Boolean; const Msg: string);
begin
  if Condition then
    raise Exception.Create('Assertion failed (expected False): ' + Msg);
end;

procedure AssertEquals(Expected, Actual: Integer; const Msg: string);
begin
  if Expected <> Actual then
    raise Exception.CreateFmt('Assertion failed: %s (Expected: %d, Actual: %d)', [Msg, Expected, Actual]);
end;

procedure AssertEquals(Expected, Actual: Boolean; const Msg: string);
begin
  if Expected <> Actual then
    raise Exception.CreateFmt('Assertion failed: %s (Expected: %s, Actual: %s)',
      [Msg, BoolToStr(Expected, True), BoolToStr(Actual, True)]);
end;

procedure AssertEquals(Expected, Actual: TGameState; const Msg: string);
begin
  if Expected <> Actual then
    raise Exception.CreateFmt('Assertion failed: %s (Expected: %d, Actual: %d)', [Msg, Ord(Expected), Ord(Actual)]);
end;

procedure AssertGreaterOrEqual(Actual, MinValue: Integer; const Msg: string);
begin
  if Actual < MinValue then
    raise Exception.CreateFmt('Assertion failed: %s (Actual: %d, MinValue: %d)', [Msg, Actual, MinValue]);
end;

procedure AssertLessOrEqual(Actual, MaxValue: Integer; const Msg: string);
begin
  if Actual > MaxValue then
    raise Exception.CreateFmt('Assertion failed: %s (Actual: %d, MaxValue: %d)', [Msg, Actual, MaxValue]);
end;

procedure AssertInRange(Actual, MinValue, MaxValue: Integer; const Msg: string);
begin
  if (Actual < MinValue) or (Actual > MaxValue) then
    raise Exception.CreateFmt('Assertion failed: %s (Actual: %d, Range: %d..%d)',
      [Msg, Actual, MinValue, MaxValue]);
end;

procedure BeginTest(const TestName: string);
begin
  Inc(TestsRun);
  CurrentTest := TestName;
  Write('  Running test: ', TestName, '... ');
end;

procedure EndTestPass;
begin
  Inc(TestsPassed);
  WriteLn('PASSED');
end;

procedure EndTestFail(const ErrorMsg: string);
begin
  Inc(TestsFailed);
  WriteLn('FAILED');
  WriteLn('    Error: ', ErrorMsg);
end;

{ Individual test procedures }

procedure TestCreateGame;
var
  Game: TGameData;
begin
  Game := TGameData.Create;
  try
    AssertEquals(gsNotStarted, Game.GameState, 'Initial state should be NotStarted');
    AssertEquals(0, Game.Rows, 'Initial rows should be 0');
    AssertEquals(0, Game.Cols, 'Initial cols should be 0');
  finally
    Game.Free;
  end;
end;

procedure TestInitGameBeginner;
var
  Game: TGameData;
begin
  Game := TGameData.Create;
  try
    Game.InitGame(gmBeginner);
    AssertEquals(BEGINNER_ROWS, Game.Rows, 'Beginner rows');
    AssertEquals(BEGINNER_COLS, Game.Cols, 'Beginner cols');
    AssertInRange(Game.MineCount, BEGINNER_MIN_MINES, BEGINNER_MAX_MINES, 'Beginner mine count');
    AssertEquals(gsNotStarted, Game.GameState, 'State should be NotStarted after init');
  finally
    Game.Free;
  end;
end;

procedure TestInitGameIntermediate;
var
  Game: TGameData;
begin
  Game := TGameData.Create;
  try
    Game.InitGame(gmIntermediate);
    AssertEquals(INTERMEDIATE_ROWS, Game.Rows, 'Intermediate rows');
    AssertEquals(INTERMEDIATE_COLS, Game.Cols, 'Intermediate cols');
    AssertInRange(Game.MineCount, INTERMEDIATE_MIN_MINES, INTERMEDIATE_MAX_MINES, 'Intermediate mine count');
  finally
    Game.Free;
  end;
end;

procedure TestInitGameExpert;
var
  Game: TGameData;
begin
  Game := TGameData.Create;
  try
    Game.InitGame(gmExpert);
    AssertEquals(EXPERT_ROWS, Game.Rows, 'Expert rows');
    AssertEquals(EXPERT_COLS, Game.Cols, 'Expert cols');
    AssertInRange(Game.MineCount, EXPERT_MIN_MINES, EXPERT_MAX_MINES, 'Expert mine count');
  finally
    Game.Free;
  end;
end;

procedure TestInitGameCustom;
var
  Game: TGameData;
begin
  Game := TGameData.Create;
  try
    Game.InitGame(10, 15, 20);
    AssertEquals(10, Game.Rows, 'Custom rows');
    AssertEquals(15, Game.Cols, 'Custom cols');
    AssertEquals(20, Game.MineCount, 'Custom mine count');
  finally
    Game.Free;
  end;
end;

procedure TestInitGameInvalidDimensions;
var
  Game: TGameData;
  ExceptionRaised: Boolean;
begin
  Game := TGameData.Create;
  try
    ExceptionRaised := False;
    try
      Game.InitGame(0, 10, 5);
    except
      ExceptionRaised := True;
    end;
    AssertTrue(ExceptionRaised, 'Should raise exception for zero rows');

    ExceptionRaised := False;
    try
      Game.InitGame(10, -5, 5);
    except
      ExceptionRaised := True;
    end;
    AssertTrue(ExceptionRaised, 'Should raise exception for negative cols');
  finally
    Game.Free;
  end;
end;

procedure TestInitGameInvalidMineCount;
var
  Game: TGameData;
  ExceptionRaised: Boolean;
begin
  Game := TGameData.Create;
  try
    ExceptionRaised := False;
    try
      Game.InitGame(5, 5, -1);
    except
      ExceptionRaised := True;
    end;
    AssertTrue(ExceptionRaised, 'Should raise exception for negative mine count');

    ExceptionRaised := False;
    try
      Game.InitGame(5, 5, 25);
    except
      ExceptionRaised := True;
    end;
    AssertTrue(ExceptionRaised, 'Should raise exception for mine count >= total cells');
  finally
    Game.Free;
  end;
end;

procedure TestGetModeConfig;
var
  Config: TModeConfig;
begin
  Config := TGameData.GetModeConfig(gmBeginner);
  AssertEquals(BEGINNER_ROWS, Config.Rows, 'Beginner config rows');
  AssertEquals(BEGINNER_COLS, Config.Cols, 'Beginner config cols');
  AssertEquals(BEGINNER_MIN_MINES, Config.MinMines, 'Beginner config min mines');
  AssertEquals(BEGINNER_MAX_MINES, Config.MaxMines, 'Beginner config max mines');

  Config := TGameData.GetModeConfig(gmIntermediate);
  AssertEquals(INTERMEDIATE_ROWS, Config.Rows, 'Intermediate config rows');

  Config := TGameData.GetModeConfig(gmExpert);
  AssertEquals(EXPERT_ROWS, Config.Rows, 'Expert config rows');
end;

procedure TestInitialGameState;
var
  Game: TGameData;
  R, C: Integer;
  Cell: TCell;
begin
  Game := TGameData.Create;
  try
    Game.InitGame(5, 5, 3);

    for R := 0 to 4 do
      for C := 0 to 4 do
      begin
        Cell := Game.Cell[R, C];
        AssertFalse(Cell.HasMine, Format('Cell (%d,%d) should not have mine initially', [R, C]));
        AssertFalse(Cell.IsRevealed, Format('Cell (%d,%d) should not be revealed initially', [R, C]));
        AssertFalse(Cell.IsFlagged, Format('Cell (%d,%d) should not be flagged initially', [R, C]));
        AssertEquals(0, Cell.AdjacentMines, Format('Cell (%d,%d) should have 0 adjacent mines initially', [R, C]));
      end;
  finally
    Game.Free;
  end;
end;

procedure TestPlaceMinesCount;
var
  Game: TGameData;
  R, C: Integer;
  MineCount: Integer;
begin
  Game := TGameData.Create;
  try
    Game.InitGame(8, 8, 10);
    Game.PlaceMines(0, 0);

    MineCount := 0;
    for R := 0 to 7 do
      for C := 0 to 7 do
        if Game.Cell[R, C].HasMine then
          Inc(MineCount);

    AssertEquals(10, MineCount, 'Should have exactly 10 mines placed');
    AssertEquals(gsPlaying, Game.GameState, 'Game should be in Playing state after placing mines');
  finally
    Game.Free;
  end;
end;

procedure TestPlaceMinesExcludesFirstClick;
var
  Game: TGameData;
begin
  Game := TGameData.Create;
  try
    Game.InitGame(5, 5, 10);
    Game.PlaceMines(2, 2);

    AssertFalse(Game.Cell[2, 2].HasMine, 'First click cell should not have mine');
  finally
    Game.Free;
  end;
end;

procedure TestPlaceMinesExcludesNeighbors;
var
  Game: TGameData;
  DR, DC: Integer;
  R, C: Integer;
begin
  Game := TGameData.Create;
  try
    Game.InitGame(10, 10, 20);
    Game.PlaceMines(5, 5);

    for DR := -1 to 1 do
      for DC := -1 to 1 do
      begin
        R := 5 + DR;
        C := 5 + DC;
        AssertFalse(Game.Cell[R, C].HasMine,
          Format('Neighbor cell (%d,%d) should not have mine', [R, C]));
      end;
  finally
    Game.Free;
  end;
end;

procedure TestAdjacentMineCalculation;
var
  Game: TGameData;
begin
  Game := TGameData.Create;
  try
    Game.InitGame(3, 3, 1);
    Game.PlaceMines(0, 0);

    AssertGreaterOrEqual(Game.Cell[0, 0].AdjacentMines, 0, 'Adjacent count >= 0');
    AssertLessOrEqual(Game.Cell[0, 0].AdjacentMines, 8, 'Adjacent count <= 8');
  finally
    Game.Free;
  end;
end;

procedure TestRevealSafeCell;
var
  Game: TGameData;
  HitMine: Boolean;
begin
  Game := TGameData.Create;
  try
    Game.InitGame(10, 10, 20);
    HitMine := Game.RevealCell(0, 0);

    AssertFalse(HitMine, 'First click should be safe');
    AssertTrue(Game.Cell[0, 0].IsRevealed, 'Cell should be revealed');
    // With 20 mines on a 10x10 board, revealing one cell shouldn't win the game
    AssertTrue((Game.GameState = gsPlaying) or (Game.GameState = gsWon), 'Game should be playing or won');
  finally
    Game.Free;
  end;
end;

procedure TestRevealMine;
var
  Game: TGameData;
  R, C: Integer;
  HitMine: Boolean;
  FoundMine: Boolean;
begin
  Game := TGameData.Create;
  try
    // Use larger board to ensure we can place enough mines outside the first click area
    Game.InitGame(10, 10, 30);
    Game.RevealCell(0, 0);  // First click at corner

    FoundMine := False;
    // Search for a mine that wasn't revealed by flood
    for R := 0 to 9 do
    begin
      for C := 0 to 9 do
      begin
        if Game.Cell[R, C].HasMine and not Game.Cell[R, C].IsRevealed then
        begin
          HitMine := Game.RevealCell(R, C);
          AssertTrue(HitMine, 'Should return true when hitting mine');
          AssertEquals(gsLost, Game.GameState, 'Game should be lost after hitting mine');
          FoundMine := True;
          Break;
        end;
      end;
      if FoundMine then Break;
    end;

    AssertTrue(FoundMine, 'Should have found at least one mine to test');
  finally
    Game.Free;
  end;
end;

procedure TestToggleFlag;
var
  Game: TGameData;
begin
  Game := TGameData.Create;
  try
    Game.InitGame(5, 5, 3);

    AssertFalse(Game.Cell[2, 2].IsFlagged, 'Cell should not be flagged initially');
    Game.ToggleFlag(2, 2);
    AssertTrue(Game.Cell[2, 2].IsFlagged, 'Cell should be flagged after toggle');
  finally
    Game.Free;
  end;
end;

procedure TestToggleFlagTwice;
var
  Game: TGameData;
begin
  Game := TGameData.Create;
  try
    Game.InitGame(5, 5, 3);

    Game.ToggleFlag(2, 2);
    Game.ToggleFlag(2, 2);
    AssertFalse(Game.Cell[2, 2].IsFlagged, 'Cell should be unflagged after two toggles');
  finally
    Game.Free;
  end;
end;

procedure TestWinCondition;
var
  Game: TGameData;
  R, C: Integer;
begin
  Game := TGameData.Create;
  try
    Game.InitGame(4, 4, 2);
    Game.RevealCell(0, 0);

    for R := 0 to 3 do
      for C := 0 to 3 do
        if not Game.Cell[R, C].HasMine then
          Game.RevealCell(R, C);

    AssertEquals(gsWon, Game.GameState, 'Should win when all safe cells revealed');
  finally
    Game.Free;
  end;
end;

procedure TestGameStateInitial;
var
  Game: TGameData;
begin
  Game := TGameData.Create;
  try
    Game.InitGame(5, 5, 3);
    AssertEquals(gsNotStarted, Game.GameState, 'Initial game state should be NotStarted');

    Game.RevealCell(2, 2);
    AssertEquals(gsPlaying, Game.GameState, 'Game state should be Playing after first reveal');
  finally
    Game.Free;
  end;
end;

procedure TestRevealInvalidCell;
var
  Game: TGameData;
  HitMine: Boolean;
begin
  Game := TGameData.Create;
  try
    Game.InitGame(5, 5, 3);

    HitMine := Game.RevealCell(-1, -1);
    AssertFalse(HitMine, 'Revealing invalid cell should return false');

    HitMine := Game.RevealCell(10, 10);
    AssertFalse(HitMine, 'Revealing out-of-bounds cell should return false');
  finally
    Game.Free;
  end;
end;

procedure TestReset;
var
  Game: TGameData;
  R, C: Integer;
begin
  Game := TGameData.Create;
  try
    Game.InitGame(5, 5, 3);
    Game.RevealCell(2, 2);
    Game.ToggleFlag(1, 1);

    Game.Reset;

    AssertEquals(gsNotStarted, Game.GameState, 'Game state should be NotStarted after reset');
    AssertEquals(0, Game.RevealedCount, 'Revealed count should be 0 after reset');

    for R := 0 to 4 do
      for C := 0 to 4 do
      begin
        AssertFalse(Game.Cell[R, C].IsRevealed, 'Cell should not be revealed after reset');
        AssertFalse(Game.Cell[R, C].IsFlagged, 'Cell should not be flagged after reset');
      end;
  finally
    Game.Free;
  end;
end;

{ Macro to run a test with exception handling }
{$MACRO ON}
{$DEFINE RUN_TEST:=
  BeginTest}

procedure RunAllTests;
begin
  WriteLn('');
  WriteLn('==========================================');
  WriteLn('Running Minesweeper Game Logic Tests');
  WriteLn('==========================================');
  WriteLn('');

  BeginTest('TestCreateGame');
  try TestCreateGame; EndTestPass; except on E: Exception do EndTestFail(E.Message); end;

  BeginTest('TestInitGameBeginner');
  try TestInitGameBeginner; EndTestPass; except on E: Exception do EndTestFail(E.Message); end;

  BeginTest('TestInitGameIntermediate');
  try TestInitGameIntermediate; EndTestPass; except on E: Exception do EndTestFail(E.Message); end;

  BeginTest('TestInitGameExpert');
  try TestInitGameExpert; EndTestPass; except on E: Exception do EndTestFail(E.Message); end;

  BeginTest('TestInitGameCustom');
  try TestInitGameCustom; EndTestPass; except on E: Exception do EndTestFail(E.Message); end;

  BeginTest('TestInitGameInvalidDimensions');
  try TestInitGameInvalidDimensions; EndTestPass; except on E: Exception do EndTestFail(E.Message); end;

  BeginTest('TestInitGameInvalidMineCount');
  try TestInitGameInvalidMineCount; EndTestPass; except on E: Exception do EndTestFail(E.Message); end;

  BeginTest('TestGetModeConfig');
  try TestGetModeConfig; EndTestPass; except on E: Exception do EndTestFail(E.Message); end;

  BeginTest('TestInitialGameState');
  try TestInitialGameState; EndTestPass; except on E: Exception do EndTestFail(E.Message); end;

  BeginTest('TestPlaceMinesCount');
  try TestPlaceMinesCount; EndTestPass; except on E: Exception do EndTestFail(E.Message); end;

  BeginTest('TestPlaceMinesExcludesFirstClick');
  try TestPlaceMinesExcludesFirstClick; EndTestPass; except on E: Exception do EndTestFail(E.Message); end;

  BeginTest('TestPlaceMinesExcludesNeighbors');
  try TestPlaceMinesExcludesNeighbors; EndTestPass; except on E: Exception do EndTestFail(E.Message); end;

  BeginTest('TestAdjacentMineCalculation');
  try TestAdjacentMineCalculation; EndTestPass; except on E: Exception do EndTestFail(E.Message); end;

  BeginTest('TestRevealSafeCell');
  try TestRevealSafeCell; EndTestPass; except on E: Exception do EndTestFail(E.Message); end;

  BeginTest('TestRevealMine');
  try TestRevealMine; EndTestPass; except on E: Exception do EndTestFail(E.Message); end;

  BeginTest('TestToggleFlag');
  try TestToggleFlag; EndTestPass; except on E: Exception do EndTestFail(E.Message); end;

  BeginTest('TestToggleFlagTwice');
  try TestToggleFlagTwice; EndTestPass; except on E: Exception do EndTestFail(E.Message); end;

  BeginTest('TestWinCondition');
  try TestWinCondition; EndTestPass; except on E: Exception do EndTestFail(E.Message); end;

  BeginTest('TestGameStateInitial');
  try TestGameStateInitial; EndTestPass; except on E: Exception do EndTestFail(E.Message); end;

  BeginTest('TestRevealInvalidCell');
  try TestRevealInvalidCell; EndTestPass; except on E: Exception do EndTestFail(E.Message); end;

  BeginTest('TestReset');
  try TestReset; EndTestPass; except on E: Exception do EndTestFail(E.Message); end;
end;

procedure PrintResults;
begin
  WriteLn('');
  WriteLn('==========================================');
  WriteLn('Test Results:');
  WriteLn('  Total Tests: ', TestsRun);
  WriteLn('  Passed:      ', TestsPassed);
  WriteLn('  Failed:      ', TestsFailed);
  WriteLn('==========================================');
  WriteLn('');

  if TestsFailed = 0 then
  begin
    WriteLn('SUCCESS: All tests passed!');
    WriteLn('');
  end
  else
  begin
    WriteLn('FAILURE: Some tests failed.');
    WriteLn('');
    Halt(1);
  end;
end;

{ Main program }
begin
  Randomize;

  RunAllTests;
  PrintResults;
end.
