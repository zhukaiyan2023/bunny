import Cocoa
import SpriteKit

/// macOS host. NOTE: This target currently has only Apple SpriteKit
/// template behavior. Wiring the full SceneRouter into macOS requires
/// either moving scene/model files into `bunny Shared/` or adding
/// `bunny iOS/Models/`, `Scenes/`, `Services/`, `UI/` to the macOS
/// target's synchronized folders in `bunny.xcodeproj`. Both are
/// tracked as Sprint 2 follow-ups (see ADR-0004).
///
/// For now this view shows the Apple-bundled GameScene template so the
/// macOS app still launches and renders something.
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
