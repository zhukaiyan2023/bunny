import Cocoa
import SpriteKit

/// macOS host. NOTE: Although `bunny.xcodeproj` now declares the four
/// `bunny iOS/Models`, `Scenes`, `Services`, `UI` synchronized folders
/// as members of the macOS target (via the pbxproj surgery in
/// `tools/pbxproj_add_ios_subfolder.py`), Xcode's Swift compile phase
/// does NOT pull Swift files from those subfolders into the macOS
/// build. Result: macOS today still shows the Apple-bundled
/// `GameScene` template.
///
/// Wiring macOS to the full bunny game requires either:
///   1. Hand-adding PBXBuildFile entries per Swift file to the macOS
///      target's Sources build phase via Xcode UI, or
///   2. A build script that symlinks the iOS Swift files into
///      `bunny macOS/` at build time.
/// Both are documented as Sprint 3 follow-ups in
/// `production/sprints/sprint-02.md`.
final class GameViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let skView = self.view as! SKView
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true

        let scene = GameScene.newGameScene()
        skView.presentScene(scene)
    }
}
