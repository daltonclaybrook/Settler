import Foundation
import SourceKittenFramework

/// The name of a type. e.g. `MyResolver` or `Key.Foo`
typealias TypeName = String
/// A `TypeNameChain` is a collection of namespaces terminated by a type
/// that can be legally joined with a dot,
/// e.g. `MyModule.MyResolver.Key.Foo`
typealias TypeNameChain = [TypeName]

/// The definition of a type-alias. This may be the `Output` type-alias, or
/// a member of the `Keys` enum.
struct TypeAliasDefinition {
    let name: TypeName
    let existingType: TypeName
}

/// The definition of a Resolver's `Key` enum. This enum is a collection
/// of type-aliases defining the objects that can be resolved by a Resolver.
struct KeyDefinition {
    let typeAliases: [Located<TypeAliasDefinition>]
}

/// A parameter to a function
struct FunctionParameter {
    let name: String
    let typeName: TypeName
}

/// A function definition as the Resolver is being parsed. This might be
/// a config function, a Resolver function, or neither.
struct PartialFunctionDefinition {
    let name: String
    let parameters: [FunctionParameter]
    let returnType: TypeName?
    let isThrowing: Bool
}

/// The definition for a Resolver function. A Resolver function is one that
/// resolves a `Key` member by returning in, and takes only `Key` members
/// as parameters.
struct ResolverFunctionDefinition {
    let name: String
    let parameters: [FunctionParameter]
    let returnType: TypeName
    let isThrowing: Bool
}

/// The definition for a config function. A config function is one that takes
/// only `Key` members as parameters, and has a return type of `Void`.
struct ConfigFunctionDefinition {
    let name: String
    let parameters: [FunctionParameter]
    let isThrowing: Bool
}

/// This type represents a Resolver definition as it is being parsed. If
/// there are mistakes is missing pieces, this may not result in a complete
/// `ResolverDefinition`.
struct PartialResolverDefinition {
    let typeChain: TypeNameChain
    /// The Swift file path where the type adopts the Resolver protocol
    let adoptionFile: Located<Void>
    /// The Swift file path where the type is declared
    var declarationFile: Located<Void>? = nil
    var keyDefinition: Located<KeyDefinition>? = nil
    var outputDefinition: Located<TypeAliasDefinition>? = nil
    var functions: [Located<PartialFunctionDefinition>] = []
}

/// The complete Resolver definition after it has been completely parsed,
/// though it may not have been validated yet.
struct ResolverDefinition {
    let typeChain: TypeNameChain
    /// The Swift file path where the type adopts the Resolver protocol
    let adoptionFile: Located<Void>
    /// The Swift file path where the type is declared
    let declarationFilePath: String
    let keyDefinition: KeyDefinition
    let outputDefinition: TypeAliasDefinition
    /// A Resolver function is a function that returns a member of the `Key`.
    /// These functions may only accept other `Key` members as arguments.
    /// There must not be two Resolver functions that return the same key.
    let resolverFunctions: [Located<ResolverFunctionDefinition>]
    /// A config function is one that accepts only `Key` members as arguments
    /// and has a return type of `Void`
    let configFunctions: [ConfigFunctionDefinition]
}

protocol FunctionDefinitionType {
    var name: String { get }
    var parameters: [FunctionParameter] { get }
    var isThrowing: Bool { get }
}

extension ResolverFunctionDefinition: FunctionDefinitionType {}
extension ConfigFunctionDefinition: FunctionDefinitionType {}

extension ResolverDefinition {
    var allFunctions: [FunctionDefinitionType] {
        resolverFunctions.map(\.value) + configFunctions
    }

    var functionsForType: [TypeName: Located<ResolverFunctionDefinition>] {
        resolverFunctions.reduce(into: [:]) { result, function in
            result[function.returnType] = function
        }
    }
}
