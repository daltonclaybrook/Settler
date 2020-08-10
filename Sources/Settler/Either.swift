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

    func mapLeft<T>(_ transform: (L) -> T) -> Either<T, R> {
        switch self {
        case .left(let value):
            return .left(transform(value))
        case .right(let value):
            return .right(value)
        }
    }
}

protocol EitherType {
    associatedtype L
    associatedtype R
    var left: L? { get }
    var right: R? { get }
}

extension Either: EitherType {}

extension Array where Element: EitherType {
    func splitLeftAndRight() -> ([Element.L], [Element.R]) {
        var allLeft: [Element.L] = []
        var allRight: [Element.R] = []
        forEach { element in
            if let left = element.left {
                allLeft.append(left)
            } else if let right = element.right {
                allRight.append(right)
            }
        }
        return (allLeft, allRight)
    }
}
