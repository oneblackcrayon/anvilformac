#import "NVPanelController.h"
#import "NVBackgroundView.h"
#import "NVStatusItemView.h"
#import "NVMenubarController.h"
#import "NVTableRowView.h"
#import "NVTableCellView.h"
#import <QuartzCore/QuartzCore.h>

#define SEARCH_INSET 15

#define OPEN_DURATION .15
#define CLOSE_DURATION .1

#define POPUP_HEIGHT 122
#define PANEL_WIDTH 335
#define MENU_ANIMATION_DURATION .1

#pragma mark -

@interface NVPanelController ()
@property (nonatomic) NSInteger selectedRow;
@property (nonatomic) BOOL isEditing;
@property (nonatomic) BOOL isShowingModal;
@property (nonatomic) BOOL panelIsOpen;

@end

@implementation NVPanelController

static NSString *const kAppListTableCellIdentifier = @"appListTableCellIdentifier";
static NSString *const kAppListTableRowIdentifier = @"appListTableRowIdentifier";

#pragma mark -

- (id)init {
    
    self = [super init];
    
    if (self != nil) {
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:@"/usr/bin/curl"];
        
        [task setArguments:[NSArray arrayWithObjects:@"--silent", @"-H", @"host:pow", @"localhost:80/status.json", nil]];
        
        NSPipe *outputPipe = [NSPipe pipe];
        [task setStandardInput:[NSPipe pipe]];
        [task setStandardError:[NSPipe pipe]];
        [task setStandardOutput:outputPipe];
        [task launch];
        [task waitUntilExit];
        
        NSData *pipeData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
        NSString *pipeString = [[NSString alloc] initWithData:pipeData encoding:NSUTF8StringEncoding];
        NSLog(@"%@", pipeString);
        
        BOOL status = [pipeString length] > 0;
        [self.switchView switchTo:status withAnimation:NO];
    }
    
    return self;
}

- (id)initWithDelegate:(id<NVPanelControllerDelegate>)delegate {
    
    self = [super initWithWindowNibName:@"Panel"];
    if (self != nil)
    {
        _delegate = delegate;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSControlTextDidChangeNotification object:self.searchField];
}

#pragma mark -

- (void)awakeFromNib {
    
    [super awakeFromNib];
    
    // Make a fully skinned panel
    NSPanel *panel = (id)[self window];
    
    [panel setAcceptsMouseMovedEvents:YES];
    [panel setLevel:NSPopUpMenuWindowLevel];
    [panel setOpaque:NO];
    [panel setBackgroundColor:[NSColor clearColor]];
    
    self.headerView.backgroundImage = [NSImage imageNamed:@"Titlebar"];
    self.headerIconView.backgroundImage = [NSImage imageNamed:@"TitlebarIcon"];

    NSInteger height = self.headerIconView.backgroundImage.size.height;
    NSInteger width = self.headerIconView.backgroundImage.size.width;
    NSInteger x = (self.window.frame.size.width / 2.0 - width / 2.0);
    NSInteger y = (self.headerView.frame.size.height / 2.0 - height / 2.0);
    
    self.headerIconView.frame = CGRectMake(x, y, width, height);

//    self.appListTableView.gridStyleMask = NSTableViewSolidHorizontalGridLineMask;
    self.appListTableView.menu = [self menuForTableView];
    [self.appListTableView setDoubleAction:@selector(appListTableViewDoubleClicked:)];
    
    [self.backgroundView setBackgroundColor:[NSColor colorWithDeviceRed:244.0/255.0 green:244.0/255.0 blue:244.0/255.0 alpha:1]];
    [self.appListTableView setBackgroundColor:[NSColor colorWithDeviceRed:244.0/255.0 green:244.0/255.0 blue:244.0/255.0 alpha:1]];
    
    int opts = (NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways);
    NSTrackingArea *trackingArea = [ [NSTrackingArea alloc] initWithRect:[[self appListTableView] bounds]
                                                 options:opts
                                                   owner:self
                                                userInfo:nil];
    [[self appListTableView] addTrackingArea:trackingArea];
    
    [self.appListTableScrollView.layer setMasksToBounds:YES];
    [self.appListTableScrollView setWantsLayer:YES];
    [self.appListTableScrollView.layer setOpaque:NO];
    [self.appListTableScrollView.layer setCornerRadius:4];
    [self.appListTableScrollView.contentView setWantsLayer:YES];
    [self.appListTableScrollView setBackgroundColor:[NSColor clearColor]];
    
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.4]];
    [shadow setShadowOffset:NSMakeSize(0, -1)];
    [shadow setShadowBlurRadius:0.0];
    [self.switchLabel setTextShadow:shadow];
    
    self.addButton.image = [NSImage imageNamed:@"AddButton"];
    self.addButton.alternateImage = [NSImage imageNamed:@"AddButtonPushed"];
    
    self.switchView.delegate = self;
    self.isEditing = NO;
    
    self.settingsDivider.backgroundImage = [NSImage imageNamed:@"TitlebarSplit"];

    [self setupSettingsButton];
}

