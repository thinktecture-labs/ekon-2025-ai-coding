program minesweeper;

{$mode objfpc}{$H+}
{$modeswitch objectivec1}

uses
  CocoaAll, SysUtils, game_logic;

type
  { Forward declaration }
  TGameController = objcclass;

  { Custom NSView subclass for rendering the game board }
  TMinesweeperView = objcclass(NSView)
  private
    FGameData: TGameData;          // Reference to game logic
    FController: TGameController;  // Reference to controller for callbacks
    FCellSize: Double;             // Size of each cell in pixels

  public
    { Initialize view with game data and controller references }
    function initWithFrame_gameData_controller(frameRect: NSRect; gameData: TGameData; controller: TGameController): id; message 'initWithFrame:gameData:controller:';

    { Override drawing method to render the game board }
    procedure drawRect(dirtyRect: NSRect); message 'drawRect:'; override;

    { Override mouse event handlers }
    procedure mouseDown(event: NSEvent); message 'mouseDown:'; override;
    procedure rightMouseDown(event: NSEvent); message 'rightMouseDown:'; override;

    { Calculate cell size based on view bounds }
    procedure updateCellSize; message 'updateCellSize';

    { Helper to get cell coordinates from pixel position }
    procedure getCellAtPoint_row_col(point: NSPoint; rowPtr: PInteger; colPtr: PInteger); message 'getCellAtPoint:row:col:';
  end;

  { Main application controller }
  TGameController = objcclass(NSObject, NSApplicationDelegateProtocol)
  private
    FGameData: TGameData;          // Game logic instance
    FWindow: NSWindow;             // Main window
    FGameView: TMinesweeperView;   // Custom view for board
    FMainMenu: NSMenu;             // Main menu bar (retained to prevent autorelease)
    FTimer: NSTimer;               // Timer for updating elapsed time
    FTimeLabel: NSTextField;       // Label showing elapsed time
    FMineCountLabel: NSTextField;  // Label showing mine count
    FCurrentMode: TGameMode;       // Current difficulty mode

  public
    { NSApplication delegate methods }
    function applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication): Boolean; message 'applicationShouldTerminateAfterLastWindowClosed:';
    procedure applicationDidFinishLaunching(notification: NSNotification); message 'applicationDidFinishLaunching:';

    { Setup methods }
    procedure setupMenu; message 'setupMenu';
    procedure setupWindow; message 'setupWindow';
    procedure createGameView; message 'createGameView';

    { Game action methods }
    procedure newGame(sender: id); message 'newGame:';
    procedure setBeginner(sender: id); message 'setBeginner:';
    procedure setIntermediate(sender: id); message 'setIntermediate:';
    procedure setExpert(sender: id); message 'setExpert:';

    { Cell click callback from view }
    procedure cellClickedAtX_y_isRightClick(x: NSInteger; y: NSInteger; isRightClick: Boolean); message 'cellClickedAtX:y:isRightClick:';

    { Timer update }
    procedure updateTimer(timer: NSTimer); message 'updateTimer:';

    { Cleanup }
    procedure dealloc; override;
  end;

{ TMinesweeperView Implementation }

function TMinesweeperView.initWithFrame_gameData_controller(frameRect: NSRect; gameData: TGameData; controller: TGameController): id;
begin
  Result := inherited initWithFrame(frameRect);
  if Result <> nil then
  begin
    FGameData := gameData;
    FController := controller;
    updateCellSize;
  end;
end;

procedure TMinesweeperView.updateCellSize;
var
  widthPerCell, heightPerCell: Double;
begin
  if FGameData = nil then
  begin
    FCellSize := 30.0;
    Exit;
  end;

  // Calculate cell size based on view bounds and grid dimensions
  if FGameData.Cols > 0 then
    widthPerCell := self.bounds.size.width / FGameData.Cols
  else
    widthPerCell := 30.0;

  if FGameData.Rows > 0 then
    heightPerCell := self.bounds.size.height / FGameData.Rows
  else
    heightPerCell := 30.0;

  // Use the smaller dimension to ensure cells fit
  if widthPerCell < heightPerCell then
    FCellSize := widthPerCell
  else
    FCellSize := heightPerCell;
end;

