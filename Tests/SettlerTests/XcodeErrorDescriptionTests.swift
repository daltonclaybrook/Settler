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
}

struct MockFile: FileType {
    let path: String?
    let stringView: StringView

    init(path: String?, contents: String) {
        self.path = path
        self.stringView = StringView(contents)
    }
}
