/// Types that adopt this protocol can produce errors that are displayed
/// inside of Xcode in a particular file, on a specific line and with a
/// character offset
public protocol XcodeErrorDescription: CustomStringConvertible {
    var filePath: String? { get }
    var errorString: String { get }
    var lineAndCharacter: (line: Int, character: Int) { get }
}

extension XcodeErrorDescription {
    /// Inspired by SwiftLint
    public var description: String {
        // Xcode likes warnings and errors in the following format:
        // {full_path_to_file}{:line}{:character}: {error,warning}: {content}
        let (line, character) = lineAndCharacter
        let fileString = filePath ?? "<nopath>"
        let lineString = ":\(line)"
        let charString = ":\(character)"
        let errorLabelString = ": error"
        let errorContentString = ": \(errorString)"
        return [fileString, lineString, charString, errorLabelString, errorContentString].joined()
    }
}
