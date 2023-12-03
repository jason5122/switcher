#import "Menu.h"

@implementation Menu

- (instancetype)init {
    self = [super initWithTitle:@"Main Menu"];
    if (self) {
        NSString* appName = [NSBundle.mainBundle.infoDictionary objectForKey:@"CFBundleName"];

        NSMenuItem* appMenu = [[NSMenuItem alloc] init];
        appMenu.submenu = [[NSMenu alloc] init];
        [appMenu.submenu addItemWithTitle:[NSString stringWithFormat:@"About %@", appName]
                                   action:@selector(orderFrontStandardAboutPanel:)
                            keyEquivalent:@""];
        [appMenu.submenu addItem:[NSMenuItem separatorItem]];
        [appMenu.submenu addItemWithTitle:[NSString stringWithFormat:@"Quit %@", appName]
                                   action:@selector(terminate:)
                            keyEquivalent:@"q"];

        [self addItem:appMenu];
    }
    return self;
}

@end
