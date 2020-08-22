import Foundation

struct SettlerVersion {
    static let current = SettlerVersion(value: "0.1.0")
    let value: String
}

public let inUnitTests = NSClassFromString("XCTest") != nil
