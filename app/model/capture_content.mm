#import "capture_content.h"
#import "util/log_util.h"

capture_content::capture_content() {
    shareable_content_available = dispatch_semaphore_create(0);
}

void capture_content::get_content() {
    typedef void (^shareable_content_callback)(SCShareableContent*, NSError*);
    shareable_content_callback new_content_received =
        ^void(SCShareableContent* shareable_content, NSError* error) {
          if (error == nil && shareable_content_available != NULL) {
              this->shareable_content = shareable_content;
          } else {
              log_with_type(
                  OS_LOG_TYPE_ERROR,
                  @"Unable to get list of available applications or windows. Please check if app"
                  @"has necessary screen capture permissions.",
                  @"capture-content");
          }
          dispatch_semaphore_signal(shareable_content_available);
        };

    [SCShareableContent getShareableContentExcludingDesktopWindows:TRUE
                                               onScreenWindowsOnly:TRUE
                                                 completionHandler:new_content_received];
}

void capture_content::build_window_list() {
    dispatch_semaphore_wait(shareable_content_available, DISPATCH_TIME_FOREVER);

    NSSet* excluded_window_titles = [NSSet setWithObjects:@"Menubar", @"Item-0", nil];
    NSSet* excluded_application_names =
        [NSSet setWithObjects:@"Notification Center", @"Control Center", @"Dock", nil];

    windows = [shareable_content.windows
        filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(SCWindow* window,
                                                                          NSDictionary* bindings) {
          NSString* app_name = window.owningApplication.applicationName;
          NSString* title = window.title;

          if (app_name == NULL || title == NULL) return FALSE;
          if ([app_name isEqualToString:@""] || [title isEqualToString:@""]) return FALSE;

          return ![excluded_window_titles containsObject:title] &&
                 ![excluded_application_names containsObject:app_name];
        }]];
}
