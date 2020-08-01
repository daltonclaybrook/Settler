import ArgumentParser
import Foundation
import SourceKittenFramework

struct Resolve: ParsableCommand {
    private typealias TypeName = String
    private typealias TypeNameChain = [TypeName]

    static let configuration = CommandConfiguration(
        abstract: "Parse any Resolvers in the target project and generate type-safe functions for producing the desired Resolver outputs"
    )

    @Option(name: [.short, .customLong("sources")],
            help: "Path to a directory used to search for Resolvers")
    var sourcesPath: String = "."

    private static let typeKinds: Set<SwiftDeclarationKind> = [.class, .struct, .enum, .extension]
    private static let protocolTypeName = "Resolver"

    func validate() throws {
        let fullSourcesPath = sourcesPath.bridge().absolutePathRepresentation()
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: fullSourcesPath, isDirectory: &isDirectory)

        if !exists {
            throw ValidationError("Directory does not exist at provided sources path: \(sourcesPath)")
        } else if !isDirectory.boolValue {
            throw ValidationError("Provided sources path is not a directory: \(sourcesPath)")
        }
    }

    func run() throws {
        let path = sourcesPath.bridge().absolutePathRepresentation()
        guard let enumerator = FileManager.default.enumerator(atPath: path) else {
            throw SettlerError.unknownError
        }

        /*
        Tasks:
         - Determine list of Swift files
         - Iterate the list of files and determine the types of all Resolvers
         - Iterate again and determine all required types/functions for the resolvers
         - Determine which resolvers have errors, i.e. Missing/invalid `Key` or `Output`, missing/invalid functions, etc. and report errors
         - Determine correct order to call resolver functions, or report error if there are issues.
         - Generate the `[Resolver]+Output.swift` files for each Resolver and save them to disk
        */

        let swiftFiles = enumerator
            .compactMap { fileName -> String? in
                guard let fileName = fileName as? String,
                    fileName.hasSuffix("PersonResolver.swift") else { return nil }
                return path.bridge().appendingPathComponent(fileName)
            }

        let resolverTypeChains = try swiftFiles
            .reduce(into: [TypeNameChain]()) { result, swiftFile in
                guard let file = File(path: swiftFile) else {
                    throw SettlerError.failedToOpenFile(swiftFile)
                }
                let structure = try Structure(file: file)
                guard let substructures = structure.dictionary[SwiftDocKey.substructure.rawValue] as? [[String: SourceKitRepresentable]]
                    else { return }

                substructures.forEach { substructure in
                    storeTypeNameChainsImplementingResolver(in: &result, structure: substructure)
                }
            }

        print(resolverTypeChains)
    }

    // MARK: - Helpers

    private func storeTypeNameChainsImplementingResolver(in typeChains: inout [TypeNameChain], structure: [String: SourceKitRepresentable], currentNamespaces: TypeNameChain = []) {
        guard let typeName = structure[SwiftDocKey.name.rawValue] as? String,
            let kindString = structure[SwiftDocKey.kind.rawValue] as? String,
            let kind = SwiftDeclarationKind(rawValue: kindString),
            Resolve.typeKinds.contains(kind)
            else { return }

        let namespacesAndType = currentNamespaces + [typeName]
        let inheritedTypes = structure[SwiftDocKey.inheritedtypes.rawValue] as? [[String: SourceKitRepresentable]] ?? []
        let inheritedTypeNames = inheritedTypes.compactMap { type in
            type[SwiftDocKey.name.rawValue] as? String
        }
        if inheritedTypeNames.contains(Resolve.protocolTypeName) {
            typeChains.append(namespacesAndType)
        }

        // Recurse into substructures and add any deeper types that implement Resolver
        let substructures = structure[SwiftDocKey.substructure.rawValue] as? [[String: SourceKitRepresentable]] ?? []
        substructures.forEach { substructure in
            storeTypeNameChainsImplementingResolver(
                in: &typeChains,
                structure: substructure,
                currentNamespaces: namespacesAndType
            )
        }
    }
}
