import Foundation
import SourceKittenFramework

typealias TypeName = String
typealias TypeNameChain = [TypeName]

struct TypeAliasDefinition {
    let name: TypeName
    let existingType: TypeName
}

struct KeyDefinition {
    let typeAliases: [Located<TypeAliasDefinition>]
}

struct FunctionParameter {
    let name: String
    let typeName: TypeName
}

struct PartialFunctionDefinition {
    let name: String
    let parameters: [FunctionParameter]
    let returnType: TypeName?
}

struct ResolverFunctionDefinition {
    let name: String
    let parameters: [FunctionParameter]
    let returnType: TypeName
}

struct ConfigFunctionDefinition {
    let name: String
    let parameters: [FunctionParameter]
}

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

struct ResolverDefinition {
    let typeChain: TypeNameChain
    /// The Swift file path where the type adopts the Resolver protocol
    let adoptionFilePath: String
    /// The Swift file path where the type is declared
    let declarationFilePath: String
    let keyDefinition: KeyDefinition
    let outputDefinition: TypeAliasDefinition
    /// A resolver function is a function that returns a member of the `Key`.
    /// These functions may only accept other `Key` members as arguments.
    /// There must not be two resolver functions that return the same key.
    let resolverFunctions: [ResolverFunctionDefinition]
    /// A config function is one that accepts only `Key` members as arguments
    /// and has a return type of `Void`
    let configFunctions: [ConfigFunctionDefinition]
}
