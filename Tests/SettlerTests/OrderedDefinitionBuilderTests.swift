import XCTest
@testable import SettlerFramework
import SourceKittenFramework

final class OrderedDefinitionBuilderTests: XCTestCase {
    func testSimpleResolverReturnsCorrectOrder() throws {
        let resolver = try sampleResolverDefinition()
        let definition = try XCTUnwrap(OrderedDefinitionBuilder.build(with: resolver).left)
        let allCalls = definition.allCallDefinitions
        let expected = [
            try resolver.getResolverFunctionWith(namePrefix: "resolveBar"),
            try resolver.getResolverFunctionWith(namePrefix: "resolveFoo"),
        ]
        XCTAssertEqual(allCalls, expected)
    }

    func testResolverWithCircularDependencyReturnsError() throws {
        let contents = SampleResolverContents.circularResolverContents
        let resolver = try sampleResolverDefinition(contents: contents.strippingMarkers)
        let result = OrderedDefinitionBuilder.build(with: resolver)
        let errors = try XCTUnwrap(result.right)

        XCTAssertEqual(errors.count, 1)
        assert(located: errors[safe: 0], equals: .circularResolverDependency(keys: ["Key.Bar", "Key.Fizz", "Key.Foo", "Key.Bar"]), in: contents)
    }

    func testErrorIsReturnedForThrowingFunctionWithLazyUsage() throws {
        let contents = SampleResolverContents.throwingWithLazyUsageContents
        let resolver = try sampleResolverDefinition(contents: contents.strippingMarkers)
        let result = OrderedDefinitionBuilder.build(with: resolver)
        let errors = try XCTUnwrap(result.right)

        XCTAssertEqual(errors.count, 1)
        assert(located: errors[safe: 0], equals: .resolverFunctionCannotBeThrowingIfResultIsUsedLazily, in: contents)
    }

    // MARK: - Helpers

    private func sampleResolverDefinition(
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

extension OrderedResolverDefinition {
    var allCalls: [FunctionCall] {
        functionOrder.sections.flatMap(\.calls)
    }

    var allCallDefinitions: [ResolverFunctionDefinition] {
        allCalls.map(\.definition)
    }
}