- (void)setupSettingsButton {
    
    self.settingsButton.image = [NSImage imageNamed:@"Settings"];
    self.settingsButton.alternateImage = [NSImage imageNamed:@"SettingsAlt"];
    
    NSMenu *settingsMenu = [[NSMenu alloc] initWithTitle:@"Settings"];
    [settingsMenu addItem:[[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""]]; // First one gets eaten by the dropdown button. It's weird.
    [settingsMenu addItem:[[NSMenuItem alloc] initWithTitle:@"Restart Pow" action:@selector(didClickRestartPow:) keyEquivalent:@""]];
    [settingsMenu addItem:[[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(didClickQuit:) keyEquivalent:@""]];
    
    [self.settingsButton setMenu:settingsMenu];
    [self.settingsButton setPreferredEdge:NSMinYEdge];
    [self.settingsButton setPullsDown:YES];
    [self.settingsButton selectItem: nil];
    
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@""
                                                  action:NULL keyEquivalent:@""];
    [item setImage:[NSImage imageNamed:@"Settings"]];
    [item setOnStateImage:nil];
    [item setMixedStateImage:nil];
    [[self.settingsButton cell] setMenuItem:item];
    
    [[self.settingsButton cell] setBordered:NO];
    [[self.settingsButton cell] setImagePosition:NSImageOnly];
    [[self.settingsButton cell] setArrowPosition:NSPopUpNoArrow];
    [[self.settingsButton cell] setUsesItemFromMenu:NO];
    [[self.settingsButton cell] setAlternateImage:[NSImage imageNamed:@"SettingsAlt"]];

}

- (void)didClickQuit:(id)sender {
    
    [[NSApplication sharedApplication] terminate:nil];
}

- (void)didClickRestartPow:(id)sender {
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/touch"];
    [task setArguments:[NSArray arrayWithObjects:[@"~/.pow/restart.txt" stringByExpandingTildeInPath], nil]];
    [task launch];
}

- (IBAction)didClickAddButton:(id)sender {
    
    NSOpenPanel *openPanel = [[NSOpenPanel alloc] init];
    openPanel.delegate = self;
    
    NSURL *sitesURL = [NSURL URLWithString:[@"~/Sites" stringByExpandingTildeInPath]];
    NSString *sitesURLString = [NSString stringWithFormat:@"file://%@", sitesURL.path];
    [openPanel setCanChooseDirectories:YES];
    openPanel.directoryURL = [NSURL URLWithString:sitesURLString];
    
    self.isShowingModal = YES;
    
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [openPanel beginSheetModalForWindow:nil completionHandler:^(NSInteger result) {
        
        self.isShowingModal = NO;
        if (result == NSFileHandlingPanelCancelButton) {
            return;
        }
        
        [[NVDataSource sharedDataSource] addAppWithURL:openPanel.URL];
        [[NVDataSource sharedDataSource] readInSavedAppDataFromDisk];
        [self.appListTableView reloadData];
        [self updatePanelHeightAndAnimate:YES];
    }];
}


- (void)switchView:(NVSwitchView *)switchView didSwitchTo:(BOOL)state {

    if (state) {
        
        [self.switchLabel setText:@"ON"];
        system("launchctl load -Fw \"$HOME/Library/LaunchAgents/cx.pow.powd.plist\" 2>/dev/null");
    } else {
        
        [self.switchLabel setText:@"OFF"];
        system("launchctl unload \"$HOME/Library/LaunchAgents/cx.pow.powd.plist\" 2>/dev/null");
    }
}

#pragma mark - Public accessors

- (BOOL)hasActivePanel {
    return _hasActivePanel;
}

- (void)setHasActivePanel:(BOOL)flag {
    
    if (self.isShowingModal) {
        
        return;
    }
    
    if (_hasActivePanel != flag) {
        
        _hasActivePanel = flag;
        if (_hasActivePanel) {
            
            [self openPanel];
        } else {
            
            [self closePanel];
        }
    }
}

#pragma mark - NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification {
    self.hasActivePanel = NO;
}

