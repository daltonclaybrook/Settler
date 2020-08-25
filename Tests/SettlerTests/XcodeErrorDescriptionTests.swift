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
        let contents = "extension TestResolver {}"
        let file1 = MockFile(path: "/path/one.swift", contents: contents)
        let error1 = DefinitionError.cantFindDeclarationFile
            .located(in: file1, offset: 0)
        let file2 = MockFile(path: "/path/two.swift", contents: contents)
        let error2 = DefinitionError
            .resolverFunctionCannotBeThrowingIfResultIsUsedLazily
            .located(in: file2, offset: 0)
        let result = [error1, error2].errorString
        let expected = """
        /path/one.swift:1:1: error: \(error1.value.description)
        /path/two.swift:1:1: error: \(error2.value.description)
        """
        XCTAssertEqual(result, expected)
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
