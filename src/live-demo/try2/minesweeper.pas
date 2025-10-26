program Minesweeper;

{$mode objfpc}{$H+}{$modeswitch objectivec1}

uses
  CocoaAll, SysUtils, Math;

type
  TCellState = (csUnclicked, csClicked, csFlagged);

  TCell = record
    HasMine: Boolean;
    State: TCellState;
    AdjacentMines: Integer;
  end;

  TGameMode = (gmBeginner, gmIntermediate, gmExpert);

  TGameState = (gsPlaying, gsWon, gsLost);

  { Regular Pascal class to hold game state }
  TGameData = class
    FGrid: array of array of TCell;
    FButtons: array of array of NSButton;
    FRows, FCols, FMines: Integer;
    FGameState: TGameState;
    FFirstClick: Boolean;

    procedure InitGame(AMode: TGameMode);
    procedure PlaceMines(ExcludeRow, ExcludeCol: Integer);
    procedure CalculateAdjacentMines;
    function CountAdjacentMines(Row, Col: Integer): Integer;
    procedure RevealCell(Row, Col: Integer);
    procedure CheckWin;
    function GetColorForNumber(Num: Integer): NSColor;

    constructor Create;
    destructor Destroy; override;
  end;

  { TGameController }
  TGameController = objcclass(NSObject, NSApplicationDelegateProtocol)
    FWindow: NSWindow;
    FContentView: NSView;
    FMainMenu: NSMenu;
    FGameData: TGameData;
    FTimer: NSTimer;
    FStartTime: NSDate;
    FTimeLabel: NSTextField;

    procedure ShowEndDialog(Won: Boolean); message 'showEndDialog:';
    procedure UpdateTimer; message 'updateTimer';
    procedure InitGameUI(AMode: TGameMode); message 'initGameUI:';
    procedure applicationDidFinishLaunching(notification: NSNotification); message 'applicationDidFinishLaunching:';
    procedure cellClicked(sender: id); message 'cellClicked:';
    procedure menuNewGame(sender: id); message 'menuNewGame:';
    procedure menuBeginner(sender: id); message 'menuBeginner:';
    procedure menuIntermediate(sender: id); message 'menuIntermediate:';
    procedure menuExpert(sender: id); message 'menuExpert:';
    procedure timerTick(timer: id); message 'timerTick:';
    procedure dealloc; override;
  end;

{ TGameData implementation }

constructor TGameData.Create;
begin
  inherited Create;
end;

destructor TGameData.Destroy;
begin
  inherited Destroy;
end;

procedure TGameData.InitGame(AMode: TGameMode);
var
  i, j: Integer;
  minCount, maxCount: Integer;
begin
  FGameState := gsPlaying;
  FFirstClick := True;

  // Set grid size based on mode
  case AMode of
    gmBeginner:
      begin
        FRows := 9;
        FCols := 9;
        minCount := 8;
        maxCount := 12;
        FMines := minCount + Random(maxCount - minCount + 1);
      end;
    gmIntermediate:
      begin
        FRows := 16;
        FCols := 16;
        minCount := 30;
        maxCount := 50;
        FMines := minCount + Random(maxCount - minCount + 1);
      end;
    gmExpert:
      begin
        FRows := 16;
        FCols := 30;
        FMines := Round(FRows * FCols * 0.21);
      end;
  end;

  // Initialize grid
  SetLength(FGrid, FRows, FCols);
  SetLength(FButtons, FRows, FCols);
  for i := 0 to FRows - 1 do
    for j := 0 to FCols - 1 do
    begin
      FGrid[i][j].HasMine := False;
      FGrid[i][j].State := csUnclicked;
      FGrid[i][j].AdjacentMines := 0;
      FButtons[i][j] := nil;
    end;
end;

procedure TGameData.PlaceMines(ExcludeRow, ExcludeCol: Integer);
var
  placed, row, col: Integer;
begin
  placed := 0;
  while placed < FMines do
  begin
    row := Random(FRows);
    col := Random(FCols);

    if ((row = ExcludeRow) and (col = ExcludeCol)) or FGrid[row][col].HasMine then
      Continue;

    FGrid[row][col].HasMine := True;
    Inc(placed);
  end;

  CalculateAdjacentMines;
end;

procedure TGameData.CalculateAdjacentMines;
var
  i, j: Integer;
begin
  for i := 0 to FRows - 1 do
    for j := 0 to FCols - 1 do
      if not FGrid[i][j].HasMine then
        FGrid[i][j].AdjacentMines := CountAdjacentMines(i, j);
