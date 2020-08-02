import ArgumentParser
import Foundation
import SourceKittenFramework

struct Resolve: ParsableCommand {
    private typealias StructuresAndFile = (structures: [[String: SourceKitRepresentable]], file: File)

    static let configuration = CommandConfiguration(
        abstract: "Parse any Resolvers in the target project and generate type-safe functions for producing the desired Resolver outputs"
    )

    @Option(name: [.short, .customLong("sources")],
            help: "Path to a directory used to search for Resolvers")
    var sourcesPath: String = "."

    private static let typeKinds: Set<SwiftDeclarationKind> = [.class, .struct, .enum, .extension]

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

        // Determine absolute paths of all Swift files
        let swiftFiles = enumerator
            .compactMap { fileName -> String? in
                guard let fileName = fileName as? String,
                    // TODO: fix this
                    fileName.hasSuffix("PersonResolver.swift") else { return nil }
                return path.bridge().appendingPathComponent(fileName)
            }

        // Determine all of the Resolver definitions from parsing every source file
        var definitions = try swiftFiles
            .reduce(into: [TypeNameChain]()) { result, swiftFile in
                guard let parsed = try getSubstructuresAndFileFor(swiftFile: swiftFile) else { return }

                parsed.structures.forEach { substructure in
                    storeTypeNameChainsImplementingResolver(in: &result, structure: substructure)
                }
            }
            .map { ResolverDefinition(typeChain: $0) }

        // Update the definitions with the relevant structures
        try swiftFiles.forEach { swiftFile in
            guard let parsed = try getSubstructuresAndFileFor(swiftFile: swiftFile) else { return }
            definitions.mutableForEach { definition in
                let structuresForDefinition = findSubstructureFor(typeChain: definition.typeChain, in: parsed.structures)
                definition.update(with: structuresForDefinition, file: parsed.file)
            }
        }
    }

    // MARK: - Helpers

    private func getSubstructuresAndFileFor(swiftFile: String) throws -> StructuresAndFile? {
        guard let file = File(path: swiftFile) else {
            throw SettlerError.failedToOpenFile(swiftFile)
        }
        let structure = try Structure(file: file)
        return structure.dictionary.substructure.map { ($0, file) }
    }

    private func storeTypeNameChainsImplementingResolver(in typeChains: inout [TypeNameChain], structure: [String: SourceKitRepresentable], currentNamespaces: TypeNameChain = []) {
        guard let typeName = structure.name,
            let kind = structure.declarationKind,
            Resolve.typeKinds.contains(kind)
            else { return }

        let namespacesAndType = currentNamespaces + [typeName]
        let inheritedTypeNames = structure.inheritedTypes?
            .compactMap { possibleType in
                (possibleType as? [String: SourceKitRepresentable])?.name
            } ?? []
        if inheritedTypeNames.contains(TypeNameConstants.resolver) {
            typeChains.append(namespacesAndType)
        }

        // Recurse into substructures and add any deeper types that implement Resolver
        structure.substructure?.forEach { substructure in
            storeTypeNameChainsImplementingResolver(
                in: &typeChains,
                structure: substructure,
                currentNamespaces: namespacesAndType
            )
        }
    }

    /// Find all substructures for the given type chain
    private func findSubstructureFor(typeChain: TypeNameChain, in structures: [[String: SourceKitRepresentable]]) -> [[String: SourceKitRepresentable]] {
        var typeChain = typeChain
        guard !typeChain.isEmpty else { return [] }
        let firstType = typeChain.removeFirst()

        let structuresForType = structures.filter { structure in
            structure.name == firstType
        }
        if typeChain.isEmpty {
            return structuresForType
        } else {
            return findSubstructureFor(typeChain: typeChain, in: structuresForType)
        }
    }
}
