import SpriteKit
import UIKit

/// Bridges SpriteKit nodes to UIKit gesture recognizers and SKCard convenience
/// accessors that the BrightSprout scenes rely on.
extension SKNode {
    /// Adds a UIKit gesture recognizer that finds this node's location in the
    /// enclosing `SKView` and routes the tap to the node.
    func addGestureRecognizer(_ gesture: UIGestureRecognizer) {
        guard let skView = self.scene?.view else { return }
        skView.isUserInteractionEnabled = true
        gesture.cancelsTouchesInView = false
        skView.addGestureRecognizer(gesture)
    }
}

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