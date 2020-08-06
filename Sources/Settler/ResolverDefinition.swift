import Foundation
import SourceKittenFramework

typealias TypeName = String
typealias TypeNameChain = [TypeName]

struct TypeAliasDefinition {
    let name: TypeName
    let existingType: TypeName
}

struct KeyDefinition {
    let typeAliases: [TypeAliasDefinition]
}

struct ResolverFunction {
    struct Parameter {
        let name: String
        let typeName: TypeName
    }

    let name: String
    let parameters: [Parameter]
    let returnType: TypeName?
}

struct ResolverDefinition {
    let typeChain: TypeNameChain
    /// The Swift file path where the type adopts the Resolver protocol
    let adoptionFilePath: String
    /// The Swift file path where the type is declared
    var declarationFilePath: String? = nil
    var keyDefinition: KeyDefinition? = nil
    var outputDefinition: TypeAliasDefinition? = nil
    var functions: [ResolverFunction] = []
}
