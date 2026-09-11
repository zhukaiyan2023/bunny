import UIKit
import SpriteKit

/// tvOS host. NOTE: This target currently has only Apple SpriteKit
/// template behavior. Wiring the full SceneRouter into tvOS requires
/// either moving scene/model files into `bunny Shared/` or adding
/// `bunny iOS/Models/`, `Scenes/`, `Services/`, `UI/` to the tvOS
/// target's synchronized folders in `bunny.xcodeproj`. Both are
/// tracked as Sprint 2 follow-ups (see ADR-0004).
///
/// In addition, tvOS scenes need a UIFocusEnvironment proxy for Siri
/// Remote input — see ADR-0006 and `epic-tvos-foundation/EPIC.md`.
final class GameViewController: UIViewController {

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
