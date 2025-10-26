program minesweeper;

{$mode objfpc}{$H+}
{$modeswitch objectivec1}

uses
  CocoaAll, SysUtils;

type
  TGameMode = (gmBeginner, gmIntermediate, gmExpert);
  
  TCellState = (csUnclicked, csClicked, csBlocked, csMine);
  
  TCell = record
    State: TCellState;
    HasMine: Boolean;
    AdjacentMines: Integer;
    Button: NSButton;
  end;

  TGameData = class
  private
    FGrid: array of array of TCell;
    FRows, FCols: Integer;
    FMineCount: Integer;
    FGameOver: Boolean;
    FGameWon: Boolean;
    FStartTime: TDateTime;
    FMode: TGameMode;
    
    procedure PlaceMines;
    procedure CalculateAdjacentMines;
    function GetCell(row, col: Integer): TCellState;
    procedure SetCell(row, col: Integer; state: TCellState);
    function CountAdjacentMines(row, col: Integer): Integer;
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure InitGame(mode: TGameMode);
    procedure RevealCell(row, col: Integer);
    procedure ToggleBlock(row, col: Integer);
    function CheckWin: Boolean;
    
    property Rows: Integer read FRows;
    property Cols: Integer read FCols;
    property MineCount: Integer read FMineCount;
    property GameOver: Boolean read FGameOver write FGameOver;
    property GameWon: Boolean read FGameWon write FGameWon;
    property StartTime: TDateTime read FStartTime write FStartTime;
    property Mode: TGameMode read FMode;
    property Cell[row, col: Integer]: TCellState read GetCell write SetCell;
  end;

  TGameController = objcclass(NSObject, NSApplicationDelegateProtocol)
    FWindow: NSWindow;
    FGameData: TGameData;
    FMainMenu: NSMenu;
    FContentView: NSView;
    FTimeLabel: NSTextField;
    FTimer: NSTimer;
    FMessageLabel: NSTextField;
    FRestartButton: NSButton;
    function applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication): Boolean; message 'applicationShouldTerminateAfterLastWindowClosed:';
    procedure applicationDidFinishLaunching(notification: NSNotification); message 'applicationDidFinishLaunching:';
    procedure cellClicked(sender: id); message 'cellClicked:';
    procedure cellRightClicked(sender: id); message 'cellRightClicked:';
    procedure startNewGame(sender: id); message 'startNewGame:';
    procedure menuNewGameBeginner(sender: id); message 'menuNewGameBeginner:';
    procedure menuNewGameIntermediate(sender: id); message 'menuNewGameIntermediate:';
    procedure menuNewGameExpert(sender: id); message 'menuNewGameExpert:';
    procedure updateTimer(timer: NSTimer); message 'updateTimer:';
    procedure CreateMenuBar; message 'CreateMenuBar';
    procedure CreateGameUI; message 'CreateGameUI';
    procedure UpdateCellButton_col(row: NSInteger; col: NSInteger); message 'UpdateCellButton:col:';
    procedure ShowGameResult(won: Boolean); message 'ShowGameResult:';
    procedure HideGameResult; message 'HideGameResult';
    procedure RevealAllMines; message 'RevealAllMines';
    procedure dealloc; override;
  end;

{ TGameData }

constructor TGameData.Create;
begin
  inherited Create;
  FGameOver := False;
  FGameWon := False;
end;

destructor TGameData.Destroy;
begin
  SetLength(FGrid, 0, 0);
  inherited Destroy;
end;

procedure TGameData.InitGame(mode: TGameMode);
var
  i, j: Integer;
begin
  FMode := mode;
  FGameOver := False;
  FGameWon := False;
  FStartTime := Now;
  
  case mode of
    gmBeginner:
      begin
        FRows := 9;
        FCols := 9;
        FMineCount := 8 + Random(5);
      end;
    gmIntermediate:
      begin
        FRows := 16;
        FCols := 16;
        FMineCount := 30 + Random(21);
      end;
    gmExpert:
      begin
        FRows := 16;
        FCols := 30;
        FMineCount := 99;
      end;
  end;
  
  SetLength(FGrid, FRows, FCols);
  
  for i := 0 to FRows - 1 do
    for j := 0 to FCols - 1 do
    begin
      FGrid[i][j].State := csUnclicked;
      FGrid[i][j].HasMine := False;
      FGrid[i][j].AdjacentMines := 0;
      FGrid[i][j].Button := nil;
    end;
  
  PlaceMines;
  CalculateAdjacentMines;
