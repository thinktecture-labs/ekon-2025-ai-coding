unit game_logic;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, DateUtils, Math;

type
  { Game mode enumeration }
  TGameMode = (gmBeginner, gmIntermediate, gmExpert);

  { Cell record - represents a single cell on the board }
  TCell = record
    IsMine: Boolean;           // True if cell contains a mine
    IsRevealed: Boolean;       // True if cell has been revealed
    IsFlagged: Boolean;        // True if cell is flagged by player
    AdjacentMines: Integer;    // Count of adjacent mines (0-8)
  end;

  { TGameData - Regular Pascal class for game logic (GUI-independent) }
  TGameData = class
  private
    FGrid: array of array of TCell;  // Dynamic 2D array for board
    FRows: Integer;                   // Number of rows
    FCols: Integer;                   // Number of columns
    FMines: Integer;                  // Total number of mines
    FGameWon: Boolean;                // True if player won
    FGameLost: Boolean;               // True if player lost
    FRevealedCount: Integer;          // Number of revealed non-mine cells
    FStartTime: TDateTime;            // Game start time
    FMinesPlaced: Boolean;            // True if mines have been placed

    { Check if coordinates are within bounds }
    function InBounds(AX, AY: Integer): Boolean;

    { Recursively reveal adjacent cells with no adjacent mines }
    procedure FloodReveal(AX, AY: Integer);

    { Count adjacent mines for a given cell }
    function CountAdjacentMines(AX, AY: Integer): Integer;

  public
    constructor Create;
    destructor Destroy; override;

    { Initialize game board based on game mode }
    procedure InitGame(AMode: TGameMode);

    { Place mines randomly, ensuring first click position and neighbors are safe }
    procedure PlaceMines(ACount: Integer; AFirstX, AFirstY: Integer);

    { Calculate adjacent mine counts for all cells }
    procedure CalculateAdjacentMines;

    { Reveal a cell - returns True if successful, False if mine hit }
    function RevealCell(AX, AY: Integer): Boolean;

    { Toggle flag on a cell }
    procedure ToggleFlag(AX, AY: Integer);

    { Get cell at specified position }
    function GetCell(AX, AY: Integer): TCell;

    { Check if win condition is met }
    function CheckWinCondition: Boolean;

    { Get elapsed time in seconds since game start }
    function GetElapsedTime: Integer;

    { Reset game state }
    procedure ResetGame;

    { Properties }
    property Rows: Integer read FRows;
    property Cols: Integer read FCols;
    property Mines: Integer read FMines;
    property GameWon: Boolean read FGameWon;
    property GameLost: Boolean read FGameLost;
    property RevealedCount: Integer read FRevealedCount;
    property MinesPlaced: Boolean read FMinesPlaced;
  end;

implementation

{ TGameData }

constructor TGameData.Create;
begin
  inherited Create;
  FRows := 0;
  FCols := 0;
  FMines := 0;
  FGameWon := False;
  FGameLost := False;
  FRevealedCount := 0;
  FStartTime := Now;
  FMinesPlaced := False;
end;

destructor TGameData.Destroy;
begin
  SetLength(FGrid, 0, 0);
  inherited Destroy;
end;

procedure TGameData.InitGame(AMode: TGameMode);
var
  i, j: Integer;
  minMines, maxMines: Integer;
begin
  // Set dimensions and mine counts based on game mode
  case AMode of
    gmBeginner:
      begin
        FRows := 9;
        FCols := 9;
        minMines := 8;
        maxMines := 12;
        FMines := minMines + Random(maxMines - minMines + 1);
      end;
    gmIntermediate:
      begin
        FRows := 16;
        FCols := 16;
        minMines := 30;
        maxMines := 50;
        FMines := minMines + Random(maxMines - minMines + 1);
      end;
    gmExpert:
      begin
        FRows := 30;
        FCols := 16;
        // Higher mine density for expert: 70-99 mines
        minMines := 70;
        maxMines := 99;
        FMines := minMines + Random(maxMines - minMines + 1);
      end;
  end;

  // Allocate grid
  SetLength(FGrid, FRows, FCols);

  // Initialize all cells
  for i := 0 to FRows - 1 do
    for j := 0 to FCols - 1 do
    begin
      FGrid[i, j].IsMine := False;
      FGrid[i, j].IsRevealed := False;
      FGrid[i, j].IsFlagged := False;
      FGrid[i, j].AdjacentMines := 0;
    end;

  // Reset game state
  FGameWon := False;
  FGameLost := False;
  FRevealedCount := 0;
  FStartTime := Now;
  FMinesPlaced := False;
end;

procedure TGameData.PlaceMines(ACount: Integer; AFirstX, AFirstY: Integer);
var
  placed: Integer;
  row, col: Integer;
  dx, dy: Integer;
  isSafe: Boolean;
begin
  if FMinesPlaced then
    Exit; // Mines already placed

  placed := 0;
  while placed < ACount do
  begin
    // Generate random position
    row := Random(FRows);
    col := Random(FCols);

    // Skip if already has mine
    if FGrid[row, col].IsMine then
      Continue;

    // Check if this position is safe (not first click or adjacent to it)
    isSafe := True;
    for dx := -1 to 1 do
      for dy := -1 to 1 do
      begin
        if (row + dx = AFirstX) and (col + dy = AFirstY) then
        begin
          isSafe := False;
          Break;
        end;
      end;

    if not isSafe then
      Continue;

    // Place mine
    FGrid[row, col].IsMine := True;
    Inc(placed);
  end;

  FMinesPlaced := True;
end;

procedure TGameData.CalculateAdjacentMines;
var
  i, j: Integer;
