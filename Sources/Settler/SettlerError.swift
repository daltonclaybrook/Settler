enum SettlerError: Error {
    case internalError
}

extension SettlerError: CustomStringConvertible {
    var description: String {
        switch self {
        case .internalError:
            return "An internal error occurred"
        }
    }
}
