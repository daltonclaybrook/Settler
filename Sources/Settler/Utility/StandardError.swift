#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#elseif canImport(MSVCRT)
import MSVCRT
#endif

// This type has been plucked out of ArgumentParser because it is not public.
// I've filed an issue to make this type public:
// https://github.com/apple/swift-argument-parser/issues/227
struct StandardError: TextOutputStream {
    mutating func write(_ string: String) {
        for byte in string.utf8 { putc(numericCast(byte), stderr) }
    }
}

var standardError = StandardError()
