import SourceKittenFramework

extension Dictionary where Key == String, Value == SourceKitRepresentable {
    var name: String? {
        self[SwiftDocKey.name.rawValue] as? String
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
}
