import SpriteKit
import UIKit

/// Main menu. Pure SpriteKit — no SwiftUI hosts. The menu is laid out as five
/// distinct horizontal bands so every element is fully visible and clearly
/// separated from the others:
///
///   band 1 (top)   — centred title + subtitle
///   band 2 (upper) — animated mascot on the left, illustrated star tally on the right
///   band 3 (mid)   — featured continue card with progress dots
///   band 4 (lower) — three-up world grid
///   band 5 (foot)  — "For Grown-Ups" pill above the home indicator
final class MenuScene: SKScene {
    private var observation: NSObjectProtocol?
    private let titleLabel = SKLabel(text: "BrightSprout", style: .title, color: SKTheme.ink)
    private let subtitle = SKLabel(text: "A learning adventure with Pip", style: .caption, color: SKTheme.ink.withAlphaComponent(0.65))
    private let continueCard = SKNode()
    private let areaStack = SKNode()
    private let mascot = SKSpriteNode(texture: SKTexture(imageNamed: "PipWorldSprite"))
    private let starTallyContainer = SKNode()
    private var starTallyText: SKLabel?
    private let mascotHalo = SKShapeNode(circleOfRadius: 110)

    override func didMove(to view: SKView) {
        backgroundColor = SKTheme.cream
        titleLabel.removeFromParent()
        subtitle.removeFromParent()
        mascot.removeFromParent()
        continueCard.removeFromParent()
        areaStack.removeFromParent()
        starTallyContainer.removeFromParent()
        buildBackground()
        buildHeader()
        buildContinueCard()
        buildAreaCards()
        buildParentButton()
        observation = NotificationCenter.default.addObserver(
            forName: .progressStoreDidChange, object: nil, queue: .main
        ) { [weak self] _ in self?.refreshProgress() }
        refreshProgress()
        SpeechService.shared.speak("Hello! Pick a world to explore.")
    }

    deinit { if let observation { NotificationCenter.default.removeObserver(observation) } }

    override func didChangeSize(_ oldSize: CGSize) {
        removeAllChildren()
        didMove(to: SKView())
    }

    // MARK: - Background

    private func buildBackground() {
        // Soft green "lawn" stripe at the bottom so the home button doesn't
        // sit on bare cream paper.
        let ground = SKShapeNode(rectOf: CGSize(width: size.width + 40, height: size.height * 0.35))
        ground.fillColor = SKTheme.green.withAlphaComponent(0.16)
        ground.strokeColor = .clear
        ground.position = CGPoint(x: 0, y: SKLayout.safeBottom(self) - size.height * 0.06)
        addChild(ground)
    }

    // MARK: - Header (title + subtitle + mascot + star tally)

    private func buildHeader() {
        let safeTop = SKLayout.safeTop(self)
        let safeWidth = SKLayout.safeWidth(self)

        // Title + subtitle centred at the top.
        titleLabel.removeFromParent()
        titleLabel.position = CGPoint(x: 0, y: safeTop - 50)
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.fontSize = 34
        titleLabel.fit(maxWidth: safeWidth * 0.92)
        addChild(titleLabel)

        subtitle.removeFromParent()
        subtitle.position = CGPoint(x: 0, y: safeTop - 82)
        subtitle.horizontalAlignmentMode = .center
        subtitle.fontSize = 15
        subtitle.fit(maxWidth: safeWidth * 0.92)
        addChild(subtitle)

        // Mascot sits on a yellow halo in the upper-left.
        mascotHalo.removeFromParent()
        mascotHalo.fillColor = SKTheme.yellow.withAlphaComponent(0.55)
        mascotHalo.strokeColor = .clear
        mascotHalo.position = CGPoint(x: -safeWidth * 0.30, y: safeTop - 200)
        addChild(mascotHalo)
        mascotHalo.run(.repeatForever(.sequence([
            .scale(to: 1.06, duration: 1.4),
            .scale(to: 1.0, duration: 1.4)
        ])))

        mascot.removeFromParent()
        let mascotHeight: CGFloat = min(SKLayout.safeHeight(self) * 0.20, 180)
        mascot.size = CGSize(width: mascotHeight * 2 / 3, height: mascotHeight)
        mascot.position = mascotHalo.position
        mascot.alpha = 1.0
        addChild(mascot)
        mascot.run(.repeatForever(.sequence([
            .moveBy(x: 0, y: -6, duration: 1.4),
            .moveBy(x: 0, y: 6, duration: 1.4)
        ])))

        // Star tally card on the opposite side — five filled/empty star outlines
        // arranged horizontally plus a numeric tally underneath.
        buildStarTally(safeWidth: safeWidth, safeTop: safeTop)
    }

