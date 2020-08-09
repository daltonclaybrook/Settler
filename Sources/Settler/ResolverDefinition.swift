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
    let isThrowing: Bool
}

struct ResolverFunctionDefinition {
    let name: String
    let parameters: [FunctionParameter]
    let returnType: TypeName
    let isThrowing: Bool
}

struct ConfigFunctionDefinition {
    let name: String
    let parameters: [FunctionParameter]
    let isThrowing: Bool
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
    let adoptionFile: Located<Void>
    /// The Swift file path where the type is declared
    let declarationFilePath: String
    let keyDefinition: KeyDefinition
    let outputDefinition: TypeAliasDefinition
    /// A resolver function is a function that returns a member of the `Key`.
    /// These functions may only accept other `Key` members as arguments.
    /// There must not be two resolver functions that return the same key.
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
}
