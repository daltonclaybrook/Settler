import SourceKittenFramework

typealias TypeName = String
typealias TypeNameChain = [TypeName]

enum TypeNameConstants {
    static let resolver = "Resolver"
    static let key = "Key"
    static let output = "Output"
}

struct KeyDefinition {
    struct Key {
        let alias: TypeName
        let dataType: TypeName
    }
    let keys: [Key]
}

struct ResolverFunction {
    let argumentKeyAliases: [TypeName]
    let returnKeyAlias: TypeName
}

struct ResolverDefinition {
    let typeChain: TypeNameChain
    var declarationFilePath: String? = nil
    var keyDefinition: KeyDefinition? = nil
    var outputType: TypeName? = nil
    var functions: [ResolverFunction] = []
    var errors: [DefinitionError] = []
}

extension ResolverDefinition {
    mutating func update(with structures: [[String: SourceKitRepresentable]], file: File) {
        structures.forEach { structure in
            update(with: structure, file: file)
        }
    }

    mutating func update(with structure: [String: SourceKitRepresentable], file: File) {
        let members = structure.substructure ?? []
        members.forEach { member in
            guard let name = structure.name,
                let kind = structure.declarationKind else { return }

            if name == TypeNameConstants.key {
                updateKey(kind: kind, structure: structure, file: file)
            } else if name == TypeNameConstants.output {
                updateOutput(kind: kind, structure: structure, file: file)
            } else if kind == .functionMethodInstance {
                updateFunctions(name: name, structure: structure, file: file)
            }
        }
    }

    // MARK: - Helper functions

    private mutating func updateKey(kind: SwiftDeclarationKind, structure: [String: SourceKitRepresentable], file: File) {
        guard kind == .enum else {
            errors.append(DefinitionError(kind: .keyIsNotAnEnum, file: file, offset: structure.offset))
            return
        }

        let typeAliases = structure.substructure ?? []

    }

    private mutating func updateOutput(kind: SwiftDeclarationKind, structure: [String: SourceKitRepresentable], file: File) {

    }

    private mutating func updateFunctions(name: String, structure: [String: SourceKitRepresentable], file: File) {

    }
}
