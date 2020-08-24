#if !canImport(ObjectiveC)
import XCTest

extension OrderedDefinitionBuilderTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__OrderedDefinitionBuilderTests = [
        ("testErrorIsReturnedForThrowingFunctionWithLazyUsage", testErrorIsReturnedForThrowingFunctionWithLazyUsage),
        ("testResolverWithCircularDependencyReturnsError", testResolverWithCircularDependencyReturnsError),
        ("testSimpleResolverReturnsCorrectOrder", testSimpleResolverReturnsCorrectOrder),
    ]
}

extension OutputFileContentsBuilderTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__OutputFileContentsBuilderTests = [
        ("testOutputWithFourSpacesIsCorrect", testOutputWithFourSpacesIsCorrect),
        ("testOutputWithResolvedLazyKeyIsCorrect", testOutputWithResolvedLazyKeyIsCorrect),
        ("testOutputWithTabsIsCorrect", testOutputWithTabsIsCorrect),
        ("testOutputWithTwoSpacesIsCorrect", testOutputWithTwoSpacesIsCorrect),
        ("testOutputWithUnresolvedLazyKeyIsCorrect", testOutputWithUnresolvedLazyKeyIsCorrect),
    ]
}

extension ResolverDefinitionBuilderTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__ResolverDefinitionBuilderTests = [
        ("testDefinitionHasCorrectConfigFunctions", testDefinitionHasCorrectConfigFunctions),
        ("testDefinitionHasCorrectKeys", testDefinitionHasCorrectKeys),
        ("testDefinitionHasCorrectOutput", testDefinitionHasCorrectOutput),
        ("testDefinitionHasCorrectResolverFunctions", testDefinitionHasCorrectResolverFunctions),
        ("testDefinitionHasCorrectTypeChain", testDefinitionHasCorrectTypeChain),
        ("testDefinitionIsReturnedForResolverWithNamespace", testDefinitionIsReturnedForResolverWithNamespace),
        ("testDefinitionIsReturnedWithAnExtension", testDefinitionIsReturnedWithAnExtension),
        ("testErrorIsReturnedForAllKeyMembersThatAreNotTypeAliases", testErrorIsReturnedForAllKeyMembersThatAreNotTypeAliases),
        ("testErrorIsReturnedForKeyThatIsNotAnEnum", testErrorIsReturnedForKeyThatIsNotAnEnum),
        ("testErrorIsReturnedForOutputThatIsNotAnAlias", testErrorIsReturnedForOutputThatIsNotAnAlias),
        ("testErrorIsReturnedIfResolverDeclarationCannotBeFound", testErrorIsReturnedIfResolverDeclarationCannotBeFound),
        ("testErrorIsReturnedIfResolverFunctionContainsNonKeyParam", testErrorIsReturnedIfResolverFunctionContainsNonKeyParam),
        ("testErrorIsReturnedIfResolverHasDuplicateResolverFunctions", testErrorIsReturnedIfResolverHasDuplicateResolverFunctions),
        ("testErrorIsReturnedWhenOutputIsNotAMemberOfKey", testErrorIsReturnedWhenOutputIsNotAMemberOfKey),
        ("testNoDefinitionOrErrorReturnedForNoKey", testNoDefinitionOrErrorReturnedForNoKey),
        ("testNoDefinitionOrErrorReturnedForNoOutput", testNoDefinitionOrErrorReturnedForNoOutput),
    ]
}

extension TypeAliasDefinitionBuilderTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__TypeAliasDefinitionBuilderTests = [
        ("testInvalidTypeAliasReturnsError", testInvalidTypeAliasReturnsError),
        ("testKeyMemberErrorIsCorrect", testKeyMemberErrorIsCorrect),
        ("testOutputErrorIsCorrect", testOutputErrorIsCorrect),
        ("testUnusualTypeAliasReturnsDefinition", testUnusualTypeAliasReturnsDefinition),
        ("testValidTypeAliasReturnsDefinition", testValidTypeAliasReturnsDefinition),
    ]
}

public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(OrderedDefinitionBuilderTests.__allTests__OrderedDefinitionBuilderTests),
        testCase(OutputFileContentsBuilderTests.__allTests__OutputFileContentsBuilderTests),
        testCase(ResolverDefinitionBuilderTests.__allTests__ResolverDefinitionBuilderTests),
        testCase(TypeAliasDefinitionBuilderTests.__allTests__TypeAliasDefinitionBuilderTests),
    ]
}
#endif
