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

    func testErrorIsReturnedIfResolverHasDuplicateResolverFunctions() throws {
        let contents = """
        struct TestResolver: Resolver {
            typealias Output = Key.Foo
            enum Key {
                typealias Foo = String
            }
            ↓func resolveFirstFoo() -> Key.Foo { "abc" }
            ↓func resolveSecondFoo() -> Key.Foo { "123" }
        }
        """
        let output = try ResolverDefinitionBuilder.buildWith(pathsOrContents: [.contents(contents.strippingMarkers)])
        XCTAssertEqual(output.definitions.count, 0)
        XCTAssertEqual(output.errors.count, 2)
        assert(located: output.errors, contains: [
            .duplicateReturnTypesInResolverFunctions,
            .duplicateReturnTypesInResolverFunctions
        ], in: contents)
    }

    func testDefinitionHasCorrectTypeChain() throws {
        let output = try ResolverDefinitionBuilder.buildWith(pathsOrContents: [.contents(completeTestResolverContents)])
        let definition = try XCTUnwrap(output.definitions[safe: 0])
        XCTAssertEqual(output.definitions.count, 1)
        XCTAssertEqual(output.errors.count, 0)
        XCTAssertEqual(definition.typeChain, ["TestResolver"])
    }

    func testDefinitionHasCorrectKeys() throws {
        let output = try ResolverDefinitionBuilder.buildWith(pathsOrContents: [.contents(completeTestResolverContents)])
        let definition = try XCTUnwrap(output.definitions[safe: 0])
        let keys = definition.keyDefinition.typeAliases.map(\.value)
        let expectedKeys = [
            TypeAliasDefinition(name: "Foo", existingType: "String"),
            TypeAliasDefinition(name: "Bar", existingType: "Int")
        ]
        XCTAssertEqual(keys, expectedKeys)
    }

    func testDefinitionHasCorrectOutput() throws {
        let output = try ResolverDefinitionBuilder.buildWith(pathsOrContents: [.contents(completeTestResolverContents)])
        let definition = try XCTUnwrap(output.definitions[safe: 0])
        let expectedOutput = TypeAliasDefinition(name: "Output", existingType: "Key.Foo")
        XCTAssertEqual(definition.outputDefinition, expectedOutput)
    }

    func testDefinitionHasCorrectResolverFunctions() throws {
        let output = try ResolverDefinitionBuilder.buildWith(pathsOrContents: [.contents(completeTestResolverContents)])
        let definition = try XCTUnwrap(output.definitions[safe: 0])
        let resolverFunctions = definition.resolverFunctions.map(\.value)
        let expectedResolverFunctions = [
            ResolverFunctionDefinition(name: "resolveFoo(bar:)", parameters: [
                FunctionParameter(name: "bar", typeName: "Key.Bar")
            ], returnType: "Key.Foo", isThrowing: false),
            ResolverFunctionDefinition(name: "resolveBar()", parameters: [], returnType: "Key.Bar", isThrowing: false)
        ]
        XCTAssertEqual(resolverFunctions, expectedResolverFunctions)
    }

    func testDefinitionHasCorrectConfigFunctions() throws {
        let output = try ResolverDefinitionBuilder.buildWith(pathsOrContents: [.contents(completeTestResolverContents)])
        let definition = try XCTUnwrap(output.definitions[safe: 0])
        let expectedConfigFunctions = [
            ConfigFunctionDefinition(name: "configure(foo:bar:)", parameters: [
                FunctionParameter(name: "foo", typeName: "Key.Foo"),
                FunctionParameter(name: "bar", typeName: "Key.Bar")
            ], isThrowing: true)
        ]
        XCTAssertEqual(definition.configFunctions, expectedConfigFunctions)
    }

    func testDefinitionIsReturnedWithAnExtension() throws {
        let declaration = """
        struct TestResolver: Resolver {
            typealias Output = Key.Foo
            enum Key {
                typealias Foo = String
                typealias Bar = Int
            }
        }
        """
        let functions = """
        extension TestResolver {
            func resolveFoo(bar: Key.Bar) -> Key.Foo { "abc" }
            func resolveBar() -> Key.Bar { 123 }
        }
        """
        let contents: [FilePathOrContents] = [declaration, functions].map { .contents($0.strippingMarkers) }
        let output = try ResolverDefinitionBuilder.buildWith(pathsOrContents: contents)
        XCTAssertEqual(output.definitions.count, 1)
        XCTAssertEqual(output.errors.count, 0)
    }

    func testDefinitionIsReturnedForResolverWithNamespace() throws {
        let declaration = """
        enum Namespace {
            struct TestResolver: Resolver {
                typealias Output = Key.Foo
                enum Key {
                    typealias Foo = String
                    typealias Bar = Int
                }
            }
        }
        """
        let functions = """
        extension Namespace.TestResolver {
            func resolveFoo(bar: Key.Bar) -> Key.Foo { "abc" }
            func resolveBar() -> Key.Bar { 123 }
        }
        """
        let contents: [FilePathOrContents] = [declaration, functions].map { .contents($0.strippingMarkers) }
        let output = try ResolverDefinitionBuilder.buildWith(pathsOrContents: contents)
        XCTAssertEqual(output.definitions.count, 1)
        XCTAssertEqual(output.errors.count, 0)
        XCTAssertEqual(output.definitions[safe: 0]?.typeChain, ["Namespace", "TestResolver"])
    }

    // MARK: - Helpers

    var completeTestResolverContents: String {
        """
        struct TestResolver: Resolver {
            var someProperty = "abc123"

            typealias Output = Key.Foo
            enum Key {
                typealias Foo = String
                typealias Bar = Int
            }

            // Resolver functions
            func resolveFoo(bar: Key.Bar) -> Key.Foo { "abc" }
            func resolveBar() -> Key.Bar { 123 }

            // Config functions
            func configure(foo: Key.Foo, bar: Key.Bar) throws { print(foo) }

            // Ignored functions
            func thisIsIgnored(foo: Key.Foo, testing: String) { print(testing) }
        }
        """
    }
}
