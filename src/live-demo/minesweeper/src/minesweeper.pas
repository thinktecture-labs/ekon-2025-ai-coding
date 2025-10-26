program minesweeper;

{$mode objfpc}{$H+}
{$modeswitch objectivec2}

uses
  CocoaAll, SysUtils, GameLogic;

type
  { Forward declarations }
  TGameController = objcclass;
  TMinesweeperView = objcclass;

  { TMinesweeperView - Custom NSView for rendering the minesweeper grid }
  TMinesweeperView = objcclass(NSView)
  private
    FGameData: TGameData;          // Reference to Pascal game logic class
    FCellSize: Double;             // Size of each cell in pixels
    FController: TGameController;  // Reference to controller for callbacks
    FTimer: NSTimer;               // Timer for updating elapsed time display

    procedure updateTimerDisplay(timer: NSTimer); message 'updateTimerDisplay:';

  public
    function initWithFrame_controller(frameRect: NSRect; controller: TGameController): id; message 'initWithFrame:controller:';
    procedure dealloc; override; message 'dealloc';
    procedure drawRect(dirtyRect: NSRect); override; message 'drawRect:';
    procedure mouseDown(event: NSEvent); override; message 'mouseDown:';
    procedure rightMouseDown(event: NSEvent); override; message 'rightMouseDown:';

    procedure startNewGame(mode: TGameMode); message 'startNewGame:';
    procedure updateDisplay; message 'updateDisplay';
    function gameData: TGameData; message 'gameData';
  end;

  { TGameController - Application delegate and menu handler }
  TGameController = objcclass(NSObject, NSApplicationDelegateProtocol)
  private
    FWindow: NSWindow;
    FView: TMinesweeperView;
    FMainMenu: NSMenu;           // Strong reference to prevent autorelease
    FCurrentMode: TGameMode;

  public
    function init: id; override; message 'init';
    procedure dealloc; override; message 'dealloc';

    { NSApplicationDelegate methods }
    procedure applicationDidFinishLaunching(notification: NSNotification); message 'applicationDidFinishLaunching:';
    function applicationShouldTerminateAfterLastWindowClosed(sender: id): Boolean; message 'applicationShouldTerminateAfterLastWindowClosed:';

    { Menu action handlers }
    procedure newGame(sender: id); message 'newGame:';
    procedure beginnerMode(sender: id); message 'beginnerMode:';
    procedure intermediateMode(sender: id); message 'intermediateMode:';
    procedure expertMode(sender: id); message 'expertMode:';

    { Helper methods }
    procedure updateWindowTitle; message 'updateWindowTitle';
    procedure resizeWindowForMode(mode: TGameMode); message 'resizeWindowForMode:';
  end;

{ TMinesweeperView Implementation }

function TMinesweeperView.initWithFrame_controller(frameRect: NSRect; controller: TGameController): id;
begin
  Result := inherited initWithFrame(frameRect);
  if Result <> nil then
  begin
    FCellSize := 32.0;  // 32x32 pixels per cell
    FController := controller;
    FGameData := TGameData.Create;
    FGameData.InitGame(gmBeginner);  // Start with Beginner mode

    // Start timer for updating elapsed time (fires every second)
    FTimer := NSTimer.scheduledTimerWithTimeInterval_target_selector_userInfo_repeats(
      1.0, Self, sel_registerName('updateTimerDisplay:'), nil, True);
  end;
end;

procedure TMinesweeperView.dealloc;
begin
  if Assigned(FTimer) then
  begin
    FTimer.invalidate;
    FTimer := nil;
  end;
  if Assigned(FGameData) then
    FGameData.Free;
  inherited dealloc;
end;

procedure TMinesweeperView.updateTimerDisplay(timer: NSTimer);
begin
  // Trigger redraw to update timer display
  if (FGameData.GameState = gsPlaying) then
    self.setNeedsDisplayInRect(self.bounds);
end;

