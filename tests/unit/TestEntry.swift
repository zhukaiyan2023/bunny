import Foundation

/// Entry point. Compiled as a library (no implicit main), then `@main` gives
/// us a single entry. The runner collects every test group, runs them, and
/// exits with 0 on success, non-zero on any failure.

@main
struct BunnyTestEntry {
    static func main() async {
        // All test types (ProgressStore, SceneRouter) are @MainActor, so we
        // hop to the main actor before running any test code.
        await MainActor.run { runOnMain() }
    }

    @MainActor
    static func runOnMain() {
        let runner = TestRunner()
        progressStoreTests(into: runner)
        curriculumTests(into: runner)
        sceneRouterTests(into: runner)

        print("")
        print("════════════════════════════════════════")
        print("Bunny Unit Tests")
        print("════════════════════════════════════════")
        print("")
        exit(Int32(runner.run()))
    }
}