end;

function TGameData.CountAdjacentMines(Row, Col: Integer): Integer;
var
  i, j, count: Integer;
begin
  count := 0;
  for i := Max(0, Row - 1) to Min(FRows - 1, Row + 1) do
    for j := Max(0, Col - 1) to Min(FCols - 1, Col + 1) do
      if (i <> Row) or (j <> Col) then
        if FGrid[i][j].HasMine then
          Inc(count);
  Result := count;
end;

procedure TGameData.RevealCell(Row, Col: Integer);
var
  i, j: Integer;
  btn: NSButton;
begin
  if (FGrid[Row][Col].State <> csUnclicked) then
    Exit;

  FGrid[Row][Col].State := csClicked;
  btn := FButtons[Row][Col];

  btn.setEnabled(False);
  btn.layer.setBackgroundColor(NSColor.colorWithRed_green_blue_alpha(0.7, 0.9, 1.0, 1.0).CGColor);

  if FGrid[Row][Col].HasMine then
  begin
    btn.layer.setBackgroundColor(NSColor.redColor.CGColor);
    btn.setTitle(NSSTR('💣'));
    FGameState := gsLost;
  end
  else if FGrid[Row][Col].AdjacentMines > 0 then
  begin
    btn.setTitle(NSSTR(PChar(IntToStr(FGrid[Row][Col].AdjacentMines))));
    btn.setAttributedTitle(
      NSAttributedString.alloc.initWithString_attributes(
        NSSTR(PChar(IntToStr(FGrid[Row][Col].AdjacentMines))),
        NSDictionary.dictionaryWithObject_forKey(
          GetColorForNumber(FGrid[Row][Col].AdjacentMines),
          NSForegroundColorAttributeName)));
  end
  else
  begin
    for i := Max(0, Row - 1) to Min(FRows - 1, Row + 1) do
      for j := Max(0, Col - 1) to Min(FCols - 1, Col + 1) do
        if (i <> Row) or (j <> Col) then
          RevealCell(i, j);
  end;
end;

function TGameData.GetColorForNumber(Num: Integer): NSColor;
begin
  case Num of
    1: Result := NSColor.colorWithRed_green_blue_alpha(0.0, 0.6, 0.0, 1.0);
    2: Result := NSColor.colorWithRed_green_blue_alpha(0.0, 0.4, 0.0, 1.0);
    3: Result := NSColor.colorWithRed_green_blue_alpha(0.8, 0.7, 0.0, 1.0);
    4: Result := NSColor.orangeColor;
  else
    Result := NSColor.redColor;
  end;
end;

procedure TGameData.CheckWin;
var
  i, j: Integer;
  allRevealed: Boolean;
begin
  allRevealed := True;
  for i := 0 to FRows - 1 do
    for j := 0 to FCols - 1 do
      if not FGrid[i][j].HasMine and (FGrid[i][j].State <> csClicked) then
      begin
        allRevealed := False;
        Break;
      end;

  if allRevealed then
    FGameState := gsWon;
end;

{ TGameController implementation }

procedure TGameController.dealloc;
begin
  if Assigned(FMainMenu) then
    FMainMenu.release;
  if Assigned(FStartTime) then
    FStartTime.release;
  if Assigned(FTimer) then
  begin
    FTimer.invalidate;
    FTimer.release;
  end;
  if Assigned(FGameData) then
    FGameData.Free;
  inherited dealloc;
end;

procedure TGameController.InitGameUI(AMode: TGameMode);
var
  i, j: Integer;
  btn: NSButton;
  cellSize: Double;
  windowWidth, windowHeight: Double;
  contentRect: NSRect;
