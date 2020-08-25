import XCTest
@testable import SettlerFramework

final class ArrayAdditionsTests: XCTestCase {
    func testMutableForEach() {
        var nums = [1, 2, 3]
        nums.mutableForEach { $0 *= 2 }
        XCTAssertEqual(nums, [2, 4, 6])
    }

    func testMapEachCombination() {
        let nums = [1, 2, 3, 4]
        let result = nums.mapEachCombination { $0 + $1 }
        XCTAssertEqual(result, [3, 4, 5, 5, 6, 7])
    }

    func testFlatMapEachCombination() {
        let nums = [1, 2, 3, 4]
        let result = nums.flatMapEachCombination { [$0 + $1, -1] }
        XCTAssertEqual(result, [3, -1, 4, -1, 5, -1, 5, -1, 6, -1, 7, -1])
    }

    func testReduceEachCombinationInto() {
        let nums = [1, 2, 3]
        let result = nums.reduceEachCombination(into: ["0"]) { result, first, second in
            result.append("\(first)\(second)")
        }
        XCTAssertEqual(result, ["0", "12", "13", "23"])
    }

    func testCompactMapRemoving() {
        var nums = [0, 1, 2, 3, 4, 5, 6]
        let result = nums.compactMapRemoving { $0 % 2 == 0 ? $0 : nil }
        XCTAssertEqual(nums, [1, 3, 5])
        XCTAssertEqual(result, [0, 2, 4, 6])
    }
}
