import Foundation
import os

class CustomLog: NSObject {
    static var logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "switcher")
}
