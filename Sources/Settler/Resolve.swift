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
                    fileName.hasSuffix(".swift") else { return nil }
                return path.bridge().appendingPathComponent(fileName)
            }

        do {
            let definitions = try ResolverDefinitionBuilder.buildWith(swiftFiles: swiftFiles)
            print(definitions)
        } catch let error {
            print(error)
            throw error
        }
    }
}
