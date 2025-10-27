program example_usage;

{$mode objfpc}{$H+}

uses
  SysUtils, game_logic;

var
  game: TGameData;
  x, y: Integer;
  cell: TCell;

begin
  WriteLn('=== Minesweeper Game Logic Example ===');
  WriteLn('');

  // Initialize random number generator
  Randomize;

  // Create game instance
  game := TGameData.Create;
  try
    // Initialize a beginner game (9x9 with 8-12 mines)
    WriteLn('Initializing beginner game...');
    game.InitGame(gmBeginner);
    WriteLn('Board size: ', game.Rows, 'x', game.Cols);
    WriteLn('Mines: ', game.Mines);
    WriteLn('');

    // Simulate first click (this will place mines avoiding this position)
    WriteLn('First click at (4, 4)...');
    if game.RevealCell(4, 4) then
      WriteLn('Safe cell revealed!')
    else
      WriteLn('Hit a mine! (This should never happen on first click)');
    WriteLn('Revealed cells: ', game.RevealedCount);
    WriteLn('');

    // Flag a suspected mine
    WriteLn('Flagging cell (0, 0)...');
    game.ToggleFlag(0, 0);
    cell := game.GetCell(0, 0);
    WriteLn('Cell (0, 0) is flagged: ', cell.IsFlagged);
    WriteLn('');

    // Check a cell's properties
    cell := game.GetCell(4, 4);
    WriteLn('Cell (4, 4) properties:');
    WriteLn('  Is Mine: ', cell.IsMine);
    WriteLn('  Is Revealed: ', cell.IsRevealed);
    WriteLn('  Is Flagged: ', cell.IsFlagged);
    WriteLn('  Adjacent Mines: ', cell.AdjacentMines);
    WriteLn('');

    // Display game state
    WriteLn('Game state:');
    WriteLn('  Game Won: ', game.GameWon);
    WriteLn('  Game Lost: ', game.GameLost);
    WriteLn('  Elapsed Time: ', game.GetElapsedTime, ' seconds');
    WriteLn('');

    // Display a simple text representation of part of the board
    WriteLn('Board visualization (top-left 5x5 section):');
    WriteLn('Legend: . = unrevealed, F = flagged, X = mine, 0-8 = adjacent count');
    WriteLn('');
    for x := 0 to 4 do
    begin
      for y := 0 to 4 do
      begin
        cell := game.GetCell(x, y);
        if cell.IsFlagged then
          Write('F ')
        else if not cell.IsRevealed then
          Write('. ')
        else if cell.IsMine then
          Write('X ')
        else
          Write(cell.AdjacentMines, ' ');
      end;
      WriteLn;
    end;
    WriteLn('');

    WriteLn('Example completed successfully!');
  finally
    game.Free;
  end;
end.
