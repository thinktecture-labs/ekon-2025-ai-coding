program MinesweeperApp;

{$mode objfpc}{$H+}
{$modeswitch objectivec1}
{$linkframework Cocoa}

uses
  SysUtils, Math, CocoaAll;

type
  TGameMode = (gmBeginner, gmIntermediate, gmExpert);

  TMineCell = record
    HasMine: Boolean;
    Revealed: Boolean;
    Flagged: Boolean;
    Exploded: Boolean;
    Adjacent: Integer;
  end;

  TModeConfig = record
    Width: Integer;
    Height: Integer;
    MinMines: Integer;
    MaxMines: Integer;
    DisplayName: NSString;
  end;

  TAppDelegate = objcclass;
  TMineGameController = class;
  TBoardView = objcclass(NSView)
  public
    function initWithFrame(frameRect: NSRect): id; override; message 'initWithFrame:';
    procedure drawRect(dirtyRect: NSRect); override; message 'drawRect:';
    procedure mouseDown(event: NSEvent); override; message 'mouseDown:';
    procedure rightMouseDown(event: NSEvent); override; message 'rightMouseDown:';
    procedure otherMouseDown(event: NSEvent); override; message 'otherMouseDown:';
  end;

  TModeMenuItems = array[TGameMode] of NSMenuItem;

  TMineGameController = class
  private
    FDelegate: TAppDelegate;
    FWindow: NSWindow;
    FMainMenu: NSMenu;
    FModeMenuItems: TModeMenuItems;
    FHeaderView: NSView;
    FTimerLabel: NSTextField;
    FMessageLabel: NSTextField;
    FMessageButton: NSButton;
    FBoardView: TBoardView;
    FBoardBackground: NSView;
    FRows: Integer;
    FCols: Integer;
    FMineCount: Integer;
    FRevealedCount: Integer;
    FElapsedSeconds: Integer;
    FGameActive: Boolean;
    FTimer: NSTimer;
    FCurrentMode: TGameMode;
    FBoard: array of array of TMineCell;
    procedure BuildWindow;
    procedure BuildMenu;
    procedure BuildHeader;
    procedure BuildBoardArea;
    procedure ResetBoardState;
    procedure PlaceMines;
    procedure CalculateAdjacencies;
    procedure UpdateAllCells;
    procedure RevealCell(const Row, Col: Integer);
    procedure FloodReveal(const Row, Col: Integer);
    procedure ToggleFlag(const Row, Col: Integer);
    procedure HandleMineHit(const Row, Col: Integer);
    procedure CheckForWin;
    procedure SetTimerRunning(const Running: Boolean);
    procedure UpdateTimerLabel;
    procedure ResetMessageArea;
    procedure ShowMessage(const Text: NSString);
    procedure ShowWinMessage;
    procedure ShowLossMessage;
    function InBounds(const Row, Col: Integer): Boolean;
    function TotalSafeCells: Integer;
    function AllMinesFlagged: Boolean;
    function ModeConfig(const Mode: TGameMode): TModeConfig;
  public
    constructor Create(const ADelegate: TAppDelegate);
    destructor Destroy; override;
    procedure Initialize;
    procedure TearDown;
    procedure Restart;
    procedure ChangeMode(const Mode: TGameMode);
    procedure Tick;
    procedure HandlePrimaryClick(const Row, Col: Integer);
    procedure HandleFlagClick(const Row, Col: Integer);
    procedure UpdateModeMenuState;
    procedure RedrawBoard;
    function Rows: Integer;
    function Cols: Integer;
    function CellSize: Double;
    function CellAt(const Row, Col: Integer): TMineCell;
    function CurrentMode: TGameMode;
    procedure BoardGeometry(out ACellSize, OffsetX, OffsetY: Double);
  end;

  TAppDelegate = objcclass(NSObject)
  private
    FController: TMineGameController;
  public
    procedure applicationDidFinishLaunching(notification: NSNotification); message 'applicationDidFinishLaunching:';
    procedure applicationWillTerminate(notification: NSNotification); message 'applicationWillTerminate:';
    procedure restartGame(sender: id); message 'restartGame:';
    procedure changeMode(sender: id); message 'changeMode:';
    procedure updateTimer(sender: id); message 'updateTimer:';
    procedure dealloc; override; message 'dealloc';
  end;