end;

procedure TGameData.PlaceMines;
var
  placed: Integer;
  row, col: Integer;
begin
  placed := 0;
  while placed < FMineCount do
  begin
    row := Random(FRows);
    col := Random(FCols);
    if not FGrid[row][col].HasMine then
    begin
      FGrid[row][col].HasMine := True;
      Inc(placed);
    end;
  end;
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

function TGameData.CountAdjacentMines(row, col: Integer): Integer;
var
  dr, dc, r, c: Integer;
begin
  Result := 0;
  for dr := -1 to 1 do
    for dc := -1 to 1 do
    begin
      if (dr = 0) and (dc = 0) then Continue;
      r := row + dr;
      c := col + dc;
      if (r >= 0) and (r < FRows) and (c >= 0) and (c < FCols) then
        if FGrid[r][c].HasMine then
          Inc(Result);
    end;
end;

function TGameData.GetCell(row, col: Integer): TCellState;
begin
  Result := FGrid[row][col].State;
end;

procedure TGameData.SetCell(row, col: Integer; state: TCellState);
begin
  FGrid[row][col].State := state;
end;

procedure TGameData.RevealCell(row, col: Integer);
var
  dr, dc, r, c: Integer;
begin
  if FGameOver then Exit;
  if (row < 0) or (row >= FRows) or (col < 0) or (col >= FCols) then Exit;
  if FGrid[row][col].State <> csUnclicked then Exit;
  
  if FGrid[row][col].HasMine then
  begin
    FGrid[row][col].State := csMine;
    FGameOver := True;
    Exit;
  end;
  
  FGrid[row][col].State := csClicked;
  
  if FGrid[row][col].AdjacentMines = 0 then
  begin
    for dr := -1 to 1 do
      for dc := -1 to 1 do
      begin
        if (dr = 0) and (dc = 0) then Continue;
        r := row + dr;
        c := col + dc;
        RevealCell(r, c);
      end;
  end;
end;

procedure TGameData.ToggleBlock(row, col: Integer);
begin
  if FGameOver then Exit;
  if (row < 0) or (row >= FRows) or (col < 0) or (col >= FCols) then Exit;
  
  if FGrid[row][col].State = csUnclicked then
    FGrid[row][col].State := csBlocked
  else if FGrid[row][col].State = csBlocked then
    FGrid[row][col].State := csUnclicked;
end;

function TGameData.CheckWin: Boolean;
var
  i, j: Integer;
  blockedMines, totalBlocked: Integer;
begin
  if FGameOver then
  begin
    Result := False;
    Exit;
  end;
  
  blockedMines := 0;
  totalBlocked := 0;
  
  for i := 0 to FRows - 1 do
    for j := 0 to FCols - 1 do
    begin
      if FGrid[i][j].State = csBlocked then
      begin
        Inc(totalBlocked);
        if FGrid[i][j].HasMine then
          Inc(blockedMines);
      end;
    end;
  
  Result := (blockedMines = FMineCount) and (totalBlocked = FMineCount);
  if Result then
    FGameWon := True;
end;

{ TGameController }

function TGameController.applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication): Boolean;
begin
  Result := True;
end;

procedure TGameController.applicationDidFinishLaunching(notification: NSNotification);
begin
  NSApp.setActivationPolicy(NSApplicationActivationPolicyRegular);
  CreateMenuBar;
  
  FGameData := TGameData.Create;
  FGameData.InitGame(gmBeginner);
  
  FWindow := NSWindow.alloc.initWithContentRect_styleMask_backing_defer(
    NSMakeRect(100, 100, 600, 650),
    NSTitledWindowMask or NSClosableWindowMask or NSMiniaturizableWindowMask,
    NSBackingStoreBuffered,
    False);
  FWindow.setTitle(NSSTR('Minesweeper'));
  FWindow.center;
  
  CreateGameUI;
  
  FTimer := NSTimer.scheduledTimerWithTimeInterval_target_selector_userInfo_repeats(
    1.0, Self, objcselector('updateTimer:'), nil, True);
  
  FWindow.makeKeyAndOrderFront(nil);
  NSApp.activateIgnoringOtherApps(True);