procedure TMinesweeperView.drawRect(dirtyRect: NSRect);
var
  row, col: Integer;
  cellRect: NSRect;
  cell: TCell;
  text: NSString;
  textRect: NSRect;
  textColor: NSColor;
  attrs: NSMutableDictionary;
  font: NSFont;
  paragraphStyle: NSMutableParagraphStyle;
  timerRect: NSRect;
  timerText: NSString;
  timerHeight: Double;
begin
  // Define timer display area height
  timerHeight := 30.0;

  // Draw background
  NSColor.windowBackgroundColor.setFill;
  NSBezierPath.fillRect(self.bounds);

  // Draw timer at top
  timerRect := NSMakeRect(0, self.bounds.size.height - timerHeight,
                          self.bounds.size.width, timerHeight);
  NSColor.colorWithCalibratedWhite_alpha(0.95, 1.0).setFill;
  NSBezierPath.fillRect(timerRect);

  // Draw timer text
  timerText := NSString.stringWithFormat(NSSTR('Time: %d seconds'), FGameData.ElapsedSeconds);
  textRect := NSMakeRect(10, self.bounds.size.height - timerHeight + 5,
                        self.bounds.size.width - 20, 20);

  // Setup text attributes for timer
  attrs := NSMutableDictionary.dictionaryWithCapacity(2);
  font := NSFont.systemFontOfSize(14);
  attrs.setObject_forKey(font, NSFontAttributeName);
  attrs.setObject_forKey(NSColor.blackColor, NSForegroundColorAttributeName);

  timerText.drawInRect_withAttributes(textRect, attrs);

  // Draw grid cells (offset by timer height)
  for row := 0 to FGameData.Rows - 1 do
  begin
    for col := 0 to FGameData.Cols - 1 do
    begin
      // Calculate cell rectangle (Y coordinate flipped for Cocoa)
      // Cocoa origin is bottom-left, so we need to adjust
      cellRect := NSMakeRect(
        col * FCellSize,
        (FGameData.Rows - 1 - row) * FCellSize,  // Flip Y coordinate
        FCellSize - 1,
        FCellSize - 1
      );

      cell := FGameData.Cell[row, col];

      // Determine cell background color based on state
      if not cell.IsRevealed then
      begin
        if cell.IsFlagged then
          NSColor.orangeColor.setFill  // Flagged: orange
        else
          NSColor.lightGrayColor.setFill;  // Unrevealed: light grey
      end
      else
      begin
        if cell.HasMine then
          NSColor.redColor.setFill  // Mine hit: red
        else
          NSColor.colorWithCalibratedWhite_alpha(0.92, 1.0).setFill;  // Revealed: off-white
      end;

      NSBezierPath.fillRect(cellRect);

      // Draw cell border
      NSColor.gridColor.setStroke;
      NSBezierPath.strokeRect(cellRect);

      // Draw number if revealed and has adjacent mines
      if cell.IsRevealed and (not cell.HasMine) and (cell.AdjacentMines > 0) then
      begin
        // Determine number color based on adjacent mine count
        case cell.AdjacentMines of
          1: textColor := NSColor.colorWithCalibratedRed_green_blue_alpha(0.0, 0.6, 0.0, 1.0);  // green
          2: textColor := NSColor.colorWithCalibratedRed_green_blue_alpha(0.0, 0.4, 0.0, 1.0);  // dark green
          3: textColor := NSColor.colorWithCalibratedRed_green_blue_alpha(0.8, 0.8, 0.0, 1.0);  // yellow
          4: textColor := NSColor.orangeColor;  // orange
          else textColor := NSColor.redColor;  // 5+: red
        end;

        text := NSString.stringWithFormat(NSSTR('%d'), cell.AdjacentMines);

        // Setup text attributes for centered drawing
        attrs := NSMutableDictionary.dictionaryWithCapacity(3);
        font := NSFont.boldSystemFontOfSize(18);
        attrs.setObject_forKey(font, NSFontAttributeName);
        attrs.setObject_forKey(textColor, NSForegroundColorAttributeName);

        // Center align text
        paragraphStyle := NSMutableParagraphStyle.alloc.init.autorelease;
        paragraphStyle.setAlignment(NSCenterTextAlignment);
        attrs.setObject_forKey(paragraphStyle, NSParagraphStyleAttributeName);

        // Draw text centered in cell
        textRect := NSMakeRect(
          cellRect.origin.x,
          cellRect.origin.y + (FCellSize - 20) / 2,  // Center vertically
          FCellSize - 1,
          20
        );
        text.drawInRect_withAttributes(textRect, attrs);
      end;
    end;
  end;

  // Draw game over overlay if game is finished
  if (FGameData.GameState = gsWon) or (FGameData.GameState = gsLost) then
  begin
    // Semi-transparent black overlay
    NSColor.colorWithCalibratedWhite_alpha(0.0, 0.3).setFill;
    NSBezierPath.fillRect(NSMakeRect(0, 0, self.bounds.size.width,
                                     self.bounds.size.height - timerHeight));

    // Message text
    if FGameData.GameState = gsWon then
      text := NSSTR('Congratulations, you won!')
    else
      text := NSSTR('Sorry, you lost');

    // Setup text attributes for message
    attrs := NSMutableDictionary.dictionaryWithCapacity(3);
    font := NSFont.boldSystemFontOfSize(24);
    attrs.setObject_forKey(font, NSFontAttributeName);
    attrs.setObject_forKey(NSColor.whiteColor, NSForegroundColorAttributeName);

    // Center align
    paragraphStyle := NSMutableParagraphStyle.alloc.init.autorelease;
    paragraphStyle.setAlignment(NSCenterTextAlignment);
    attrs.setObject_forKey(paragraphStyle, NSParagraphStyleAttributeName);

    // Draw message centered on screen
    textRect := NSMakeRect(
      0,
      (self.bounds.size.height - timerHeight) / 2 - 15,
      self.bounds.size.width,
      30
    );
    text.drawInRect_withAttributes(textRect, attrs);
  end;