begin
  // Stop existing timer
  if Assigned(FTimer) then
  begin
    FTimer.invalidate;
    FTimer.release;
    FTimer := nil;
  end;

  if Assigned(FStartTime) then
  begin
    FStartTime.release;
    FStartTime := nil;
  end;

  // Initialize game data
  FGameData.InitGame(AMode);

  // Clear old content view
  if Assigned(FContentView) then
  begin
    FContentView.removeFromSuperview;
    FContentView.release;
  end;

  // Create new content view
  cellSize := 30.0;
  windowWidth := FGameData.FCols * cellSize + 40;
  windowHeight := FGameData.FRows * cellSize + 80;

  contentRect := NSMakeRect(0, 0, windowWidth, windowHeight);
  FContentView := NSView.alloc.initWithFrame(contentRect);
  FContentView.retain;

  // Create timer label
  FTimeLabel := NSTextField.alloc.initWithFrame(NSMakeRect(10, windowHeight - 30, windowWidth - 20, 25));
  FTimeLabel.setStringValue(NSSTR('Time: 0s'));
  FTimeLabel.setBezeled(False);
  FTimeLabel.setDrawsBackground(False);
  FTimeLabel.setEditable(False);
  FTimeLabel.setSelectable(False);
  FTimeLabel.setAlignment(NSCenterTextAlignment);
  FContentView.addSubview(FTimeLabel);

  // Create buttons
  for i := 0 to FGameData.FRows - 1 do
    for j := 0 to FGameData.FCols - 1 do
    begin
      btn := NSButton.alloc.initWithFrame(
        NSMakeRect(20 + j * cellSize, windowHeight - 60 - (i + 1) * cellSize, cellSize, cellSize));
      btn.setTag(i * 1000 + j);
      btn.setTitle(NSSTR(''));
      btn.setBezelStyle(NSRoundedBezelStyle);
      btn.setTarget(Self);
      btn.setAction(ObjCSelector('cellClicked:'));
      btn.setEnabled(True);

      btn.setWantsLayer(True);
      btn.layer.setBackgroundColor(NSColor.grayColor.CGColor);

      FContentView.addSubview(btn);
      FGameData.FButtons[i][j] := btn;
    end;

  // Update window
  FWindow.setContentView(FContentView);
  FWindow.setFrame_display(NSMakeRect(100, 100, windowWidth, windowHeight), True);
  FWindow.setTitle(NSSTR('Minesweeper'));
end;

procedure TGameController.ShowEndDialog(Won: Boolean);
var
  alert: NSAlert;
  response: NSModalResponse;
  message: NSString;
begin
  alert := NSAlert.alloc.init;

  if Won then
    message := NSSTR('Congratulations, you won!')
  else
    message := NSSTR('Sorry, you lost!');

  alert.setMessageText(message);
  alert.addButtonWithTitle(NSSTR('New Game'));

  response := alert.runModal;
  alert.release;

  if response = NSAlertFirstButtonReturn then
    menuNewGame(nil);
end;

procedure TGameController.UpdateTimer;
var
  elapsed: NSTimeInterval;
begin
  if Assigned(FStartTime) then
  begin
    elapsed := -FStartTime.timeIntervalSinceNow;
    FTimeLabel.setStringValue(NSSTR(PChar(Format('Time: %ds', [Trunc(elapsed)]))));
  end;
end;

procedure TGameController.cellClicked(sender: id);
var
  tag, row, col: Integer;
  event: NSEvent;
  rightClick: Boolean;
  btn: NSButton;
begin
  if FGameData.FGameState <> gsPlaying then
    Exit;

  btn := NSButton(sender);
  tag := btn.tag;
  row := tag div 1000;
  col := tag mod 1000;

  event := NSApp.currentEvent;
  rightClick := (event.type_ = NSRightMouseDown) or
                (event.type_ = NSLeftMouseDown) and
                ((event.modifierFlags and NSControlKeyMask) <> 0);

  if rightClick then
  begin
    if FGameData.FGrid[row][col].State = csUnclicked then
    begin
      FGameData.FGrid[row][col].State := csFlagged;
      btn.layer.setBackgroundColor(NSColor.orangeColor.CGColor);
      btn.setTitle(NSSTR('🚩'));
    end
    else if FGameData.FGrid[row][col].State = csFlagged then
    begin
      FGameData.FGrid[row][col].State := csUnclicked;
      btn.layer.setBackgroundColor(NSColor.grayColor.CGColor);
      btn.setTitle(NSSTR(''));
    end;
    FGameData.CheckWin;
  end
  else
  begin
    if FGameData.FGrid[row][col].State = csFlagged then
      Exit;

    if FGameData.FFirstClick then
    begin
      FGameData.FFirstClick := False;
      FGameData.PlaceMines(row, col);
      FStartTime := NSDate.date.retain;
      FTimer := NSTimer.scheduledTimerWithTimeInterval_target_selector_userInfo_repeats(
        1.0, Self, ObjCSelector('timerTick:'), nil, True);
      FTimer.retain;
    end;

    FGameData.RevealCell(row, col);

    if FGameData.FGameState = gsPlaying then
      FGameData.CheckWin;
  end;

  // Check for end game
  if FGameData.FGameState <> gsPlaying then
  begin
    if Assigned(FTimer) then
    begin
      FTimer.invalidate;
      FTimer.release;
      FTimer := nil;
    end;
    ShowEndDialog(FGameData.FGameState = gsWon);
  end;