end;

procedure TGameController.CreateMenuBar;
var
  mainMenu, appMenu, gameMenu: NSMenu;
  appMenuItem, gameMenuItem, quitItem, newGameItem, beginnerItem, intermediateItem, expertItem: NSMenuItem;
begin
  FMainMenu := NSMenu.alloc.init;
  
  appMenuItem := NSMenuItem.alloc.init;
  FMainMenu.addItem(appMenuItem);
  
  appMenu := NSMenu.alloc.init;
  appMenuItem.setSubmenu(appMenu);
  
  quitItem := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(
    NSSTR('Quit'), objcselector('terminate:'), NSSTR('q'));
  quitItem.setTarget(NSApp);
  appMenu.addItem(quitItem);
  
  gameMenuItem := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(
    NSSTR('Game'), nil, NSSTR(''));
  FMainMenu.addItem(gameMenuItem);
  
  gameMenu := NSMenu.alloc.initWithTitle(NSSTR('Game'));
  gameMenuItem.setSubmenu(gameMenu);
  
  newGameItem := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(
    NSSTR('New Game (Current Mode)'), objcselector('startNewGame:'), NSSTR('n'));
  newGameItem.setTarget(Self);
  gameMenu.addItem(newGameItem);
  
  gameMenu.addItem(NSMenuItem.separatorItem);
  
  beginnerItem := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(
    NSSTR('Beginner (9×9)'), objcselector('menuNewGameBeginner:'), NSSTR('1'));
  beginnerItem.setTarget(Self);
  gameMenu.addItem(beginnerItem);
  
  intermediateItem := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(
    NSSTR('Intermediate (16×16)'), objcselector('menuNewGameIntermediate:'), NSSTR('2'));
  intermediateItem.setTarget(Self);
  gameMenu.addItem(intermediateItem);
  
  expertItem := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(
    NSSTR('Expert (30×16)'), objcselector('menuNewGameExpert:'), NSSTR('3'));
  expertItem.setTarget(Self);
  gameMenu.addItem(expertItem);
  
  NSApp.setMainMenu(FMainMenu);
end;

procedure TGameController.CreateGameUI;
var
  i, j: Integer;
  btn: NSButton;
  cellSize: Integer;
  windowWidth, windowHeight: Integer;
  rect: NSRect;
