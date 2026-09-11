import SpriteKit
import UIKit

/// Main menu — Pip's World hub. Three worlds (Math Kingdom, English
/// Village, Life Skills Garden) on a soft pastel sky with floating
/// dust motes. Each world has its own illustrated background, level
/// count, and progress ring.
///
/// Pillar 1 (Calm): pastel palette, slow drift, no flashing animations.
/// Pillar 5 (Adult-gated): the parent area is a separate pill, never
/// visually mixed with the kid-facing cards.
///
/// Storage strategy: nothing is stored as a class property. Every node
/// is created locally in `buildXxx()`. This avoids the "SKNode already
/// has a parent" crash that bites when `didChangeSize → didMove`
/// re-enters the scene.
final class MenuScene: SKScene {

    private var observation: NSObjectProtocol?

    private struct World {
        let area: LearningArea
        let title: String
        let subtitle: String
        let art: String
        let tint: UIColor
        let accent: UIColor
    }
    private let worlds: [World] = [
        World(area: .math,       title: "Math Kingdom",
              subtitle: "25 puzzles", art: "MathBakery",
              tint: SKTheme.blue,    accent: SKTheme.blue.withAlphaComponent(0.18)),
        World(area: .english,    title: "English Village",
              subtitle: "15 scenes", art: "Bedroom",
              tint: SKTheme.orange,  accent: SKTheme.orange.withAlphaComponent(0.18)),
        World(area: .lifeSkills, title: "Life Skills Garden",
              subtitle: "10 missions", art: "Kitchen",
              tint: SKTheme.green,   accent: SKTheme.green.withAlphaComponent(0.18)),
    ]

    override func didMove(to view: SKView) {
        backgroundColor = SKTheme.cream

        // Ambient: sky → cream → grass gradient.
        SKAmbient.install(in: self, config: SKAmbient.Configuration(
            particleCount: 36,
            palette: [
                UIColor.white.withAlphaComponent(0.85),
                SKTheme.yellow.withAlphaComponent(0.55),
                SKTheme.pink.withAlphaComponent(0.45),
                SKTheme.green.withAlphaComponent(0.30),
            ],
            backgroundGradient: [
                UIColor(red: 0.82, green: 0.90, blue: 0.99, alpha: 1.0),
                SKTheme.cream,
                SKTheme.green.withAlphaComponent(0.30),
            ],
            driftSpeed: 7
        ))

        buildMascot(in: view)
        buildTitle()
        buildWorlds()
        buildFooter()
        buildParentButton()

        observation = NotificationCenter.default.addObserver(
            forName: .progressStoreDidChange, object: nil, queue: .main
        ) { [weak self] _ in self?.refreshProgress() }
        refreshProgress()
        SpeechService.shared.speak("Hello! Pick a world to explore.")
        Feedback.shared.tap()
    }

    deinit { if let observation { NotificationCenter.default.removeObserver(observation) } }

    override func didChangeSize(_ oldSize: CGSize) {
        // Per-node lifecycle: drop everything and rebuild from scratch.
        removeAllChildren()
        SKAmbient.uninstall(from: self)
        didMove(to: SKView())
    }

    // MARK: - Mascot