    private func buildStarTally(safeWidth: CGFloat, safeTop: CGFloat) {
        starTallyContainer.removeFromParent()
        starTallyContainer.removeAllChildren()

        let card = SKCard(width: 180, height: 96, cornerRadius: 24, fill: SKTheme.paper)
        card.position = CGPoint(x: safeWidth * 0.30, y: safeTop - 200)
        starTallyContainer.addChild(card)

        // Five outline stars in a row.
        let stars = SKHUD.makeStars(filled: 0, size: 22, spacing: 4)
        stars.position = CGPoint(x: 0, y: 18)
        card.addChild(stars)

        let tally = SKLabel(text: "0 / 150", style: .caption, color: SKTheme.ink)
        tally.position = CGPoint(x: 0, y: -22)
        tally.horizontalAlignmentMode = .center
        tally.fontSize = 14
        tally.fit(maxWidth: 140)
        card.addChild(tally)
        starTallyText = tally

        addChild(starTallyContainer)
    }

    // MARK: - Continue card

    private func buildContinueCard() {
        let card = SKCard(width: min(SKLayout.cardMaxWidth(self), 720), height: 168, cornerRadius: 28)
        card.fillColor = SKTheme.yellow
        card.strokeColor = SKTheme.orange.withAlphaComponent(0.4)

        let topTag = SKLabel(text: "CONTINUE", style: .caption, color: SKTheme.orange)
        topTag.position = CGPoint(x: -card.frame.width / 2 + 24, y: card.frame.height / 2 - 24)
        topTag.horizontalAlignmentMode = .left
        topTag.fontSize = 12
        card.addChild(topTag)

        let label = SKLabel(text: "Pick a world to start", style: .headline, color: SKTheme.ink)
        label.position = CGPoint(x: 0, y: 30)
        label.horizontalAlignmentMode = .center
        label.fit(maxWidth: card.frame.width - 40)
        card.addChild(label)

        let levelName = SKLabel(text: "Drag, listen, and play with Pip", style: .body, color: SKTheme.ink.withAlphaComponent(0.78))
        levelName.position = CGPoint(x: 0, y: 0)
        levelName.horizontalAlignmentMode = .center
        levelName.fontSize = 16
        levelName.fit(maxWidth: card.frame.width - 40)
        card.addChild(levelName)

        // Three progress dots — all unlit at the start.
        let dotContainer = SKNode()
        dotContainer.position = CGPoint(x: 0, y: -30)
        for i in -1...1 {
            let dot = SKShapeNode(circleOfRadius: 5)
            dot.fillColor = SKTheme.ink.withAlphaComponent(i == 0 ? 0.65 : 0.25)
            dot.strokeColor = .clear
            dot.position = CGPoint(x: CGFloat(i) * 16, y: 0)
            dotContainer.addChild(dot)
        }
        card.addChild(dotContainer)

        let button = SKButton(title: "Go", style: .primary(color: SKTheme.orange), action: { [weak self] in
            let level = ProgressStore.shared.recommendedLevel
            if level.area == .english {
                SceneRouter.shared.goMap(area: .english)
            } else {
                SceneRouter.shared.goMap(area: level.area)
            }
            _ = self
        })
        button.setSize(width: 220, height: 56)
        button.position = CGPoint(x: 0, y: -62)
        card.addChild(button)

        continueCard.removeFromParent()
        continueCard.removeAllChildren()
        continueCard.addChild(card)
        // Sit the card just below the mascot band, above the area grid.
        continueCard.position = CGPoint(x: 0, y: SKLayout.safeTop(self) - 360)
        addChild(continueCard)
    }

    // MARK: - Area grid

