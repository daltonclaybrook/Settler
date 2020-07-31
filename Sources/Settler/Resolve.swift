import ArgumentParser
import Foundation
import SourceKittenFramework

struct Resolve: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Parse any Resolvers in the target project and generate type-safe functions for producing the desired Resolver outputs"
    )

    @Option(name: [.short, .customLong("sources")],
            help: "Path to a directory used to search for Resolvers")
    var sourcesPath: String = "."

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
            throw SettlerError.internalError
        }

        try enumerator.forEach { fileName in
            guard let fileName = fileName as? String,
                fileName.hasSuffix(".swift") else { return }
            let filePath = path.bridge().appendingPathComponent(fileName)
            try processFile(path: filePath)
        }
    }

    // MARK: - Helpers

    private func processFile(path: String) throws {
        guard let file = File(path: path) else { return }
        let structure = try Structure(file: file)
        structure.dictionary.forEach { key,  }
    }
}
