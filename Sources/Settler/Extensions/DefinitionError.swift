import SourceKittenFramework

struct DefinitionError: Error {
    enum Kind {
        case keyIsNotAnEnum
        case keyMemberIsNotATypeAlias
        case invalidTypeAlias
    }

    let kind: Kind
    let filePath: String?
    let line: Int
    let character: Int
}

extension DefinitionError: CustomStringConvertible {
    init(kind: Kind, file: File, offset: Int64?) {
        self.kind = kind
        self.filePath = file.path
        let byteOffset = ByteCount(offset ?? 0)
        let location = file.stringView.lineAndCharacter(forByteOffset: byteOffset)
        self.line = (location?.line ?? 0) + 1 // 1-indexed
        self.character = (location?.character ?? 0) + 1 // 1-indexed
    }

    /// Inspired by SwiftLint
    var description: String {
        // Xcode likes warnings and errors in the following format:
        // {full_path_to_file}{:line}{:character}: {error,warning}: {content}
        let fileString: String = filePath ?? "<nopath>"
        let lineString: String = ":\(line)"
        let charString: String = ":\(character)"
        let errorString = ": error"
        let contentString = ": \(kind.description)"
        return [fileString, lineString, charString, errorString, contentString].joined()
    }
}

extension DefinitionError.Kind: CustomStringConvertible {
    var description: String {
        switch self {
        case .keyIsNotAnEnum:
            return "The Key type must be an enum"
        case .keyMemberIsNotATypeAlias:
            return "Key must only contain type-aliases. No other types are permitted."
        case .invalidTypeAlias:
            return "The type-alias is invalid. See the docs."
        }
    }
}