- (void)windowDidResignKey:(NSNotification *)notification; {
    if ([[self window] isVisible]) {
        self.hasActivePanel = NO;
    }
}

- (void)windowDidResize:(NSNotification *)notification {
    
    NSWindow *panel = [notification object];

    NSRect statusRect = [self statusRectForWindow:panel];
    NSRect panelRect = [panel frame];

    CGFloat statusX = roundf(NSMidX(statusRect));
    CGFloat panelX = statusX - NSMinX(panelRect);

    self.backgroundView.arrowX = panelX;
    
    NSInteger appListHeight = panel.frame.size.height - self.headerView.frame.size.height - 6;
    [self.appListTableScrollView setFrame:NSMakeRect(1, 1, PANEL_WIDTH - 2, appListHeight)];
}

#pragma mark - Keyboard

- (void)cancelOperation:(id)sender {
    self.hasActivePanel = NO;
}

#pragma mark - Public methods

- (NSRect)statusRectForWindow:(NSWindow *)window {
    
    NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
    NSRect statusRect = NSZeroRect;
    
    NVStatusItemView *statusItemView = nil;
    if ([self.delegate respondsToSelector:@selector(statusItemViewForPanelController:)]) {
        statusItemView = [self.delegate statusItemViewForPanelController:self];
    }
    
    if (statusItemView) {
        statusRect = statusItemView.globalRect;
        statusRect.origin.y = NSMinY(statusRect) - NSHeight(statusRect);
    } else {
        statusRect.size = NSMakeSize(STATUS_ITEM_VIEW_WIDTH, [[NSStatusBar systemStatusBar] thickness]);
        statusRect.origin.x = roundf((NSWidth(screenRect) - NSWidth(statusRect)) / 2);
        statusRect.origin.y = NSHeight(screenRect) - NSHeight(statusRect) * 2;
    }
    return statusRect;
}

- (void)openPanel {
    
    if (self.panelIsOpen) {
        [self.appListTableView reloadData];
        [self updatePanelHeightAndAnimate:YES];
        return;
    }
    
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    
    self.panelIsOpen = YES;
    
    [[self appListTableView] reloadData];
    
    [self updatePanelHeightAndAnimate:NO];
        
    NSWindow *panel = [self window];
    
    NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
    NSRect statusRect = [self statusRectForWindow:panel];
    
    NSRect panelRect = [panel frame];
    panelRect.size.width = PANEL_WIDTH;
    
    panelRect.origin.x = roundf(NSMidX(statusRect) - NSWidth(panelRect) / 2);
    panelRect.origin.y = NSMaxY(statusRect) - NSHeight(panelRect);
    
    if (NSMaxX(panelRect) > (NSMaxX(screenRect) - ARROW_HEIGHT))
        panelRect.origin.x -= NSMaxX(panelRect) - (NSMaxX(screenRect) - ARROW_HEIGHT);
    
    [NSApp activateIgnoringOtherApps:NO];
    [panel setFrame:panelRect display:YES];
    [panel setAlphaValue:1];
    
    [panel performSelector:@selector(makeFirstResponder:) withObject:self.appListTableView afterDelay:0];
    
    [self updatePanelHeightAndAnimate:NO];
        
    [panel makeKeyAndOrderFront:nil];
}

