import SpriteKit
import UIKit

/// Bridges SpriteKit nodes to UIKit gesture recognizers and SKCard convenience
/// accessors that the BrightSprout scenes rely on.
extension SKNode {
    /// Adds a UIKit gesture recognizer that finds this node's location in the
    /// enclosing `SKView` and routes the tap to the node.
    ///
    /// Scene construction often creates a node, configures its gesture, and
    /// only then adds it to the scene graph. In that window `scene` is nil, so
    /// the old implementation silently discarded the recognizer. Defer the
    /// binding to the next main-loop turn; by then SpriteKit has attached the
    /// node to its real scene and its view is available.
    func addGestureRecognizer(_ gesture: UIGestureRecognizer) {
        let delegate = SKNodeGestureDelegate(node: self)
        gesture.delegate = delegate
        objc_setAssociatedObject(gesture, &gestureDelegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        func installIfPossible() {
            guard let skView = self.scene?.view else { return }
            skView.isUserInteractionEnabled = true
            gesture.cancelsTouchesInView = false
            skView.addGestureRecognizer(gesture)
        }

        if self.scene?.view != nil {
            installIfPossible()
        } else {
            DispatchQueue.main.async { [weak self] in
                guard self != nil else { return }
                installIfPossible()
            }
        }
    }
}

/// UIKit gesture recognizers are installed on the enclosing SKView, so UIKit
/// otherwise sends every tap to every node-level recognizer in that view. The
/// delegate turns each recognizer back into a true node hit target and also
/// prevents recognizers belonging to nodes removed during a rebuild from
/// intercepting current-screen input.
private final class SKNodeGestureDelegate: NSObject, UIGestureRecognizerDelegate {
    weak var node: SKNode?

    init(node: SKNode) {
        self.node = node
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let node, let scene = node.scene, let view = scene.view,
              let tap = gestureRecognizer as? UITapGestureRecognizer else { return false }
        let scenePoint = view.convert(tap.location(in: view), to: scene)
        // SKNode.contains(_:) expects a point in the node's parent
        // coordinate space, not the node's local coordinate space.
        guard let parent = node.parent else { return false }
        return node.contains(parent.convert(scenePoint, from: scene))
    }
}

private var gestureDelegateKey: UInt8 = 0

extension SKShapeNode {
    /// A simple mutable size that mirrors the shape's frame dimensions.
    var size: CGSize {
        get { frame.size }
        set {
            self.path = CGPath(rect: CGRect(x: -newValue.width / 2,
                                            y: -newValue.height / 2,
                                            width: newValue.width,
                                            height: newValue.height),
                               transform: nil)
        }
    }

    /// A simple stroke-end fraction in [0,1] that re-renders the node's path
    /// as a partial arc starting from the top and sweeping clockwise. This is
    /// used by progress-style indicators such as the parent gate.
    var strokeEnd: CGFloat {
        get {
            (objc_getAssociatedObject(self, &strokeFractionKey) as? CGFloat) ?? 1
        }
        set {
            let fraction = max(0, min(1, newValue))
            objc_setAssociatedObject(self, &strokeFractionKey, fraction, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            let radius = min(frame.width, frame.height) / 2
            guard radius > 0 else { return }
            let start = CGFloat.pi / 2
            let end = start - fraction * 2 * .pi
            let path = CGMutablePath()
            path.addArc(center: .zero, radius: radius,
                        startAngle: start, endAngle: end, clockwise: true)
            self.path = path
        }
    }
}

private var strokeFractionKey: UInt8 = 0
