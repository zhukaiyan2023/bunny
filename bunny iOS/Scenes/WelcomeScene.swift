import SpriteKit
import UIKit

/// First-launch greeting scene. S1-01 from the Onboarding epic.
///
/// "Hi! I'm Pip. Want to play with me?"
///
/// Single full-screen tap target. Tapping anywhere routes to the
/// recommended first level (M01 — Bakery Box Rescue). The visual
/// "Yes!" button is purely decoration — kids don't have to hit a
/// precise target. Follows the scene-system contract documented in
/// `design/gdd/scene-system.md`.
final class WelcomeScene: SKScene {
    private let pipHalo = SKShapeNode(circleOfRadius: 140)
    private let pipSprite = SKSpriteNode(texture: SKTexture(imageNamed: "PipHero"))
    private let greeting = SKLabelNode(text: "Hi! I'm Pip.\nWant to play with me?")
    private let prompt = SKLabelNode(text: "Tap anywhere to begin")
    private let yesButton = SKShapeNode(rectOf: CGSize(width: 240, height: 64),
                                        cornerRadius: 28)
    private let yesLabel = SKLabelNode(text: "Yes!")
    private var hasRouted = false

    override func didMove(to view: SKView) {
        backgroundColor = SKTheme.cream

        // Ambient particles for depth behind the welcome halo.
        SKAmbient.install(in: self, config: SKAmbient.Configuration(
            particleCount: 22,
            palette: [
                SKTheme.yellow.withAlphaComponent(0.55),
                SKTheme.pink.withAlphaComponent(0.45),
                SKTheme.green.withAlphaComponent(0.35),
            ],
            backgroundGradient: [SKTheme.cream, SKTheme.green.withAlphaComponent(0.18)],
            driftSpeed: 7
        ))

        buildHalo()
        buildPip()
        buildGreeting()
        buildPrompt()
        buildButton()
        animateEntry()

        SpeechService.shared.speak("Hi! I'm Pip. Want to play with me?")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        routeToFirstLevel()
    }

    // MARK: - Layout

    private func buildHalo() {
        pipHalo.fillColor = SKTheme.yellow.withAlphaComponent(0.55)
        pipHalo.strokeColor = .clear
        pipHalo.position = CGPoint(x: 0, y: 90)
        addChild(pipHalo)
        pipHalo.run(.repeatForever(.sequence([
            SKAction.scale(to: 1.05, duration: 1.6),
            SKAction.scale(to: 1.00, duration: 1.6),
        ])))
    }

    private func buildPip() {
        let h: CGFloat = min(220, SKLayout.safeHeight(self) * 0.22)
        pipSprite.size = CGSize(width: h * 2 / 3, height: h)
        pipSprite.position = pipHalo.position
        pipSprite.alpha = 1.0
        addChild(pipSprite)
        pipSprite.run(.repeatForever(.sequence([
            SKAction.moveBy(x: 0, y: -6, duration: 1.4),
            SKAction.moveBy(x: 0, y: 6, duration: 1.4),
        ])))
        // Simulated blink: a brief Y-scale squash every ~3.5s.
        // The asset has no eye-frame variants, so we fake a blink by
        // scaling Y to 0.1 for 90ms.
        pipSprite.run(.repeatForever(.sequence([
            SKAction.wait(forDuration: 3.4),
            SKAction.group([
                SKAction.scaleY(to: 0.1, duration: 0.045),
                SKAction.scaleX(to: 1.08, duration: 0.045),
            ]),
            SKAction.group([
                SKAction.scaleY(to: 1.0, duration: 0.045),
                SKAction.scaleX(to: 1.0, duration: 0.045),
            ]),
        ])))
    }

    private func buildGreeting() {
        greeting.fontName = "AvenirNext-DemiBold"
        greeting.fontSize = 32
        greeting.fontColor = SKTheme.ink
        greeting.numberOfLines = 2
        greeting.verticalAlignmentMode = .center
        greeting.horizontalAlignmentMode = .center
        let maxW = SKLayout.safeWidth(self) * 0.85
        var size: CGFloat = 32
        greeting.fontSize = size
        while greeting.frame.width > maxW && size > 18 {
            size -= 1
            greeting.fontSize = size
        }
        greeting.position = CGPoint(x: 0, y: -160)
        addChild(greeting)
    }

    private func buildPrompt() {
        prompt.fontName = "AvenirNext-Regular"
        prompt.fontSize = 18
        prompt.fontColor = SKTheme.ink.withAlphaComponent(0.6)
        prompt.verticalAlignmentMode = .center
        prompt.horizontalAlignmentMode = .center
        prompt.position = CGPoint(x: 0, y: SKLayout.safeBottom(self) + 96)
        addChild(prompt)
    }

    private func buildButton() {
        yesButton.fillColor = SKTheme.green
        yesButton.strokeColor = SKTheme.green.withAlphaComponent(0.85)
        yesButton.lineWidth = 0
        yesButton.position = CGPoint(x: 0, y: -260)
        addChild(yesButton)

        yesLabel.fontName = "AvenirNext-DemiBold"
        yesLabel.fontSize = 26
        yesLabel.fontColor = .white
        yesLabel.verticalAlignmentMode = .center
        yesLabel.horizontalAlignmentMode = .center
        yesLabel.position = .zero
        yesButton.addChild(yesLabel)
    }

    private func animateEntry() {
        greeting.alpha = 0
        prompt.alpha = 0
        yesButton.alpha = 0
        greeting.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            SKAction.fadeIn(withDuration: 0.6),
        ]))
        prompt.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.fadeIn(withDuration: 0.4),
        ]))
        yesButton.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.2),
            SKAction.fadeIn(withDuration: 0.4),
        ]))
        pipSprite.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.1, duration: 0.4),
                SKAction.fadeIn(withDuration: 0.4),
            ]),
            SKAction.scale(to: 1.0, duration: 0.2),
        ]))
    }

    // MARK: - Routing

    private func routeToFirstLevel() {
        guard !hasRouted else { return }
        hasRouted = true
        SpeechService.shared.stop()
        // The "first" level per the curriculum ordering is M01 — the easiest
        // math level ("Bakery Box Rescue"). Fall back to the first English
        // level if M01 is unexpectedly absent.
        let firstLevel = Curriculum.levels.first(where: { $0.id == "M01" })
            ?? Curriculum.levels(in: .english).first
        if let firstLevel {
            SceneRouter.shared.goScene(level: firstLevel)
        } else {
            SceneRouter.shared.goHome()
        }
    }
}