var
  GameController: TMineGameController = nil;

function NSSTR(const S: AnsiString): NSString;
begin
  Result := NSString.stringWithUTF8String(PChar(S));
end;

{ Utility functions }

function CellBackgroundColor(const Cell: TMineCell): NSColor;
begin
  if Cell.Exploded then
    Exit(NSColor.redColor);
  if Cell.Flagged then
    Exit(NSColor.orangeColor);
  if Cell.Revealed then
    Exit(NSColor.colorWithCalibratedRed_green_blue_alpha(0.75, 0.88, 1.0, 1.0));
  Result := NSColor.colorWithCalibratedWhite_alpha(0.75, 1.0);
end;

function NumberColor(const Count: Integer): NSColor;
begin
  case Count of
    1: Result := NSColor.greenColor;
    2: Result := NSColor.colorWithCalibratedRed_green_blue_alpha(0.0, 0.4, 0.0, 1.0);
    3: Result := NSColor.yellowColor;
    4: Result := NSColor.orangeColor;
    else Result := NSColor.redColor;
  end;
end;

{ TMineGameController }

constructor TMineGameController.Create(const ADelegate: TAppDelegate);
begin
  inherited Create;
  FDelegate := ADelegate;
  FTimer := nil;
  FRows := 0;
  FCols := 0;
  FMineCount := 0;
  FRevealedCount := 0;
  FElapsedSeconds := 0;
  FGameActive := False;
  Randomize;
end;

destructor TMineGameController.Destroy;
begin
  TearDown;
  if FMessageButton <> nil then
  begin
    FMessageButton.release;
    FMessageButton := nil;
  end;
  if FMessageLabel <> nil then
  begin
    FMessageLabel.release;
    FMessageLabel := nil;
  end;
  if FTimerLabel <> nil then
  begin
    FTimerLabel.release;
    FTimerLabel := nil;
  end;
  if FHeaderView <> nil then
  begin
    FHeaderView.release;
    FHeaderView := nil;
  end;
  if FBoardView <> nil then
  begin
    FBoardView.release;
    FBoardView := nil;
  end;
  if FBoardBackground <> nil then
  begin
    FBoardBackground.release;
    FBoardBackground := nil;
  end;
  if FMainMenu <> nil then
  begin
    FMainMenu.release;
    FMainMenu := nil;
  end;
  if FWindow <> nil then
  begin
    FWindow.release;
    FWindow := nil;
  end;
  inherited Destroy;
end;

procedure TMineGameController.Initialize;
begin
  GameController := Self;
  BuildWindow;
  BuildMenu;
  BuildHeader;
  BuildBoardArea;
  ChangeMode(gmBeginner);
  NSApp.setMainMenu(FMainMenu);
  FWindow.makeKeyAndOrderFront(nil);
  NSApp.activateIgnoringOtherApps(True);
end;

procedure TMineGameController.TearDown;
begin
  SetTimerRunning(False);
  SetLength(FBoard, 0);
end;

procedure TMineGameController.BuildWindow;
var
  styleMask: NSUInteger;
  initialFrame: NSRect;
begin
  styleMask := NSTitledWindowMask or NSClosableWindowMask or NSMiniaturizableWindowMask or NSResizableWindowMask;
  initialFrame := NSMakeRect(100, 100, 640, 720);

  FWindow := NSWindow.alloc.initWithContentRect_styleMask_backing_defer(initialFrame, styleMask, NSBackingStoreBuffered, False);
  FWindow.setTitle(NSSTR('Minesweeper'));
  FWindow.center;
