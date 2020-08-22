import ArgumentParser
import SettlerFramework

enum IndentArgument: String, ExpressibleByArgument {
    case spaces, tabs

    func toIndentation(tabSize: Int) -> Indentation {
        switch self {
        case .spaces:
            return .spaces(count: tabSize)
        case .tabs:
            return .tabs
        }
    }
}
