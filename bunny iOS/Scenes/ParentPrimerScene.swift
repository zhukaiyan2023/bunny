import SpriteKit
import UIKit

/// Post-M01 parent setup primer. S1-02 from the Onboarding epic.
///
/// Shown once after the child's first completed level. Three short text
/// cards (parent area, TTS rate, daily limit) plus two buttons:
///   - "Show me" → routes to the parent gate → parent dashboard
///   - "Later"   → routes to the menu
///
/// Both paths complete onboarding (the next reset will run it again,
/// per S1-03). Whole screen is tappable to honor the kid-friendly
/// "tap anywhere" affordance.
final class ParentPrimerScene: SKScene {
    private let pipSprite = SKSpriteNode(texture: SKTexture(imageNamed: "PipHero"))
    private let title = SKLabelNode(text: "Quick note for grown-ups")
    private let card1 = ParentPrimerScene.makeCard(
        "Open the parent area",
        "Tap the small 'For Grown-Ups' pill on the main menu and solve a multiplication puzzle.")
    private let card2 = ParentPrimerScene.makeCard(
        "Adjust the voice",
        "Inside the parent area, drag the speech slider to make Pip talk faster or slower.")
    private let card3 = ParentPrimerScene.makeCard(
        "Set a daily limit",
        "Pick how many minutes Pip plays each day — 5, 10, 15, 20 or 30.")
    private let showMeButton = SKShapeNode(rectOf: CGSize(width: 240, height: 64),
                                            cornerRadius: 28)
    private let showMeLabel = SKLabelNode(text: "Show me")
    private let laterButton = SKShapeNode(rectOf: CGSize(width: 240, height: 64),
                                          cornerRadius: 28)
    private let laterLabel = SKLabelNode(text: "Later")
    private var hasNavigated = false

    override func didMove(to view: SKView) {
        backgroundColor = SKTheme.cream
        buildPip()
        buildTitle()
        buildCards()
        buildButtons()
        animateEntry()
        SpeechService.shared.speak("Quick note for grown-ups.")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        routeToMenu()
    }

    // MARK: - Layout

    private func buildPip() {
        let h: CGFloat = min(120, SKLayout.safeHeight(self) * 0.12)
        pipSprite.size = CGSize(width: h * 2 / 3, height: h)
        pipSprite.position = CGPoint(x: -SKLayout.safeWidth(self) * 0.32,
                                      y: SKLayout.safeTop(self) - 80)
        pipSprite.alpha = 1.0
        addChild(pipSprite)
        pipSprite.run(.repeatForever(.sequence([
            SKAction.moveBy(x: 0, y: -4, duration: 1.6),
            SKAction.moveBy(x: 0, y: 4, duration: 1.6),
        ])))
    }

    private func buildTitle() {
        title.fontName = "AvenirNext-DemiBold"
        title.fontSize = 22
        title.fontColor = SKTheme.ink
        title.verticalAlignmentMode = .center
        title.horizontalAlignmentMode = .center
        title.numberOfLines = 0
        title.text = "Quick note for grown-ups"
        title.position = CGPoint(x: 0, y: SKLayout.safeTop(self) - 110)
        // Auto-shrink so it fits the safe width.
        var size: CGFloat = 22
        title.fontSize = size
        let maxWidth = SKLayout.safeWidth(self) * 0.92
        while title.frame.width > maxWidth && size > 16 {
            size -= 1
            title.fontSize = size
        }
        addChild(title)
    }

    private func buildCards() {
        let cardWidth = min(SKLayout.cardMaxWidth(self), 560)
        let cardHeight: CGFloat = 92
        let spacing: CGFloat = 12
        let stack = SKNode()
        stack.position = CGPoint(x: 0, y: 30)
        addChild(stack)

        // Recreate cards at the chosen width — SKShapeNode doesn't auto-resize
        // its path when `.size` is set, so we replace the card contents with
        // ones that match the actual width.
        for (i, original) in [card1, card2, card3].enumerated() {
            original.removeAllChildren()
            // Rebuild the rounded rect path at the chosen width.
            original.path = CGPath(roundedRect: CGRect(x: -cardWidth / 2,
                                                        y: -cardHeight / 2,
                                                        width: cardWidth,
                                                        height: cardHeight),
                                    cornerWidth: 18, cornerHeight: 18, transform: nil)
            let titleLabel = SKLabelNode(text: ["Open the parent area", "Adjust the voice", "Set a daily limit"][i])
            titleLabel.fontName = "AvenirNext-DemiBold"
            titleLabel.fontSize = 15
            titleLabel.fontColor = SKTheme.ink
            titleLabel.horizontalAlignmentMode = .left
            titleLabel.verticalAlignmentMode = .center
            titleLabel.position = CGPoint(x: -cardWidth / 2 + 12, y: 18)
            original.addChild(titleLabel)
            let body = ["Tap the small 'For Grown-Ups' pill on the menu, then solve a multiplication puzzle.",
                        "In the parent area, drag the speech slider to make Pip talk faster or slower.",
                        "Pick how many minutes Pip plays each day — 5, 10, 15, 20 or 30."][i]
            let bodyLabel = SKLabelNode(text: body)
            bodyLabel.fontName = "AvenirNext-Regular"
            bodyLabel.fontSize = 11
            bodyLabel.fontColor = SKTheme.ink.withAlphaComponent(0.7)
            bodyLabel.horizontalAlignmentMode = .left
            bodyLabel.verticalAlignmentMode = .center
            bodyLabel.numberOfLines = 0
            bodyLabel.lineBreakMode = .byTruncatingTail
            bodyLabel.preferredMaxLayoutWidth = cardWidth - 24
            bodyLabel.position = CGPoint(x: -cardWidth / 2 + 12, y: -12)
            original.addChild(bodyLabel)
            original.position = CGPoint(x: 0,
                                        y: -CGFloat(i) * (cardHeight + spacing))
            stack.addChild(original)
        }
    }