- (void)togglePanel {
    
    if (self.panelIsOpen) {
        [self closePanel];
    } else {
        [self openPanel];
    }
}

- (void)closePanel {
    
    if (!self.panelIsOpen) {
        return;
    }
    
    [[NSApplication sharedApplication] deactivate];
    
    self.panelIsOpen = NO;
    [[self window] setAlphaValue:0];
    
    dispatch_after(dispatch_walltime(NULL, NSEC_PER_SEC * CLOSE_DURATION * 2), dispatch_get_main_queue(), ^{
        
        [self.window orderOut:nil];
    });
}

#pragma mark - Sizing

- (BOOL)isPowInstalled {
    
    NSString *powPath = [@"~/.pow" stringByExpandingTildeInPath];
    BOOL isDirectory;
    BOOL isThere = [[NSFileManager defaultManager] fileExistsAtPath:powPath isDirectory:&isDirectory];
    return isThere && isDirectory;
}

- (void)updatePanelHeightAndAnimate:(BOOL)shouldAnimate {
    
    [self.appListTableView sizeToFit];
    
    NSRect panelRect = [[self window] frame];
    
    NSInteger newHeight = (self.appListTableView.rowHeight + self.appListTableView.intercellSpacing.height) * [self.appListTableView numberOfRows] + 6 + self.headerView.frame.size.height;
    
    NSInteger y = [[NSScreen mainScreen] frame].size.height - newHeight - 24;
    panelRect = CGRectMake(panelRect.origin.x, y, panelRect.size.width, newHeight);
    
    if ([[[NVDataSource sharedDataSource] apps] count] == 0) {
        
        if ([self isPowInstalled]) {
            
            self.noAppsView.hidden = NO;
            self.welcomeView.hidden = YES;
            
            panelRect.origin.y -= self.noAppsView.frame.size.height;
            panelRect.size.height += self.noAppsView.frame.size.height;
        } else {
            
            self.noAppsView.hidden = YES;
            self.welcomeView.hidden = NO;

            panelRect.origin.y -= self.welcomeView.frame.size.height;
            panelRect.size.height += self.welcomeView.frame.size.height;
        }
    } else {
        self.noAppsView.hidden = YES;
        self.welcomeView.hidden = YES;
    }
    
    if (shouldAnimate) {
        [[[self window] animator] setFrame:panelRect display:YES];
    } else {
        [self.window setFrame:panelRect display:YES];
    }
}

- (void)renderAlternatePanels {
    
    [self.appListTableView setHidden:YES];
    
    if ([[[NVDataSource sharedDataSource] apps] count] > 0) {
        
    } else {
        [self.noAppsView setHidden:NO];
        [self.noAppsView setFrame:self.window.frame];
    }
}

#pragma mark - Table View Delegate

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView {
    
    return NO;
}

- (BOOL)tableView:(NSTableView *)tableView shouldTrackCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    return YES;
}

