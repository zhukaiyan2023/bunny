import SpriteKit
import UIKit

/// Compact HUD primitives reused by every game scene.
enum SKHUD {
    /// Draws 0-3 filled stars in a row.
    static func makeStars(filled: Int, size: CGFloat = 26, spacing: CGFloat = 4) -> SKNode {
        let container = SKNode()
        for index in 0..<3 {
            let node = SKShapeNode()
            let path = starPath(size: size)
            node.path = path
            node.fillColor = index < filled ? SKTheme.yellow : SKTheme.cream
            node.strokeColor = SKTheme.ink.withAlphaComponent(0.65)
            node.lineWidth = 1.2
            node.position.x = CGFloat(index) * (size + spacing) - (size + spacing)
            container.addChild(node)
        }
        return container
    }

    static func starPath(size: CGFloat, points: Int = 5) -> CGPath {
        let path = CGMutablePath()
        let radius = size / 2
        let inner = radius * 0.5
        for i in 0..<(points * 2) {
            let angle = Double(i) * .pi / Double(points) - .pi / 2
            let r = i % 2 == 0 ? radius : inner
            let x = cos(angle) * r
            let y = sin(angle) * r
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        path.closeSubpath()
        return path
    }

    /// Circular pause/back button rendered with SpriteKit primitives.
    static func makeCircleButton(symbol: String, color: UIColor = SKTheme.paper, diameter: CGFloat = 52) -> SKNode {
        let node = SKNode()
        let circle = SKShapeNode(circleOfRadius: diameter / 2)
        circle.fillColor = color
        circle.strokeColor = SKTheme.cardStroke
        circle.lineWidth = 1.4
        node.addChild(circle)
        let label = SKLabelNode(text: symbolImage(for: symbol))
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = diameter * 0.55
        label.fontColor = SKTheme.ink
        label.verticalAlignmentMode = .center
        node.addChild(label)
        node.userData = NSMutableDictionary()
        node.userData?["circle"] = circle
        return node
    }

    private static func symbolImage(for symbol: String) -> String {
        // Avoid system image rendering; use Unicode glyphs that ship with the system font.
        switch symbol {
        case "chevron.left": return "‹"
        case "chevron.right": return "›"
        case "speaker.wave.2.fill": return "♪"
        case "play.fill": return "▶"
        case "pause.fill": return "‖"
        case "hand.raised.fill": return "?"
        case "lock.fill": return "★"
        case "xmark": return "✕"
        case "arrow.clockwise": return "↻"
        default: return "•"
        }
    }
}

/// A horizontal progress bar with a moving fill.
final class SKProgressBar: SKNode {
    private let track: SKShapeNode
    private let fill: SKShapeNode
    private let width: CGFloat
    private let height: CGFloat
    init(width: CGFloat = 280, height: CGFloat = 18, color: UIColor = SKTheme.blue) {
        self.width = width
        self.height = height
        track = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: height / 2)
        track.fillColor = SKTheme.cream
        track.strokeColor = SKTheme.cardStroke
        track.lineWidth = 1
        fill = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: height / 2)
        fill.fillColor = color
        fill.strokeColor = .clear
        super.init()
        addChild(track)
        addChild(fill)
        fill.xScale = 0
        fill.position.x = -width / 2
        fill.zPosition = 1
    }
    required init?(coder aDecoder: NSCoder) { fatalError() }
    func setProgress(_ value: Double, animated: Bool = false) {
        let clamped = max(0, min(1, value))
        fill.removeAllActions()
        if animated {
            fill.run(.scaleX(to: CGFloat(clamped), duration: 0.25))
        } else {
            fill.xScale = CGFloat(clamped)
        }
    }
}