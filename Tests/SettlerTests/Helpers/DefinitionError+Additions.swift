@testable import SettlerFramework

extension DefinitionError: Comparable {
    public static func < (lhs: DefinitionError, rhs: DefinitionError) -> Bool {
        // This probably isn't an acceptable implementation for production code,
        // but it seems okay for the tests! 😅
        lhs.description < rhs.description
    }
}