end;

procedure TMinesweeperView.mouseDown(event: NSEvent);
var
  point: NSPoint;
  col, row: Integer;
begin
  // Convert window coordinates to view coordinates
  point := self.convertPoint_fromView(event.locationInWindow, nil);

  // Calculate grid position (remember Y is flipped)
  col := Trunc(point.x / FCellSize);
  row := FGameData.Rows - 1 - Trunc(point.y / FCellSize);  // Flip Y back

  // Check if click is within grid bounds
  if (row >= 0) and (row < FGameData.Rows) and
     (col >= 0) and (col < FGameData.Cols) then
  begin
    // Check for Ctrl+Click (treat as right-click/flag)
    if (event.modifierFlags and NSControlKeyMask) <> 0 then
      FGameData.ToggleFlag(row, col)
    else
      FGameData.RevealCell(row, col);

    // Trigger redraw and update window title
    self.setNeedsDisplayInRect(self.bounds);
    FController.updateWindowTitle;
  end;
end;

procedure TMinesweeperView.rightMouseDown(event: NSEvent);
var
  point: NSPoint;
  col, row: Integer;
begin
  // Convert window coordinates to view coordinates
  point := self.convertPoint_fromView(event.locationInWindow, nil);

  // Calculate grid position (remember Y is flipped)
  col := Trunc(point.x / FCellSize);
  row := FGameData.Rows - 1 - Trunc(point.y / FCellSize);  // Flip Y back

  // Check if click is within grid bounds
  if (row >= 0) and (row < FGameData.Rows) and
     (col >= 0) and (col < FGameData.Cols) then
  begin
    FGameData.ToggleFlag(row, col);
    self.setNeedsDisplayInRect(self.bounds);
    FController.updateWindowTitle;
  end;
end;

procedure TMinesweeperView.startNewGame(mode: TGameMode);
begin
  FGameData.InitGame(mode);
  self.setNeedsDisplayInRect(self.bounds);
  FController.updateWindowTitle;
end;

