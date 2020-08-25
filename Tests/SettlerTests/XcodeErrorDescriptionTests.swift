import XCTest
@testable import SettlerFramework
import SourceKittenFramework

final class XcodeErrorDescriptionTests: XCTestCase {
    func testXcodeErrorStringIsCorrect() {
        let contents = "  enum Output {}"
        let file = MockFile(path: "/this/is/a/path.swift", contents: contents)
        let locatedError = DefinitionError.outputIsNotATypeAlias
            .located(in: file, offset: 2)
        let expected = "/this/is/a/path.swift:1:3: error: \(locatedError.value.description)"
        XCTAssertEqual(locatedError.description, expected)
    }

    func testErrorStringIsCorrectWhenPathIsNil() {
        let contents = """
        struct TestResolver: Resolver {
            typealias Output = String
        }
        """
        let file = MockFile(path: nil, contents: contents)
        let locatedError = DefinitionError.outputIsNotAKeyMember
            .located(in: file, offset: 36)
        let expected = "<nopath>:2:5: error: \(locatedError.value.description)"
        XCTAssertEqual(locatedError.description, expected)
    }

    func testJoinedErrorStringsAreCorrect() {
        let errors: [DefinitionError] = [
            .keyIsNotAnEnum,
            .invalidTypeAlias,
            .invalidFunction,
            .unexpectedSyntaxElement,
            .cantFindDeclarationFile,
            .circularResolverDependency(keys: ["Key.Foo", "Key.Bar"]),
            .resolverFunctionCannotBeThrowingIfResultIsUsedLazily
        ]
        let contents = "extension TestResolver {}"
        let locatedErrors = errors.enumerated()
            .map { (index, error) -> Located<DefinitionError> in
                let file = MockFile(path: "/path/file\(index).swift", contents: contents)
                return error.located(in: file, offset: 0)
            }
        let expectedErrorStrings = locatedErrors.map { located in
            "\(located.filePath!):1:1: error: \(located.value.description)"
        }
        let expected = expectedErrorStrings.joined(separator: "\n")
        XCTAssertEqual(locatedErrors.errorString, expected)
    }
}

struct MockFile: FileType {
    let path: String?
    let stringView: StringView

    init(path: String?, contents: String) {
        self.path = path
        self.stringView = StringView(contents)
    }
}
