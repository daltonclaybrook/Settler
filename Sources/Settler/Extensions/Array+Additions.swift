extension Array {
    mutating func mutableForEach(block: (inout Element) -> Void) {
        indices.forEach { index in
            block(&self[index])
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
}
