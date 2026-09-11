import SpriteKit
import UIKit

/// Visual tokens shared by every SpriteKit scene.
/// Colors mirror the previous SwiftUI palette so generated artwork remains on-brand.
enum SKTheme {
    static let cream: UIColor = UIColor(red: 0.99, green: 0.96, blue: 0.88, alpha: 1)
    static let ink: UIColor = UIColor(red: 0.18, green: 0.20, blue: 0.34, alpha: 1)
    static let paper: UIColor = UIColor(red: 1.0, green: 0.99, blue: 0.94, alpha: 1)
    static let blue: UIColor = UIColor(red: 0.27, green: 0.55, blue: 0.95, alpha: 1)
    static let green: UIColor = UIColor(red: 0.46, green: 0.78, blue: 0.55, alpha: 1)
    static let yellow: UIColor = UIColor(red: 1.0, green: 0.83, blue: 0.27, alpha: 1)
    static let pink: UIColor = UIColor(red: 0.97, green: 0.65, blue: 0.74, alpha: 1)
    static let orange: UIColor = UIColor(red: 0.97, green: 0.55, blue: 0.31, alpha: 1)
    static let purple: UIColor = UIColor(red: 0.62, green: 0.43, blue: 0.86, alpha: 1)
    static let shadow: UIColor = UIColor.black.withAlphaComponent(0.18)
    static let dimOverlay: UIColor = UIColor.black.withAlphaComponent(0.45)
    static let cardStroke: UIColor = UIColor.black.withAlphaComponent(0.10)

    /// Standardized radii and spacing constants for layout math.
    enum Layout {
        static let cardCorner: CGFloat = 22
        static let cardInset: CGFloat = 18
        static let buttonHeight: CGFloat = 60
        static let titleSize: CGFloat = 42
        static let headlineSize: CGFloat = 30
        static let bodySize: CGFloat = 22
        static let captionSize: CGFloat = 16
    }

    static func color(for area: LearningArea) -> UIColor {
        switch area {
        case .math: return blue
        case .english: return orange
        case .lifeSkills: return green
        }
    }
}

/// A reusable label drawn with the project's rounded typography.
final class SKLabel: SKNode {
    private let labelNode = SKLabelNode()
    var text: String {
        get { labelNode.text ?? "" }
        set { labelNode.text = newValue }
    }
    var color: UIColor {
        get { labelNode.fontColor ?? SKTheme.ink }
        set { labelNode.fontColor = newValue }
    }
    var fontSize: CGFloat {
        get { labelNode.fontSize }
        set { labelNode.fontSize = newValue }
    }
    var horizontalAlignmentMode: SKLabelHorizontalAlignmentMode {
        get { labelNode.horizontalAlignmentMode }
        set { labelNode.horizontalAlignmentMode = newValue }
    }
    var verticalAlignmentMode: SKLabelVerticalAlignmentMode {
        get { labelNode.verticalAlignmentMode }
        set { labelNode.verticalAlignmentMode = newValue }
    }
    var preferredMaxLayoutWidth: CGFloat {
        get { labelNode.preferredMaxLayoutWidth }
        set { labelNode.preferredMaxLayoutWidth = newValue }
    }

    init(text: String = "", style: Style = .body, color: UIColor = SKTheme.ink) {
        super.init()
        labelNode.text = text
        labelNode.fontName = "AvenirNext-Heavy"
        labelNode.fontColor = color
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        // Default to single-line so a missing preferredMaxLayoutWidth never
        // causes the text to wrap onto its own characters (which renders as
        // stacked duplicates in iOS 26). Callers that want wrapping should
        // call `fit(maxWidth:)` and set `numberOfLines = 0` themselves.
        labelNode.numberOfLines = 1
        apply(style: style)
        addChild(labelNode)
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    func apply(style: Style) {
        switch style {
        case .title:
            labelNode.fontName = "AvenirNext-Heavy"
            labelNode.fontSize = SKTheme.Layout.titleSize
        case .headline:
            labelNode.fontName = "AvenirNext-Heavy"
            labelNode.fontSize = SKTheme.Layout.headlineSize
        case .body:
            labelNode.fontName = "AvenirNext-DemiBold"
            labelNode.fontSize = SKTheme.Layout.bodySize
        case .caption:
            labelNode.fontName = "AvenirNext-Medium"
            labelNode.fontSize = SKTheme.Layout.captionSize
        case .button:
            labelNode.fontName = "AvenirNext-Heavy"
            labelNode.fontSize = 24
        }
    }

    enum Style {
        case title, headline, body, caption, button
    }

    func fit(maxWidth: CGFloat) {
        labelNode.preferredMaxLayoutWidth = maxWidth
    }
}