program GermanWordle;

uses
  Classes, SysUtils, Crt, StrUtils;

const
  WordLength = 5;
  MaxGuesses = 6;
  WordFileName = 'wordles.txt';

var
  wordList: TStringList;
  secretWord, guess: string;
  guessCount: Integer;
  gameOver: Boolean;

procedure LoadWords;
var
  i: Integer;
begin
  if not FileExists(WordFileName) then
  begin
    WriteLn('Error: ', WordFileName, ' not found.');
    Halt(1);
  end;

  wordList := TStringList.Create;
  wordList.LoadFromFile(WordFileName);

  for i := wordList.Count - 1 downto 0 do
  begin
    if Length(Trim(wordList[i])) <> WordLength then
      wordList.Delete(i);
  end;

  if wordList.Count = 0 then
  begin
    WriteLn('No valid 5-letter words found in ', WordFileName);
    wordList.Free;
    Halt(1);
  end;
end;

procedure SelectRandomWord;
begin
  Randomize;
  secretWord := UpperCase(Trim(wordList[Random(wordList.Count)]));
end;

procedure PrintGuess(guess: string);
var
  i, j: Integer;
  secretCopy: string;
  letterState: array[1..WordLength] of Char; // G=Green, Y=Yellow, X=Gray
begin
  secretCopy := secretWord;

  for i := 1 to WordLength do
    letterState[i] := 'X';

  for i := 1 to WordLength do
  begin
    if guess[i] = secretCopy[i] then
    begin
      letterState[i] := 'G';
      secretCopy[i] := '#';
    end;
  end;

  for i := 1 to WordLength do
  begin
    if letterState[i] <> 'G' then
    begin
      j := Pos(guess[i], secretCopy);
      if j > 0 then
      begin
        letterState[i] := 'Y';
        secretCopy[j] := '#';
      end;
    end;
  end;

  for i := 1 to WordLength do
  begin
    case letterState[i] of
      'G': TextBackground(Green);
      'Y': TextBackground(Yellow);
      'X': TextBackground(LightGray);
    end;
    TextColor(Black);
    Write(guess[i]);
  end;
  TextBackground(Black);
  TextColor(LightGray);
  WriteLn;
end;

procedure ReadGuess(var currentGuess: string);
var
  ch: Char;
begin
  currentGuess := '';
  repeat
    ch := ReadKey;
    if (ch >= 'a') and (ch <= 'z') and (Length(currentGuess) < WordLength) then
    begin
      currentGuess := currentGuess + UpperCase(ch);
      Write(UpperCase(ch));
    end
    else if (ch = #8) and (Length(currentGuess) > 0) then // Backspace
    begin
      Delete(currentGuess, Length(currentGuess), 1);
      Write(#8#32#8);
    end;
  until (ch = #13) and (Length(currentGuess) = WordLength); // Enter key
end;

begin
  ClrScr;
  LoadWords;
  SelectRandomWord;
  guessCount := 0;
  gameOver := False;

  WriteLn('German Wordle! You have ', MaxGuesses, ' guesses.');

  while not gameOver do
  begin
    WriteLn;
    Write('Guess (', guessCount + 1, '/', MaxGuesses, '): ');
    ReadGuess(guess);
    WriteLn;

    Inc(guessCount);
    PrintGuess(guess);

    if guess = secretWord then
    begin
      WriteLn('Congratulations! You guessed the word!');
      gameOver := True;
    end
    else if guessCount >= MaxGuesses then
    begin
      WriteLn('You ran out of guesses. The word was: ', secretWord);
      gameOver := True;
    end;
  end;

  wordList.Free;
end.