procedure TMinesweeperView.updateDisplay;
begin
  self.setNeedsDisplayInRect(self.bounds);
end;

function TMinesweeperView.gameData: TGameData;
begin
  Result := FGameData;
end;

{ TGameController Implementation }

function TGameController.init: id;
begin
  Result := inherited init;
  if Result <> nil then
  begin
    FCurrentMode := gmBeginner;
  end;
end;

procedure TGameController.dealloc;
begin
  if Assigned(FMainMenu) then
    FMainMenu := nil;
  inherited dealloc;
end;

procedure TGameController.applicationDidFinishLaunching(notification: NSNotification);
var
  frame: NSRect;
  style: NSUInteger;
  timerHeight: Double;
begin
  timerHeight := 30.0;

  // Calculate window size for Beginner mode (9x9) + timer
  frame := NSMakeRect(0, 0,
                      BEGINNER_COLS * 32.0,
                      BEGINNER_ROWS * 32.0 + timerHeight);

  // Create window with standard macOS style
  style := NSTitledWindowMask or NSClosableWindowMask or NSMiniaturizableWindowMask;
  FWindow := NSWindow.alloc.initWithContentRect_styleMask_backing_defer(
    frame, style, NSBackingStoreBuffered, False);
  FWindow.setTitle(NSSTR('Minesweeper'));
  FWindow.center;

  // Create and install the minesweeper view
  FView := TMinesweeperView.alloc.initWithFrame_controller(
    NSMakeRect(0, 0, frame.size.width, frame.size.height), Self);
  FWindow.setContentView(FView);

  // Prevent user resizing by setting min/max size to current size
  FWindow.setMinSize(NSMakeSize(frame.size.width, frame.size.height));
  FWindow.setMaxSize(NSMakeSize(frame.size.width, frame.size.height));

  // Show window
  FWindow.makeKeyAndOrderFront(nil);
  NSApp.activateIgnoringOtherApps(True);

  updateWindowTitle;
end;

function TGameController.applicationShouldTerminateAfterLastWindowClosed(sender: id): Boolean;
begin
  Result := True;
end;

procedure TGameController.updateWindowTitle;
var
  title: NSString;
  modeStr: NSString;
begin
  // Determine mode string
  case FCurrentMode of
    gmBeginner: modeStr := NSSTR('Beginner');
    gmIntermediate: modeStr := NSSTR('Intermediate');
    gmExpert: modeStr := NSSTR('Expert');
  end;

  // Update title based on game state
  if FView.gameData.GameState = gsWon then
    title := NSString.stringWithFormat(NSSTR('Minesweeper - %@ - You Win!'), modeStr)
  else if FView.gameData.GameState = gsLost then
    title := NSString.stringWithFormat(NSSTR('Minesweeper - %@ - Game Over'), modeStr)
  else
    title := NSString.stringWithFormat(NSSTR('Minesweeper - %@'), modeStr);

  if FWindow <> nil then
    FWindow.setTitle(title);
end;

procedure TGameController.resizeWindowForMode(mode: TGameMode);
var
  config: TModeConfig;
  newFrame: NSRect;
  timerHeight: Double;
begin
  timerHeight := 30.0;
  config := TGameData.GetModeConfig(mode);

  // Calculate new window size
  newFrame := NSMakeRect(0, 0,
                         config.Cols * 32.0,
                         config.Rows * 32.0 + timerHeight);

  // Update window size constraints
  FWindow.setMinSize(NSMakeSize(newFrame.size.width, newFrame.size.height));
  FWindow.setMaxSize(NSMakeSize(newFrame.size.width, newFrame.size.height));

  // Resize window and view
  FWindow.setFrame_display(NSMakeRect(
    FWindow.frame.origin.x,
    FWindow.frame.origin.y + FWindow.frame.size.height - newFrame.size.height,
    newFrame.size.width,
    newFrame.size.height
  ), True);

  FView.setFrame(NSMakeRect(0, 0, newFrame.size.width, newFrame.size.height));
end;

{ Menu action handlers }

