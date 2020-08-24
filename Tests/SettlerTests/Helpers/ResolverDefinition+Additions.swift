@testable import SettlerFramework
import XCTest

extension ResolverDefinition {
    func getResolverFunctionWith(namePrefix: String, file: StaticString = #file, line: UInt = #line) throws -> ResolverFunctionDefinition {
        let function = resolverFunctions.first { $0.value.name.hasPrefix(namePrefix) }
        return try XCTUnwrap(function?.value, file: file, line: line)
    }
}
