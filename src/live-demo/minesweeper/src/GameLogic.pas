unit GameLogic;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, DateUtils;

const
  // Game mode configurations
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

type
  { TGameMode - Enumeration of available game difficulty levels }
  TGameMode = (gmBeginner, gmIntermediate, gmExpert);

  { TGameState - Current state of the game }
  TGameState = (gsNotStarted, gsPlaying, gsWon, gsLost);

  { TCell - Represents a single cell in the minesweeper grid }
  TCell = record
    HasMine: Boolean;       // True if this cell contains a mine
    IsRevealed: Boolean;    // True if this cell has been revealed
    IsFlagged: Boolean;     // True if this cell has been flagged by player
    AdjacentMines: Integer; // Number of mines in adjacent cells (0-8)
  end;

  { TModeConfig - Configuration for a game mode }
  TModeConfig = record
    Rows: Integer;
    Cols: Integer;
    MinMines: Integer;
    MaxMines: Integer;
  end;

  { TGameData - Main game logic class, completely GUI-independent }
  TGameData = class
  private
    FGrid: array of array of TCell;
    FRows: Integer;
    FCols: Integer;
    FMineCount: Integer;
    FGameState: TGameState;
    FStartTime: TDateTime;
    FEndTime: TDateTime;
    FFirstClickMade: Boolean;
    FRevealedCount: Integer;

    function GetCell(ARow, ACol: Integer): TCell;
    function GetElapsedSeconds: Integer;
    function IsValidCell(ARow, ACol: Integer): Boolean;
    function CountAdjacentMines(ARow, ACol: Integer): Integer;
    procedure CalculateAllAdjacentMines;
    procedure FloodReveal(ARow, ACol: Integer);
    procedure CheckWinCondition;

  public
    constructor Create;
    destructor Destroy; override;

    { Initialize a new game with the specified mode }
    procedure InitGame(AMode: TGameMode); overload;

    { Initialize a new game with custom dimensions and mine count }
    procedure InitGame(ARows, ACols, AMines: Integer); overload;

    { Place mines on the board, excluding the first click position and its neighbors }
    procedure PlaceMines(AFirstClickRow, AFirstClickCol: Integer);

    { Reveal a cell at the specified position. Returns True if a mine was hit. }
    function RevealCell(ARow, ACol: Integer): Boolean;

    { Toggle the flag state of a cell }
    procedure ToggleFlag(ARow, ACol: Integer);

    { Get configuration for a specific game mode }
    class function GetModeConfig(AMode: TGameMode): TModeConfig;

    { Reset the game to initial state }
    procedure Reset;

    { Properties }
    property Rows: Integer read FRows;
    property Cols: Integer read FCols;
    property MineCount: Integer read FMineCount;
    property GameState: TGameState read FGameState;
    property ElapsedSeconds: Integer read GetElapsedSeconds;
    property Cell[ARow, ACol: Integer]: TCell read GetCell;
    property RevealedCount: Integer read FRevealedCount;
  end;

implementation

{ TGameData }

constructor TGameData.Create;
begin
  inherited Create;
  FRows := 0;
  FCols := 0;
  FMineCount := 0;
  FGameState := gsNotStarted;
  FFirstClickMade := False;
  FRevealedCount := 0;
end;

destructor TGameData.Destroy;
begin
  SetLength(FGrid, 0);
  inherited Destroy;
end;

class function TGameData.GetModeConfig(AMode: TGameMode): TModeConfig;
begin
  case AMode of
    gmBeginner:
      begin
        Result.Rows := BEGINNER_ROWS;
        Result.Cols := BEGINNER_COLS;
        Result.MinMines := BEGINNER_MIN_MINES;
        Result.MaxMines := BEGINNER_MAX_MINES;
      end;
    gmIntermediate:
      begin
        Result.Rows := INTERMEDIATE_ROWS;
        Result.Cols := INTERMEDIATE_COLS;
        Result.MinMines := INTERMEDIATE_MIN_MINES;
        Result.MaxMines := INTERMEDIATE_MAX_MINES;
      end;
    gmExpert:
      begin
        Result.Rows := EXPERT_ROWS;
        Result.Cols := EXPERT_COLS;
        Result.MinMines := EXPERT_MIN_MINES;
        Result.MaxMines := EXPERT_MAX_MINES;
      end;
  end;
end;

