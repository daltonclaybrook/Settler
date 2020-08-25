import XCTest
@testable import SettlerFramework

final class StringAdditionsTests: XCTestCase {
    func testPrefixIsStripped() {
        let key = "Key.Foo"
        let stripped = key.strippingPrefix("Key.")
        XCTAssertEqual(stripped, "Foo")
    }

    func testSuffixIsStripped() {
        let key = "Key.Foo"
        let stripped = key.strippingSuffix(".Foo")
        XCTAssertEqual(stripped, "Key")
    }

    func testPrefixAndSuffixAreStripped() {
        let key = "Lazy<Key.Foo>"
        let stripped = key.stripping(prefix: "Lazy<", andSuffix: ">")
        XCTAssertEqual(stripped, "Key.Foo")
    }

    func testSuffixIsNotStrippedWithoutPrefix() {
        let key = "Key.Foo>"
        let stripped = key.stripping(prefix: "Lazy<", andSuffix: ">")
        XCTAssertEqual(stripped, "Key.Foo>")
    }

    func testPrefixIsNotStrippedWithoutSuffix() {
        let key = "Lazy<Key.Foo"
        let stripped = key.stripping(prefix: "Lazy<", andSuffix: ">")
        XCTAssertEqual(stripped, "Lazy<Key.Foo")
    }

    func testDotPathIsExpandedCorrectly() {
        let relativePath = "./Sources"
        let absolutePath = relativePath.bridge().absolutePathRepresentation()
        let currentDirectory = FileManager.default.currentDirectoryPath
        let expected = "\(currentDirectory)/Sources"
        XCTAssertEqual(absolutePath, expected)
    }

    func testTildeIsExpandedCorrectly() {
        let tildePath = "~/Sources"
        let absolutePath = tildePath.bridge().absolutePathRepresentation()
        let homeDirectory = NSHomeDirectory()
        let expected = "\(homeDirectory)/Sources"
        XCTAssertEqual(absolutePath, expected)
    }
}