end;

procedure TMineGameController.BuildMenu;
var
  mainMenu: NSMenu;
  appMenuItem: NSMenuItem;
  appMenu: NSMenu;
  quitItem: NSMenuItem;
  gameMenuItem: NSMenuItem;
  gameMenu: NSMenu;
  restartItem: NSMenuItem;
  modeItem: NSMenuItem;
  mode: TGameMode;
begin
  mainMenu := NSMenu.alloc.initWithTitle(NSSTR('Minesweeper'));
  FMainMenu := mainMenu.retain;

  appMenuItem := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(NSSTR('Minesweeper'), nil, NSSTR(''));
  mainMenu.addItem(appMenuItem);
  appMenu := NSMenu.alloc.initWithTitle(NSSTR('Minesweeper'));
  appMenuItem.setSubmenu(appMenu);

  quitItem := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(NSSTR('Quit Minesweeper'), sel_getUid('terminate:'), NSSTR('q'));
  quitItem.setTarget(NSApp);
  quitItem.setKeyEquivalentModifierMask(NSCommandKeyMask);
  appMenu.addItem(quitItem);

  gameMenuItem := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(NSSTR('Game'), nil, NSSTR(''));
  mainMenu.addItem(gameMenuItem);
  gameMenu := NSMenu.alloc.initWithTitle(NSSTR('Game'));
  gameMenuItem.setSubmenu(gameMenu);

  restartItem := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(NSSTR('Restart'), sel_getUid('restartGame:'), NSSTR('r'));
  restartItem.setTarget(FDelegate);
  restartItem.setKeyEquivalentModifierMask(NSCommandKeyMask);
  gameMenu.addItem(restartItem);
  gameMenu.addItem(NSMenuItem.separatorItem);

  for mode in TGameMode do
  begin
    modeItem := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(ModeConfig(mode).DisplayName, sel_getUid('changeMode:'), NSSTR(''));
    modeItem.setTarget(FDelegate);
    modeItem.setTag(Ord(mode));
    gameMenu.addItem(modeItem);
    FModeMenuItems[mode] := modeItem;
  end;
end;

procedure TMineGameController.BuildHeader;
const
  HeaderHeight = 80.0;
  TimerWidth = 160.0;
  MessageHeight = 24.0;
  ButtonWidth = 160.0;
var
  contentBounds: NSRect;
  timerFrame, messageFrame, buttonFrame: NSRect;
begin
  contentBounds := FWindow.contentView.bounds;

  FHeaderView := NSView.alloc.initWithFrame(NSMakeRect(0, contentBounds.size.height - HeaderHeight, contentBounds.size.width, HeaderHeight));
  FHeaderView.setAutoresizingMask(NSViewWidthSizable or NSViewMinYMargin);
  FWindow.contentView.addSubview(FHeaderView);

  timerFrame := NSMakeRect(20, HeaderHeight - MessageHeight - 10, TimerWidth, MessageHeight);
  FTimerLabel := NSTextField.alloc.initWithFrame(timerFrame);
  FTimerLabel.setBezeled(False);
  FTimerLabel.setDrawsBackground(False);
  FTimerLabel.setEditable(False);
  FTimerLabel.setSelectable(False);
  FTimerLabel.setFont(NSFont.boldSystemFontOfSize(18));
  FTimerLabel.setStringValue(NSSTR('Time: 000'));
  FHeaderView.addSubview(FTimerLabel);

  messageFrame := NSMakeRect(20, 10, contentBounds.size.width - 40 - ButtonWidth, MessageHeight);
  FMessageLabel := NSTextField.alloc.initWithFrame(messageFrame);
  FMessageLabel.setBezeled(False);
  FMessageLabel.setDrawsBackground(False);
  FMessageLabel.setEditable(False);
  FMessageLabel.setSelectable(False);
  FMessageLabel.setFont(NSFont.systemFontOfSize(16));
  FMessageLabel.setTextColor(NSColor.blackColor);
  FMessageLabel.setHidden(True);
  FHeaderView.addSubview(FMessageLabel);

  buttonFrame := NSMakeRect(contentBounds.size.width - ButtonWidth - 20, 10, ButtonWidth, MessageHeight + 6);
  FMessageButton := NSButton.alloc.initWithFrame(buttonFrame);
  FMessageButton.setTitle(NSSTR('Start New Game'));
  FMessageButton.setTarget(FDelegate);
  FMessageButton.setAction(sel_getUid('restartGame:'));
  FMessageButton.setBezelStyle(NSRoundedBezelStyle);
  FMessageButton.setHidden(True);
  FHeaderView.addSubview(FMessageButton);
