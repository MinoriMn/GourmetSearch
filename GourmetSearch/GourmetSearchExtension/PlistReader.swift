import Foundation

struct PlistReader {
    private let keyFilePath: String?

    init (forResource: String) {
        keyFilePath = Bundle.main.path(forResource: forResource, ofType: "plist")
    }

    func getKeys() -> NSDictionary? {
        guard let keyFilePath = keyFilePath else {
            return nil
        }
        return NSDictionary(contentsOfFile: keyFilePath)
    }

    func getValue(key: String) -> AnyObject? {
        guard let keys = getKeys() else {
            return nil
        }
        return keys[key]! as AnyObject
    }
}
