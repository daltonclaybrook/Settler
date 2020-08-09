import SourceKittenFramework

struct DefinitionError: Error {
    enum Kind {
        case keyIsNotAnEnum
        case keyMemberIsNotATypeAlias
        case invalidTypeAlias
        case outputIsNotATypeAlias
        case outputIsNotAKeyMember
        case unexpectedSyntaxElement
        case cantFindDeclarationFile
        case resolverFunctionContainsNonKeyParam
        case duplicateReturnTypesInResolverFunctions
        case noResolverFunctionForKey
        case noResolverFunctionsWithZeroParams
        case unresolvableDependencies
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
        self.line = (location?.line ?? 0)
        self.character = (location?.character ?? 0)
    }

    init<T>(kind: Kind, located: Located<T>) {
        self.init(kind: kind, file: located.file, offset: located.offset)
    }

    /// Inspired by SwiftLint
    var description: String {
        // Xcode likes warnings and errors in the following format:
        // {full_path_to_file}{:line}{:character}: {error,warning}: {content}
        let fileString = filePath ?? "<nopath>"
        let lineString = ":\(line)"
        let charString = ":\(character)"
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
            return "Key must only contain type-aliases. No other members are permitted."
        case .invalidTypeAlias:
            return "The type-alias is invalid. See the docs."
        case .outputIsNotATypeAlias:
            return "Output must by a type-alias"
        case .outputIsNotAKeyMember:
            return "Output must be a member of 'Key'"
        case .unexpectedSyntaxElement:
            return "This syntax element is unexpected. Consider filing a GitHub issue."
        case .cantFindDeclarationFile:
            return "The declaration for this type could not be found. Make sure the Swift file is included in your '--sources' path."
        case .resolverFunctionContainsNonKeyParam:
            return "Resolver functions must only accept 'Key' members as arguments. This function is considered a resolver function because it returns a 'Key' member."
        case .duplicateReturnTypesInResolverFunctions:
            return "This resolver function has the same return type as another function. You may only implement one resolver function per type."
        case .noResolverFunctionForKey:
            return "Could not find a resolver function for this key"
        case .noResolverFunctionsWithZeroParams:
            return "None of the resolver functions could be called because they all depend on other functions"
        case .unresolvableDependencies:
            return "Could not resolve the dependencies of this function. This could be due to a circular dependency chain."
        }
    }
}

struct AggregateError<E: Error>: Error {
    let underlying: [E]
}

extension AggregateError: CustomStringConvertible where E: CustomStringConvertible {
    var description: String {
        underlying.map(\.description).joined(separator: "\n")
    }
}