procedure TGameData.InitGame(AMode: TGameMode);
var
  Config: TModeConfig;
  NumMines: Integer;
begin
  Config := GetModeConfig(AMode);
  // Randomize mine count within the range for this mode
  NumMines := Config.MinMines + Random(Config.MaxMines - Config.MinMines + 1);
  InitGame(Config.Rows, Config.Cols, NumMines);
end;

procedure TGameData.InitGame(ARows, ACols, AMines: Integer);
var
  I, J: Integer;
begin
  // Validate input parameters
  if (ARows <= 0) or (ACols <= 0) then
    raise Exception.Create('Board dimensions must be positive');
  if (AMines < 0) or (AMines >= ARows * ACols) then
    raise Exception.Create('Invalid mine count');

  FRows := ARows;
  FCols := ACols;
  FMineCount := AMines;
  FGameState := gsNotStarted;
  FFirstClickMade := False;
  FRevealedCount := 0;

  // Initialize grid
  SetLength(FGrid, FRows, FCols);
  for I := 0 to FRows - 1 do
    for J := 0 to FCols - 1 do
    begin
      FGrid[I][J].HasMine := False;
      FGrid[I][J].IsRevealed := False;
      FGrid[I][J].IsFlagged := False;
      FGrid[I][J].AdjacentMines := 0;
    end;
end;

procedure TGameData.Reset;
var
  I, J: Integer;
begin
  FGameState := gsNotStarted;
  FFirstClickMade := False;
  FRevealedCount := 0;

  for I := 0 to FRows - 1 do
    for J := 0 to FCols - 1 do
    begin
      FGrid[I][J].HasMine := False;
      FGrid[I][J].IsRevealed := False;
      FGrid[I][J].IsFlagged := False;
      FGrid[I][J].AdjacentMines := 0;
    end;
end;

function TGameData.IsValidCell(ARow, ACol: Integer): Boolean;
begin
  Result := (ARow >= 0) and (ARow < FRows) and (ACol >= 0) and (ACol < FCols);
end;

function TGameData.GetCell(ARow, ACol: Integer): TCell;
begin
  if not IsValidCell(ARow, ACol) then
    raise Exception.CreateFmt('Cell position out of bounds: (%d, %d)', [ARow, ACol]);
  Result := FGrid[ARow][ACol];
end;

function TGameData.GetElapsedSeconds: Integer;
var
  EndTime: TDateTime;
begin
  if FGameState = gsNotStarted then
    Result := 0
  else if (FGameState = gsWon) or (FGameState = gsLost) then
    Result := SecondsBetween(FEndTime, FStartTime)
  else
    Result := SecondsBetween(Now, FStartTime);
end;

procedure TGameData.PlaceMines(AFirstClickRow, AFirstClickCol: Integer);
var
  PlacedMines: Integer;
  Row, Col: Integer;
  DR, DC: Integer;
  ExcludedCells: array of record R, C: Integer; end;
  ExcludeCount: Integer;
  I: Integer;
  IsExcluded: Boolean;
begin
  if not IsValidCell(AFirstClickRow, AFirstClickCol) then
    raise Exception.Create('First click position out of bounds');

  // Build list of excluded cells (first click and its 8 neighbors)
  ExcludeCount := 0;
  SetLength(ExcludedCells, 9);

  for DR := -1 to 1 do
    for DC := -1 to 1 do
    begin
      Row := AFirstClickRow + DR;
      Col := AFirstClickCol + DC;
      if IsValidCell(Row, Col) then
      begin
        ExcludedCells[ExcludeCount].R := Row;
        ExcludedCells[ExcludeCount].C := Col;
        Inc(ExcludeCount);
      end;
    end;

  // Place mines randomly, excluding the first click area
  PlacedMines := 0;
  while PlacedMines < FMineCount do
  begin
    Row := Random(FRows);
    Col := Random(FCols);

    // Check if this cell already has a mine
    if FGrid[Row][Col].HasMine then
      Continue;

    // Check if this cell is excluded
    IsExcluded := False;
    for I := 0 to ExcludeCount - 1 do
      if (ExcludedCells[I].R = Row) and (ExcludedCells[I].C = Col) then
      begin
        IsExcluded := True;
        Break;
      end;

    if not IsExcluded then
    begin
      FGrid[Row][Col].HasMine := True;
      Inc(PlacedMines);
    end;
  end;

  // Calculate adjacent mine counts
  CalculateAllAdjacentMines;

  // Game is now started
  FGameState := gsPlaying;
  FFirstClickMade := True;
  FStartTime := Now;
