unit uBoard;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Math;

type
  TCell = record
    hasMine: Boolean;
    revealed: Boolean;
    flagged: Boolean;
    adjacent: Byte;
  end;

  { TBoard }

  TBoard = class
  private
    FWidth, FHeight, FMines: Integer;
    FGrid: array of TCell;
    FRevealedCount: Integer;
    FGameOver: Boolean;
    FWin: Boolean;
    function IndexOf(x, y: Integer): SizeInt; inline;
    function InBounds(x, y: Integer): Boolean; inline;
    procedure ComputeAdjacency;
    procedure FloodReveal(x, y: Integer);
  public
    constructor Create(aWidth, aHeight, aMines: Integer);
    procedure Clear;
    procedure GenerateWithSeed(aSeed: QWord);
    function CellAt(x, y: Integer): TCell; inline;
    function Reveal(x, y: Integer): Boolean; // returns True if hit a mine
    procedure ToggleFlag(x, y: Integer);
    function InGame: Boolean; inline;
    property GameOver: Boolean read FGameOver;
    property Win: Boolean read FWin;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property Mines: Integer read FMines;
  end;

implementation

constructor TBoard.Create(aWidth, aHeight, aMines: Integer);
begin
  if (aWidth <= 0) or (aHeight <= 0) then
    raise EArgumentException.Create('Board size must be positive');
  if (aMines < 0) or (aMines >= aWidth * aHeight) then
    raise EArgumentException.Create('Invalid mine count');
  FWidth := aWidth;
  FHeight := aHeight;
  FMines := aMines;
  SetLength(FGrid, FWidth * FHeight);
  Clear;
end;

procedure TBoard.Clear;
var
  i: SizeInt;
begin
  for i := 0 to High(FGrid) do
  begin
    FGrid[i].hasMine := False;
    FGrid[i].revealed := False;
    FGrid[i].flagged := False;
    FGrid[i].adjacent := 0;
  end;
  FRevealedCount := 0;
  FGameOver := False;
  FWin := False;
end;

function TBoard.IndexOf(x, y: Integer): SizeInt;
begin
  Result := y * FWidth + x;
end;

function TBoard.InBounds(x, y: Integer): Boolean;
begin
  Result := (x >= 0) and (y >= 0) and (x < FWidth) and (y < FHeight);
end;

procedure TBoard.ComputeAdjacency;
var
  x, y, dx, dy, nx, ny: Integer;
  count: Byte;
begin
  for y := 0 to FHeight - 1 do
    for x := 0 to FWidth - 1 do
    begin
      if FGrid[IndexOf(x, y)].hasMine then
      begin
        FGrid[IndexOf(x, y)].adjacent := 255; // marker for mines
        Continue;
      end;
      count := 0;
      for dy := -1 to 1 do
        for dx := -1 to 1 do
        begin
          if (dx = 0) and (dy = 0) then Continue;
          nx := x + dx; ny := y + dy;
          if InBounds(nx, ny) and FGrid[IndexOf(nx, ny)].hasMine then
            Inc(count);
        end;
      FGrid[IndexOf(x, y)].adjacent := count;
    end;
end;

procedure TBoard.GenerateWithSeed(aSeed: QWord);
var
  placed, i, p, total: SizeInt;
  idxs: array of SizeInt;
begin
  Clear;
  RandSeed := aSeed;
  total := FWidth * FHeight;
  SetLength(idxs, total);
  for i := 0 to total - 1 do idxs[i] := i;
  // Fisher-Yates shuffle
  for i := total - 1 downto 1 do
  begin
    p := Random(i + 1);
    if p <> i then
    begin
      idxs[i] := idxs[i] xor idxs[p];
      idxs[p] := idxs[i] xor idxs[p];
      idxs[i] := idxs[i] xor idxs[p];
    end;
  end;
  for placed := 0 to FMines - 1 do
    FGrid[idxs[placed]].hasMine := True;
  ComputeAdjacency;
end;

function TBoard.CellAt(x, y: Integer): TCell;
begin
  if not InBounds(x, y) then
    raise ERangeError.Create('Cell out of bounds');
  Result := FGrid[IndexOf(x, y)];
end;

function TBoard.InGame: Boolean;
begin
  Result := not FGameOver;
end;

procedure TBoard.FloodReveal(x, y: Integer);
var
  dx, dy, nx, ny: Integer;
  idx: SizeInt;
begin
  if not InBounds(x, y) then Exit;
  idx := IndexOf(x, y);
  if FGrid[idx].revealed or FGrid[idx].flagged then Exit;
  FGrid[idx].revealed := True;
  Inc(FRevealedCount);
  if FGrid[idx].adjacent <> 0 then Exit;
  for dy := -1 to 1 do
    for dx := -1 to 1 do
    begin
      if (dx = 0) and (dy = 0) then Continue;
      nx := x + dx; ny := y + dy;
      if InBounds(nx, ny) then
        FloodReveal(nx, ny);
    end;
end;

function TBoard.Reveal(x, y: Integer): Boolean;
var
  idx: SizeInt;
  totalSafe: Integer;
begin
  Result := False;
  if FGameOver then Exit;
  if not InBounds(x, y) then Exit;
  idx := IndexOf(x, y);
  if FGrid[idx].flagged or FGrid[idx].revealed then Exit;
  if FGrid[idx].hasMine then
  begin
    FGrid[idx].revealed := True;
    FGameOver := True;
    Result := True;
    Exit;
  end;
  FloodReveal(x, y);
  totalSafe := FWidth * FHeight - FMines;
  if FRevealedCount >= totalSafe then
  begin
    FWin := True;
    FGameOver := True;
  end;
end;

procedure TBoard.ToggleFlag(x, y: Integer);
var
  idx: SizeInt;
begin
  if FGameOver then Exit;
  if not InBounds(x, y) then Exit;
  idx := IndexOf(x, y);
  if FGrid[idx].revealed then Exit;
  FGrid[idx].flagged := not FGrid[idx].flagged;
end;

end.
