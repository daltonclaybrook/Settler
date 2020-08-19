protocol XcodeErrorDescription: CustomStringConvertible {
    var filePath: String? { get }
    var errorString: String { get }
    var lineAndCharacter: (line: Int, character: Int) { get }
}

extension XcodeErrorDescription {
    /// Inspired by SwiftLint
    var description: String {
        // Xcode likes warnings and errors in the following format:
        // {full_path_to_file}{:line}{:character}: {error,warning}: {content}
        let (line, character) = lineAndCharacter
        let fileString = filePath ?? "<nopath>"
        let lineString = ":\(line)"
        let charString = ":\(character)"
        let errorString = ": error"
        let contentString = ": \(errorString)"
        return [fileString, lineString, charString, errorString, contentString].joined()
    }
}
