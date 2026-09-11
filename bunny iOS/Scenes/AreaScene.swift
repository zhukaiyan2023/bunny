import SpriteKit
import UIKit

/// Per-area world. Shows a backdrop for the chosen area and previews the
/// recommended level before the player dives into the level map.
final class AreaScene: SKScene {
    let area: LearningArea

    init(size: CGSize, area: LearningArea) {
        self.area = area
        super.init(size: size)
        scaleMode = .resizeFill
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    override func didMove(to view: SKView) {
        backgroundColor = SKTheme.cream
        buildBackground()
        buildHeader()
        buildContinue()
        buildPathButton()
        SpeechService.shared.speak(areaWelcome(area))
    }

    override func didChangeSize(_ oldSize: CGSize) {
        removeAllChildren()
        didMove(to: SKView())
    }

    private func buildBackground() {
        let tint = SKTheme.color(for: area).withAlphaComponent(0.2)
        let bg = SKShapeNode(rectOf: CGSize(width: size.width + 40, height: size.height + 40))
        bg.fillColor = tint
        bg.strokeColor = .clear
        bg.position = .zero
        addChild(bg)
    }

    private func buildHeader() {
        let back = SKHUD.makeCircleButton(symbol: "chevron.left", diameter: 56)
        back.position = CGPoint(x: SKLayout.safeLeft(self) + 36, y: SKLayout.safeTop(self) - 40)
        back.zPosition = 10
        let tap = UITapGestureRecognizer(target: self, action: #selector(goHome))
        back.addGestureRecognizer(tap)
        addChild(back)

        let title = SKLabel(text: area.rawValue, style: .title, color: SKTheme.ink)
        title.fontSize = 42
        title.position = CGPoint(x: 0, y: SKLayout.safeTop(self) - 100)
        addChild(title)

        let subtitle = SKLabel(text: areaDescription(area), style: .body, color: SKTheme.ink.withAlphaComponent(0.7))
        subtitle.position = CGPoint(x: 0, y: SKLayout.safeTop(self) - 180)
        subtitle.fit(maxWidth: SKLayout.safeWidth(self) * 0.86)
        addChild(subtitle)
    }

    private func buildContinue() {
        let recommended = ProgressStore.shared.recommendedLevel
        guard recommended.area == area || Curriculum.levels(in: area).contains(where: { !ProgressStore.shared.completed.contains($0.id) }) else {
            return
        }
        let target = Curriculum.levels(in: area).first(where: { !ProgressStore.shared.completed.contains($0.id) })
            ?? Curriculum.levels(in: area).last!
        let card = SKCard(width: SKLayout.cardMaxWidth(self), height: 230, cornerRadius: 30)
        card.fillColor = SKTheme.paper
        // Sit the card below the subtitle with comfortable breathing room.
        card.position = CGPoint(x: 0, y: SKLayout.safeHeight(self) * 0.05)
        addChild(card)

        let title = SKLabel(text: "Up Next", style: .caption, color: SKTheme.ink.withAlphaComponent(0.6))
        title.position = CGPoint(x: 0, y: 82)
        card.addChild(title)
        let levelName = SKLabel(text: target.title, style: .headline, color: SKTheme.ink)
        levelName.position = CGPoint(x: 0, y: 32)
        levelName.fit(maxWidth: card.frame.width - 40)
        card.addChild(levelName)
        let detail = SKLabel(text: target.instruction, style: .body, color: SKTheme.ink.withAlphaComponent(0.7))
        detail.position = CGPoint(x: 0, y: -18)
        detail.fit(maxWidth: card.frame.width - 60)
        card.addChild(detail)

        let button = SKButton(title: "Play", style: .primary(color: SKTheme.color(for: area)), action: {
            SceneRouter.shared.goScene(level: target)
        })
        button.setSize(width: 220, height: 60)
        button.position = CGPoint(x: 0, y: -80)
        card.addChild(button)
    }

    private func buildPathButton() {
        let card = SKCard(width: 320, height: 80, cornerRadius: 30, fill: SKTheme.paper)
        card.position = CGPoint(x: 0, y: SKLayout.safeBottom(self) + 80)
        addChild(card)
        let label = SKLabel(text: "See All Levels", style: .button, color: SKTheme.ink)
        card.addChild(label)
        let tap = UITapGestureRecognizer(target: self, action: #selector(goMap))
        card.addGestureRecognizer(tap)
    }

    @objc private func goHome() { SceneRouter.shared.goHome() }
    @objc private func goMap() { SceneRouter.shared.goMap(area: area) }

    private func areaDescription(_ area: LearningArea) -> String {
        switch area {
        case .english: return "Help Pip with daily routines: breakfast, brushing teeth, bedtime and more."
        case .math: return "Solve puzzles, build patterns and tell time with Pip's friends."
        case .lifeSkills: return "Make smart choices: plan, share, stay safe, be kind."
        }
    }

    private func areaWelcome(_ area: LearningArea) -> String {
        switch area {
        case .english: return "Welcome home! Let's help Pip."
        case .math: return "Let's play with numbers!"
        case .lifeSkills: return "Let's learn smart choices!"
        }
    }
}