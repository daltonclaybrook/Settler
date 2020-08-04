import Foundation
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
        let name: TypeName
        // Do we need to even record the data type?
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
            guard let name = member.name,
                let kind = member.declarationKind else { return }

            if name == TypeNameConstants.key {
                updateKey(kind: kind, structure: member, file: file)
            } else if name == TypeNameConstants.output {
                updateOutput(kind: kind, structure: member, file: file)
            } else if kind == .functionMethodInstance {
                updateFunctions(name: name, structure: member, file: file)
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
        let keyResults = typeAliases.map { alias -> Result<KeyDefinition.Key, DefinitionError> in
            guard let kind = alias.declarationKind, kind == .typealias else {
                let error = DefinitionError(kind: .keyMemberIsNotATypeAlias, file: file, offset: alias.offset)
                return .failure(error)
            }

            guard let offset = alias.offset,
                let nameOffset = alias.nameOffset,
                let length = alias.length,
                let nameLength = alias.nameLength,
                let name = alias.name else {
                    let error = DefinitionError(kind: .invalidTypeAlias, file: file, offset: alias.offset)
                    return .failure(error)
            }

            let offsetAfterName = nameOffset + nameLength
            let lengthAfterName = offset + length - offsetAfterName
            let byteRange = ByteRange(location: ByteCount(offsetAfterName), length: ByteCount(lengthAfterName))
            let afterName = file.stringView.substringWithByteRange(byteRange) ?? ""

            let whitespaceAndEqual = CharacterSet.whitespaces.union(CharacterSet(charactersIn: "="))
            let dataType = afterName.trimmingCharacters(in: whitespaceAndEqual)
            guard !dataType.isEmpty else {
                let error = DefinitionError(kind: .invalidTypeAlias, file: file, offset: offset)
                return .failure(error)
            }

            return .success(KeyDefinition.Key(name: name, dataType: dataType))
        }

        keyDefinition = KeyDefinition(keys: keyResults.compactMap(\.successValue))
        errors.append(contentsOf: keyResults.compactMap(\.failureError))
    }

    private mutating func updateOutput(kind: SwiftDeclarationKind, structure: [String: SourceKitRepresentable], file: File) {

    }

    private mutating func updateFunctions(name: String, structure: [String: SourceKitRepresentable], file: File) {

    }
}
