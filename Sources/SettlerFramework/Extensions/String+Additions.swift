// Inspired by SourceKitten
// https://github.com/jpsim/SourceKitten

import Foundation

extension String {
    public func bridge() -> NSString {
        self as NSString
    }

    public func strippingPrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count))
    }

    public func strippingSuffix(_ suffix: String) -> String {
        guard hasSuffix(suffix) else { return self }
        return String(dropLast(suffix.count))
    }

    /// Only strip the provided prefix and suffix if both exist
    public func stripping(prefix: String, andSuffix suffix: String) -> Self {
        guard hasPrefix(prefix) && hasSuffix(suffix) else { return self }
        let stripped = String(dropFirst(prefix.count))
        return String(stripped.dropLast(suffix.count))
    }
}

extension NSString {
    public func bridge() -> String {
        self as String
    }

    public func absolutePathRepresentation(rootDirectory: String = FileManager.default.currentDirectoryPath) -> String {
        let expanded = expandingTildeInPath
        guard !expanded.bridge().isAbsolutePath else { return expanded }
        return NSString.path(withComponents: [rootDirectory, expanded]).bridge().standardizingPath
    }
}
