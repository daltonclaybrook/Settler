import ArgumentParser
import Foundation
import SettlerFramework

struct Resolve: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Parse any Resolvers in the target project and generate type-safe functions for producing the desired Resolver outputs"
    )

    @Option(name: [.short, .customLong("sources")],
            help: "Path to a directory used to search for Resolvers")
    var sourcesPath: String = "."

    @Option(help: "Style of indentation to use for generated code")
    var indent: IndentArgument = .spaces

    @Option(help: "Count of spaces to use for indentation. Only valid with '--indent spaces'.")
    var tabSize: Int = 4

    private var indentation: Indentation {
        indent.toIndentation(tabSize: tabSize)
    }

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

        // Determine absolute paths of all Swift files in `sourcesPath`
        let swiftFiles = enumerator
            .compactMap { fileName -> String? in
                guard let fileName = fileName as? String,
                    fileName.hasSuffix(".swift") else { return nil }
                return path.bridge().appendingPathComponent(fileName)
            }

        let definitionsAndErrors = try ResolverDefinitionBuilder.buildWith(swiftFiles: swiftFiles)
        let (orderedDefinitions, orderBuilderErrors) = definitionsAndErrors.definitions
            .map(OrderedDefinitionBuilder.build(with:))
            .splitLeftAndRight()

        try orderedDefinitions.forEach { definition in
            let builder = OutputFileContentsBuilder(orderedDefinition: definition)
            let contents = builder.buildFileContents(with: indentation)
            try saveFileContents(contents, for: definition.definition)
        }

        let allErrors = definitionsAndErrors.errors + orderBuilderErrors.flatMap { $0 }
        if !allErrors.isEmpty {
            let errorString = allErrors.errorString
            print(errorString, to: &standardError)
        } else {
            print("✅ All Resolvers were generated successfully!")
        }
    }

    // MARK: - Helpers

    private func saveFileContents(_ contents: String, for definition: ResolverDefinition) throws {
        let fileName = "\(definition.typeChain.dotJoined)+Output.swift"
        let filePath = definition.declarationFilePath
            .bridge()
            .deletingLastPathComponent
            .bridge()
            .appendingPathComponent(fileName)
        try contents.write(toFile: filePath, atomically: true, encoding: .utf8)
    }
}
