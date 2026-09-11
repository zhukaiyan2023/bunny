import SpriteKit
import UIKit

/// A rounded, paper-styled card used as a panel background across scenes.
final class SKCard: SKShapeNode {
    init(width: CGFloat, height: CGFloat, cornerRadius: CGFloat = SKTheme.Layout.cardCorner,
         fill: UIColor = SKTheme.paper, stroke: UIColor = SKTheme.cardStroke) {
        super.init()
        let path = CGPath(roundedRect: CGRect(x: -width / 2, y: -height / 2, width: width, height: height),
                           cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        self.path = path
        fillColor = fill
        strokeColor = stroke
        lineWidth = 1.4
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    func resize(width: CGFloat, height: CGFloat, cornerRadius: CGFloat = SKTheme.Layout.cardCorner) {
        let path = CGPath(roundedRect: CGRect(x: -width / 2, y: -height / 2, width: width, height: height),
                           cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        self.path = path
    }
}