end;

function TGameData.CountAdjacentMines(ARow, ACol: Integer): Integer;
var
  DR, DC: Integer;
  NRow, NCol: Integer;
  Count: Integer;
begin
  Count := 0;

  for DR := -1 to 1 do
    for DC := -1 to 1 do
    begin
      // Skip the center cell
      if (DR = 0) and (DC = 0) then
        Continue;

      NRow := ARow + DR;
      NCol := ACol + DC;

      if IsValidCell(NRow, NCol) and FGrid[NRow][NCol].HasMine then
        Inc(Count);
    end;

  Result := Count;
end;

procedure TGameData.CalculateAllAdjacentMines;
var
  I, J: Integer;
begin
  for I := 0 to FRows - 1 do
    for J := 0 to FCols - 1 do
      if not FGrid[I][J].HasMine then
        FGrid[I][J].AdjacentMines := CountAdjacentMines(I, J);
end;

procedure TGameData.FloodReveal(ARow, ACol: Integer);
var
  DR, DC: Integer;
  NRow, NCol: Integer;
begin
  if not IsValidCell(ARow, ACol) then
    Exit;

  // Don't reveal if already revealed or flagged
  if FGrid[ARow][ACol].IsRevealed or FGrid[ARow][ACol].IsFlagged then
    Exit;

  // Don't reveal mines during flood
  if FGrid[ARow][ACol].HasMine then
    Exit;

  // Reveal this cell
  FGrid[ARow][ACol].IsRevealed := True;
  Inc(FRevealedCount);

  // If this cell has adjacent mines, stop flooding
  if FGrid[ARow][ACol].AdjacentMines > 0 then
    Exit;

  // Recursively reveal all 8 neighbors
  for DR := -1 to 1 do
    for DC := -1 to 1 do
    begin
      if (DR = 0) and (DC = 0) then
        Continue;

      NRow := ARow + DR;
      NCol := ACol + DC;

      FloodReveal(NRow, NCol);
    end;
end;

function TGameData.RevealCell(ARow, ACol: Integer): Boolean;
begin
  Result := False;

  // Validate position
  if not IsValidCell(ARow, ACol) then
    Exit;

  // Can't reveal if game is over
  if (FGameState = gsWon) or (FGameState = gsLost) then
    Exit;

  // Can't reveal flagged cells
  if FGrid[ARow][ACol].IsFlagged then
    Exit;

  // Can't reveal already revealed cells
  if FGrid[ARow][ACol].IsRevealed then
    Exit;

  // If this is the first click, place mines first
  if not FFirstClickMade then
    PlaceMines(ARow, ACol);

  // Check if this cell has a mine
  if FGrid[ARow][ACol].HasMine then
  begin
    FGrid[ARow][ACol].IsRevealed := True;
    FGameState := gsLost;
    FEndTime := Now;
    Result := True;
    Exit;
  end;

  // Reveal the cell (and potentially flood reveal)
  FloodReveal(ARow, ACol);

  // Check for win condition
  CheckWinCondition;
end;

procedure TGameData.ToggleFlag(ARow, ACol: Integer);
begin
  // Validate position
  if not IsValidCell(ARow, ACol) then
    Exit;

  // Can't flag if game is over
  if (FGameState = gsWon) or (FGameState = gsLost) then
    Exit;

  // Can't flag revealed cells
  if FGrid[ARow][ACol].IsRevealed then
    Exit;

  // Toggle flag state
  FGrid[ARow][ACol].IsFlagged := not FGrid[ARow][ACol].IsFlagged;

  // Check for win condition (in case all non-mine cells are revealed)
  CheckWinCondition;
end;

procedure TGameData.CheckWinCondition;
var
  TotalCells: Integer;
  SafeCells: Integer;
begin
  // Can only win if game is in progress
  if FGameState <> gsPlaying then
    Exit;

  TotalCells := FRows * FCols;
  SafeCells := TotalCells - FMineCount;

  // Win condition: all non-mine cells are revealed
  if FRevealedCount >= SafeCells then
  begin
    FGameState := gsWon;
    FEndTime := Now;
  end;
end;

end.
