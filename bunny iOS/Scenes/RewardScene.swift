import SpriteKit
import UIKit

/// Celebrates completion of an immersive scene. Animated confetti, stars and a
/// clear route back to the world map.
final class RewardScene: SKScene {
    let level: LevelDefinition
    let stars: Int

    init(size: CGSize, level: LevelDefinition, stars: Int) {
        self.level = level
        self.stars = stars
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = SKTheme.cream
    }
    required init?(coder aDecoder: NSCoder) { fatalError() }

    override func didMove(to view: SKView) {
        buildBackground()
        buildHeader()
        buildStars()
        buildConfetti()
        buildActionButtons()
        SpeechService.shared.speak("You did it, " + level.title + "!")

        // S2 wiring: if this is the very first M01 completion, route to
        // the parent primer after the celebration so the parent gets a
        // one-time primer on the parent area + TTS + session cap.
        if level.id == "M01",
           ProgressStore.shared.attempts["M01"] == 1 {
            run(SKAction.sequence([
                SKAction.wait(forDuration: 2.6),
                SKAction.run { SceneRouter.shared.goParentPrimer() },
            ]))
        }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        removeAllChildren()
        didMove(to: SKView())
    }

    private func buildBackground() {
        let haloRadius = min(size.width, size.height) * 0.42
        let halo = SKShapeNode(circleOfRadius: haloRadius)
        halo.fillColor = SKTheme.yellow.withAlphaComponent(0.18)
        halo.strokeColor = .clear
        halo.position = CGPoint(x: 0, y: SKLayout.safeHeight(self) * 0.10)
        addChild(halo)
        halo.run(.repeatForever(.sequence([
            .scale(to: 1.05, duration: 1.2),
            .scale(to: 1.0, duration: 1.2)
        ])))
    }

    private func buildHeader() {
        let title = SKLabel(text: "Great work!", style: .title, color: SKTheme.ink)
        title.position = CGPoint(x: 0, y: SKLayout.safeTop(self) - 110)
        title.fontSize = 56
        addChild(title)

        let subtitle = SKLabel(text: level.title, style: .headline, color: SKTheme.orange)
        subtitle.position = CGPoint(x: 0, y: SKLayout.safeTop(self) - 170)
        subtitle.fit(maxWidth: SKLayout.safeWidth(self) * 0.86)
        addChild(subtitle)
    }

    private func buildStars() {
        let starsNode = SKHUD.makeStars(filled: stars, size: 56, spacing: 14)
        starsNode.position = CGPoint(x: 0, y: SKLayout.safeTop(self) - 300)
        starsNode.alpha = 0
        addChild(starsNode)

        let pop = SKAction.sequence([
            .group([.scale(to: 1.0, duration: 0.4), .fadeIn(withDuration: 0.4)]),
            .wait(forDuration: 0.1),
            .scale(to: 1.08, duration: 0.15),
            .scale(to: 1.0, duration: 0.15)
        ])
        starsNode.run(pop)
    }

    private func buildConfetti() {
        let palette: [UIColor] = [SKTheme.pink, SKTheme.blue, SKTheme.green, SKTheme.yellow, SKTheme.purple, SKTheme.orange]
        for _ in 0..<50 {
            let piece = SKShapeNode(rectOf: CGSize(width: 10, height: 14), cornerRadius: 2)
            piece.fillColor = palette.randomElement() ?? SKTheme.pink
            piece.strokeColor = .clear
            piece.position = CGPoint(
                x: CGFloat.random(in: -size.width / 2 ... size.width / 2),
                y: SKLayout.safeTop(self) + 60
            )
            piece.zRotation = CGFloat.random(in: -1.0 ... 1.0)
            addChild(piece)
            let fall = SKAction.moveBy(x: CGFloat.random(in: -120 ... 120),
                                       y: SKLayout.safeBottom(self) - 80,
                                       duration: TimeInterval.random(in: 2.5 ... 4.5))
            let spin = SKAction.rotate(byAngle: CGFloat.random(in: -3 ... 3), duration: 2.0)
            piece.run(.sequence([.group([fall, spin]), .removeFromParent()]))
        }
    }

    private func buildActionButtons() {
        let home = SKButton(title: "Home", style: .secondary(color: SKTheme.blue), action: { [weak self] in
            guard let self else { return }
            SceneRouter.shared.goHome()
            _ = self
        })
        home.setSize(width: min(220, SKLayout.safeWidth(self) * 0.45), height: 70)
        home.position = CGPoint(x: -130, y: SKLayout.safeBottom(self) + 80)
        addChild(home)

        let replay = SKButton(title: "Play Again", style: .primary(color: SKTheme.orange), action: { [weak self] in
            guard let self else { return }
            SceneRouter.shared.goScene(level: self.level)
            _ = self
        })
        replay.setSize(width: min(220, SKLayout.safeWidth(self) * 0.45), height: 70)
        replay.position = CGPoint(x: 130, y: SKLayout.safeBottom(self) + 80)
        addChild(replay)
    }
}