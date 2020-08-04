/// A mechanism for resolving dependencies lazily.
///
/// This is useful when runtime circumstances prevent a dependency from needing to be instantiated.
@dynamicMemberLookup
public final class Lazy<Value> {
    private var value: Value?
    private let creationBlock: () -> Value

    public init(_ creationBlock: @escaping () -> Value) {
        self.creationBlock = creationBlock
    }

    public func resolve() -> Value {
        if let value = value {
            return value
        } else {
            let value = creationBlock()
            self.value = value
            return value
        }
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<Value, T>) -> T {
        resolve()[keyPath: keyPath]
    }
}
