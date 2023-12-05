import Foundation

class Person: NSObject {
    var name: String?

    @objc
    init(name: String) {
        self.name = name
    }

    @objc
    func printName() {
        let name = self.name ?? "no name"
        CustomLog.logger.log("\(name, privacy: .public)")
    }
}
