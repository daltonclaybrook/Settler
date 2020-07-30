// Inspired by SourceKitten
// https://github.com/jpsim/SourceKitten

import Foundation

extension String {
    func bridge() -> NSString {
        self as NSString
    }
}

extension NSString {
    func bridge() -> String {
        self as String
    }

    func absolutePathRepresentation(rootDirectory: String = FileManager.default.currentDirectoryPath) -> String {
        let expanded = expandingTildeInPath
        guard !expanded.bridge().isAbsolutePath else { return expanded }
        return NSString.path(withComponents: [rootDirectory, expanded]).bridge().standardizingPath
    }
}
