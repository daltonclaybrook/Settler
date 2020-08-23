import Foundation

struct SettlerVersion {
    static let current = SettlerVersion(value: "0.1.0")
    let value: String
}

public let inUnitTests = ProcessInfo.processInfo
    .arguments
    .contains { $0.hasSuffix("xctest") }
