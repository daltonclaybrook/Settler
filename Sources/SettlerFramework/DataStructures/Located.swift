import SourceKittenFramework

/// Represents an object that has a corresponding location in a file,
/// such as a function definition.
@dynamicMemberLookup
public struct Located<Value> {
    public let value: Value
    public let file: File
    public let offset: Int64?

    public subscript<T>(dynamicMember keyPath: KeyPath<Value, T>) -> T {
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

    func mapConstant<C>(_ value: C) -> Located<C> {
        Located<C>(value: value, file: file, offset: offset)
    }
}

extension Located: XcodeErrorDescription where Value: Error, Value: CustomStringConvertible {
    public var filePath: String? { file.path }
    public var errorString: String { value.description }

    public var lineAndCharacter: (line: Int, character: Int) {
        let byteOffset = ByteCount(offset ?? 0)
        return file.stringView.lineAndCharacter(forByteOffset: byteOffset) ?? (0, 0)
    }
}

extension Located: Error where Value: Error {}

/// We get the implementation for this conformance automatically
/// from the `XcodeErrorDescription` conformance
extension Located: CustomStringConvertible where Value: Error, Value: CustomStringConvertible {}