begin
  for i := 0 to FRows - 1 do
    for j := 0 to FCols - 1 do
    begin
      if not FGrid[i, j].IsMine then
        FGrid[i, j].AdjacentMines := CountAdjacentMines(i, j)
      else
        FGrid[i, j].AdjacentMines := 0; // Mines don't need adjacent count
    end;
end;

function TGameData.InBounds(AX, AY: Integer): Boolean;
begin
  Result := (AX >= 0) and (AX < FRows) and (AY >= 0) and (AY < FCols);
end;

function TGameData.CountAdjacentMines(AX, AY: Integer): Integer;
var
  count: Integer;
  dx, dy: Integer;
  nx, ny: Integer;
begin
  count := 0;

  // Check all 8 adjacent cells
  for dx := -1 to 1 do
    for dy := -1 to 1 do
    begin
      // Skip center cell
      if (dx = 0) and (dy = 0) then
        Continue;

      nx := AX + dx;
      ny := AY + dy;

      // Check if neighbor is in bounds and has mine
      if InBounds(nx, ny) and FGrid[nx, ny].IsMine then
        Inc(count);
    end;

  Result := count;
end;

procedure TGameData.FloodReveal(AX, AY: Integer);
var
  dx, dy: Integer;
  nx, ny: Integer;
begin
  // Check bounds
  if not InBounds(AX, AY) then
    Exit;

  // Skip if already revealed or flagged
  if FGrid[AX, AY].IsRevealed or FGrid[AX, AY].IsFlagged then
    Exit;

  // Skip if it's a mine
  if FGrid[AX, AY].IsMine then
    Exit;

  // Reveal this cell
  FGrid[AX, AY].IsRevealed := True;
  Inc(FRevealedCount);

  // If cell has adjacent mines, don't continue flood
  if FGrid[AX, AY].AdjacentMines > 0 then
    Exit;

  // Recursively reveal all 8 adjacent cells
  for dx := -1 to 1 do
    for dy := -1 to 1 do
    begin
      if (dx = 0) and (dy = 0) then
        Continue;

      nx := AX + dx;
      ny := AY + dy;

      if InBounds(nx, ny) then
        FloodReveal(nx, ny);
    end;
end;

function TGameData.RevealCell(AX, AY: Integer): Boolean;
begin
  Result := False;

  // Check bounds
  if not InBounds(AX, AY) then
    Exit;

  // Can't reveal if game is over
  if FGameWon or FGameLost then
    Exit;

  // Skip if already revealed
  if FGrid[AX, AY].IsRevealed then
  begin
    Result := True;
    Exit;
  end;

  // Skip if flagged
  if FGrid[AX, AY].IsFlagged then
  begin
    Result := True;
    Exit;
  end;

  // Place mines on first click
  if not FMinesPlaced then
  begin
    PlaceMines(FMines, AX, AY);
    CalculateAdjacentMines;
  end;

  // Check if it's a mine
  if FGrid[AX, AY].IsMine then
  begin
    FGrid[AX, AY].IsRevealed := True;
    FGameLost := True;
    Result := False;
    Exit;
  end;

  // Reveal cell(s)
  if FGrid[AX, AY].AdjacentMines = 0 then
    FloodReveal(AX, AY)
  else
  begin
    FGrid[AX, AY].IsRevealed := True;
    Inc(FRevealedCount);
  end;

  // Check win condition
  CheckWinCondition;

  Result := True;
end;

procedure TGameData.ToggleFlag(AX, AY: Integer);
begin
  // Check bounds
  if not InBounds(AX, AY) then
    Exit;

  // Can't flag if game is over
  if FGameWon or FGameLost then
    Exit;

  // Can't flag revealed cells
  if FGrid[AX, AY].IsRevealed then
    Exit;

  // Toggle flag
  FGrid[AX, AY].IsFlagged := not FGrid[AX, AY].IsFlagged;

  // Check win condition (in case all mines are correctly flagged)
  CheckWinCondition;
end;

function TGameData.GetCell(AX, AY: Integer): TCell;
begin
  if not InBounds(AX, AY) then
  begin
    // Return empty cell for out of bounds
    Result.IsMine := False;
    Result.IsRevealed := False;
    Result.IsFlagged := False;
    Result.AdjacentMines := 0;
  end
  else
    Result := FGrid[AX, AY];
end;

function TGameData.CheckWinCondition: Boolean;
var
  totalCells: Integer;
  safeCells: Integer;
begin
  Result := False;

  // Can't win if game is already lost
  if FGameLost then
    Exit;

  // Calculate total safe cells (non-mine cells)
  totalCells := FRows * FCols;
  safeCells := totalCells - FMines;

  // Win condition: all safe cells are revealed
  if FRevealedCount >= safeCells then
  begin
    FGameWon := True;
    Result := True;
    Exit;
  end;

  // Alternative win condition: all mines correctly flagged and no false flags
  // This is more restrictive but some implementations use it
  {
  flaggedMines := 0;
  totalFlags := 0;
  for i := 0 to FRows - 1 do
    for j := 0 to FCols - 1 do
    begin
      if FGrid[i, j].IsFlagged then
      begin
        Inc(totalFlags);
        if FGrid[i, j].IsMine then
          Inc(flaggedMines);
      end;
    end;

  if (flaggedMines = FMines) and (totalFlags = FMines) then
  begin
    FGameWon := True;
    Result := True;
  end;
  }
end;

function TGameData.GetElapsedTime: Integer;
begin
  Result := SecondsBetween(Now, FStartTime);
end;

procedure TGameData.ResetGame;
begin
  SetLength(FGrid, 0, 0);
  FRows := 0;
  FCols := 0;
  FMines := 0;
  FGameWon := False;
  FGameLost := False;
  FRevealedCount := 0;
  FStartTime := Now;
  FMinesPlaced := False;
end;

end.
