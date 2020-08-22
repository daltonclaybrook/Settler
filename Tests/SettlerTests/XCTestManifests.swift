#if !canImport(ObjectiveC)
import XCTest

extension ResolverDefinitionBuilderTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__ResolverDefinitionBuilderTests = [
        ("testErrorIsReturnedForAllKeyMembersThatAreNotTypeAliases", testErrorIsReturnedForAllKeyMembersThatAreNotTypeAliases),
        ("testErrorIsReturnedForKeyThatIsNotAnEnum", testErrorIsReturnedForKeyThatIsNotAnEnum),
        ("testErrorIsReturnedForOutputThatIsNotAnAlias", testErrorIsReturnedForOutputThatIsNotAnAlias),
        ("testErrorIsReturnedIfResolverDeclarationCannotBeFound", testErrorIsReturnedIfResolverDeclarationCannotBeFound),
        ("testErrorIsReturnedIfResolverFunctionContainsNonKeyParam", testErrorIsReturnedIfResolverFunctionContainsNonKeyParam),
        ("testErrorIsReturnedWhenOutputIsNotAMemberOfKey", testErrorIsReturnedWhenOutputIsNotAMemberOfKey),
        ("testNoDefinitionOrErrorReturnedForNoKey", testNoDefinitionOrErrorReturnedForNoKey),
        ("testNoDefinitionOrErrorReturnedForNoOutput", testNoDefinitionOrErrorReturnedForNoOutput),
    ]
}

public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(ResolverDefinitionBuilderTests.__allTests__ResolverDefinitionBuilderTests),
    ]
}
#endif
