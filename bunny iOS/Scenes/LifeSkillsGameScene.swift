import SpriteKit
import UIKit

/// Scene for life-skills missions. Each step is a multiple-choice question
/// presented as a card with three illustrated options. Correct choices pop,
/// the wrong answer shakes, and the next question fades in.
final class LifeSkillsGameScene: SKScene {
    let level: LevelDefinition
    private let header = SKNode()
    private let body = SKNode()
    private let promptLabel = SKLabel(text: "", style: .headline, color: SKTheme.ink)
    private let progressBar = SKProgressBar(width: 280)
    private let options: [SKNode] = [SKNode(), SKNode(), SKNode()]
    private var questions: [LifeSkillQuestion] = []
    private var index = 0
    private var correct = 0

    struct LifeSkillQuestion {
        let prompt: String
        let options: [(label: String, glyph: String, isCorrect: Bool)]
    }

    init(size: CGSize, level: LevelDefinition) {
        self.level = level
        self.questions = LifeSkillsGameScene.makeQuestions(for: level)
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = SKTheme.cream
    }
    required init?(coder aDecoder: NSCoder) { fatalError() }

    deinit { SpeechService.shared.stopSpeech() }

    override func didMove(to view: SKView) {
        removeAllChildren()
        backgroundColor = SKTheme.cream
        header.removeFromParent()
        body.removeFromParent()
        promptLabel.removeFromParent()
        progressBar.removeFromParent()
        for opt in options { opt.removeFromParent() }
        installHeader()
        installBody()
        present(index: 0)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        removeAllChildren()
        didMove(to: SKView())
    }

