import SpriteKit
import UIKit

/// Grid of levels for one area. Locked levels fade; completed ones show stars.
final class LevelMapScene: SKScene {
    let area: LearningArea

    init(size: CGSize, area: LearningArea) {
        self.area = area
        super.init(size: size)
        scaleMode = .resizeFill
    }
    required init?(coder aDecoder: NSCoder) { fatalError() }

    override func didMove(to view: SKView) {
        backgroundColor = SKTheme.cream
        buildHeader()
        buildPath()
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

        let title = SKLabel(text: area.rawValue, style: .headline, color: SKTheme.ink)
        title.position = CGPoint(x: 0, y: SKLayout.safeTop(self) - 80)
        addChild(title)
    }

    private func buildPath() {
        let levels = Curriculum.levels(in: area)
        let store = ProgressStore.shared
        guard !levels.isEmpty else { return }

        // Path zigzags across the viewport, sized to the safe area.
        let columns = max(3, min(5, Int(SKLayout.safeWidth(self) / 180)))
        let nodeSize: CGFloat = min(110, SKLayout.safeWidth(self) / CGFloat(columns) * 0.65)
        let spacing = nodeSize + 38
        let totalWidth = CGFloat(columns) * spacing - 38
        let startX = -totalWidth / 2 + nodeSize / 2
        let topY = SKLayout.safeTop(self) - 160
        let rowHeight = nodeSize + 90
        let bottomY = SKLayout.safeBottom(self) + 80
        let available = topY - bottomY
        let rows = max(1, Int(available / rowHeight))
        let ribbonContainer = SKNode()
        addChild(ribbonContainer)

        for (index, level) in levels.enumerated() {
            let row = index / columns
            if row >= rows { break }
            let column = index % columns
            let isOddRow = row % 2 == 1
            let xOffset = isOddRow ? spacing / 2 : 0
            let x = startX + CGFloat(column) * spacing + xOffset
            let y = topY - CGFloat(row) * rowHeight - CGFloat(index % columns) * 4
            let node = makeLevelNode(level: level, size: nodeSize, unlocked: store.isUnlocked(level, in: levels))
            node.position = CGPoint(x: x, y: y)
            ribbonContainer.addChild(node)
        }
    }

    private func makeLevelNode(level: LevelDefinition, size: CGFloat, unlocked: Bool) -> SKNode {
        let node = SKNode()
        let fillColor: UIColor = unlocked ? SKTheme.color(for: area).withAlphaComponent(0.18) : SKTheme.paper
        let strokeColor: UIColor = unlocked ? SKTheme.color(for: area) : SKTheme.cardStroke
        let base = SKShapeNode(circleOfRadius: size / 2)
        base.fillColor = fillColor
        base.strokeColor = strokeColor
        base.lineWidth = 3
        node.addChild(base)

        let number = SKLabelNode(text: String(level.id.dropFirst(level.id.first?.isLetter == true ? 1 : 0)))
        number.fontName = "AvenirNext-Heavy"
        number.fontSize = 36
        number.fontColor = unlocked ? SKTheme.ink : SKTheme.ink.withAlphaComponent(0.4)
        node.addChild(number)

        let title = SKLabel(text: level.title, style: .caption, color: unlocked ? SKTheme.ink : SKTheme.ink.withAlphaComponent(0.4))
        title.position = CGPoint(x: 0, y: -size / 2 - 16)
        title.fit(maxWidth: size * 1.6)
        node.addChild(title)

        let store = ProgressStore.shared
        if let stars = store.stars[level.id] {
            let starsNode = SKHUD.makeStars(filled: stars, size: 14)
            starsNode.position = CGPoint(x: 0, y: size / 2 + 18)
            node.addChild(starsNode)
        }

        if unlocked {
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            node.addGestureRecognizer(tap)
            node.userData = NSMutableDictionary()
            node.userData?["levelID"] = level.id
        }
        return node
    }

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard let node = recognizer.view as? SKNode,
              let id = node.userData?["levelID"] as? String,
              let level = Curriculum.levels.first(where: { $0.id == id }) else { return }
        SceneRouter.shared.goLesson(level: level)
    }

    @objc private func goHome() { SceneRouter.shared.goHome() }
}