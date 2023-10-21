#include "Menu.h"

@implementation Menu
- (NSMenu*)createMenu {
    NSMenu* mainMenu = [[NSMenu alloc] initWithTitle:@"MainMenu"];
    NSMenuItem* menuItem;
    NSMenu* submenu;

    menuItem = [mainMenu addItemWithTitle:@"Application"
                                   action:NULL
                            keyEquivalent:@""];
    submenu = [[NSMenu alloc] initWithTitle:@"Application"];
    [NSApp performSelector:@selector(setAppleMenu:)
                withObject:submenu];
    [self populateApplicationMenu:submenu];
    [mainMenu setSubmenu:submenu forItem:menuItem];

    menuItem = [mainMenu addItemWithTitle:@"File"
                                   action:NULL
                            keyEquivalent:@""];
    submenu = [[NSMenu alloc]
        initWithTitle:NSLocalizedString(@"File", @"File menu")];
    [self populateFileMenu:submenu];
    [mainMenu setSubmenu:submenu forItem:menuItem];

    menuItem = [mainMenu addItemWithTitle:@"View"
                                   action:NULL
                            keyEquivalent:@""];
    submenu = [[NSMenu alloc]
        initWithTitle:NSLocalizedString(@"View", @"View menu")];
    [self populateViewMenu:submenu];
    [mainMenu setSubmenu:submenu forItem:menuItem];

    menuItem = [mainMenu addItemWithTitle:@"Window"
                                   action:NULL
                            keyEquivalent:@""];
    submenu = [[NSMenu alloc]
        initWithTitle:NSLocalizedString(@"Window", @"Window menu")];
    [self populateWindowMenu:submenu];
    [mainMenu setSubmenu:submenu forItem:menuItem];
    [NSApp setWindowsMenu:submenu];

    return mainMenu;
}

- (void)populateApplicationMenu:(NSMenu*)menu {
    id bundleInfo = [[NSBundle mainBundle] infoDictionary];
    NSString* appName = [bundleInfo objectForKey:@"CFBundleName"];

    NSMenuItem* menuItem;

    NSString* aboutString = [NSString
        stringWithFormat:@"%@ %@", NSLocalizedString(@"About", nil), appName];
    menuItem = [menu addItemWithTitle:aboutString
                               action:@selector(orderFrontStandardAboutPanel:)
                        keyEquivalent:@""];
    [menuItem setTarget:NSApp];

    [menu addItem:[NSMenuItem separatorItem]];

    NSString* hideString = [NSString
        stringWithFormat:@"%@ %@", NSLocalizedString(@"Hide", nil), appName];
    menuItem = [menu addItemWithTitle:hideString
                               action:@selector(hide:)
                        keyEquivalent:@"h"];
    [menuItem setTarget:NSApp];

    NSString* hideOthersString = NSLocalizedString(@"Hide Others", nil);
    menuItem = [menu addItemWithTitle:hideOthersString
                               action:@selector(hideOtherApplications:)
                        keyEquivalent:@"h"];
    [menuItem setKeyEquivalentModifierMask:NSEventModifierFlagOption |
                                           NSEventModifierFlagCommand];
    [menuItem setTarget:NSApp];

    NSString* showAllString = NSLocalizedString(@"Show All", nil);
    menuItem = [menu addItemWithTitle:showAllString
                               action:@selector(unhideAllApplications:)
                        keyEquivalent:@""];
    [menuItem setTarget:NSApp];

    [menu addItem:[NSMenuItem separatorItem]];

    NSString* quitString = [NSString
        stringWithFormat:@"%@ %@", NSLocalizedString(@"Quit", nil), appName];
    menuItem = [menu addItemWithTitle:quitString
                               action:@selector(terminate:)
                        keyEquivalent:@"q"];
    [menuItem setTarget:NSApp];
}

- (void)populateFileMenu:(NSMenu*)menu {
    NSString* title;

    title = NSLocalizedString(@"New Window", @"New Window menu item");
    [menu addItemWithTitle:title
                    action:@selector(newDocument:)
             keyEquivalent:@"n"];

    title = NSLocalizedString(@"Close Window", @"Close Window menu item");
    [menu addItemWithTitle:title
                    action:@selector(performClose:)
             keyEquivalent:@"w"];
}

- (void)populateViewMenu:(NSMenu*)menu {
    NSString* title;
    NSMenuItem* menuItem;

    title = NSLocalizedString(@"Enter Full Screen",
                              @"Enter Full Screen menu item");
    menuItem = [menu addItemWithTitle:title
                               action:@selector(toggleFullScreen:)
                        keyEquivalent:@"f"];
    [menuItem setKeyEquivalentModifierMask:NSEventModifierFlagFunction];
}

- (void)populateWindowMenu:(NSMenu*)menu {
    NSString* title;

    title = NSLocalizedString(@"Minimize", nil);
    [menu addItemWithTitle:title
                    action:@selector(performMiniaturize:)
             keyEquivalent:@"m"];

    title = NSLocalizedString(@"Zoom", nil);
    [menu addItemWithTitle:title
                    action:@selector(performZoom:)
             keyEquivalent:@""];

    [menu addItem:[NSMenuItem separatorItem]];

    title = NSLocalizedString(@"Bring All to Front", nil);
    [menu addItemWithTitle:title
                    action:@selector(arrangeInFront:)
             keyEquivalent:@""];
}
@end
