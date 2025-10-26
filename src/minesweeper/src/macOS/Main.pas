program Main;

{$mode objfpc}{$H+}
{$modeswitch objectivec2}

uses
  CocoaAll, uBoard, uGameView;

type
  AppDelegate = objcclass(NSObject, NSApplicationDelegateProtocol)
  private
    window: NSWindow;
    view: TMinesweeperView;
  public
    procedure applicationDidFinishLaunching(notification: NSNotification); message 'applicationDidFinishLaunching:';
    function applicationShouldTerminateAfterLastWindowClosed(sender: id): Boolean; message 'applicationShouldTerminateAfterLastWindowClosed:';
    procedure newGame(sender: id); message 'newGame:';
  end;

procedure BuildMenus(delegate: AppDelegate); forward;

procedure AppDelegate.applicationDidFinishLaunching(notification: NSNotification);
var
  frame: NSRect;
  style: NSUInteger;
begin
  frame := NSMakeRect(0, 0, 9*28+1, 9*28+1);
  // Use legacy-style masks for broader FPC Cocoa header compatibility
  style := NSTitledWindowMask or NSClosableWindowMask or NSMiniaturizableWindowMask;
  window := NSWindow.alloc.initWithContentRect_styleMask_backing_defer(frame, style, NSBackingStoreBuffered, False);
  window.setTitle(NSSTR('Minesweeper'));
  window.center;
  // Install game view
  view := TMinesweeperView.alloc.initWithFrame(NSMakeRect(0,0,frame.size.width, frame.size.height));
  window.setContentView(view);
  // Prevent user resizing: keep min/max identical to initial size
  window.setMinSize(NSMakeSize(frame.size.width, frame.size.height));
  window.setMaxSize(NSMakeSize(frame.size.width, frame.size.height));
  window.makeKeyAndOrderFront(nil);
  NSApp.activateIgnoringOtherApps(True);
end;

function AppDelegate.applicationShouldTerminateAfterLastWindowClosed(sender: id): Boolean;
begin
  Result := True;
end;

procedure AppDelegate.newGame(sender: id);
begin
  if view <> nil then view.NewGame;
end;

procedure BuildMenus(delegate: AppDelegate);
var
  mainMenu, appMenu, gameMenu: NSMenu;
  appItem, gameItem, item: NSMenuItem;
begin
  mainMenu := NSMenu.alloc.initWithTitle(NSSTR('MainMenu'));

  // App menu
  appItem := NSMenuItem.alloc.init;
  appMenu := NSMenu.alloc.initWithTitle(NSSTR('Minesweeper'));
  item := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(NSSTR('Quit Minesweeper'), sel_registerName('terminate:'), NSSTR('q'));
  item.setKeyEquivalentModifierMask(NSCommandKeyMask);
  appMenu.addItem(item);
  appItem.setSubmenu(appMenu);
  mainMenu.addItem(appItem);

  // Game menu
  gameItem := NSMenuItem.alloc.init;
  gameMenu := NSMenu.alloc.initWithTitle(NSSTR('Game'));
  item := NSMenuItem.alloc.initWithTitle_action_keyEquivalent(NSSTR('New Game'), sel_registerName('newGame:'), NSSTR('n'));
  item.setKeyEquivalentModifierMask(NSCommandKeyMask);
  item.setTarget(delegate);
  gameMenu.addItem(item);
  gameItem.setSubmenu(gameMenu);
  mainMenu.addItem(gameItem);

  NSApp.setMainMenu(mainMenu);
end;

var
  app: NSApplication;
  delegate: AppDelegate;
begin
  app := NSApplication.sharedApplication;
  delegate := AppDelegate.alloc.init;
  app.setDelegate(delegate);
  BuildMenus(delegate);
  app.run;
end.