end;

procedure TMineGameController.BuildBoardArea;
var
  contentBounds: NSRect;
  boardFrame: NSRect;
begin
  contentBounds := FWindow.contentView.bounds;
  boardFrame := NSMakeRect(20, 20, contentBounds.size.width - 40, contentBounds.size.height - 40 - FHeaderView.frame.size.height);

  if FBoardBackground <> nil then
  begin
    FBoardBackground.removeFromSuperview;
    FBoardBackground.release;
  end;

  FBoardBackground := NSView.alloc.initWithFrame(boardFrame);
  FBoardBackground.setAutoresizingMask(NSViewWidthSizable or NSViewHeightSizable or NSViewMinYMargin);
  FBoardBackground.setWantsLayer(True);
  FBoardBackground.layer.setBackgroundColor(NSColor.colorWithCalibratedWhite_alpha(0.9, 1.0).CGColor);
  FBoardBackground.layer.setCornerRadius(8.0);
  FWindow.contentView.addSubview(FBoardBackground);

  if FBoardView <> nil then
  begin
    FBoardView.removeFromSuperview;
    FBoardView.release;
  end;

  FBoardView := TBoardView.alloc.initWithFrame(FBoardBackground.bounds);
  FBoardView.setAutoresizingMask(NSViewWidthSizable or NSViewHeightSizable);
  FBoardBackground.addSubview(FBoardView);
end;

function TMineGameController.ModeConfig(const Mode: TGameMode): TModeConfig;
begin
  case Mode of
    gmBeginner:
      begin
        Result.Width := 9;
        Result.Height := 9;
        Result.MinMines := 8;
        Result.MaxMines := 12;
        Result.DisplayName := NSSTR('Beginner');
      end;
    gmIntermediate:
      begin
        Result.Width := 16;
        Result.Height := 16;
        Result.MinMines := 30;
        Result.MaxMines := 50;
        Result.DisplayName := NSSTR('Intermediate');
      end;
    gmExpert:
      begin
        Result.Width := 30;
        Result.Height := 16;
        Result.MinMines := 80;
        Result.MaxMines := 120;
        Result.DisplayName := NSSTR('Expert');
      end;
  end;
end;

procedure TMineGameController.ChangeMode(const Mode: TGameMode);
var
  config: TModeConfig;
  row: Integer;
begin
  SetTimerRunning(False);
  FCurrentMode := Mode;
  UpdateModeMenuState;

  config := ModeConfig(Mode);
  FRows := config.Height;
  FCols := config.Width;

  SetLength(FBoard, FRows);
  for row := 0 to FRows - 1 do
    SetLength(FBoard[row], FCols);

  ResetBoardState;
  PlaceMines;
  CalculateAdjacencies;
  UpdateAllCells;
  RedrawBoard;
  SetTimerRunning(True);
end;

procedure TMineGameController.Restart;
begin
  ChangeMode(FCurrentMode);
end;

procedure TMineGameController.ResetBoardState;
var
  row, col: Integer;
