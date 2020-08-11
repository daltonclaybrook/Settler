enum SettlerError: Error {
    case unknownError
    case failedToOpenFile(String)
}

extension SettlerError: CustomStringConvertible {
    var description: String {
        switch self {
        case .unknownError:
            return "An unknown error occurred"
        case .failedToOpenFile(let file):
            return "Failed to open file: \(file)"
        }
    }
}