    private static func makeCard(_ heading: String, _ body: String) -> SKShapeNode {
        let card = SKShapeNode(rectOf: CGSize(width: 540, height: 92), cornerRadius: 18)
        card.fillColor = SKTheme.paper
        card.strokeColor = SKTheme.ink.withAlphaComponent(0.08)
        card.lineWidth = 1
        let titleLabel = SKLabelNode(text: heading)
        titleLabel.fontName = "AvenirNext-DemiBold"
        titleLabel.fontSize = 15
        titleLabel.fontColor = SKTheme.ink
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: -255, y: 18)
        card.addChild(titleLabel)
        let bodyLabel = SKLabelNode(text: body)
        bodyLabel.fontName = "AvenirNext-Regular"
        bodyLabel.fontSize = 11
        bodyLabel.fontColor = SKTheme.ink.withAlphaComponent(0.7)
        bodyLabel.horizontalAlignmentMode = .left
        bodyLabel.verticalAlignmentMode = .center
        bodyLabel.numberOfLines = 0
        bodyLabel.lineBreakMode = .byTruncatingTail
        bodyLabel.preferredMaxLayoutWidth = 510
        bodyLabel.position = CGPoint(x: -255, y: -12)
        card.addChild(bodyLabel)
        return card
    }

    private func buildButtons() {
        showMeButton.fillColor = SKTheme.blue
        showMeButton.strokeColor = .clear
        showMeButton.lineWidth = 0
        showMeButton.position = CGPoint(x: -140,
                                       y: SKLayout.safeBottom(self) + 130)
        addChild(showMeButton)

        showMeLabel.fontName = "AvenirNext-DemiBold"
        showMeLabel.fontSize = 18
        showMeLabel.fontColor = .white
        showMeLabel.verticalAlignmentMode = .center
        showMeLabel.horizontalAlignmentMode = .center
        showMeLabel.position = .zero
        showMeButton.addChild(showMeLabel)

        let showTap = UITapGestureRecognizer(target: self, action: #selector(handleShowMe))
        showMeButton.addGestureRecognizer(showTap)

        laterButton.fillColor = SKTheme.paper
        laterButton.strokeColor = SKTheme.ink.withAlphaComponent(0.25)
        laterButton.lineWidth = 1.5
        laterButton.position = CGPoint(x: 140,
                                      y: SKLayout.safeBottom(self) + 130)
        addChild(laterButton)

        laterLabel.fontName = "AvenirNext-DemiBold"
        laterLabel.fontSize = 18
        laterLabel.fontColor = SKTheme.ink
        laterLabel.verticalAlignmentMode = .center
        laterLabel.horizontalAlignmentMode = .center
        laterLabel.position = .zero
        laterButton.addChild(laterLabel)

        let laterTap = UITapGestureRecognizer(target: self, action: #selector(handleLater))
        laterButton.addGestureRecognizer(laterTap)

        let prompt = SKLabelNode(text: "Tap anywhere to continue")
        prompt.fontName = "AvenirNext-Regular"
        prompt.fontSize = 13
        prompt.fontColor = SKTheme.ink.withAlphaComponent(0.5)
        prompt.verticalAlignmentMode = .center
        prompt.horizontalAlignmentMode = .center
        prompt.position = CGPoint(x: 0, y: SKLayout.safeBottom(self) + 80)
        addChild(prompt)
    }

    private func animateEntry() {
        title.alpha = 0
        for card in [card1, card2, card3] { card.alpha = 0 }
        showMeButton.alpha = 0
        laterButton.alpha = 0
        title.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.2),
            SKAction.fadeIn(withDuration: 0.4),
        ]))
        for (i, card) in [card1, card2, card3].enumerated() {
            card.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.4 + Double(i) * 0.18),
                SKAction.fadeIn(withDuration: 0.35),
            ]))
        }
        showMeButton.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.1),
            SKAction.fadeIn(withDuration: 0.35),
        ]))
        laterButton.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.1),
            SKAction.fadeIn(withDuration: 0.35),
        ]))
    }

    // MARK: - Actions

    @objc private func handleShowMe() { routeToParentGate() }
    @objc private func handleLater() { routeToMenu() }

    // MARK: - Routing

    private func routeToParentGate() {
        guard !hasNavigated else { return }
        hasNavigated = true
        SpeechService.shared.stop()
        SceneRouter.shared.goParentGate()
    }

    private func routeToMenu() {
        guard !hasNavigated else { return }
        hasNavigated = true
        SpeechService.shared.stop()
        SceneRouter.shared.goHome()
    }
}