begin
  FRevealedCount := 0;
  FElapsedSeconds := 0;
  FGameActive := True;
  UpdateTimerLabel;
  ResetMessageArea;

  for row := 0 to FRows - 1 do
    for col := 0 to FCols - 1 do
    begin
      FBoard[row, col].HasMine := False;
      FBoard[row, col].Revealed := False;
      FBoard[row, col].Flagged := False;
      FBoard[row, col].Exploded := False;
      FBoard[row, col].Adjacent := 0;
    end;
end;

procedure TMineGameController.PlaceMines;
var
  targetMines, placed, row, col: Integer;
  config: TModeConfig;
begin
  config := ModeConfig(FCurrentMode);
  targetMines := config.MinMines + Random(config.MaxMines - config.MinMines + 1);
  FMineCount := targetMines;

  placed := 0;
  while placed < targetMines do
  begin
    row := Random(FRows);
    col := Random(FCols);
    if not FBoard[row, col].HasMine then
    begin
      FBoard[row, col].HasMine := True;
      Inc(placed);
    end;
  end;
end;

procedure TMineGameController.CalculateAdjacencies;
const
  Neighbors: array[0..7] of record DR, DC: Integer; end = (
    (DR: -1; DC: -1), (DR: -1; DC: 0), (DR: -1; DC: 1),
    (DR: 0; DC: -1), (DR: 0; DC: 1),
    (DR: 1; DC: -1), (DR: 1; DC: 0), (DR: 1; DC: 1)
  );
var
  row, col, i, nr, nc: Integer;
begin
  for row := 0 to FRows - 1 do
    for col := 0 to FCols - 1 do
    begin
      FBoard[row, col].Adjacent := 0;
      if FBoard[row, col].HasMine then
        Continue;
      for i := Low(Neighbors) to High(Neighbors) do
      begin
        nr := row + Neighbors[i].DR;
        nc := col + Neighbors[i].DC;
        if InBounds(nr, nc) and FBoard[nr, nc].HasMine then
          Inc(FBoard[row, col].Adjacent);
      end;
    end;
end;

procedure TMineGameController.UpdateAllCells;
begin
  // Rendering handled by board view; request redraw.
end;

procedure TMineGameController.RedrawBoard;
begin
  if FBoardView <> nil then
    FBoardView.setNeedsDisplayInRect(FBoardView.bounds);
end;

procedure TMineGameController.ResetMessageArea;
begin
  FMessageLabel.setHidden(True);
  FMessageButton.setHidden(True);
end;

procedure TMineGameController.ShowMessage(const Text: NSString);
begin
  FMessageLabel.setStringValue(Text);
  FMessageLabel.setHidden(False);
  FMessageButton.setHidden(False);
end;

procedure TMineGameController.ShowWinMessage;
begin
  ShowMessage(NSSTR('Congratulations, you won'));
end;

procedure TMineGameController.ShowLossMessage;
begin
  ShowMessage(NSSTR('Sorry, you lost'));
end;

procedure TMineGameController.SetTimerRunning(const Running: Boolean);
begin
  if Running then
  begin
    if FTimer = nil then
    begin
      FTimer := NSTimer.scheduledTimerWithTimeInterval_target_selector_userInfo_repeats(1.0, FDelegate, sel_getUid('updateTimer:'), nil, True);
      FTimer.retain;
    end;
  end
  else if FTimer <> nil then
  begin
    FTimer.invalidate;
    FTimer.release;
    FTimer := nil;
  end;
end;

procedure TMineGameController.UpdateTimerLabel;
var
  formatted: AnsiString;
begin
  formatted := Format('Time: %0.3d', [FElapsedSeconds]);
  FTimerLabel.setStringValue(NSSTR(formatted));
end;

procedure TMineGameController.Tick;
begin
  if not FGameActive then
    Exit;
  Inc(FElapsedSeconds);
  UpdateTimerLabel;
end;

function TMineGameController.InBounds(const Row, Col: Integer): Boolean;
begin
  Result := (Row >= 0) and (Row < FRows) and (Col >= 0) and (Col < FCols);
end;

