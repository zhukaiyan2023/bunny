import SpriteKit
import UIKit

/// An explorable scene + 8-moment lesson plan presentation. Replaces the old
/// `SceneLessonPlanView` SwiftUI screen with a pure SpriteKit experience.
final class LessonPlanScene: SKScene {
    let level: LevelDefinition
    private var gameScene = ImmersiveMissionScene()
    private let sceneContainer = SKNode()
    private let planContainer = SKNode()

    init(size: CGSize, level: LevelDefinition) {
        self.level = level
        super.init(size: size)
        scaleMode = .resizeFill
    }
    required init?(coder aDecoder: NSCoder) { fatalError() }

    override func didMove(to view: SKView) {
        backgroundColor = SKTheme.cream
        gameScene.removeFromParent()
        sceneContainer.removeFromParent()
        planContainer.removeFromParent()
        buildHeader()
        installScene()
        showPlan()
        SpeechService.shared.speak(SceneLessonPlan.make(for: level).invitation + " Tap an object to explore, or let's help Pip.")
    }

    override func didChangeSize(_ oldSize: CGSize) {
        removeAllChildren()
        didMove(to: SKView())
    }

    private func buildHeader() {
        let back = SKHUD.makeCircleButton(symbol: "chevron.left", diameter: 56)
        back.position = CGPoint(x: SKLayout.safeLeft(self) + 36, y: SKLayout.safeTop(self) - 28)
        let tap = UITapGestureRecognizer(target: self, action: #selector(goMap))
        back.addGestureRecognizer(tap)
        addChild(back)

        let title = SKLabel(text: level.title, style: .headline, color: SKTheme.ink)
        title.position = CGPoint(x: 0, y: SKLayout.safeTop(self) - 80)
        addChild(title)
    }

    private func installScene() {
        let cardWidth = SKLayout.cardMaxWidth(self)
        let cardHeight = min(SKLayout.safeHeight(self) * 0.50, 480)
        let card = SKCard(width: cardWidth, height: cardHeight, cornerRadius: 28)
        card.position = CGPoint(x: 0, y: SKLayout.safeTop(self) - 130 - cardHeight / 2)
        addChild(card)

        gameScene.size = card.frame.size
        gameScene.scaleMode = .aspectFill
        let spec = HomeMissionSpec.spec(for: level.scene)
        gameScene.configure(backgroundName: spec.room.assetName,
                            items: spec.items, completed: [],
                            target: SceneDropTarget(label: "", x: 0.5, y: 0.5),
                            placedItem: nil, helpItemID: nil,
                            reduceMotion: false, explorationOnly: true,
                            sceneKind: level.scene)
        gameScene.position = card.position
        addChild(gameScene)
    }

    private func showPlan() {
        planContainer.removeAllChildren()
        let plan = SceneLessonPlan.make(for: level)
        let card = SKCard(width: SKLayout.cardMaxWidth(self), height: min(SKLayout.safeHeight(self) * 0.42, 260), cornerRadius: 26)
        card.position = CGPoint(x: 0, y: SKLayout.safeBottom(self) + 90 + card.frame.height / 2)
        planContainer.addChild(card)

        let title = SKLabel(text: "Today's Journey", style: .headline, color: SKTheme.ink)
        title.position = CGPoint(x: 0, y: card.frame.height / 2 - 32)
        card.addChild(title)
        let invitation = SKLabel(text: plan.invitation, style: .body, color: SKTheme.ink.withAlphaComponent(0.78))
        invitation.position = CGPoint(x: 0, y: card.frame.height / 2 - 76)
        invitation.fit(maxWidth: card.frame.width - 40)
        card.addChild(invitation)
        let challenge = SKLabel(text: plan.realWorldChallenge, style: .caption, color: SKTheme.purple)
        challenge.position = CGPoint(x: 0, y: -card.frame.height / 2 + 60)
        challenge.fit(maxWidth: card.frame.width - 40)
        card.addChild(challenge)

        let playButton = SKButton(title: "Let's Help Pip", style: .primary(color: SKTheme.orange), action: { [weak self] in
            guard let self else { return }
            SceneRouter.shared.goScene(level: self.level)
        })
        playButton.setSize(width: min(280, card.frame.width * 0.65), height: 64)
        playButton.position = CGPoint(x: 0, y: -card.frame.height / 2 + 16)
        card.addChild(playButton)
    }

    @objc private func goMap() { SceneRouter.shared.goMap(area: level.area) }
}