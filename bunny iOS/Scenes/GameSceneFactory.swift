import SpriteKit
import UIKit

/// Builds the correct gameplay scene for a given level definition.
enum GameSceneFactory {
    static func makeScene(size: CGSize, level: LevelDefinition) -> SKScene {
        let scale = max(size.width, 900) / 900
        switch level.area {
        case .english:
            return EnglishGameScene(size: size, level: level)
        case .math:
            return MathGameScene(size: size, level: level)
        case .lifeSkills:
            return LifeSkillsGameScene(size: size, level: level)
        }
    }
}

/// Adds shared screen chrome (background, top bar) to every scene.
class GameSceneBase: SKScene {
    let chrome = SKNode()
    let topBar = SKNode()
    let backgroundLayer = SKNode()
    private(set) var backButton: SKNode?
    var onBack: (() -> Void)?
    var topTitle: SKLabel?

    override func didMove(to view: SKView) {
        backgroundColor = SKTheme.cream
        addChild(backgroundLayer)
        addChild(chrome)
        chrome.zPosition = 200
        installBackButton()
    }

    func installBackButton() {
        let back = SKHUD.makeCircleButton(symbol: "chevron.left", diameter: 56)
        back.position = CGPoint(x: -size.width / 2 + 44, y: size.height / 2 - 56)
        back.zPosition = 220
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleBack))
        back.addGestureRecognizer(tap)
        chrome.addChild(back)
        backButton = back
    }

    @objc private func handleBack() { onBack?() }

    func setTopTitle(_ text: String, subtitle: String? = nil) {
        topBar.removeAllChildren()
        let card = SKCard(width: min(size.width * 0.7, 600), height: subtitle == nil ? 80 : 110)
        card.position = CGPoint(x: 0, y: size.height / 2 - 64)
        card.zPosition = 200
        topBar.addChild(card)

        let titleLabel = SKLabel(text: text, style: .headline, color: SKTheme.ink)
        titleLabel.fit(maxWidth: card.frame.width - 30)
        titleLabel.position = CGPoint(x: 0, y: subtitle == nil ? 0 : 18)
        topBar.addChild(titleLabel)
        topTitle = titleLabel

        if let subtitle {
            let sub = SKLabel(text: subtitle, style: .caption, color: SKTheme.ink.withAlphaComponent(0.6))
            sub.fit(maxWidth: card.frame.width - 30)
            sub.position = CGPoint(x: 0, y: -22)
            topBar.addChild(sub)
        }
        chrome.addChild(topBar)
    }
}