function TMineGameController.TotalSafeCells: Integer;
begin
  Result := FRows * FCols - FMineCount;
end;

function TMineGameController.AllMinesFlagged: Boolean;
var
  row, col: Integer;
  cell: TMineCell;
begin
  for row := 0 to FRows - 1 do
    for col := 0 to FCols - 1 do
    begin
      cell := FBoard[row, col];
      if cell.HasMine then
      begin
        if not cell.Flagged then
          Exit(False);
      end
      else if cell.Flagged then
        Exit(False);
    end;
  Result := True;
end;

procedure TMineGameController.HandleMineHit(const Row, Col: Integer);
var
  r, c: Integer;
begin
  FGameActive := False;
  SetTimerRunning(False);
  FBoard[Row, Col].Exploded := True;

  for r := 0 to FRows - 1 do
    for c := 0 to FCols - 1 do
      if FBoard[r, c].HasMine then
        FBoard[r, c].Revealed := True;

  ShowLossMessage;
  RedrawBoard;
end;

procedure TMineGameController.CheckForWin;
begin
  if not FGameActive then
    Exit;

  if FRevealedCount = TotalSafeCells then
  begin
    FGameActive := False;
    SetTimerRunning(False);
    ShowWinMessage;
    Exit;
  end;

  if AllMinesFlagged then
  begin
    FGameActive := False;
    SetTimerRunning(False);
    ShowWinMessage;
  end;
end;

procedure TMineGameController.RevealCell(const Row, Col: Integer);
begin
  if not InBounds(Row, Col) then
    Exit;
  if FBoard[Row, Col].Revealed or FBoard[Row, Col].Flagged then
    Exit;

  FBoard[Row, Col].Revealed := True;
  Inc(FRevealedCount);

  if FBoard[Row, Col].HasMine then
  begin
    HandleMineHit(Row, Col);
    Exit;
  end;

  if FBoard[Row, Col].Adjacent = 0 then
    FloodReveal(Row, Col);

  RedrawBoard;
  CheckForWin;
end;

procedure TMineGameController.FloodReveal(const Row, Col: Integer);
const
  Neighbors: array[0..7] of record DR, DC: Integer; end = (
    (DR: -1; DC: -1), (DR: -1; DC: 0), (DR: -1; DC: 1),
    (DR: 0; DC: -1), (DR: 0; DC: 1),
    (DR: 1; DC: -1), (DR: 1; DC: 0), (DR: 1; DC: 1)
  );
var
  i, nr, nc: Integer;
begin
  for i := Low(Neighbors) to High(Neighbors) do
  begin
    nr := Row + Neighbors[i].DR;
    nc := Col + Neighbors[i].DC;
    if InBounds(nr, nc) and (not FBoard[nr, nc].Revealed) and (not FBoard[nr, nc].HasMine) then
      RevealCell(nr, nc);
  end;
end;

procedure TMineGameController.ToggleFlag(const Row, Col: Integer);
begin
  if not InBounds(Row, Col) then
    Exit;
  if FBoard[Row, Col].Revealed then
    Exit;
  FBoard[Row, Col].Flagged := not FBoard[Row, Col].Flagged;
  RedrawBoard;
  CheckForWin;
end;

procedure TMineGameController.HandlePrimaryClick(const Row, Col: Integer);
begin
  if not FGameActive then
    Exit;
  RevealCell(Row, Col);
end;

procedure TMineGameController.HandleFlagClick(const Row, Col: Integer);
begin
  if not FGameActive then
    Exit;
  ToggleFlag(Row, Col);
end;

function TMineGameController.Rows: Integer;
begin
  Result := FRows;
end;

function TMineGameController.Cols: Integer;
begin
  Result := FCols;
end;

function TMineGameController.CellSize: Double;
var
  usableWidth, usableHeight, sizeX, sizeY: Double;
