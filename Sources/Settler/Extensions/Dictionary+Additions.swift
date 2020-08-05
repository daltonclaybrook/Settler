import SourceKittenFramework

extension Dictionary where Key == String, Value == SourceKitRepresentable {
    var name: String? {
        self[SwiftDocKey.name.rawValue] as? String
    }

    var typeName: TypeName? {
        self[SwiftDocKey.typeName.rawValue] as? TypeName
    }

    var substructure: [[String: SourceKitRepresentable]]? {
        self[SwiftDocKey.substructure.rawValue] as? [[String: SourceKitRepresentable]]
    }

    var declarationKind: SwiftDeclarationKind? {
        let kindString = self[SwiftDocKey.kind.rawValue] as? String
        return kindString.flatMap(SwiftDeclarationKind.init(rawValue:))
    }

    var inheritedTypes: [SourceKitRepresentable]? {
        self[SwiftDocKey.inheritedtypes.rawValue] as? [SourceKitRepresentable]
    }

    var offset: Int64? {
        self[SwiftDocKey.offset.rawValue] as? Int64
    }

    var nameOffset: Int64? {
        self[SwiftDocKey.nameOffset.rawValue] as? Int64
    }

    var length: Int64? {
        self[SwiftDocKey.length.rawValue] as? Int64
    }

    var nameLength: Int64? {
        self[SwiftDocKey.nameLength.rawValue] as? Int64
    }

    var accessibility: Accessibility? {
        let accessibilityString = self[Accessibility.docKey] as? String
        return accessibilityString.flatMap(Accessibility.init(rawValue:))
    }
}
