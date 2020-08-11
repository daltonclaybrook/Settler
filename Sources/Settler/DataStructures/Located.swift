import SourceKittenFramework

@dynamicMemberLookup
struct Located<Value> {
    let value: Value
    let file: File
    let offset: Int64?

    subscript<T>(dynamicMember keyPath: KeyPath<Value, T>) -> T {
        value[keyPath: keyPath]
    }
}

extension Located where Value == Void {
    init(file: File, offset: Int64?) {
        self.init(value: (), file: file, offset: offset)
    }
}

extension Located {
    func map<U>(_ transform: (Value) -> U) -> Located<U> {
        Located<U>(value: transform(value), file: file, offset: offset)
    }

    func mapVoid() -> Located<Void> {
        Located<Void>(file: file, offset: offset)
    }
}