begin
  if (FBoardView = nil) or (FCols = 0) or (FRows = 0) then
    Exit(32.0);
  usableWidth := FBoardView.bounds.size.width;
  usableHeight := FBoardView.bounds.size.height;
  sizeX := usableWidth / FCols;
  sizeY := usableHeight / FRows;
  Result := Min(sizeX, sizeY);
end;

function TMineGameController.CellAt(const Row, Col: Integer): TMineCell;
begin
  if InBounds(Row, Col) then
    Result := FBoard[Row, Col]
  else
  begin
    Result.HasMine := False;
    Result.Revealed := False;
    Result.Flagged := False;
    Result.Exploded := False;
    Result.Adjacent := 0;
  end;
end;

function TMineGameController.CurrentMode: TGameMode;
begin
  Result := FCurrentMode;
end;

procedure TMineGameController.BoardGeometry(out ACellSize, OffsetX, OffsetY: Double);
var
  totalWidth, totalHeight: Double;
begin
  ACellSize := CellSize;
  totalWidth := ACellSize * FCols;
  totalHeight := ACellSize * FRows;
  OffsetX := 0.0;
  OffsetY := 0.0;
  if FBoardView <> nil then
  begin
    OffsetX := (FBoardView.bounds.size.width - totalWidth) / 2;
    OffsetY := (FBoardView.bounds.size.height - totalHeight) / 2;
  end;
end;

procedure TMineGameController.UpdateModeMenuState;
var
  mode: TGameMode;
begin
  for mode in TGameMode do
    if FModeMenuItems[mode] <> nil then
      if mode = FCurrentMode then
        FModeMenuItems[mode].setState(NSOnState)
      else
        FModeMenuItems[mode].setState(NSOffState);
end;

{ TBoardView }

function TBoardView.initWithFrame(frameRect: NSRect): id;
begin
  Result := inherited initWithFrame(frameRect);
  if Result <> nil then
    Self.setWantsLayer(True);
end;

procedure TBoardView.drawRect(dirtyRect: NSRect);
var
  controller: TMineGameController;
  cellSize: Double;
  offsetX, offsetY: Double;
  row, col: Integer;
  cellRect: NSRect;
  cell: TMineCell;
  attrs: NSDictionary;
  font: NSFont;
  drawRectLocal: NSRect;
  textColor: NSColor;
  textValue: NSString;
begin
  inherited drawRect(dirtyRect);
  controller := GameController;
  if controller = nil then
    Exit;
  if (controller.Rows = 0) or (controller.Cols = 0) then
    Exit;

  controller.BoardGeometry(cellSize, offsetX, offsetY);
  font := NSFont.boldSystemFontOfSize(Max(12.0, cellSize * 0.55));

  for row := 0 to controller.Rows - 1 do
    for col := 0 to controller.Cols - 1 do
    begin
      cell := controller.CellAt(row, col);
      cellRect := NSMakeRect(offsetX + col * cellSize, offsetY + (controller.Rows - 1 - row) * cellSize, cellSize, cellSize);

      CellBackgroundColor(cell).setFill;
      NSBezierPath.fillRect(cellRect);

      NSColor.blackColor.setStroke;
      NSBezierPath.strokeRect(cellRect);

      textValue := nil;
      textColor := NSColor.blackColor;

      if cell.Flagged then
        textValue := NSSTR('F')
      else if cell.Revealed and cell.HasMine then
      begin
        textValue := NSSTR('M');
        textColor := NSColor.blackColor;
      end
      else if cell.Revealed and (cell.Adjacent > 0) then
      begin
        textValue := NSSTR(IntToStr(cell.Adjacent));
        textColor := NumberColor(cell.Adjacent);
      end;

      if textValue <> nil then
      begin
        attrs := NSDictionary.dictionaryWithObjectsAndKeys(font, NSFontAttributeName, textColor, NSForegroundColorAttributeName, nil);
        drawRectLocal := NSMakeRect(cellRect.origin.x, cellRect.origin.y + (cellSize - font.pointSize) / 2 - 2, cellSize, font.pointSize + 4);
        textValue.drawInRect_withAttributes(drawRectLocal, attrs);
      end;
    end;