    private func buildAreaCards() {
        areaStack.removeFromParent()
        areaStack.removeAllChildren()
        let columns: CGFloat = 3
        let spacing: CGFloat = 14
        let cardWidth = (min(SKLayout.cardMaxWidth(self), 720) - (columns - 1) * spacing) / columns
        let cardHeight: CGFloat = min(180, SKLayout.safeHeight(self) * 0.22)
        let totalWidth = columns * cardWidth + (columns - 1) * spacing
        let startX = -totalWidth / 2 + cardWidth / 2
        let areas: [LearningArea] = [.english, .math, .lifeSkills]
        for (index, area) in areas.enumerated() {
            let card = makeAreaCard(area: area, width: cardWidth, height: cardHeight)
            card.position = CGPoint(x: startX + CGFloat(index) * (cardWidth + spacing), y: 0)
            areaStack.addChild(card)
        }
        // Sit the area grid above the parent button with breathing room.
        let bottomAnchor = SKLayout.safeBottom(self) + 96 + cardHeight / 2 + 12
        areaStack.position = CGPoint(x: 0, y: bottomAnchor)
        addChild(areaStack)
    }

    private func makeAreaCard(area: LearningArea, width: CGFloat, height: CGFloat) -> SKNode {
        let card = SKCard(width: width, height: height, cornerRadius: 22)
        let icon = SKShapeNode(rectOf: CGSize(width: width - 24, height: height * 0.42), cornerRadius: 16)
        icon.fillColor = SKTheme.color(for: area)
        icon.strokeColor = .clear
        icon.position = CGPoint(x: 0, y: height * 0.10)
        card.addChild(icon)
        let glyph = SKLabelNode(text: area == .english ? "🏠" : area == .math ? "🔢" : "🌳")
        glyph.fontSize = min(40, height * 0.26)
        glyph.fontName = "AvenirNext-Heavy"
        glyph.position = CGPoint(x: 0, y: height * 0.10)
        card.addChild(glyph)

        let label = SKLabel(text: area.rawValue, style: .body, color: SKTheme.ink)
        label.fontSize = 18
        label.position = CGPoint(x: 0, y: -height * 0.26)
        card.addChild(label)
        let subtitle: String = {
            switch area {
            case .english: return "15 scenes"
            case .math: return "25 puzzles"
            case .lifeSkills: return "10 missions"
            }
        }()
        let sub = SKLabel(text: subtitle, style: .caption, color: SKTheme.ink.withAlphaComponent(0.6))
        sub.position = CGPoint(x: 0, y: -height * 0.42)
        sub.fit(maxWidth: width - 16)
        card.addChild(sub)

        // Subtle hover-ready breathing animation so each card feels alive.
        let delay = TimeInterval(index(for: area)) * 0.15
        card.run(.repeatForever(.sequence([
            .wait(forDuration: delay),
            .scale(to: 1.02, duration: 1.6),
            .scale(to: 1.0, duration: 1.6)
        ])))

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleAreaTap(_:)))
        card.addGestureRecognizer(tap)
        card.userData = NSMutableDictionary()
        card.userData?["area"] = area.rawValue
        return card
    }

    private func index(for area: LearningArea) -> Int {
        switch area {
        case .english: return 0
        case .math: return 1
        case .lifeSkills: return 2
        }
    }

    // MARK: - Parent button

    private func buildParentButton() {
        let card = SKCard(width: 260, height: 64, cornerRadius: 28, fill: SKTheme.paper)
        card.position = CGPoint(x: 0, y: SKLayout.safeBottom(self) + 56)
        addChild(card)
        let label = SKLabel(text: "For Grown-Ups", style: .button, color: SKTheme.purple)
        label.position = CGPoint(x: 0, y: 0)
        card.addChild(label)
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleParent))
        card.addGestureRecognizer(tap)
    }

    // MARK: - Actions

    @objc private func handleAreaTap(_ recognizer: UITapGestureRecognizer) {
        guard let node = recognizer.view as? SKNode,
              let raw = node.userData?["area"] as? String,
              let area = LearningArea(rawValue: raw) else { return }
        SceneRouter.shared.goMap(area: area)
    }

    @objc private func handleParent() {
        SceneRouter.shared.goParentGate()
    }

    private func refreshProgress() {
        let store = ProgressStore.shared
        starTallyText?.text = "\(store.totalStars) / 150"
    }
}