procedure TMinesweeperView.drawRect(dirtyRect: NSRect);
var
  row, col: Integer;
  cell: TCell;
  cellRect: NSRect;
  cellColor: NSColor;
  borderColor: NSColor;
  path: NSBezierPath;
  numStr: NSString;
  textColor: NSColor;
  attrs: NSMutableDictionary;
  font: NSFont;
  paragraphStyle: NSMutableParagraphStyle;
  textRect: NSRect;
begin
  if FGameData = nil then
    Exit;

  // Draw each cell
  for row := 0 to FGameData.Rows - 1 do
  begin
    for col := 0 to FGameData.Cols - 1 do
    begin
      cell := FGameData.GetCell(row, col);

      // Calculate cell rectangle
      cellRect := NSMakeRect(
        col * FCellSize,
        (FGameData.Rows - row - 1) * FCellSize,  // Flip Y coordinate
        FCellSize,
        FCellSize
      );

      // Determine cell color based on state
      if cell.IsRevealed then
      begin
        if cell.IsMine then
          cellColor := NSColor.redColor  // Revealed mine (game over)
        else
          cellColor := NSColor.colorWithCalibratedWhite_alpha(0.92, 1.0);  // Revealed empty
      end
      else if cell.IsFlagged then
        cellColor := NSColor.orangeColor  // Flagged
      else
        cellColor := NSColor.lightGrayColor;  // Unrevealed

      // Fill cell background
      cellColor.setFill;
      path := NSBezierPath.bezierPathWithRect(cellRect);
      path.fill;

      // Draw cell border
      borderColor := NSColor.gridColor;
      borderColor.setStroke;
      path.stroke;

      // Draw text for revealed cells with adjacent mines
      if cell.IsRevealed and (not cell.IsMine) and (cell.AdjacentMines > 0) then
      begin
        numStr := NSSTR(PChar(IntToStr(cell.AdjacentMines)));

        // Determine text color based on number
        case cell.AdjacentMines of
          1: textColor := NSColor.colorWithRed_green_blue_alpha(0.0, 0.7, 0.0, 1.0);  // Green
          2: textColor := NSColor.colorWithRed_green_blue_alpha(0.0, 0.5, 0.0, 1.0);  // Dark green
          3: textColor := NSColor.colorWithRed_green_blue_alpha(0.9, 0.9, 0.0, 1.0);  // Yellow
          4: textColor := NSColor.orangeColor;
        else
          textColor := NSColor.redColor;
        end;

        // Create text attributes for centered text
        attrs := NSMutableDictionary.alloc.init;
        font := NSFont.boldSystemFontOfSize(FCellSize * 0.6);
        attrs.setObject_forKey(font, NSFontAttributeName);
        attrs.setObject_forKey(textColor, NSForegroundColorAttributeName);

        // Center text horizontally
        paragraphStyle := NSMutableParagraphStyle.alloc.init;
        paragraphStyle.setAlignment(NSCenterTextAlignment);
        attrs.setObject_forKey(paragraphStyle, NSParagraphStyleAttributeName);

        // Calculate text rectangle (centered vertically)
        textRect := cellRect;
        textRect.origin.y := textRect.origin.y + (FCellSize - font.pointSize) / 2 - 2;

        // Draw the text
        numStr.drawInRect_withAttributes(textRect, attrs);

        attrs.release;
        paragraphStyle.release;
      end
      else if cell.IsFlagged and (not cell.IsRevealed) then
      begin
        // Draw flag symbol
        numStr := NSSTR('🚩');

        attrs := NSMutableDictionary.alloc.init;
        font := NSFont.systemFontOfSize(FCellSize * 0.6);
        attrs.setObject_forKey(font, NSFontAttributeName);

        paragraphStyle := NSMutableParagraphStyle.alloc.init;
        paragraphStyle.setAlignment(NSCenterTextAlignment);
        attrs.setObject_forKey(paragraphStyle, NSParagraphStyleAttributeName);

        textRect := cellRect;
        textRect.origin.y := textRect.origin.y + (FCellSize - font.pointSize) / 2 - 2;

        numStr.drawInRect_withAttributes(textRect, attrs);

        attrs.release;
        paragraphStyle.release;
      end
      else if cell.IsRevealed and cell.IsMine then
      begin
        // Draw mine symbol
        numStr := NSSTR('💣');

        attrs := NSMutableDictionary.alloc.init;
        font := NSFont.systemFontOfSize(FCellSize * 0.6);
        attrs.setObject_forKey(font, NSFontAttributeName);

        paragraphStyle := NSMutableParagraphStyle.alloc.init;
        paragraphStyle.setAlignment(NSCenterTextAlignment);
        attrs.setObject_forKey(paragraphStyle, NSParagraphStyleAttributeName);

        textRect := cellRect;
        textRect.origin.y := textRect.origin.y + (FCellSize - font.pointSize) / 2 - 2;

        numStr.drawInRect_withAttributes(textRect, attrs);

        attrs.release;
        paragraphStyle.release;
      end;
    end;
  end;
