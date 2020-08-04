import Foundation
import SourceKittenFramework

typealias TypeName = String
typealias TypeNameChain = [TypeName]

enum TypeNameConstants {
    static let resolver = "Resolver"
    static let key = "Key"
    static let output = "Output"
}

struct TypeAliasDefinition {
    let name: TypeName
    let existingType: TypeName
}

struct KeyDefinition {
    let typeAliases: [TypeAliasDefinition]
}

struct ResolverFunction {
    let argumentKeyAliases: [TypeName]
    let returnKeyAlias: TypeName
}

struct ResolverDefinition {
    let typeChain: TypeNameChain
    var declarationFilePath: String? = nil
    var keyDefinition: KeyDefinition? = nil
    var outputDefinition: TypeAliasDefinition? = nil
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

        let aliasStructures = structure.substructure ?? []
        let typeAliasResults = aliasStructures.map { structure in
            TypeAliasDefinition.build(from: structure, in: file)
                .mapError { error in
                    DefinitionError(kind: error.keyMemberErrorKind, file: file, offset: structure.offset)
                }
        }

        keyDefinition = KeyDefinition(typeAliases: typeAliasResults.compactMap(\.successValue))
        errors.append(contentsOf: typeAliasResults.compactMap(\.failureError))
    }

    private mutating func updateOutput(kind: SwiftDeclarationKind, structure: [String: SourceKitRepresentable], file: File) {
        guard kind == .typealias else {
            errors.append(DefinitionError(kind: .outputIsNotATypeAlias, file: file, offset: structure.offset))
            return
        }

        switch TypeAliasDefinition.build(from: structure, in: file) {
        case .success(let definition):
            outputDefinition = definition
        case .failure(let error):
            errors.append(DefinitionError(kind: error.outputErrorKind, file: file, offset: structure.offset))
        }
    }

    private mutating func updateFunctions(name: String, structure: [String: SourceKitRepresentable], file: File) {

    }
}

extension TypeAliasDefinition {
    enum TypeAliasError: Error {
        case notATypeAlias
        case missingRequiredFields
        case invalidExistingType
    }

    static func build(from structure: [String: SourceKitRepresentable], in file: File) -> Result<Self, TypeAliasError> {
        guard let kind = structure.declarationKind, kind == .typealias else {
            return .failure(.notATypeAlias)
        }

        guard let offset = structure.offset,
            let nameOffset = structure.nameOffset,
            let length = structure.length,
            let nameLength = structure.nameLength,
            let name = structure.name else {
                return .failure(.missingRequiredFields)
        }

        let offsetAfterName = nameOffset + nameLength
        let lengthAfterName = offset + length - offsetAfterName
        let byteRange = ByteRange(location: ByteCount(offsetAfterName), length: ByteCount(lengthAfterName))
        let afterName = file.stringView.substringWithByteRange(byteRange) ?? ""

        let whitespaceAndEqual = CharacterSet.whitespaces.union(CharacterSet(charactersIn: "="))
        let existingType = afterName.trimmingCharacters(in: whitespaceAndEqual)
        guard !existingType.isEmpty else {
            return .failure(.invalidExistingType)
        }

        return .success(TypeAliasDefinition(name: name, existingType: existingType))
    }
}

extension TypeAliasDefinition.TypeAliasError {
    /// The error kind when this error occurs inside of the Key definition
    var keyMemberErrorKind: DefinitionError.Kind {
        switch self {
        case .notATypeAlias:
            return .keyMemberIsNotATypeAlias
        case .missingRequiredFields, .invalidExistingType:
            return .invalidTypeAlias
        }
    }

    /// The error kind when this error occurs on the Output definition
    var outputErrorKind: DefinitionError.Kind {
        switch self {
        case .notATypeAlias:
            return .outputIsNotATypeAlias
        case .missingRequiredFields, .invalidExistingType:
            return .invalidTypeAlias
        }
    }
}