-(void)mouseMoved:(NSEvent *)theEvent {
    
    NSPoint point = [self.appListTableView convertPoint:[theEvent locationInWindow] fromView:self.backgroundView];
    NSInteger row = [self.appListTableView rowAtPoint:point];
    
    
    if (!self.isEditing) {
        
        // A bug - we have to reset the selection, I think. Changes aren't fired when it's the same.
        [self.appListTableView selectRowIndexes:[[NSIndexSet alloc] init] byExtendingSelection:NO];
        [self.appListTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    }
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    
    return [[[NVDataSource sharedDataSource] apps] count];
}

- (void)mouseExited:(NSEvent *)theEvent {
    
    if (!self.isEditing && [self.appListTableView selectedRow] > -1) {

        [[self.appListTableView rowViewAtRow:[self.appListTableView selectedRow] makeIfNecessary:NO] setBackgroundColor:[NSColor clearColor]];
        [[self.appListTableView viewAtColumn:0 row:[self.appListTableView selectedRow] makeIfNecessary:NO] hideControls];
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    
    self.isEditing = NO;
    
    if (self.selectedRow > -1 && self.selectedRow < self.appListTableView.numberOfRows) {
        [[self.appListTableView rowViewAtRow:self.selectedRow makeIfNecessary:NO] setBackgroundColor:[NSColor clearColor]];
        [[self.appListTableView viewAtColumn:0 row:self.selectedRow makeIfNecessary:NO] hideControls];
    }
    
    self.selectedRow = [self.appListTableView selectedRow];
    
    if ([self.appListTableView selectedRow] > -1) {
        
        [[self.appListTableView viewAtColumn:0 row:self.selectedRow makeIfNecessary:NO] showControls];
        [[self.appListTableView rowViewAtRow:[self.appListTableView selectedRow] makeIfNecessary:NO] setBackgroundColor:[NSColor whiteColor]];
    }
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    NVApp *app = [[[NVDataSource sharedDataSource] apps] objectAtIndex:row];
    
    NVTableCellView *cellView = (NVTableCellView *)[tableView makeViewWithIdentifier:kAppListTableCellIdentifier owner:self];
    [cellView.siteLabel setText:app.name];
    [cellView.siteLabel setTextColor:[NSColor colorWithDeviceRed:68.0/255.0 green:68.0/255.0 blue:68.0/255.0 alpha:1.0]];
    [cellView.siteLabel setEnabled:NO];
    [cellView.siteLabel sizeToFit];
    cellView.siteLabel.delegate = self;
    [cellView.siteLabel setWidth];
    
    [cellView hideControls];
    [cellView.siteLabel setWidth];
    
    [cellView resizeSubviewsWithOldSize:cellView.frame.size];
    
    if (app.faviconURL) {
    
        cellView.faviconImageView.backgroundImage = [NSImage imageNamed:@"SiteIcon"];
        NSImage *faviconImage = [[NSImage alloc] initWithContentsOfURL:app.faviconURL];
        cellView.faviconImageView.foregroundImage = [self imageRepresentationOfImage:faviconImage
                                                                            withSize:NSMakeSize(16, 16)];
    } else {
        
        cellView.faviconImageView.backgroundImage = [NSImage imageNamed:@"SiteIconDefault"];
    }

    return cellView;
}


- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    
    NVTableRowView *rowView = (NVTableRowView *)[tableView makeViewWithIdentifier:kAppListTableRowIdentifier owner:self];
    if (rowView == nil) {
        
        rowView = [[NVTableRowView alloc] init];
        rowView.identifier = kAppListTableRowIdentifier;
    }
    
    return rowView;
}

- (NSImage *)imageRepresentationOfImage:(NSImage *)image withSize:(NSSize)size {
    
    NSImage *requestedRepresentationImage = nil;
    for (NSBitmapImageRep *representation in image.representations) {
        
        if (CGSizeEqualToSize(representation.size, size)) {
            requestedRepresentationImage = [[NSImage alloc] initWithData:[representation TIFFRepresentation]];
        }
    }
    
    return requestedRepresentationImage;
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    
    if (commandSelector == @selector(cancelOperation:)) {
        
        self.isEditing = NO;
        [self.appListTableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.0];
    }
    return NO;
}

- (void)resizeTextField:(NVLabel *)textField {
    
    NSRect frame = textField.frame;
    
    float fontSize = [[textField.font.fontDescriptor objectForKey:NSFontSizeAttribute] floatValue];
    NSString *fontName = [textField.font.fontDescriptor objectForKey:NSFontNameAttribute];
    
    NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                fontName, NSFontNameAttribute,
                                [NSNumber numberWithFloat:fontSize], NSFontSizeAttribute,
                                nil];
    
    NSAttributedString* attributedString = [[NSAttributedString alloc] initWithString:textField.text attributes:attributes];
    NSSize size = attributedString.size;
    NSInteger width = (int)size.width + 8;
    
    [textField setFrame:CGRectMake(frame.origin.x, frame.origin.y, width, frame.size.height)];
}

