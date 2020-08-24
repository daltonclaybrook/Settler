@testable import SettlerFramework
import XCTest

extension ResolverDefinition {
    func getResolverFunctionWith(namePrefix: String, file: StaticString = #file, line: UInt = #line) throws -> ResolverFunctionDefinition {
        let function = resolverFunctions.first { $0.value.name.hasPrefix(namePrefix) }
        return try XCTUnwrap(function?.value, file: file, line: line)
    }

    static func makeSampleDefinition(
        contents: String = SampleResolverContents.completeResolver,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> ResolverDefinition {
        let definition = try ResolverDefinitionBuilder
            .buildWith(pathsOrContents: [.contents(contents)])
            .definitions[safe: 0]
        return try XCTUnwrap(definition, file: file, line: line)
    }
}
