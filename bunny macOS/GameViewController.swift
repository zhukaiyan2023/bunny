import Cocoa
import SpriteKit

/// macOS host. The full bunny scene graph (Models/Scenes/Services/UI) lives
/// under `bunny iOS/` and depends on UIKit (UITouch, UITapGestureRecognizer)
/// so it does not currently compile into this target. macOS still shows
/// Apple's bundled `GameScene` template as a placeholder.
///
/// Wiring macOS to the real bunny game is documented as a Sprint-3
/// follow-up. The pbxproj would need to either:
///   1. Add PBXBuildFile entries per Swift file to the macOS target's
///      Sources build phase via Xcode UI, after first refactoring the
///      scene touch handling to use platform-agnostic gestures; or
///   2. Adopt macCatalyst, which keeps UIKit and reuses the iOS scenes
///      directly.
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