- (void)controlTextDidChange:(NSNotification *)obj  {
    
    NVTableCellView *tableCellView = [self.appListTableView viewAtColumn:0 row:self.selectedRow makeIfNecessary:NO];
    tableCellView.localLabel.hidden =  YES;
    
    [self resizeTextField: [obj object]];
}

- (void)controlTextDidEndEditing:(NSNotification *)obj {
    
    self.isEditing = NO;

    NSTextField *textField = (NSTextField *)obj.object;
    NSInteger selectedIndex = self.selectedRow;
    
    NVTableCellView *tableCellView = [self.appListTableView viewAtColumn:0 row:self.selectedRow makeIfNecessary:NO];
    tableCellView.localLabel.hidden =  NO;
    
    NVApp *app = (NVApp *)[[NVDataSource sharedDataSource].apps objectAtIndex:selectedIndex];
    [app renameTo:textField.stringValue];
    
    [[NVDataSource sharedDataSource] readInSavedAppDataFromDisk];
    [self.appListTableView reloadData];
}

#pragma mark - Menus

- (NSMenu *)menuForTableView {
    
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Site Menu"];
    
    NSMenuItem *openInBrowserMenuItem = [[NSMenuItem alloc] initWithTitle:@"Open in Browser" action:@selector(didClickOpenWithBrowser:) keyEquivalent:@""];
    [menu addItem:openInBrowserMenuItem];
    NSMenuItem *openInFinderMenuItem = [[NSMenuItem alloc] initWithTitle:@"Open in Finder" action:@selector(didClickOpenInFinder:) keyEquivalent:@""];
    [menu addItem:openInFinderMenuItem];
    NSMenuItem *openInTerminalMenuItem = [[NSMenuItem alloc] initWithTitle:@"Open in Terminal" action:@selector(didClickOpenInTerminal:) keyEquivalent:@""];
    [menu addItem:openInTerminalMenuItem];

    
    [menu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Restart" action:@selector(didClickRestart:) keyEquivalent:@""];
    [menu addItem:menuItem];
    NSMenuItem *renameMenuItem = [[NSMenuItem alloc] initWithTitle:@"Rename" action:@selector(didClickRename:) keyEquivalent:@""];
    [menu addItem:renameMenuItem];
    NSMenuItem *removeMenuItem = [[NSMenuItem alloc] initWithTitle:@"Remove" action:@selector(removeClickedRow:) keyEquivalent:@""];
    [menu addItem:removeMenuItem];
    
    [menu setAutoenablesItems:NO];
    
    return menu;
}

- (void)appListTableViewDoubleClicked:(id)sender {
    
    NVDataSource *dataSource = [NVDataSource sharedDataSource];
    NVApp *app = [dataSource.apps objectAtIndex:self.appListTableView.clickedRow];
    
    [[NSWorkspace sharedWorkspace] openURL:app.browserURL];
}

- (void)didClickRename:(id)sender {
    
    NSIndexSet *rowToSelect = [NSIndexSet indexSetWithIndex:self.appListTableView.clickedRow];
    [self.appListTableView selectRowIndexes:rowToSelect byExtendingSelection:NO];
    NVTableCellView *cell = (NVTableCellView *)[self.appListTableView viewAtColumn:0 row:self.appListTableView.clickedRow makeIfNecessary:YES];
    self.isEditing = YES;
    [cell.textField setEnabled:YES];
    [cell.textField becomeFirstResponder];
}

- (void)didClickOpenInTerminal:(id)sender {
    
    NVDataSource *dataSource = [NVDataSource sharedDataSource];
    NVApp *app = [dataSource.apps objectAtIndex:self.appListTableView.clickedRow];
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/open"];
    [task setArguments:[NSArray arrayWithObjects:@"-a", @"Terminal", app.url.path, nil]];
    [task launch];
}

- (void)didClickOpenInFinder:(id)sender {
    
    NVDataSource *dataSource = [NVDataSource sharedDataSource];
    NVApp *app = [dataSource.apps objectAtIndex:self.appListTableView.clickedRow];

    [[NSWorkspace sharedWorkspace] openURL:app.url];
}

- (void)didClickOpenWithBrowser:(id)sender {
    
    NVDataSource *dataSource = [NVDataSource sharedDataSource];
    NVApp *app = [dataSource.apps objectAtIndex:self.appListTableView.clickedRow];
    
    [[NSWorkspace sharedWorkspace] openURL:app.browserURL];
}

- (IBAction)didClickRestart:(id)sender {
    
    NVDataSource *dataSource = [NVDataSource sharedDataSource];
    NVApp *app = [dataSource.apps objectAtIndex:self.appListTableView.clickedRow];
    
    [app restart];
}

-(void)setSelectionFromClick{
    
    NSInteger theClickedRow = [self.appListTableView clickedRow];
    NSIndexSet *thisIndexSet = [NSIndexSet indexSetWithIndex:theClickedRow];
    [self.appListTableView selectRowIndexes:thisIndexSet byExtendingSelection:NO];
}

- (IBAction)didClickDeleteButton:(id)sender {

    NSInteger clickedRow = self.appListTableView.selectedRow;
    NVDataSource *dataSource = [NVDataSource sharedDataSource];
    NVApp *app = [dataSource.apps objectAtIndex:clickedRow];
    
    [dataSource removeApp:app];
    
    self.selectedRow = -1;
    NSIndexSet *thisIndexSet = [NSIndexSet indexSetWithIndex:clickedRow];
    [self.appListTableView removeRowsAtIndexes:thisIndexSet withAnimation:NSTableViewAnimationEffectFade];
    
    [self updatePanelHeightAndAnimate:YES];
}

- (IBAction)didClickRestartButton:(id)sender {
    NVDataSource *dataSource = [NVDataSource sharedDataSource];
    NVApp *app = [dataSource.apps objectAtIndex:self.appListTableView.selectedRow];
    
    [app restart];
}

- (IBAction)didClickInstallPowButton:(id)sender {
    
    [self.installPowButton setEnabled:NO];
    [self.installPowButton setTitle:@"Installing..."];
    [self.welcomeView setAlphaValue:0.8];
    
    NSTask *task = [[NSTask alloc] init];
    
    [task setLaunchPath:@"/bin/sh"];
    [task setArguments:[NSArray arrayWithObjects:[[NSBundle mainBundle] pathForResource:@"InstallPow" ofType:@"sh"], nil]];

    NSPipe *outputPipe = [NSPipe pipe];
    [task setStandardInput:[NSPipe pipe]];
    [task setStandardError:[NSPipe pipe]];
    [task setStandardOutput:outputPipe];
    
    [task launch];
    [task waitUntilExit];
    
    NSData *pipeData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
    NSString *pipeString = [[NSString alloc] initWithData:pipeData encoding:NSUTF8StringEncoding];
    NSLog(@"%@", pipeString);
    
    [self updatePanelHeightAndAnimate:YES];
}

@end
