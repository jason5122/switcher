#import <Cocoa/Cocoa.h>

typedef enum {
    kSLPSAllWindows = 0x100,
    kSLPSUserGenerated = 0x200,
    kSLPSNoWindows = 0x400,
} SLPSMode;

extern "C" CGError _SLPSSetFrontProcessWithOptions(ProcessSerialNumber* psn, uint32_t wid,
                                                   uint32_t mode);
extern "C" CGError SLPSPostEventRecordTo(ProcessSerialNumber* psn, uint8_t* bytes);
