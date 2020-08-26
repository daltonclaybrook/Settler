import Foundation

struct SettlerVersion {
    static let current = SettlerVersion(value: "0.1.1")
    let value: String
}

public let inUnitTests = ProcessInfo.processInfo
    .arguments
    .contains { $0.hasSuffix("xctest") }
