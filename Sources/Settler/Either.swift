enum Either<L, R> {
    case left(L)
    case right(R)
}

extension Either {
    var left: L? {
        switch self {
        case .left(let left):
            return left
        case .right:
            return nil
        }
    }

    var right: R? {
        switch self {
        case .left:
            return nil
        case .right(let right):
            return right
        }
    }
}
