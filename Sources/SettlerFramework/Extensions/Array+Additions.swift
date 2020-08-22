extension Array {
    mutating func mutableForEach(block: (inout Element) throws -> Void) rethrows {
        try indices.forEach { index in
            try block(&self[index])
        }
    }

    /// Apply a function to each combination of elements in the array and
    /// return the result
    func mapEachCombination<T>(_ transform: (Element, Element) -> T) -> [T] {
        reduceEachCombination(into: [T]()) { result, first, second in
            result.append(transform(first, second))
        }
    }

    /// Apply a function to each combination of elements in the array and
    /// return the flattened result
    func flatMapEachCombination<T>(_ transform: (Element, Element) -> [T]) -> [T] {
        reduceEachCombination(into: [T]()) { result, first, second in
            result.append(contentsOf: transform(first, second))
        }
    }

    /// Apply a reducer function to each combination of elements in the array and
    /// return the result
    func reduceEachCombination<T>(into: T, _ reducer: (inout T, Element, Element) -> Void) -> T {
        guard !isEmpty else { return into }
        var into = into
        for index1 in (0..<(count - 1)) {
            for index2 in ((index1 + 1)..<count) {
                reducer(&into, self[index1], self[index2])
            }
        }
        return into
    }

    /// Apply a map function to every element in the array. For those elements that
    /// return a non-nil result, remove that element from the receiver. Return the
    /// mapped elements.
    mutating func compactMapRemoving<T>(_ transform: (Element) -> T?) -> [T] {
        var result: [T] = []
        removeAll { element in
            guard let output = transform(element) else { return false }
            result.append(output)
            return true
        }
        return result
    }
}

public extension Array where Element: XcodeErrorDescription {
    /// Returns the complete error string of an array of definition errors
    var errorString: String {
        map(\.description).joined(separator: "\n")
    }
}
