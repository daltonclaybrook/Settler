import XCTest
@testable import SettlerFramework
import SourceKittenFramework

final class OutputFileContentsBuilderTests: XCTestCase {
    func testOutputWithFourSpacesIsCorrect() throws {
        let definition = try makeTestOrderedDefinition()
        let builder = OutputFileContentsBuilder(orderedDefinition: definition)
        let output = builder.buildFileContents(with: .spaces(count: 4))
        let expected = expectedCompleteResolverOutput
        XCTAssertEqual(output, expected)
    }

    func testOutputWithTwoSpacesIsCorrect() throws {
        let definition = try makeTestOrderedDefinition()
        let builder = OutputFileContentsBuilder(orderedDefinition: definition)
        let output = builder.buildFileContents(with: .spaces(count: 2))
        let expected = expectedCompleteResolverOutput
            .replacingOccurrences(of: .spaces(count: 4), with: .spaces(count: 2))
        XCTAssertEqual(output, expected)
    }

    func testOutputWithTabsIsCorrect() throws {
        let definition = try makeTestOrderedDefinition()
        let builder = OutputFileContentsBuilder(orderedDefinition: definition)
        let output = builder.buildFileContents(with: .tabs)
        let expected = expectedCompleteResolverOutput
            .replacingOccurrences(of: .spaces(count: 4), with: .tabs)
        XCTAssertEqual(output, expected)
    }

    func testOutputWithUnresolvedLazyKeyIsCorrect() throws {
        let definition = try makeTestOrderedDefinition(contents: SampleResolverContents.contentsWithUnresolvedLazy)
        let builder = OutputFileContentsBuilder(orderedDefinition: definition)
        let output = builder.buildFileContents(with: .spaces(count: 4))
        let expected = """
        \(OutputFileContentsBuilder.headerString)
        // DO NOT EDIT
        import Settler

        extension TestResolver {
            func resolve() -> Output {
                // Resolver functions
                let bar = Lazy {
                    self.resolveBar()
                }
                let foo = resolveFoo(bar: bar)

                return foo
            }
        }

        """
        XCTAssertEqual(output, expected)
    }

    func testOutputWithResolvedLazyKeyIsCorrect() throws {
        let definition = try makeTestOrderedDefinition(contents: SampleResolverContents.contentsWithResolvedLazy)
        let builder = OutputFileContentsBuilder(orderedDefinition: definition)
        let output = builder.buildFileContents(with: .spaces(count: 4))
        let expected = """
        \(OutputFileContentsBuilder.headerString)
        // DO NOT EDIT
        import Settler

        extension TestResolver {
            func resolve() -> Output {
                // Resolver functions
                let fizz = Lazy {
                    self.resolveFizz()
                }
                let foo = resolveFoo(fizz: fizz)
                let bar = resolveBar(foo: foo, fizz: fizz.resolve())

                return bar
            }
        }

        """
        XCTAssertEqual(output, expected)
    }

    // MARK: - Helpers

    private func makeTestOrderedDefinition(
        contents: String = SampleResolverContents.completeResolver,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> OrderedResolverDefinition {
        let resolverDefinition = try ResolverDefinition.makeSampleDefinition(contents: contents)
        let orderedDefinition = OrderedDefinitionBuilder.build(with: resolverDefinition)
        return try XCTUnwrap(orderedDefinition.left, file: file, line: line)
    }

    private var expectedCompleteResolverOutput: String {
        """
        \(OutputFileContentsBuilder.headerString)
        // DO NOT EDIT
        import Settler

        extension TestResolver {
            func resolve() throws -> Output {
                // Resolver functions
                let bar = resolveBar()
                let foo = resolveFoo(bar: bar)
                // Configuration
                configure(foo: foo, bar: bar)
                return foo
            }
        }

        """
    }
}
