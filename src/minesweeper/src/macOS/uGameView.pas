unit uGameView;

{$mode objfpc}{$H+}
{$modeswitch objectivec2}

interface

uses
  CocoaAll, SysUtils, uBoard;

type
  { TMinesweeperView }
  TMinesweeperView = objcclass(NSView)
  private
    FBoard: TBoard;
    FCellSize: Double;
    procedure UpdateWindowTitle; message 'UpdateWindowTitle';
  public
    function initWithFrame(frameRect: NSRect): id; override; message 'initWithFrame:';
    procedure dealloc; override; message 'dealloc';
    procedure drawRect(dirtyRect: NSRect); override; message 'drawRect:';
    procedure mouseDown(event: NSEvent); override; message 'mouseDown:';
    procedure rightMouseDown(event: NSEvent); override; message 'rightMouseDown:';
    procedure NewGame; message 'NewGame';
  end;

implementation

function TMinesweeperView.initWithFrame(frameRect: NSRect): id;
var
  seed: QWord;
  nowSec: Double;
begin
  Result := inherited initWithFrame(frameRect);
  if Result <> nil then
  begin
    FCellSize := 28;
    FBoard := TBoard.Create(9, 9, 10);
    nowSec := NSDate.date.timeIntervalSince1970;
    if nowSec < 0 then nowSec := 0;
    seed := QWord(Trunc(nowSec * 1000.0));
    FBoard.GenerateWithSeed(seed);
    self.setPostsFrameChangedNotifications(True);
    self.setWantsBestResolutionOpenGLSurface(False);
    UpdateWindowTitle;
  end;
end;

procedure TMinesweeperView.UpdateWindowTitle;
var
  title: NSString;
begin
  if FBoard.GameOver then
  begin
    if FBoard.Win then
      title := NSSTR('Minesweeper - You Win!')
    else
      title := NSSTR('Minesweeper - Game Over');
  end
  else
    title := NSSTR('Minesweeper');
  if self.window <> nil then
    self.window.setTitle(title);
end;

procedure TMinesweeperView.dealloc;
begin
  if Assigned(FBoard) then FBoard.Free;
  inherited dealloc;
end;

procedure TMinesweeperView.drawRect(dirtyRect: NSRect);
var
  ctx: NSGraphicsContext;
  x, y: Integer;
  r: NSRect;
  cell: TCell;
  txt: NSString;
  attrs: NSDictionary;
  color: NSColor;
begin
  ctx := NSGraphicsContext.currentContext;
  // Background
  NSColor.windowBackgroundColor.setFill;
  NSBezierPath.fillRect(self.bounds);

  // Draw cells
  for y := 0 to FBoard.Height - 1 do
    for x := 0 to FBoard.Width - 1 do
    begin
      r := NSMakeRect(x * FCellSize, y * FCellSize, FCellSize-1, FCellSize-1);
      cell := FBoard.CellAt(x, y);
      if not cell.revealed then
      begin
        if cell.flagged then
          color := NSColor.orangeColor
        else
          color := NSColor.lightGrayColor; // unrevealed
      end
      else
      begin
        if cell.hasMine then
          color := NSColor.redColor
        else if cell.adjacent = 0 then
          color := NSColor.colorWithCalibratedWhite_alpha(0.92, 1.0) // revealed empty area
        else
          color := NSColor.whiteColor; // revealed numbered
      end;
      color.setFill;
      NSBezierPath.fillRect(r);

      // Border
      NSColor.gridColor.setStroke;
      NSBezierPath.strokeRect(r);

      // Number
      if cell.revealed and (not cell.hasMine) and (cell.adjacent > 0) then
      begin
        txt := NSString.stringWithUTF8String(PChar(IntToStr(cell.adjacent)));
        // Simple centered draw
        r.origin.x := r.origin.x + (FCellSize/2 - 4);
        r.origin.y := r.origin.y + (FCellSize/2 - 7);
        r.size.width := 12; r.size.height := 14;
        txt.drawInRect_withAttributes(r, nil);
      end;
    end;

  // Game over / win overlay
  if FBoard.GameOver then
  begin
    NSColor.colorWithCalibratedWhite_alpha(0, 0.2).setFill;
    NSBezierPath.fillRect(self.bounds);
    if FBoard.Win then
      txt := NSSTR('You Win!')
    else
      txt := NSSTR('Game Over');
    r := self.bounds;
    r.origin.y := r.origin.y + r.size.height/2 - 10;
    r.origin.x := r.origin.x + r.size.width/2 - 40;
    r.size.width := 200; r.size.height := 20;
    txt.drawInRect_withAttributes(r, nil);
  end;
end;

procedure TMinesweeperView.mouseDown(event: NSEvent);
var
  p: NSPoint;
  gx, gy: Integer;
begin
  p := self.convertPoint_fromView(event.locationInWindow, nil);
  gx := Trunc(p.x / FCellSize);
  gy := Trunc(p.y / FCellSize);
  if (gx >= 0) and (gy >= 0) and (gx < FBoard.Width) and (gy < FBoard.Height) then
  begin
    if event.modifierFlags and NSControlKeyMask <> 0 then
      FBoard.ToggleFlag(gx, gy)
    else
      FBoard.Reveal(gx, gy);
    self.setNeedsDisplayInRect(self.bounds);
    UpdateWindowTitle;
  end;
end;

procedure TMinesweeperView.rightMouseDown(event: NSEvent);
var
  p: NSPoint;
  gx, gy: Integer;
begin
  p := self.convertPoint_fromView(event.locationInWindow, nil);
  gx := Trunc(p.x / FCellSize);
  gy := Trunc(p.y / FCellSize);
  if (gx >= 0) and (gy >= 0) and (gx < FBoard.Width) and (gy < FBoard.Height) then
  begin
    FBoard.ToggleFlag(gx, gy);
    self.setNeedsDisplayInRect(self.bounds);
    UpdateWindowTitle;
  end;
end;

procedure TMinesweeperView.NewGame;
var
  seed: QWord;
  nowSec: Double;
begin
  nowSec := NSDate.date.timeIntervalSince1970;
  if nowSec < 0 then nowSec := 0;
  seed := QWord(Trunc(nowSec * 1000.0));
  FBoard.GenerateWithSeed(seed);
  self.setNeedsDisplayInRect(self.bounds);
  UpdateWindowTitle;
end;

end.
