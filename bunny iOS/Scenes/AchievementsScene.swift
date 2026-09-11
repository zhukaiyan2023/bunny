import SpriteKit
import UIKit

/// Celebration summary of mastered scenes. Each badge shows the level title,
/// the earned stars, and a friendly check mark when complete.
final class AchievementsScene: SKScene {
    private let scrollNode = SKNode()

    override func didMove(to view: SKView) {
        backgroundColor = SKTheme.cream
        scrollNode.removeFromParent()
        buildHeader()
        buildBadgeWall()
        buildBackButton()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        removeAllChildren()
        didMove(to: SKView())
    }

    private func buildHeader() {
        let back = SKHUD.makeCircleButton(symbol: "chevron.left", diameter: 56)
        back.position = CGPoint(x: SKLayout.safeLeft(self) + 36, y: SKLayout.safeTop(self) - 28)
        let tap = UITapGestureRecognizer(target: self, action: #selector(goHome))
        back.addGestureRecognizer(tap)
        addChild(back)

        let title = SKLabel(text: "Achievements", style: .title, color: SKTheme.ink)
        title.fontSize = 48
        title.position = CGPoint(x: 0, y: SKLayout.safeTop(self) - 80)
        addChild(title)
        let subtitle = SKLabel(text: "Earn stars by helping Pip every day.",
                               style: .body,
                               color: SKTheme.ink.withAlphaComponent(0.65))
        subtitle.position = CGPoint(x: 0, y: SKLayout.safeTop(self) - 130)
        subtitle.fit(maxWidth: SKLayout.safeWidth(self) * 0.86)
        addChild(subtitle)
    }

    private func buildBadgeWall() {
        scrollNode.removeAllChildren()
        let store = ProgressStore.shared
        let levels = Curriculum.levels
        let columns: CGFloat = CGFloat(max(3, min(5, Int(SKLayout.safeWidth(self) / 110))))
        let badgeSize: CGFloat = min(96, SKLayout.safeWidth(self) / CGFloat(columns) * 0.75)
        let spacing = badgeSize + 18
        let totalWidth = columns * spacing - 18
        let startX = -totalWidth / 2 + badgeSize / 2
        let topY = SKLayout.safeTop(self) - 230
        let rowHeight = badgeSize + 50
        let bottomY = SKLayout.safeBottom(self) + 100
        let maxRows = max(1, Int((topY - bottomY) / rowHeight))

        for (index, level) in levels.enumerated() {
            let row = index / Int(columns)
            if row >= maxRows { break }
            let col = index % Int(columns)
            let earned = store.stars[level.id] ?? 0
            let isUnlocked = earned > 0
            let node = makeBadge(level: level, stars: earned, size: badgeSize, lit: isUnlocked)
            node.position = CGPoint(x: startX + CGFloat(col) * spacing,
                                    y: topY - CGFloat(row) * rowHeight)
            scrollNode.addChild(node)
        }
        addChild(scrollNode)
    }

    private func makeBadge(level: LevelDefinition, stars: Int, size: CGFloat, lit: Bool) -> SKNode {
        let node = SKNode()
        let ring = SKShapeNode(circleOfRadius: size / 2)
        ring.fillColor = lit ? SKTheme.color(for: level.area).withAlphaComponent(0.18) : SKTheme.paper
        ring.strokeColor = lit ? SKTheme.color(for: level.area) : SKTheme.cardStroke
        ring.lineWidth = 3
        node.addChild(ring)

        let glyph = SKLabelNode(text: level.area == .english ? "🏠" : level.area == .math ? "🔢" : "🌳")
        glyph.fontSize = size * 0.4
        glyph.fontName = "AvenirNext-Heavy"
        glyph.position = CGPoint(x: 0, y: 6)
        node.addChild(glyph)

        let starsNode = SKHUD.makeStars(filled: stars, size: 10, spacing: 1)
        starsNode.position = CGPoint(x: 0, y: -size / 2 - 14)
        node.addChild(starsNode)

        if lit {
            node.run(.repeatForever(.sequence([
                .scale(to: 1.04, duration: 0.8),
                .scale(to: 1.0, duration: 0.8)
            ])))
        }
        return node
    }

    private func buildBackButton() {
        let back = SKButton(title: "Home", style: .primary(color: SKTheme.blue), action: { [weak self] in
            _ = self
            SceneRouter.shared.goHome()
        })
        back.setSize(width: 220, height: 70)
        back.position = CGPoint(x: 0, y: SKLayout.safeBottom(self) + 80)
        addChild(back)
    }

    @objc private func goHome() { SceneRouter.shared.goHome() }
}