    private func installHeader() {
        header.removeAllChildren()
        header.removeFromParent()
        addChild(header)
        let back = SKHUD.makeCircleButton(symbol: "chevron.left", diameter: 56)
        back.position = CGPoint(x: SKLayout.safeLeft(self) + 36, y: SKLayout.safeTop(self) - 28)
        let tap = UITapGestureRecognizer(target: self, action: #selector(goMap))
        back.addGestureRecognizer(tap)
        header.addChild(back)

        // Title centred, no overlap with the back chevron.
        let title = SKLabel(text: level.title, style: .headline, color: SKTheme.ink)
        title.fontSize = 22
        title.position = CGPoint(x: 0, y: SKLayout.safeTop(self) - 64)
        title.horizontalAlignmentMode = .center
        title.fit(maxWidth: SKLayout.safeWidth(self) * 0.90)
        header.addChild(title)

        progressBar.position = CGPoint(x: 0, y: SKLayout.safeTop(self) - 110)
        progressBar.setProgress(0, animated: false)
        header.addChild(progressBar)
    }

    private func installBody() {
        body.removeAllChildren()
        body.removeFromParent()
        addChild(body)

        // The prompt card shows the question.
        let card = SKCard(width: SKLayout.cardMaxWidth(self), height: 150, cornerRadius: 28)
        card.position = CGPoint(x: 0, y: SKLayout.safeTop(self) - 240)
        body.addChild(card)

        promptLabel.position = CGPoint(x: 0, y: 0)
        promptLabel.fontSize = 18
        promptLabel.horizontalAlignmentMode = .center
        promptLabel.fit(maxWidth: card.frame.width - 40)
        card.addChild(promptLabel)

        // Three illustrated option cards laid out below the prompt.
        let cardWidth = (SKLayout.cardMaxWidth(self) - 2 * 14) / 3
        let cardHeight: CGFloat = min(170, SKLayout.safeHeight(self) * 0.20)
        let totalWidth = 3 * cardWidth + 2 * 14
        let baseX = -totalWidth / 2 + cardWidth / 2
        let gridY = SKLayout.safeTop(self) - 410 - cardHeight / 2
        for i in 0..<3 {
            let option = options[i]
            option.removeAllChildren()
            option.removeFromParent()
            option.position = CGPoint(x: baseX + CGFloat(i) * (cardWidth + 14), y: gridY)
            body.addChild(option)
        }
    }

    private func present(index: Int) {
        guard index < questions.count else { complete(); return }
        self.index = index
        progressBar.setProgress(Double(index) / Double(max(questions.count, 1)), animated: true)
        let q = questions[index]
        promptLabel.text = q.prompt
        SpeechService.shared.speak(q.prompt)
        for (i, option) in options.enumerated() {
            let opt = q.options[safe: i] ?? ("", "?", false)
            option.removeAllChildren()
            // Build the option card.
            let card = SKCard(width: 110, height: 150, cornerRadius: 22, fill: SKTheme.paper)
            card.position = .zero
            let glyph = SKLabelNode(text: opt.glyph)
            glyph.fontSize = 44
            glyph.fontName = "AvenirNext-Heavy"
            glyph.position = CGPoint(x: 0, y: 30)
            card.addChild(glyph)
            let label = SKLabel(text: opt.label, style: .caption, color: SKTheme.ink)
            label.fontSize = 14
            label.position = CGPoint(x: 0, y: -38)
            label.horizontalAlignmentMode = .center
            label.fit(maxWidth: 92)
            card.addChild(label)
            option.addChild(card)

            // Hit area — covers the whole card. Tapping it triggers the action.
            let hit = SKShapeNode(rectOf: CGSize(width: 110, height: 150), cornerRadius: 22)
            hit.fillColor = .clear
            hit.strokeColor = .clear
            hit.position = .zero
            hit.name = "hit"
            option.addChild(hit)
            option.userData = NSMutableDictionary()
            option.userData?["correct"] = opt.isCorrect
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: body)
        for option in options {
            if option.contains(location) {
                handleChoice(option: option)
                return
            }
        }
    }

    private func handleChoice(option: SKNode) {
        guard let isCorrect = option.userData?["correct"] as? Bool else { return }
        if isCorrect {
            correct += 1
            SpeechService.shared.playSuccessTone()
            SpeechService.shared.speak("Great choice!")
            option.run(.sequence([
                .scale(to: 1.05, duration: 0.1),
                .scale(to: 1.0, duration: 0.15)
            ]))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.present(index: (self?.index ?? 0) + 1)
            }
        } else {
            SpeechService.shared.playTryAgainTone()
            let originalX = option.position.x
            option.run(.sequence([
                .moveBy(x: -10, y: 0, duration: 0.05),
                .moveBy(x: 20, y: 0, duration: 0.05),
                .moveBy(x: -20, y: 0, duration: 0.05),
                .moveBy(x: 10, y: 0, duration: 0.05)
            ]))
            _ = originalX
        }
    }

    private func complete() {
        let stars = max(1, min(3, correct))
        ProgressStore.shared.complete(level, stars: stars)
        SceneRouter.shared.goReward(level: level, stars: stars)
    }

    @objc private func goMap() {
        SpeechService.shared.stopSpeech()
        SceneRouter.shared.goMap(area: level.area)
    }

    private static func makeQuestions(for level: LevelDefinition) -> [LifeSkillQuestion] {
        let base = level.vocabulary
        let promptTemplates = [
            "Which one is the smartest choice?",
            "Pick the safe option.",
            "What should you do first?",
            "Which feels kindest?",
            "Help Pip make a good plan."
        ]
        let glyphSets: [[String]] = [
            ["✅", "⚠️", "❓"],
            ["🧠", "😴", "📱"],
            ["🥕", "🍬", "🧁"],
            ["🚦", "🚗", "🏃"],
            ["🤝", "👎", "🙅"]
        ]
        return (0..<5).map { i in
            let correctIndex = i % 3
            let prompt = "\(promptTemplates[i % promptTemplates.count]) (\(base.first ?? "kind"))"
            let glyphs = glyphSets[i % glyphSets.count]
            let labels = ["Good choice", "Maybe later", "Try again"]
            let opts = (0..<3).map { idx -> (String, String, Bool) in
                (labels[idx], glyphs[idx % glyphs.count], idx == correctIndex)
            }
            return LifeSkillQuestion(prompt: prompt, options: opts)
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
