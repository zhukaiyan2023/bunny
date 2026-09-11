import SpriteKit
import UIKit

/// Layout helpers that every scene uses to position UI consistently across
/// portrait phones, landscape phones, and iPads. The helpers respect the
/// device's safe area insets so HUD chrome never collides with the notch,
/// dynamic island, rounded corners, or the home indicator.
enum SKLayout {
    /// Returns the safe-area insets reported by the active scene view.
    static func safeInsets(in scene: SKScene) -> UIEdgeInsets {
        if #available(iOS 11.0, *), let view = scene.view,
           let insets = view.safeAreaInsets as UIEdgeInsets? {
            return insets
        }
        return .zero
    }

    /// Top of the visible safe area in scene coordinates (positive Y up).
    /// Falls back to a sensible default when the view isn't laid out yet.
    static func safeTop(_ scene: SKScene) -> CGFloat {
        let insets = safeInsets(in: scene)
        if insets.top > 0 || insets.bottom > 0 || insets.left > 0 || insets.right > 0 {
            return scene.size.height / 2 - insets.top
        }
        // No real safe area yet — assume iPhone-style notch on top.
        return scene.size.height / 2 - max(48, scene.size.height * 0.05)
    }

    /// Bottom of the visible safe area in scene coordinates.
    static func safeBottom(_ scene: SKScene) -> CGFloat {
        let insets = safeInsets(in: scene)
        if insets.top > 0 || insets.bottom > 0 || insets.left > 0 || insets.right > 0 {
            return -scene.size.height / 2 + insets.bottom
        }
        return -scene.size.height / 2 + max(34, scene.size.height * 0.03)
    }

    /// Left edge of the safe area in scene coordinates.
    static func safeLeft(_ scene: SKScene) -> CGFloat {
        let insets = safeInsets(in: scene)
        return -scene.size.width / 2 + insets.left
    }

    /// Right edge of the safe area in scene coordinates.
    static func safeRight(_ scene: SKScene) -> CGFloat {
        let insets = safeInsets(in: scene)
        return scene.size.width / 2 - insets.right
    }

    /// Full safe-area width available for content.
    static func safeWidth(_ scene: SKScene) -> CGFloat {
        safeRight(scene) - safeLeft(scene)
    }

    /// Full safe-area height available for content.
    static func safeHeight(_ scene: SKScene) -> CGFloat {
        safeTop(scene) - safeBottom(scene)
    }

    /// Detects whether the scene is wider than tall — useful for picking a
    /// different layout strategy on landscape phones / iPads.
    static func isLandscape(_ scene: SKScene) -> Bool {
        scene.size.width > scene.size.height
    }

    /// A reasonable max-width for any card in the safe area. On iPad we cap
    /// cards at 720pt so they don't stretch awkwardly wide.
    static func cardMaxWidth(_ scene: SKScene) -> CGFloat {
        isLandscape(scene) ? min(safeWidth(scene) * 0.92, 760) : safeWidth(scene) * 0.94
    }
}

extension SKShapeNode {
    /// Convenience accessor for centering a node within the safe area.
    func placeSafeTop(_ scene: SKScene, inset: CGFloat = 0) {
        position.y = SKLayout.safeTop(scene) - inset - frame.height / 2
    }

    func placeSafeBottom(_ scene: SKScene, inset: CGFloat = 0) {
        position.y = SKLayout.safeBottom(scene) + inset + frame.height / 2
    }

    func placeSafeCenter(_ scene: SKScene, verticalOffset: CGFloat = 0) {
        position.y = verticalOffset
    }
}