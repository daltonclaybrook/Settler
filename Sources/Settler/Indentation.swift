enum Indentation {
    case spaces(count: Int)
    case tabs
}

extension Indentation: CustomStringConvertible {
    var description: String {
        switch self {
        case .spaces(let count):
            return Array(repeating: " ", count: count).joined()
        case .tabs:
            return "\t"
        }
    }

    func depth(_ depth: Int) -> IndentDepth {
        IndentDepth(indentation: self, depth: depth)
    }
}

struct IndentDepth {
    let indentation: Indentation
    let depth: Int
}

extension IndentDepth: CustomStringConvertible {
    var description: String {
        Array(repeating: indentation.description, count: depth).joined()
    }

    static func + (lhs: IndentDepth, rhs: Int) -> IndentDepth {
        IndentDepth(indentation: lhs.indentation, depth: lhs.depth + rhs)
    }
}
