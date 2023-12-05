import Foundation

@objcMembers
class Person: NSObject {
    var name: String?

    init(name: String) {
        self.name = name
    }

    func printName() {
        let name = self.name ?? "no name"
        LogUtil.customLog(.default, "person", "hiya %@", name)
    }
}
