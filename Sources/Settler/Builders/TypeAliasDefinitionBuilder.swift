import Foundation
import SourceKittenFramework

struct TypeAliasDefinitionBuilder {
    enum TypeAliasError: Error {
        case notATypeAlias
        case missingRequiredFields
        case invalidExistingType
    }

    static func buildFrom(aliasStructure: [String: SourceKitRepresentable], in file: File) -> Result<Located<TypeAliasDefinition>, TypeAliasError> {
        guard let kind = aliasStructure.declarationKind, kind == .typealias else {
            return .failure(.notATypeAlias)
        }

        guard let offset = aliasStructure.offset,
            let nameOffset = aliasStructure.nameOffset,
            let length = aliasStructure.length,
            let nameLength = aliasStructure.nameLength,
            let name = aliasStructure.name else {
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

        let definition = TypeAliasDefinition(name: name, existingType: existingType)
        return .success(Located(value: definition, file: file, offset: offset))
    }
}

extension TypeAliasDefinitionBuilder.TypeAliasError {
    /// The error when this error occurs inside of the Key definition
    var keyMemberError: DefinitionError {
        switch self {
        case .notATypeAlias:
            return .keyMemberIsNotATypeAlias
        case .missingRequiredFields, .invalidExistingType:
            return .invalidTypeAlias
        }
    }

    /// The error when this error occurs on the Output definition
    var outputError: DefinitionError {
        switch self {
        case .notATypeAlias:
            return .outputIsNotATypeAlias
        case .missingRequiredFields, .invalidExistingType:
            return .invalidTypeAlias
        }
    }
}
