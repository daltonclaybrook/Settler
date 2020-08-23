import XCTest
@testable import SettlerFramework
import SourceKittenFramework

final class TypeAliasDefinitionBuilderTests: XCTestCase {
    func testValidTypeAliasReturnsDefinition() throws {
        let contents = "typealias Output = Key.Foo"
        let (file, structure) = try fileAndAliasStructure(contents: contents)
        let result = TypeAliasDefinitionBuilder
            .buildFrom(aliasStructure: structure, in: file)
            .map(\.value)

        let expected = TypeAliasDefinition(name: "Output", existingType: "Key.Foo")
        XCTAssertEqual(result, .success(expected))
    }

    func testInvalidTypeAliasReturnsError() throws {
        let contents = """
        struct NotATypeAlias {
            var foo = "abc"
        }
        """
        let (file, structure) = try fileAndAliasStructure(contents: contents)
        let result = TypeAliasDefinitionBuilder
            .buildFrom(aliasStructure: structure, in: file)
            .map(\.value)
        XCTAssertEqual(result, .failure(.notATypeAlias))
    }

    func testUnusualTypeAliasReturnsDefinition() throws {
        let contents = "typealias       SomeName     =       String; let foo = 123"
        let (file, structure) = try fileAndAliasStructure(contents: contents)
        let result = TypeAliasDefinitionBuilder
            .buildFrom(aliasStructure: structure, in: file)
            .map(\.value)

        let expected = TypeAliasDefinition(name: "SomeName", existingType: "String")
        XCTAssertEqual(result, .success(expected))
    }

    func testKeyMemberErrorIsCorrect() throws {
        let contents = "let foo = 123"
        let (file, structure) = try fileAndAliasStructure(contents: contents)
        let error = TypeAliasDefinitionBuilder
            .buildFrom(aliasStructure: structure, in: file)
            .failureError?
            .keyMemberError
        XCTAssertEqual(error, .keyMemberIsNotATypeAlias)
    }

    func testOutputErrorIsCorrect() throws {
        let contents = "enum Foo {}"
        let (file, structure) = try fileAndAliasStructure(contents: contents)
        let error = TypeAliasDefinitionBuilder
            .buildFrom(aliasStructure: structure, in: file)
            .failureError?
            .outputError
        XCTAssertEqual(error, .outputIsNotATypeAlias)
    }

    // MARK: - Helpers

    private func fileAndAliasStructure(contents: String, file: StaticString = #file, line: UInt = #line) throws -> (File, [String: SourceKitRepresentable]) {
        let sourceFile = File(contents: contents)
        let structure = try Structure(file: sourceFile)
            .dictionary
            .substructure?[safe: 0]
        let unwrapped = try XCTUnwrap(structure, file: file, line: line)
        return (sourceFile, unwrapped)
    }
}