begin
  if Assigned(FContentView) then
  begin
    FContentView.removeFromSuperview;
    FContentView.release;
  end;
  
  cellSize := 30;
  if FGameData.Cols > 20 then cellSize := 20;
  
  windowWidth := FGameData.Cols * cellSize + 40;
  windowHeight := FGameData.Rows * cellSize + 90;
  
  rect := FWindow.frame;
  rect.size.width := windowWidth;
  rect.size.height := windowHeight;
  FWindow.setFrame_display(rect, True);
  
  FContentView := NSView.alloc.initWithFrame(NSMakeRect(0, 0, windowWidth, windowHeight));
  FWindow.setContentView(FContentView);
  
  FTimeLabel := NSTextField.alloc.initWithFrame(NSMakeRect(20, windowHeight - 40, windowWidth - 40, 30));
  FTimeLabel.setStringValue(NSSTR('Time: 0s'));
  FTimeLabel.setBordered(False);
  FTimeLabel.setBackgroundColor(NSColor.clearColor);
  FTimeLabel.setEditable(False);
  FTimeLabel.setAlignment(NSCenterTextAlignment);
  FContentView.addSubview(FTimeLabel);
  
  for i := 0 to FGameData.Rows - 1 do
    for j := 0 to FGameData.Cols - 1 do
    begin
      btn := NSButton.alloc.initWithFrame(NSMakeRect(
        20 + j * cellSize,
        windowHeight - 60 - (i + 1) * cellSize,
        cellSize - 2,
        cellSize - 2));
      btn.setTitle(NSSTR(''));
      btn.setBezelStyle(NSRegularSquareBezelStyle);
      btn.setTag(i * 1000 + j);
      btn.setTarget(Self);
      btn.setAction(objcselector('cellClicked:'));
      btn.sendActionOn(NSLeftMouseDownMask or NSRightMouseDownMask);
      
      FGameData.FGrid[i][j].Button := btn;
      UpdateCellButton_col(i, j);
      
      FContentView.addSubview(btn);
    end;
  
  FMessageLabel := NSTextField.alloc.initWithFrame(NSMakeRect(
    windowWidth / 2 - 150, windowHeight / 2 + 20, 300, 40));
  FMessageLabel.setStringValue(NSSTR(''));
  FMessageLabel.setBordered(False);
  FMessageLabel.setBackgroundColor(NSColor.whiteColor);
  FMessageLabel.setEditable(False);
  FMessageLabel.setAlignment(NSCenterTextAlignment);
  FMessageLabel.setFont(NSFont.boldSystemFontOfSize(18));
  FMessageLabel.setHidden(True);
  FContentView.addSubview(FMessageLabel);
  
  FRestartButton := NSButton.alloc.initWithFrame(NSMakeRect(
    windowWidth / 2 - 60, windowHeight / 2 - 30, 120, 40));
  FRestartButton.setTitle(NSSTR('New Game'));
  FRestartButton.setBezelStyle(NSRoundedBezelStyle);
  FRestartButton.setTarget(Self);
  FRestartButton.setAction(objcselector('startNewGame:'));
  FRestartButton.setHidden(True);
  FContentView.addSubview(FRestartButton);
end;

procedure TGameController.UpdateCellButton_col(row: NSInteger; col: NSInteger);
var
  btn: NSButton;
  cell: TCell;
  color: NSColor;
  title: NSString;
begin
  cell := FGameData.FGrid[row][col];
  btn := cell.Button;
  
  case cell.State of
    csUnclicked:
      begin
        btn.setTitle(NSSTR(''));
        btn.setEnabled(True);
      end;
    csBlocked:
      begin
        btn.setTitle(NSSTR('🚩'));
        btn.setEnabled(True);
      end;
    csClicked:
      begin
        btn.setEnabled(False);
        if cell.AdjacentMines > 0 then
        begin
          title := NSSTR(PChar(IntToStr(cell.AdjacentMines)));
          btn.setTitle(title);
          
          case cell.AdjacentMines of
            1: color := NSColor.colorWithRed_green_blue_alpha(0.0, 0.7, 0.0, 1.0);
            2: color := NSColor.colorWithRed_green_blue_alpha(0.0, 0.5, 0.0, 1.0);
            3: color := NSColor.colorWithRed_green_blue_alpha(0.9, 0.9, 0.0, 1.0);
            4: color := NSColor.orangeColor;
          else
            color := NSColor.redColor;
          end;
          btn.setAttributedTitle(
            NSAttributedString.alloc.initWithString_attributes(
              title,
              NSDictionary.dictionaryWithObject_forKey(
                color,
                NSForegroundColorAttributeName)));
        end
        else
          btn.setTitle(NSSTR(''));
      end;
    csMine:
      begin
        btn.setTitle(NSSTR('💣'));
        btn.setEnabled(False);
      end;
  end;
end;

procedure TGameController.cellClicked(sender: id);
var
  btn: NSButton;
  tag, row, col: Integer;
  event: NSEvent;
  isRightClick: Boolean;
  i, j: Integer;
begin
  btn := NSButton(sender);
  tag := btn.tag;
  row := tag div 1000;
  col := tag mod 1000;
  
  event := NSApp.currentEvent;
  isRightClick := (event.type_ = NSRightMouseDown) or 
                  ((event.modifierFlags and NSControlKeyMask) <> 0);
  
  if isRightClick then
  begin
    FGameData.ToggleBlock(row, col);
    UpdateCellButton_col(row, col);
    
    if FGameData.CheckWin then
      ShowGameResult(True);
  end
  else
  begin
    FGameData.RevealCell(row, col);
    UpdateCellButton_col(row, col);
    
    if FGameData.GameOver then
    begin
      RevealAllMines;
      ShowGameResult(False);
    end
    else
    begin
      for i := 0 to FGameData.Rows - 1 do
        for j := 0 to FGameData.Cols - 1 do
          UpdateCellButton_col(i, j);
    end;
  end;
