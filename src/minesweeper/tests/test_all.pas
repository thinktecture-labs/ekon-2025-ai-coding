program test_all;

{$mode objfpc}{$H+}

uses
  fpcunit, testutils, testregistry, consoletestrunner, uBoard;

type
  TBoardTests = class(TTestCase)
  published
    procedure TestCreateSize;
    procedure TestMinePlacementCount;
    procedure TestAdjacencyNonMineCells;
  end;

procedure TBoardTests.TestCreateSize;
var
  b: TBoard;
begin
  b := TBoard.Create(9, 9, 10);
  try
    AssertEquals(9, b.Width);
    AssertEquals(9, b.Height);
    AssertEquals(10, b.Mines);
  finally
    b.Free;
  end;
end;

procedure TBoardTests.TestMinePlacementCount;
var
  b: TBoard;
  x, y, mines: Integer;
begin
  b := TBoard.Create(8, 8, 12);
  try
    b.GenerateWithSeed(12345);
    mines := 0;
    for y := 0 to b.Height - 1 do
      for x := 0 to b.Width - 1 do
        if b.CellAt(x, y).hasMine then Inc(mines);
    AssertEquals(12, mines);
  finally
    b.Free;
  end;
end;

procedure TBoardTests.TestAdjacencyNonMineCells;
var
  b: TBoard;
  x, y: Integer;
begin
  b := TBoard.Create(5, 5, 5);
  try
    b.GenerateWithSeed(1);
    for y := 0 to b.Height - 1 do
      for x := 0 to b.Width - 1 do
        if not b.CellAt(x, y).hasMine then
          AssertTrue('adjacent <= 8', b.CellAt(x, y).adjacent <= 8);
  finally
    b.Free;
  end;
end;

var
  Runner: TTestRunner;
begin
  RegisterTest(TBoardTests);
  Runner := TTestRunner.Create(nil);
  try
    Runner.Initialize;
    Runner.Run;
  finally
    Runner.Free;
  end;
end.
