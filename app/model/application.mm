#import "application.h"
#import "private_apis/AXUI.h"
#import "util/log_util.h"

application::application() {}

application::application(pid_t pid) {
    this->pid = pid;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    GetProcessForPID(pid, &psn);
#pragma clang diagnostic pop

    axRef = AXUIElementCreateApplication(pid);
}

bool application::is_xpc() {
    ProcessInfoRec info = ProcessInfoRec();
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    GetProcessInformation(&psn, &info);
#pragma clang diagnostic pop
    return info.processType == 'XPC!';
}
