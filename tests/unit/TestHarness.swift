import Foundation

/// Minimal XCTest-style test harness. Avoids a hard XCTest dependency so the
/// tests run with plain `swiftc`. See `tools/run_unit_tests.sh`.

enum TestResult {
    case pass
    case fail(String)

    var isPass: Bool {
        if case .pass = self { return true } else { return false }
    }
}

final class TestCase {
    let name: String
    let block: () -> TestResult
    init(_ name: String, _ block: @escaping () -> TestResult) {
        self.name = name
        self.block = block
    }
}

enum XCTestCase {
    static func XCTAssert(_ cond: @autoclosure () -> Bool,
                          _ message: String = "",
                          file: String = #file,
                          line: Int = #line) -> TestResult {
        if cond() {
            return .pass
        } else {
            return .fail("XCTAssert at \(file):\(line): \(message)")
        }
    }

    static func XCTAssertEqual<T: Equatable>(_ a: @autoclosure () -> T,
                                             _ b: @autoclosure () -> T,
                                             _ message: String = "",
                                             file: String = #file,
                                             line: Int = #line) -> TestResult {
        let av = a(); let bv = b()
        if av == bv { return .pass }
        return .fail("XCTAssertEqual at \(file):\(line): \(message) (\(av) != \(bv))")
    }

    static func XCTAssertNil<T>(_ v: @autoclosure () -> T?,
                                _ message: String = "",
                                file: String = #file,
                                line: Int = #line) -> TestResult {
        if v() == nil { return .pass }
        return .fail("XCTAssertNil at \(file):\(line): \(message) (was non-nil)")
    }

    static func XCTAssertTrue(_ cond: @autoclosure () -> Bool,
                              _ message: String = "",
                              file: String = #file,
                              line: Int = #line) -> TestResult {
        if cond() { return .pass }
        return .fail("XCTAssertTrue at \(file):\(line): \(message)")
    }
}

@MainActor
final class TestRunner {
    var cases: [TestCase] = []

    func add(_ name: String, _ block: @escaping @MainActor () -> TestResult) {
        cases.append(TestCase(name, { block() }))
    }

    func run() -> Int {
        var failures = 0
        for tc in cases {
            let r: TestResult
            if #available(macOS 13.0, *) {
                r = MainActor.assumeIsolated { tc.block() }
            } else {
                r = tc.block()
            }
            switch r {
            case .pass:
                print("  ✓ \(tc.name)")
            case .fail(let msg):
                failures += 1
                print("  ✗ \(tc.name)")
                print("      \(msg)")
            }
        }
        print("")
        let total = cases.count
        print("Ran \(total) tests: \(total - failures) passed, \(failures) failed")
        return failures == 0 ? 0 : 1
    }
}