end;

procedure TMinesweeperView.getCellAtPoint_row_col(point: NSPoint; rowPtr: PInteger; colPtr: PInteger);
var
  row, col: Integer;
begin
  col := Trunc(point.x / FCellSize);
  row := FGameData.Rows - 1 - Trunc(point.y / FCellSize);  // Flip Y coordinate

  if rowPtr <> nil then
    rowPtr^ := row;
  if colPtr <> nil then
    colPtr^ := col;
end;

procedure TMinesweeperView.mouseDown(event: NSEvent);
var
  location: NSPoint;
  localPoint: NSPoint;
  row, col: Integer;
  isRightClick: Boolean;
begin
  // Get event location and convert to view coordinates
  location := event.locationInWindow;
  localPoint := self.convertPoint_fromView(location, nil);

  // Get cell coordinates
  getCellAtPoint_row_col(localPoint, @row, @col);

  // Check for Ctrl modifier (treat as right-click)
  isRightClick := (event.modifierFlags and NSControlKeyMask) <> 0;

  // Notify controller
  if FController <> nil then
    FController.cellClickedAtX_y_isRightClick(row, col, isRightClick);
end;

procedure TMinesweeperView.rightMouseDown(event: NSEvent);
var
  location: NSPoint;
  localPoint: NSPoint;
  row, col: Integer;
begin
  // Get event location and convert to view coordinates
  location := event.locationInWindow;
  localPoint := self.convertPoint_fromView(location, nil);

  // Get cell coordinates
  getCellAtPoint_row_col(localPoint, @row, @col);

  // Notify controller (always treat as right-click)
  if FController <> nil then
    FController.cellClickedAtX_y_isRightClick(row, col, True);
end;

{ TGameController Implementation }

function TGameController.applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication): Boolean;
begin
  Result := True;
end;

procedure TGameController.applicationDidFinishLaunching(notification: NSNotification);
begin
  // CRITICAL: Set activation policy BEFORE creating windows
  NSApp.setActivationPolicy(NSApplicationActivationPolicyRegular);

  // Create game data with beginner mode
  FCurrentMode := gmBeginner;
  FGameData := TGameData.Create;
  FGameData.InitGame(FCurrentMode);

  // Setup UI
  setupMenu;
  setupWindow;
  createGameView;

  // Start timer for updating time display
  FTimer := NSTimer.scheduledTimerWithTimeInterval_target_selector_userInfo_repeats(
    1.0, Self, objcselector('updateTimer:'), nil, True);

  // Show window
  FWindow.makeKeyAndOrderFront(nil);
  NSApp.activateIgnoringOtherApps(True);
end;

procedure TGameController.setupMenu;
var
  appMenuItem, gameMenuItem: NSMenuItem;
  appMenu, gameMenu: NSMenu;
  quitItem, newGameItem, beginnerItem, intermediateItem, expertItem: NSMenuItem;