    private func buildMascot(in view: SKView) {
        let safeTop = SKLayout.safeTop(self)
        let safeWidth = SKLayout.safeWidth(self)
        let mascotY = safeTop - 250
        let mascotX = -safeWidth * 0.30

        // Shadow
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 140, height: 22))
        shadow.fillColor = SKTheme.ink.withAlphaComponent(0.12)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: mascotX, y: mascotY)
        addChild(shadow)

        // Halo
        let halo = SKShapeNode(circleOfRadius: 110)
        halo.fillColor = SKTheme.yellow.withAlphaComponent(0.55)
        halo.strokeColor = .clear
        halo.position = CGPoint(x: mascotX, y: mascotY)
        addChild(halo)
        halo.run(.repeatForever(.sequence([
            SKAction.scale(to: 1.05, duration: 1.6),
            SKAction.scale(to: 1.00, duration: 1.6),
        ])))

        // Pip sprite — drops in from above on first appearance.
        let pip = SKSpriteNode(texture: SKTexture(imageNamed: "PipWorldSprite"))
        let h: CGFloat = min(SKLayout.safeHeight(self) * 0.22, 180)
        pip.size = CGSize(width: h * 2 / 3, height: h)
        pip.position = CGPoint(x: mascotX, y: mascotY)
        pip.alpha = 1.0
        addChild(pip)

        // Run idle animations on all three.
        pip.run(.sequence([
            SKAction.group([
                SKAction.moveTo(y: mascotY + 24, duration: 0.40),
                SKAction.fadeAlpha(to: 1.0, duration: 0.30),
            ]),
            SKAction.moveTo(y: mascotY, duration: 0.18),
            SKAction.repeatForever(.sequence([
                SKAction.moveBy(x: 0, y: -6, duration: 1.4),
                SKAction.moveBy(x: 0, y: 6, duration: 1.4),
            ])),
        ]))
        halo.run(.repeatForever(.sequence([
            SKAction.moveBy(x: -4, y: 0, duration: 2.2),
            SKAction.moveBy(x: 4, y: 0, duration: 2.2),
        ])))
        shadow.run(.repeatForever(.sequence([
            SKAction.scaleX(to: 1.10, duration: 1.4),
            SKAction.scaleX(to: 0.90, duration: 1.4),
        ])))
    }

    // MARK: - Title

    private func buildTitle() {
        let safeWidth = SKLayout.safeWidth(self)
        let safeTop = SKLayout.safeTop(self)

        let title = SKLabel(text: "Pip's World", style: .title, color: SKTheme.ink)
        title.fontSize = 34
        title.horizontalAlignmentMode = .left
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: safeWidth * 0.06, y: safeTop - 90)
        addChild(title)

        let sub = SKLabel(text: "Tap a world to begin",
                          style: .caption,
                          color: SKTheme.ink.withAlphaComponent(0.65))
        sub.fontSize = 15
        sub.horizontalAlignmentMode = .left
        sub.verticalAlignmentMode = .center
        sub.position = CGPoint(x: safeWidth * 0.06, y: safeTop - 122)
        addChild(sub)
    }

    // MARK: - World cards

    private func buildWorlds() {
        let safeBottom = SKLayout.safeBottom(self)
        let cardWidth = min(SKLayout.safeWidth(self) - 32, 640)
        let cardHeight: CGFloat = 96
        let spacing: CGFloat = 10
        let stackY = safeBottom + 200

        let stack = SKNode()
        stack.position = CGPoint(x: 0, y: stackY)
        addChild(stack)

        for (index, world) in worlds.enumerated() {
            let card = makeWorldCard(world: world,
                                      width: cardWidth,
                                      height: cardHeight)
            card.position = CGPoint(x: 0,
                                     y: -CGFloat(index) * (cardHeight + spacing))
            card.userData = NSMutableDictionary()
            card.userData?["area"] = world.area.rawValue
            card.alpha = 0
            stack.addChild(card)

            card.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.10 + Double(index) * 0.10),
                SKAction.group([
                    SKAction.fadeIn(withDuration: 0.35),
                    SKAction.moveBy(x: 0, y: 10, duration: 0.35),
                ]),
            ]))

            let tap = UITapGestureRecognizer(target: self,
                                             action: #selector(handleAreaTap(_:)))
            card.addGestureRecognizer(tap)
        }
    }

    private func makeWorldCard(world: World, width: CGFloat, height: CGFloat) -> SKNode {
        let card = SKShapeNode(rectOf: CGSize(width: width, height: height),
                                cornerRadius: 28)
        card.fillColor = SKTheme.paper
        card.strokeColor = world.tint.withAlphaComponent(0.55)
        card.lineWidth = 2

        // Left accent strip.
        let strip = SKShapeNode(rectOf: CGSize(width: 14, height: height - 24),
                                 cornerRadius: 7)
        strip.fillColor = world.tint
        strip.strokeColor = .clear
        strip.position = CGPoint(x: -width / 2 + 20, y: 0)
        card.addChild(strip)

        // Round illustration disc.
        let disc = SKShapeNode(circleOfRadius: 50)
        disc.fillColor = world.accent
        disc.strokeColor = world.tint.withAlphaComponent(0.5)
        disc.lineWidth = 2
        disc.position = CGPoint(x: -width / 2 + 100, y: 0)
        card.addChild(disc)

        // Hero illustration.
        let art = SKTexture(imageNamed: world.art)
        let pic = SKSpriteNode(texture: art)
        pic.size = CGSize(width: 80, height: 80)
        pic.position = disc.position
        card.addChild(pic)

        // World title.
        let title = SKLabelNode(text: world.title)
        title.fontName = "AvenirNext-Heavy"
        title.fontSize = 26
        title.fontColor = SKTheme.ink
        title.horizontalAlignmentMode = .left
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: -width / 2 + 180, y: 22)
        card.addChild(title)

        // World subtitle.
        let sub = SKLabelNode(text: world.subtitle)
        sub.fontName = "AvenirNext-Medium"
        sub.fontSize = 15
        sub.fontColor = SKTheme.ink.withAlphaComponent(0.6)
        sub.horizontalAlignmentMode = .left
        sub.verticalAlignmentMode = .center
        sub.position = CGPoint(x: -width / 2 + 180, y: -8)
        card.addChild(sub)

        // Progress ring.
        let progress = ProgressStore.shared.completionRatio(for: world.area)
        let ring = ProgressRing(radius: 28, lineWidth: 6,
                                trackColor: SKTheme.ink.withAlphaComponent(0.10),
                                fillColor: world.tint)
        ring.position = CGPoint(x: width / 2 - 50, y: 0)
        ring.setProgress(CGFloat(progress))
        card.addChild(ring)

        // Subtle breathing pulse so the cards feel alive.
        card.run(.repeatForever(.sequence([
            SKAction.scale(to: 1.012, duration: 1.8),
            SKAction.scale(to: 1.000, duration: 1.8),
        ])))

        return card
    }

    // MARK: - Footer

    private func buildFooter() {
        let safeWidth = SKLayout.safeWidth(self)
        let safeBottom = SKLayout.safeBottom(self)

        // Star tally card (left).
        let starCard = SKCard(width: 220, height: 64, cornerRadius: 28,
                                fill: SKTheme.paper)
        starCard.position = CGPoint(x: -safeWidth * 0.30,
                                    y: safeBottom + 56)
        addChild(starCard)

        let stars = SKHUD.makeStars(filled: 0, size: 18, spacing: 4)
        stars.position = CGPoint(x: -50, y: 6)
        starCard.addChild(stars)

        let tally = SKLabel(text: "0 / 150", style: .caption,
                            color: SKTheme.ink.withAlphaComponent(0.75))
        tally.fontSize = 13
        tally.position = CGPoint(x: 0, y: -14)
        tally.horizontalAlignmentMode = .center
        starCard.addChild(tally)
        starTallyText = tally
    }

    private func buildParentButton() {
        let safeWidth = SKLayout.safeWidth(self)
        let safeBottom = SKLayout.safeBottom(self)

        let pill = SKShapeNode(rectOf: CGSize(width: 260, height: 64),
                                cornerRadius: 28)
        pill.fillColor = SKTheme.purple.withAlphaComponent(0.85)
        pill.strokeColor = .clear
        pill.lineWidth = 0
        pill.position = CGPoint(x: safeWidth * 0.30, y: safeBottom + 56)
        addChild(pill)

        let label = SKLabelNode(text: "For Grown-Ups")
        label.fontName = "AvenirNext-DemiBold"
        label.fontSize = 18
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = .zero
        pill.addChild(label)

        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(handleParent))
        pill.addGestureRecognizer(tap)
    }

    // MARK: - State holder for tally text update

    private var starTallyText: SKLabel?

    // MARK: - Actions

    @objc private func handleAreaTap(_ recognizer: UITapGestureRecognizer) {
        guard let node = recognizer.view as? SKNode,
              let raw = node.userData?["area"] as? String,
              let area = LearningArea(rawValue: raw) else { return }
        Feedback.shared.tap()
        SceneRouter.shared.goMap(area: area)
    }

    @objc private func handleParent() {
        Feedback.shared.tap()
        SceneRouter.shared.goParentGate()
    }

    private func refreshProgress() {
        let store = ProgressStore.shared
        starTallyText?.text = "\(store.totalStars) / 150"
    }
}
