import XCTest
@testable import SettlerFramework

final class ResolverDefinitionBuilderTests: XCTestCase {
    /// Since the resolver doesn't conform to the protocol, the Swift compiler will
    /// handle this error, so we expect no error
    func testNoDefinitionOrErrorReturnedForNoOutput() throws {
        let contents = """
        struct TestResolver: Resolver {
            enum Key {}
        }
        """
        let output = try ResolverDefinitionBuilder.buildWith(pathsOrContents: [.contents(contents)])
        XCTAssertEqual(output.definitions.count, 0)
        XCTAssertEqual(output.errors.count, 0)
    }

    /// Since the resolver doesn't conform to the protocol, the Swift compiler will
    /// handle this error, so we expect no error
    func testNoDefinitionOrErrorReturnedForNoKey() throws {
        let contents = """
        struct TestResolver: Resolver {
            typealias Output = Key.Foo
        }
        """
        let output = try ResolverDefinitionBuilder.buildWith(pathsOrContents: [.contents(contents)])
        XCTAssertEqual(output.definitions.count, 0)
        XCTAssertEqual(output.errors.count, 0)
    }

    func testErrorIsReturnedForOutputThatIsNotAnAlias() throws {
        let contents = """
        struct TestResolver: Resolver {
            ↓enum Output {}
            enum Key {}
        }
        """
        let output = try ResolverDefinitionBuilder.buildWith(pathsOrContents: [.contents(contents.strippingMarkers)])
        XCTAssertEqual(output.definitions.count, 0)
        XCTAssertEqual(output.errors.count, 1)
        assert(located: output.errors[safe: 0], equals: .outputIsNotATypeAlias, in: contents)
    }

    func testErrorIsReturnedForKeyThatIsNotAnEnum() throws {
        let contents = """
        struct TestResolver: Resolver {
            typealias Output = Key.Foo
            ↓struct Key {}
        }
        """
        let output = try ResolverDefinitionBuilder.buildWith(pathsOrContents: [.contents(contents.strippingMarkers)])
        XCTAssertEqual(output.definitions.count, 0)
        XCTAssertEqual(output.errors.count, 1)
        assert(located: output.errors[safe: 0], equals: .keyIsNotAnEnum, in: contents)
    }

    func testErrorIsReturnedForAllKeyMembersThatAreNotTypeAliases() throws {
        let contents = """
        struct TestResolver: Resolver {
            typealias Output = Key.Foo
            enum Key {
                ↓enum Foo {}
                typealias Bar = String
                ↓struct Fizz {}
            }
        }
        """
        let output = try ResolverDefinitionBuilder.buildWith(pathsOrContents: [.contents(contents.strippingMarkers)])
        XCTAssertEqual(output.definitions.count, 0)
        XCTAssertEqual(output.errors.count, 2)
        assert(located: output.errors, contains: [
            .keyMemberIsNotATypeAlias, .keyMemberIsNotATypeAlias
        ], in: contents)
    }

    func testErrorIsReturnedWhenOutputIsNotAMemberOfKey() throws {
        let contents = """
        struct TestResolver: Resolver {
            ↓typealias Output = String
            enum Key {}
        }
        """
        let output = try ResolverDefinitionBuilder.buildWith(pathsOrContents: [.contents(contents.strippingMarkers)])
        XCTAssertEqual(output.definitions.count, 0)
        XCTAssertEqual(output.errors.count, 1)
        assert(located: output.errors[safe: 0], equals: .outputIsNotAKeyMember, in: contents)
    }

    func testErrorIsReturnedIfResolverDeclarationCannotBeFound() throws {
        let contents = """
        ↓extension TestResolver: Resolver {
            typealias Output = Key.Foo
            enum Key {
                typealias Foo = String
            }
        }
        """
        let output = try ResolverDefinitionBuilder.buildWith(pathsOrContents: [.contents(contents.strippingMarkers)])
        XCTAssertEqual(output.definitions.count, 0)
        XCTAssertEqual(output.errors.count, 1)
        assert(located: output.errors[safe: 0], equals: .cantFindDeclarationFile, in: contents)
    }

    func testErrorIsReturnedIfResolverFunctionContainsNonKeyParam() throws {
        let contents = """
        struct TestResolver: Resolver {
            typealias Output = Key.Foo
            enum Key {
                ↓typealias Foo = String
            }
            ↓func resolveFoo(fail: Int) -> Key.Foo { "abc" }
        }
        """
        let output = try ResolverDefinitionBuilder.buildWith(pathsOrContents: [.contents(contents.strippingMarkers)])
        XCTAssertEqual(output.definitions.count, 0)
        XCTAssertEqual(output.errors.count, 2)
        assert(located: output.errors, contains: [
            .resolverFunctionContainsNonKeyParam, .noResolverFunctionForKey
        ], in: contents)
    }
}
