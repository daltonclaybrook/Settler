import XCTest
@testable import SettlerFramework
import SourceKittenFramework

final class OrderedDefinitionBuilderTests: XCTestCase {
    func testSimpleResolverReturnsCorrectOrder() throws {
        let resolver = try ResolverDefinition.makeSampleDefinition()
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
        let resolver = try ResolverDefinition.makeSampleDefinition(contents: contents.strippingMarkers)
        let result = OrderedDefinitionBuilder.build(with: resolver)
        let errors = try XCTUnwrap(result.right)

        XCTAssertEqual(errors.count, 1)
        assert(located: errors[safe: 0], equals: .circularResolverDependency(keys: ["Key.Bar", "Key.Fizz", "Key.Foo", "Key.Bar"]), in: contents)
    }

    func testErrorIsReturnedForThrowingFunctionWithLazyUsage() throws {
        let contents = SampleResolverContents.throwingWithLazyUsageContents
        let resolver = try ResolverDefinition.makeSampleDefinition(contents: contents.strippingMarkers)
        let result = OrderedDefinitionBuilder.build(with: resolver)
        let errors = try XCTUnwrap(result.right)

        XCTAssertEqual(errors.count, 1)
        assert(located: errors[safe: 0], equals: .resolverFunctionCannotBeThrowingIfResultIsUsedLazily, in: contents)
    }
}

extension OrderedResolverDefinition {
    var allCallDefinitions: [ResolverFunctionDefinition] {
        orderedCalls.map(\.definition)
    }
}