procedure TGameController.newGame(sender: id);
begin
  if FView <> nil then
  begin
    FView.startNewGame(FCurrentMode);
  end;
end;

procedure TGameController.beginnerMode(sender: id);
begin
  FCurrentMode := gmBeginner;
  resizeWindowForMode(gmBeginner);
  if FView <> nil then
    FView.startNewGame(gmBeginner);
end;

procedure TGameController.intermediateMode(sender: id);
begin
  FCurrentMode := gmIntermediate;
  resizeWindowForMode(gmIntermediate);
  if FView <> nil then
    FView.startNewGame(gmIntermediate);
end;

procedure TGameController.expertMode(sender: id);
begin
  FCurrentMode := gmExpert;
  resizeWindowForMode(gmExpert);
  if FView <> nil then
    FView.startNewGame(gmExpert);
end;

{ Menu setup procedure }

procedure BuildMenus(controller: TGameController);
var
  mainMenu, appMenu, gameMenu: NSMenu;
  appMenuItem, gameMenuItem, item: NSMenuItem;
begin
  // Create main menu bar
  mainMenu := NSMenu.alloc.initWithTitle(NSSTR('MainMenu'));

  { Application Menu }
  appMenuItem := NSMenuItem.alloc.init;
  appMenu := NSMenu.alloc.initWithTitle(NSSTR('Minesweeper'));

  // Quit menu item (Cmd+Q)
  item := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(
    NSSTR('Quit Minesweeper'),
    sel_registerName('terminate:'),
    NSSTR('q'));
  item.setKeyEquivalentModifierMask(NSCommandKeyMask);
  item.setTarget(NSApp);
  appMenu.addItem(item);

  appMenuItem.setSubmenu(appMenu);
  mainMenu.addItem(appMenuItem);

  { Game Menu }
  gameMenuItem := NSMenuItem.alloc.init;
  gameMenu := NSMenu.alloc.initWithTitle(NSSTR('Game'));

  // New Game menu item (Cmd+N)
  item := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(
    NSSTR('New Game'),
    sel_registerName('newGame:'),
    NSSTR('n'));
  item.setKeyEquivalentModifierMask(NSCommandKeyMask);
  item.setTarget(controller);
  gameMenu.addItem(item);

  // Separator
  gameMenu.addItem(NSMenuItem.separatorItem);

  // Game mode menu items
  item := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(
    NSSTR('Beginner (9x9)'),
    sel_registerName('beginnerMode:'),
    NSSTR('1'));
  item.setKeyEquivalentModifierMask(NSCommandKeyMask);
  item.setTarget(controller);
  gameMenu.addItem(item);

  item := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(
    NSSTR('Intermediate (16x16)'),
    sel_registerName('intermediateMode:'),
    NSSTR('2'));
  item.setKeyEquivalentModifierMask(NSCommandKeyMask);
  item.setTarget(controller);
  gameMenu.addItem(item);

  item := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(
    NSSTR('Expert (30x16)'),
    sel_registerName('expertMode:'),
    NSSTR('3'));
  item.setKeyEquivalentModifierMask(NSCommandKeyMask);
  item.setTarget(controller);
  gameMenu.addItem(item);

  gameMenuItem.setSubmenu(gameMenu);
  mainMenu.addItem(gameMenuItem);

  // Set as application main menu
  NSApp.setMainMenu(mainMenu);

  // Store strong reference to prevent autorelease
  controller.FMainMenu := mainMenu;
end;

{ Main program }
var
  app: NSApplication;
  controller: TGameController;
begin
  // Initialize random number generator
  Randomize;

  // Get shared application instance
  app := NSApplication.sharedApplication;

  // Set activation policy to regular app (shows in Dock, has menu bar)
  app.setActivationPolicy(NSApplicationActivationPolicyRegular);

  // Create and set application delegate
  controller := TGameController.alloc.init;
  app.setDelegate(controller);

  // Build menu system
  BuildMenus(controller);

  // Run the application event loop
  app.run;
end.