end;

procedure TGameController.timerTick(timer: id);
begin
  UpdateTimer;
end;

procedure TGameController.menuNewGame(sender: id);
begin
  InitGameUI(gmBeginner);
end;

procedure TGameController.menuBeginner(sender: id);
begin
  InitGameUI(gmBeginner);
end;

procedure TGameController.menuIntermediate(sender: id);
begin
  InitGameUI(gmIntermediate);
end;

procedure TGameController.menuExpert(sender: id);
begin
  InitGameUI(gmExpert);
end;

procedure TGameController.applicationDidFinishLaunching(notification: NSNotification);
var
  appMenu, gameMenu, levelMenu: NSMenu;
  menuItem, levelMenuItem: NSMenuItem;
  menuBar: NSMenu;
begin
  NSApp.setActivationPolicy(NSApplicationActivationPolicyRegular);

  // Create game data
  FGameData := TGameData.Create;

  // Create main menu bar
  menuBar := NSMenu.alloc.init;
  FMainMenu := menuBar;
  FMainMenu.retain;

  // App menu
  appMenu := NSMenu.alloc.initWithTitle(NSSTR('Minesweeper'));
  menuItem := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(
    NSSTR('Quit Minesweeper'), ObjCSelector('terminate:'), NSSTR('q'));
  menuItem.setTarget(NSApp);
  appMenu.addItem(menuItem);
  menuItem.release;

  menuItem := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(
    NSSTR('Minesweeper'), nil, NSSTR(''));
  menuItem.setSubmenu(appMenu);
  menuBar.addItem(menuItem);
  menuItem.release;
  appMenu.release;

  // Game menu
  gameMenu := NSMenu.alloc.initWithTitle(NSSTR('Game'));

  menuItem := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(
    NSSTR('New Game'), ObjCSelector('menuNewGame:'), NSSTR('n'));
  menuItem.setTarget(Self);
  gameMenu.addItem(menuItem);
  menuItem.release;

  gameMenu.addItem(NSMenuItem.separatorItem);

  // Level submenu
  levelMenu := NSMenu.alloc.initWithTitle(NSSTR('Level'));

  levelMenuItem := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(
    NSSTR('Beginner'), ObjCSelector('menuBeginner:'), NSSTR('1'));
  levelMenuItem.setTarget(Self);
  levelMenu.addItem(levelMenuItem);
  levelMenuItem.release;

  levelMenuItem := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(
    NSSTR('Intermediate'), ObjCSelector('menuIntermediate:'), NSSTR('2'));
  levelMenuItem.setTarget(Self);
  levelMenu.addItem(levelMenuItem);
  levelMenuItem.release;

  levelMenuItem := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(
    NSSTR('Expert'), ObjCSelector('menuExpert:'), NSSTR('3'));
  levelMenuItem.setTarget(Self);
  levelMenu.addItem(levelMenuItem);
  levelMenuItem.release;

  menuItem := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(
    NSSTR('Level'), nil, NSSTR(''));
  menuItem.setSubmenu(levelMenu);
  gameMenu.addItem(menuItem);
  menuItem.release;
  levelMenu.release;

  menuItem := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(
    NSSTR('Game'), nil, NSSTR(''));
  menuItem.setSubmenu(gameMenu);
  menuBar.addItem(menuItem);
  menuItem.release;
  gameMenu.release;

  NSApp.setMainMenu(menuBar);

  // Create window
  FWindow := NSWindow.alloc.initWithContentRect_styleMask_backing_defer(
    NSMakeRect(100, 100, 400, 400),
    NSTitledWindowMask or NSClosableWindowMask or NSMiniaturizableWindowMask,
    NSBackingStoreBuffered,
    False);
  FWindow.setTitle(NSSTR('Minesweeper'));
  FWindow.makeKeyAndOrderFront(nil);

  // Initialize game
  Randomize;
  InitGameUI(gmBeginner);

  NSApp.activateIgnoringOtherApps(True);
end;

var
  app: NSApplication;
  controller: TGameController;

begin
  app := NSApplication.sharedApplication;
  controller := TGameController.alloc.init;
  app.setDelegate(controller);
  app.run;
  controller.release;
end.
