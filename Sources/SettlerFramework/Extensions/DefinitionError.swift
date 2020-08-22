import SourceKittenFramework

/// An error discovered when parsing or validating a Resolver definition.
/// These errors are intended to be reported to the user inside of Xcode
/// by wrapping this type in `Located<DefinitionError>`.
public enum DefinitionError: Equatable, Error {
    case keyIsNotAnEnum
    case keyMemberIsNotATypeAlias
    case invalidTypeAlias
    case invalidFunction
    case outputIsNotATypeAlias
    case outputIsNotAKeyMember
    case unexpectedSyntaxElement
    case cantFindDeclarationFile
    case resolverFunctionContainsNonKeyParam
    case duplicateReturnTypesInResolverFunctions
    case noResolverFunctionForKey
    case noResolverFunctionsWithZeroParams
    case circularResolverDependency(keys: [TypeName])
    case unresolvableDependencies
    case resolverFunctionCannotBeThrowingIfResultIsUsedLazily
}

extension DefinitionError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .keyIsNotAnEnum:
            return "The Key type must be an enum"
        case .keyMemberIsNotATypeAlias:
            return "Key must only contain type-aliases. No other members are permitted."
        case .invalidTypeAlias:
            return "The type-alias is invalid. See the docs."
        case .invalidFunction:
            return "The function is invalid. See the docs."
        case .outputIsNotATypeAlias:
            return "Output must be a type-alias"
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
        case .circularResolverDependency(let keys):
            return "This function could not be called because of a circular dependency: \(keys.arrowJoined)"
        case .unresolvableDependencies:
            return "Could not resolve the dependencies of this function. This could be due to a circular dependency chain."
        case .resolverFunctionCannotBeThrowingIfResultIsUsedLazily:
            return "This function can throw, but another function accesses this dependency using 'Lazy<...>'. This is not currently supported. If this is a capability you need, consider creating a GitHub issue."
        }
    }
}

extension DefinitionError {
    func located(in file: File, offset: Int64? = nil) -> Located<DefinitionError> {
        Located(value: self, file: file, offset: offset)
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