end;

procedure TBoardView.mouseDown(event: NSEvent);
var
  controller: TMineGameController;
  point: NSPoint;
  cellSize, offsetX, offsetY: Double;
  col, row: Integer;
  localX, localY: Double;
begin
  controller := GameController;
  if controller = nil then
    Exit;

  point := Self.convertPoint_fromView(event.locationInWindow, nil);
  controller.BoardGeometry(cellSize, offsetX, offsetY);
  if cellSize <= 0 then
    Exit;

  localX := point.x - offsetX;
  localY := point.y - offsetY;
  if (localX < 0) or (localY < 0) then
    Exit;
  if (localX >= cellSize * controller.Cols) or (localY >= cellSize * controller.Rows) then
    Exit;

  col := Trunc(localX / cellSize);
  row := controller.Rows - 1 - Trunc(localY / cellSize);

  if (event.modifierFlags and NSControlKeyMask) <> 0 then
    controller.HandleFlagClick(row, col)
  else
    controller.HandlePrimaryClick(row, col);
end;

procedure TBoardView.rightMouseDown(event: NSEvent);
var
  controller: TMineGameController;
  point: NSPoint;
  cellSize, offsetX, offsetY: Double;
  col, row: Integer;
  localX, localY: Double;
begin
  controller := GameController;
  if controller = nil then
    Exit;

  point := Self.convertPoint_fromView(event.locationInWindow, nil);
  controller.BoardGeometry(cellSize, offsetX, offsetY);
  if cellSize <= 0 then
    Exit;

  localX := point.x - offsetX;
  localY := point.y - offsetY;
  if (localX < 0) or (localY < 0) then
    Exit;
  if (localX >= cellSize * controller.Cols) or (localY >= cellSize * controller.Rows) then
    Exit;

  col := Trunc(localX / cellSize);
  row := controller.Rows - 1 - Trunc(localY / cellSize);
  controller.HandleFlagClick(row, col);
end;

procedure TBoardView.otherMouseDown(event: NSEvent);
begin
  rightMouseDown(event);
end;

{ TAppDelegate }

procedure TAppDelegate.applicationDidFinishLaunching(notification: NSNotification);
begin
  FController := TMineGameController.Create(Self);
  FController.Initialize;
end;

procedure TAppDelegate.applicationWillTerminate(notification: NSNotification);
begin
  if FController <> nil then
    FController.TearDown;
end;

procedure TAppDelegate.restartGame(sender: id);
begin
  if FController <> nil then
    FController.Restart;
end;

procedure TAppDelegate.changeMode(sender: id);
var
  modeTag: Integer;
  newMode: TGameMode;
begin
  if FController = nil then
    Exit;

  modeTag := NSMenuItem(sender).tag;
  if (modeTag < Ord(Low(TGameMode))) or (modeTag > Ord(High(TGameMode))) then
    Exit;

  newMode := TGameMode(modeTag);
  if newMode <> FController.CurrentMode then
    FController.ChangeMode(newMode);
end;

procedure TAppDelegate.updateTimer(sender: id);
begin
  if FController <> nil then
    FController.Tick;
end;

procedure TAppDelegate.dealloc;
begin
  if FController <> nil then
  begin
    FController.Free;
    FController := nil;
  end;
  inherited dealloc;
end;

{ Program entry point }

var
  Pool: NSAutoreleasePool;
  App: NSApplication;
  Delegate: TAppDelegate;
begin
  Pool := NSAutoreleasePool.alloc.init;
  App := NSApplication.sharedApplication;
  App.setActivationPolicy(NSApplicationActivationPolicyRegular);

  Delegate := TAppDelegate.alloc.init;
  App.setDelegate(id(Delegate));

  App.run;

  Delegate.release;
  Pool.release;
end.