begin
  // Create main menu
  FMainMenu := NSMenu.alloc.init;

  // Application menu
  appMenuItem := NSMenuItem.alloc.init;
  FMainMenu.addItem(appMenuItem);

  appMenu := NSMenu.alloc.init;
  appMenuItem.setSubmenu(appMenu);

  quitItem := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(
    NSSTR('Quit Minesweeper'), objcselector('terminate:'), NSSTR('q'));
  quitItem.setTarget(NSApp);
  appMenu.addItem(quitItem);

  // Game menu
  gameMenuItem := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(
    NSSTR('Game'), nil, NSSTR(''));
  FMainMenu.addItem(gameMenuItem);

  gameMenu := NSMenu.alloc.initWithTitle(NSSTR('Game'));
  gameMenuItem.setSubmenu(gameMenu);

  // New Game item
  newGameItem := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(
    NSSTR('New Game'), objcselector('newGame:'), NSSTR('n'));
  newGameItem.setTarget(Self);
  gameMenu.addItem(newGameItem);

  gameMenu.addItem(NSMenuItem.separatorItem);

  // Beginner mode
  beginnerItem := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(
    NSSTR('Beginner (9x9)'), objcselector('setBeginner:'), NSSTR('1'));
  beginnerItem.setTarget(Self);
  gameMenu.addItem(beginnerItem);

  // Intermediate mode
  intermediateItem := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(
    NSSTR('Intermediate (16x16)'), objcselector('setIntermediate:'), NSSTR('2'));
  intermediateItem.setTarget(Self);
  gameMenu.addItem(intermediateItem);

  // Expert mode
  expertItem := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(
    NSSTR('Expert (30x16)'), objcselector('setExpert:'), NSSTR('3'));
  expertItem.setTarget(Self);
  gameMenu.addItem(expertItem);

  // Set as main menu
  NSApp.setMainMenu(FMainMenu);
end;

procedure TGameController.setupWindow;
var
  windowWidth, windowHeight: Double;
  cellSize: Double;
begin
  // Calculate window size based on grid
  if FGameData.Cols > 20 then
    cellSize := 25.0
  else if FGameData.Cols > 15 then
    cellSize := 30.0
  else
    cellSize := 40.0;

  windowWidth := FGameData.Cols * cellSize + 40;
  windowHeight := FGameData.Rows * cellSize + 100;

  // Create window
  FWindow := NSWindow.alloc.initWithContentRect_styleMask_backing_defer(
    NSMakeRect(100, 100, windowWidth, windowHeight),
    NSTitledWindowMask or NSClosableWindowMask or NSMiniaturizableWindowMask,
    NSBackingStoreBuffered,
    False);
  FWindow.setTitle(NSSTR('Minesweeper'));
  FWindow.center;

  // Create time label at top
  FTimeLabel := NSTextField.alloc.initWithFrame(
    NSMakeRect(20, windowHeight - 40, windowWidth / 2 - 30, 30));
  FTimeLabel.setStringValue(NSSTR('Time: 0s'));
  FTimeLabel.setBordered(False);
  FTimeLabel.setBackgroundColor(NSColor.clearColor);
  FTimeLabel.setEditable(False);
  FTimeLabel.setAlignment(NSLeftTextAlignment);

  // Create mine count label at top right
  FMineCountLabel := NSTextField.alloc.initWithFrame(
    NSMakeRect(windowWidth / 2 + 10, windowHeight - 40, windowWidth / 2 - 30, 30));
  FMineCountLabel.setStringValue(NSSTR(PChar(Format('Mines: %d', [FGameData.Mines]))));
  FMineCountLabel.setBordered(False);
  FMineCountLabel.setBackgroundColor(NSColor.clearColor);
  FMineCountLabel.setEditable(False);
  FMineCountLabel.setAlignment(NSRightTextAlignment);
end;

procedure TGameController.createGameView;
var
  contentView: NSView;
  gameViewHeight: Double;
begin
  contentView := FWindow.contentView;

  // Calculate game view height (leave space for labels at top)
  gameViewHeight := contentView.bounds.size.height - 50;

  // Create game view
  if FGameView <> nil then
  begin
    FGameView.removeFromSuperview;
    FGameView.release;
  end;

  FGameView := TMinesweeperView.alloc.initWithFrame_gameData_controller(
    NSMakeRect(20, 10, contentView.bounds.size.width - 40, gameViewHeight),
    FGameData,
    Self);

  contentView.addSubview(FGameView);
  contentView.addSubview(FTimeLabel);
  contentView.addSubview(FMineCountLabel);
end;

procedure TGameController.newGame(sender: id);
begin
  // Restart with current mode
  FGameData.InitGame(FCurrentMode);

  // Update mine count label
  FMineCountLabel.setStringValue(NSSTR(PChar(Format('Mines: %d', [FGameData.Mines]))));

  // Update window title
  FWindow.setTitle(NSSTR('Minesweeper'));

  // Redraw game view
  FGameView.setNeedsDisplayInRect(FGameView.bounds);

  // Reset timer
  FTimeLabel.setStringValue(NSSTR('Time: 0s'));
