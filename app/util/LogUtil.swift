import Foundation
import os

class LogUtil: NSObject {
    static let bundleId = Bundle.main.bundleIdentifier!

    static func customLog(
        _ type: OSLogType, _ category: String, _ format: String, _ args: CVarArg...
    ) {
        let logger = Logger(subsystem: bundleId, category: category)
        withVaList(args) { vaList in
            let message = NSString(
                format: format,
                arguments: vaList)
            logger.log(level: type, "\(message, privacy: .public)")
        }
    }
}
