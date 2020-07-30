@dynamicMemberLookup
public struct Resolved<KeyValue> {
    public let value: KeyValue

    public subscript<T>(dynamicMember keyPath: KeyPath<KeyValue, T>) -> T {
        value[keyPath: keyPath]
    }

    public init(_ value: KeyValue) {
        self.value = value
    }
}

public protocol Resolver {
    associatedtype Output
}