end;

procedure TGameController.cellRightClicked(sender: id);
begin
  cellClicked(sender);
end;

procedure TGameController.RevealAllMines;
var
  i, j: Integer;
begin
  for i := 0 to FGameData.Rows - 1 do
    for j := 0 to FGameData.Cols - 1 do
      if FGameData.FGrid[i][j].HasMine then
      begin
        if FGameData.FGrid[i][j].State <> csMine then
          FGameData.FGrid[i][j].State := csMine;
        UpdateCellButton_col(i, j);
      end;
end;

procedure TGameController.ShowGameResult(won: Boolean);
begin
  if won then
    FMessageLabel.setStringValue(NSSTR('Congratulations, you won!'))
  else
    FMessageLabel.setStringValue(NSSTR('Sorry, you lost!'));
  
  FMessageLabel.setHidden(False);
  FRestartButton.setHidden(False);
  
  if Assigned(FTimer) then
  begin
    FTimer.invalidate;
    FTimer := nil;
  end;
end;

procedure TGameController.HideGameResult;
begin
  FMessageLabel.setHidden(True);
  FRestartButton.setHidden(True);
end;

procedure TGameController.startNewGame(sender: id);
begin
  HideGameResult;
  FGameData.InitGame(FGameData.Mode);
  CreateGameUI;
  
  if Assigned(FTimer) then
    FTimer.invalidate;
  FTimer := NSTimer.scheduledTimerWithTimeInterval_target_selector_userInfo_repeats(
    1.0, Self, objcselector('updateTimer:'), nil, True);
end;

procedure TGameController.menuNewGameBeginner(sender: id);
begin
  HideGameResult;
  FGameData.InitGame(gmBeginner);
  CreateGameUI;
  
  if Assigned(FTimer) then
    FTimer.invalidate;
  FTimer := NSTimer.scheduledTimerWithTimeInterval_target_selector_userInfo_repeats(
    1.0, Self, objcselector('updateTimer:'), nil, True);
end;

procedure TGameController.menuNewGameIntermediate(sender: id);
begin
  HideGameResult;
  FGameData.InitGame(gmIntermediate);
  CreateGameUI;
  
  if Assigned(FTimer) then
    FTimer.invalidate;
  FTimer := NSTimer.scheduledTimerWithTimeInterval_target_selector_userInfo_repeats(
    1.0, Self, objcselector('updateTimer:'), nil, True);
end;

procedure TGameController.menuNewGameExpert(sender: id);
begin
  HideGameResult;
  FGameData.InitGame(gmExpert);
  CreateGameUI;
  
  if Assigned(FTimer) then
    FTimer.invalidate;
  FTimer := NSTimer.scheduledTimerWithTimeInterval_target_selector_userInfo_repeats(
    1.0, Self, objcselector('updateTimer:'), nil, True);
end;

procedure TGameController.updateTimer(timer: NSTimer);
var
  elapsed: Integer;
  timeStr: String;
begin
  if not FGameData.GameOver then
  begin
    elapsed := Round((Now - FGameData.StartTime) * 86400);
    timeStr := Format('Time: %ds', [elapsed]);
    FTimeLabel.setStringValue(NSSTR(PChar(timeStr)));
  end;
end;

procedure TGameController.dealloc;
begin
  if Assigned(FTimer) then
    FTimer.invalidate;
  if Assigned(FGameData) then
    FGameData.Free;
  if Assigned(FMainMenu) then
    FMainMenu.release;
  inherited dealloc;
end;

var
  app: NSApplication;
  controller: TGameController;

begin
  Randomize;
  app := NSApplication.sharedApplication;
  controller := TGameController.alloc.init;
  app.setDelegate(controller);
  app.run;
end.
