import SpriteKit
import UIKit

/// A touchable, focusable button rendered entirely with SpriteKit primitives.
final class SKButton: SKNode {
    enum Style {
        case primary(color: UIColor)
        case secondary(color: UIColor)
        case chip(color: UIColor)
        case ghost
    }

    private let background: SKShapeNode
    private let icon: SKSpriteNode?
    private let titleLabel: SKLabel
    let action: () -> Void
    private(set) var isEnabled = true
    var isPressed = false

    init(title: String, iconName: String? = nil, style: Style, action: @escaping () -> Void) {
        self.action = action
        background = SKShapeNode(rectOf: .zero, cornerRadius: SKTheme.Layout.cardCorner)
        background.lineWidth = 0
        let (fill, stroke) = Self.styling(style)
        background.fillColor = fill
        background.strokeColor = stroke
        titleLabel = SKLabel(text: title, style: .button)
        titleLabel.color = Self.foregroundColor(for: style)
        if let iconName, !iconName.isEmpty {
            icon = SKSpriteNode(texture: SKTexture(imageNamed: iconName))
        } else {
            icon = nil
        }
        super.init()
        addChild(background)
        addChild(titleLabel)
        if let icon {
            addChild(icon)
        }
        isUserInteractionEnabled = true
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    func setSize(width: CGFloat, height: CGFloat = SKTheme.Layout.buttonHeight) {
        background.path = nil
        let path = CGPath(roundedRect: CGRect(x: -width / 2, y: -height / 2, width: width, height: height),
                           cornerWidth: SKTheme.Layout.cardCorner, cornerHeight: SKTheme.Layout.cardCorner, transform: nil)
        background.path = path
        titleLabel.position = CGPoint(x: 0, y: 0)
        titleLabel.fit(maxWidth: width * 0.78)
        if let icon {
            icon.size = CGSize(width: height * 0.5, height: height * 0.5)
            icon.position = CGPoint(x: -width / 2 + height * 0.55, y: 0)
            titleLabel.position.x = height * 0.1
        }
    }

    func setEnabled(_ value: Bool) {
        isEnabled = value
        alpha = value ? 1 : 0.45
    }

    func setTitle(_ value: String) {
        titleLabel.text = value
    }

    private static func styling(_ style: Style) -> (UIColor, UIColor) {
        switch style {
        case .primary(let color): return (color, color.withAlphaComponent(0.85))
        case .secondary(let color): return (SKTheme.paper, color)
        case .chip(let color): return (color.withAlphaComponent(0.18), color.withAlphaComponent(0.55))
        case .ghost: return (SKTheme.paper.withAlphaComponent(0.0), SKTheme.cardStroke)
        }
    }

    private static func foregroundColor(for style: Style) -> UIColor {
        switch style {
        case .primary: return .white
        case .secondary(let color): return color
        case .chip(let color): return color
        case .ghost: return SKTheme.ink
        }
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isEnabled, let touch = touches.first else { return }
        let point = touch.location(in: self)
        guard background.contains(point) else { return }
        isPressed = true
        run(.scale(to: 0.96, duration: 0.08))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        let inside = background.contains(point)
        if isPressed && !inside {
            isPressed = false
            run(.scale(to: 1, duration: 0.12))
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isPressed, let touch = touches.first else { return }
        let point = touch.location(in: self)
        let tapped = background.contains(point)
        isPressed = false
        run(.scale(to: 1, duration: 0.18))
        if tapped, isEnabled {
            // Soft tap feedback on every button release.
            Feedback.shared.tap()
            action()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isPressed = false
        run(.scale(to: 1, duration: 0.18))
    }
}