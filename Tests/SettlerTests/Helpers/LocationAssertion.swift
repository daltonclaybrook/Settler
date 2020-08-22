import Foundation
@testable import SettlerFramework
import SourceKittenFramework
import XCTest

func assert<T>(located: Located<T>?, equals: T, in contents: String, file: StaticString = #file, line: UInt = #line) where T: Equatable {
    guard let located = located else {
        return XCTFail("Located value is nil", file: file, line: line)
    }
    guard let locatedOffset = located.offset else {
        return XCTFail("The provided located value has a nil offset", file: file, line: line)
    }

    XCTAssertEqual(located.value, equals, file: file, line: line)

    var contents = contents
    var markerDistances: Set<Int> = []
    while let markerIndex = contents.firstIndex(of: "↓") {
        let distance = contents.distance(from: contents.startIndex, to: markerIndex)
        markerDistances.insert(distance)
        contents.remove(at: markerIndex)
    }

    guard !markerDistances.isEmpty else {
        return XCTFail("File contents did not contain any marker indexes ('↓')", file: file, line: line)
    }

    let locatedByteOffset = ByteCount(locatedOffset)
    let errorLocation = File(contents: contents).stringView.location(fromByteOffset: locatedByteOffset)
    guard markerDistances.contains(errorLocation) else {
        return XCTFail("No markers found at expected location: \(errorLocation)", file: file, line: line)
    }
}

func assert<T>(located: [Located<T>], contains: [T], in contents: String, file: StaticString = #file, line: UInt = #line) where T: Comparable {
    XCTAssertGreaterThanOrEqual(located.count, contains.count, file: file, line: line)

    let sortedLocated = located.sorted { $0.value < $1.value }
    let sortedMatchingValues = contains.sorted(by: <)
    zip(sortedLocated, sortedMatchingValues).forEach { pair in
        assert(located: pair.0, equals: pair.1, in: contents, file: file, line: line)
    }
}

extension String {
    var strippingMarkers: String {
        replacingOccurrences(of: "↓", with: "")
    }
}
