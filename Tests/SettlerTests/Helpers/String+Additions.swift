@testable import SettlerFramework

extension String {
    func replacingOccurrences(of target: Indentation, with replacement: Indentation) -> String {
        replacingOccurrences(of: target.description, with: replacement.description)
    }
}
