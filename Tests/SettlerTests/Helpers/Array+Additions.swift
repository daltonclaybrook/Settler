extension Array {
    subscript(safe index: Int) -> Element? {
        guard (0..<count).contains(index) else { return nil }
        return self[index]
    }
}
