#import "model/applications.h"
#import "model/space.h"
#import "view/MainView.h"
#import <Cocoa/Cocoa.h>

@interface WindowController : NSWindowController {
    CGSize size;
    CGFloat padding;
    CGFloat innerPadding;
    CGFloat titleTextPadding;
    MainView* mainView;
    space* sp;
    applications apps;
    int numDelays;
}

@property(nonatomic, getter=isShown) bool shown;

- (instancetype)initWithSize:(CGSize)size
                     padding:(CGFloat)padding
                innerPadding:(CGFloat)innerPadding
            titleTextPadding:(CGFloat)titleTextPadding;
- (void)cycleSelectedIndex;
- (void)focusSelectedIndex;
- (void)showWindow:(bool)activeAppOnly;
- (void)hideWindow;

@end