end;

procedure TGameController.setBeginner(sender: id);
begin
  FCurrentMode := gmBeginner;
  FGameData.InitGame(FCurrentMode);

  // Resize window for new grid size
  setupWindow;
  createGameView;

  FWindow.setTitle(NSSTR('Minesweeper - Beginner'));
  FTimeLabel.setStringValue(NSSTR('Time: 0s'));
end;

procedure TGameController.setIntermediate(sender: id);
begin
  FCurrentMode := gmIntermediate;
  FGameData.InitGame(FCurrentMode);

  // Resize window for new grid size
  setupWindow;
  createGameView;

  FWindow.setTitle(NSSTR('Minesweeper - Intermediate'));
  FTimeLabel.setStringValue(NSSTR('Time: 0s'));
end;

procedure TGameController.setExpert(sender: id);
begin
  FCurrentMode := gmExpert;
  FGameData.InitGame(FCurrentMode);

  // Resize window for new grid size
  setupWindow;
  createGameView;

  FWindow.setTitle(NSSTR('Minesweeper - Expert'));
  FTimeLabel.setStringValue(NSSTR('Time: 0s'));
end;

procedure TGameController.cellClickedAtX_y_isRightClick(x: NSInteger; y: NSInteger; isRightClick: Boolean);
var
  alert: NSAlert;
  response: NSInteger;
begin
  // Check if game is already over
  if FGameData.GameWon or FGameData.GameLost then
    Exit;

  if isRightClick then
  begin
    // Toggle flag
    FGameData.ToggleFlag(x, y);

    // Check win condition
    if FGameData.CheckWinCondition then
    begin
      // Game won!
      FWindow.setTitle(NSSTR('Minesweeper - You Won!'));

      // Show congratulations alert
      alert := NSAlert.alloc.init;
      alert.setMessageText(NSSTR('Congratulations!'));
      alert.setInformativeText(NSSTR('You won! All mines have been revealed.'));
      alert.addButtonWithTitle(NSSTR('New Game'));
      alert.addButtonWithTitle(NSSTR('OK'));

      response := alert.runModal;
      alert.release;

      if response = NSAlertFirstButtonReturn then
        newGame(nil);
    end;
  end
  else
  begin
    // Reveal cell
    if not FGameData.RevealCell(x, y) then
    begin
      // Hit a mine - game lost
      FWindow.setTitle(NSSTR('Minesweeper - Game Over'));

      // Show game over alert
      alert := NSAlert.alloc.init;
      alert.setMessageText(NSSTR('Game Over'));
      alert.setInformativeText(NSSTR('You hit a mine! Better luck next time.'));
      alert.addButtonWithTitle(NSSTR('New Game'));
      alert.addButtonWithTitle(NSSTR('OK'));

      response := alert.runModal;
      alert.release;

      if response = NSAlertFirstButtonReturn then
        newGame(nil);
    end
    else if FGameData.GameWon then
    begin
      // Game won by revealing all safe cells
      FWindow.setTitle(NSSTR('Minesweeper - You Won!'));

      alert := NSAlert.alloc.init;
      alert.setMessageText(NSSTR('Congratulations!'));
      alert.setInformativeText(NSSTR('You won! All safe cells have been revealed.'));
      alert.addButtonWithTitle(NSSTR('New Game'));
      alert.addButtonWithTitle(NSSTR('OK'));

      response := alert.runModal;
      alert.release;

      if response = NSAlertFirstButtonReturn then
        newGame(nil);
    end;
  end;

  // Redraw game view
  FGameView.setNeedsDisplayInRect(FGameView.bounds);
end;

procedure TGameController.updateTimer(timer: NSTimer);
var
  elapsed: Integer;
  timeStr: String;
begin
  if not FGameData.GameWon and not FGameData.GameLost then
  begin
    elapsed := FGameData.GetElapsedTime;
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
  pool: NSAutoreleasePool;

begin
  Randomize;
  pool := NSAutoreleasePool.new;
  app := NSApplication.sharedApplication;

  controller := TGameController.alloc.init;
  app.setDelegate(controller);
  app.run;

  pool.release;
end.
