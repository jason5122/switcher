import Foundation
import os

class LogUtil: NSObject {
    static var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "switcher")
}
