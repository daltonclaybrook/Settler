extension Array {
    mutating func mutableForEach(block: (inout Element) -> Void) {
        indices.forEach { index in
            block(&self[index])
        }
    }
}
