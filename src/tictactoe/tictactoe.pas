program TicTacToe;

uses
  SysUtils, crt;

var
  board: array[1..3, 1..3] of Char;
  currentPlayer: Char;
  gameOver: Boolean;
  winner: Char;
  cursorX, cursorY: Integer;

procedure InitializeBoard;
var
  i, j: Integer;
begin
  for i := 1 to 3 do
    for j := 1 to 3 do
      board[i, j] := ' ';
  cursorX := 1;
  cursorY := 1;
end;

procedure PrintBoard;
var
  i, j: Integer;
begin
  ClrScr;
  WriteLn('-------------');
  for i := 1 to 3 do
  begin
    Write('| ');
    for j := 1 to 3 do
    begin
      if (i = cursorY) and (j = cursorX) then
      begin
        TextBackground(White);
      end
      else
      begin
        TextBackground(Black);
      end;
      Write(board[i, j]);
      TextBackground(Black);
      Write(' | ');
    end;
    WriteLn;
    WriteLn('-------------');
  end;
end;

function IsBoardFull: Boolean;
var
  i, j: Integer;
  isFull: Boolean;
begin
  isFull := True;
  for i := 1 to 3 do
    for j := 1 to 3 do
      if board[i, j] = ' ' then
        isFull := False;
  IsBoardFull := isFull;
end;

function CheckWinner: Char;
var
  i: Integer;
  win: Char;
begin
  win := ' ';
  // Check rows
  for i := 1 to 3 do
    if (board[i, 1] = board[i, 2]) and (board[i, 2] = board[i, 3]) and (board[i, 1] <> ' ') then
      win := board[i, 1];

  // Check columns
  for i := 1 to 3 do
    if (board[1, i] = board[2, i]) and (board[2, i] = board[3, i]) and (board[1, i] <> ' ') then
      win := board[1, i];

  // Check diagonals
  if (board[1, 1] = board[2, 2]) and (board[2, 2] = board[3, 3]) and (board[1, 1] <> ' ') then
    win := board[1, 1];
  if (board[1, 3] = board[2, 2]) and (board[2, 2] = board[3, 1]) and (board[1, 3] <> ' ') then
    win := board[1, 3];
  CheckWinner := win;
end;

procedure GetPlayerMove;
var
  key: Char;
begin
  repeat
    PrintBoard;
    WriteLn('Player ', currentPlayer, ', use arrow keys to move, space/enter to select.');
    key := ReadKey;
    if key = #0 then
    begin
      key := ReadKey;
      case key of
        #72: cursorY := cursorY - 1; // Up
        #80: cursorY := cursorY + 1; // Down
        #75: cursorX := cursorX - 1; // Left
        #77: cursorX := cursorX + 1; // Right
      end;
      if cursorX < 1 then cursorX := 3;
      if cursorX > 3 then cursorX := 1;
      if cursorY < 1 then cursorY := 3;
      if cursorY > 3 then cursorY := 1;
    end;
  until ((key = #32) or (key = #13)) and (board[cursorY, cursorX] = ' ');
  board[cursorY, cursorX] := currentPlayer;
end;

begin
  InitializeBoard;
  currentPlayer := 'X';
  gameOver := False;
  winner := ' ';

  while not gameOver do
  begin
    GetPlayerMove;
    winner := CheckWinner;
    if (winner <> ' ') or IsBoardFull then
      gameOver := True
    else
    if currentPlayer = 'X' then
      currentPlayer := 'O'
    else
      currentPlayer := 'X';
  end;

  PrintBoard;
  if winner <> ' ' then
    WriteLn('Player ', winner, ' wins!')
  else
    WriteLn('It''s a draw!');
end.