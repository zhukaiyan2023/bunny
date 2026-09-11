import SpriteKit
import UIKit

/// Math challenge scene. Each level presents a target number and a tray of
/// animated number tiles. Players drag tiles into the answer slot to combine
/// them. Streaks award bonus stars; persistence unlocks the next scene.
final class MathGameScene: SKScene {
    let level: LevelDefinition
    private let room = SKNode()
    private let hud = SKNode()
    private let titleLabel = SKLabel(text: "", style: .headline, color: SKTheme.ink)
    private let footer = SKLabel(text: "", style: .body, color: SKTheme.ink.withAlphaComponent(0.7))
    private let progressBar = SKProgressBar(width: 280)
    private let starsBadge = SKHUD.makeStars(filled: 0, size: 22)
    private var tray: [Int] = []
    private var target = 0
    private var selectedTiles: [SKNode] = []
    private var currentSum: Int = 0
    private var attempts = 0
    private var step = 0
    private var problemsPerLevel = 5
    private let problemList: [MathProblem]

    struct MathProblem {
        let prompt: String
        let target: Int
        let tray: [Int]
        let answer: [Int]
    }

    init(size: CGSize, level: LevelDefinition) {
        self.level = level
        self.problemList = MathGameScene.makeProblems(for: level)
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = SKTheme.cream
    }
    required init?(coder aDecoder: NSCoder) { fatalError() }

    deinit {
        SpeechService.shared.stopSpeech()
    }

    override func didMove(to view: SKView) {
        backgroundColor = SKTheme.cream
        hud.removeFromParent()
        footer.removeFromParent()
        progressBar.removeFromParent()
        titleLabel.removeFromParent()
        starsBadge.removeFromParent()
        installRoom()
        installHUD()
        loadProblem(index: 0)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        removeAllChildren()
        didMove(to: SKView())
    }

    private func installRoom() {
        room.zPosition = 0
        room.removeFromParent()
        room.removeAllChildren()
        addChild(room)

        // Reserve space for the top HUD (title + progress row) and the bottom
        // footer. The math-room area sits between them.
        let topReserve = SKLayout.safeInsets(in: self).top + 150
        let bottomReserve = SKLayout.safeInsets(in: self).bottom + 110
        let usableHeight = max(280, size.height - topReserve - bottomReserve)
        let backdrop = SKShapeNode(rectOf: CGSize(width: size.width + 20, height: usableHeight))
        backdrop.fillColor = SKTheme.blue.withAlphaComponent(0.10)
        backdrop.strokeColor = .clear
        backdrop.position = CGPoint(x: 0, y: bottomReserve + usableHeight / 2 - size.height / 2)
        room.addChild(backdrop)

        let targetCard = SKCard(width: min(SKLayout.cardMaxWidth(self), 320), height: 150, cornerRadius: 30)
        targetCard.position = CGPoint(x: 0, y: backdrop.position.y + usableHeight * 0.32)
        targetCard.fillColor = SKTheme.paper
        room.addChild(targetCard)
        let targetTitle = SKLabel(text: "Make", style: .caption, color: SKTheme.ink.withAlphaComponent(0.65))
        targetTitle.position = CGPoint(x: 0, y: 38)
        targetCard.addChild(targetTitle)
        let targetNumber = SKLabelNode(text: "?")
        targetNumber.fontName = "AvenirNext-Heavy"
        targetNumber.fontSize = 64
        targetNumber.fontColor = SKTheme.ink
        targetNumber.position = CGPoint(x: 0, y: -14)
        targetNumber.name = "target"
        targetCard.addChild(targetNumber)

        let answerRow = SKNode()
        answerRow.name = "answerRow"
        answerRow.position = CGPoint(x: 0, y: backdrop.position.y + 8)
        room.addChild(answerRow)

        let trayContainer = SKNode()
        trayContainer.name = "tray"
        trayContainer.position = CGPoint(x: 0, y: backdrop.position.y - usableHeight * 0.28)
        room.addChild(trayContainer)
    }

    private func installHUD() {
        hud.zPosition = 50
        hud.removeAllChildren()
        addChild(hud)

        let insets = SKLayout.safeInsets(in: self)
        let back = SKHUD.makeCircleButton(symbol: "chevron.left", diameter: 56)
        back.position = CGPoint(x: SKLayout.safeLeft(self) + 36, y: SKLayout.safeTop(self) - 28)
        let tap = UITapGestureRecognizer(target: self, action: #selector(confirmExit))
        back.addGestureRecognizer(tap)
        hud.addChild(back)

        // Title centred at the top (separate row from the progress + stars so
        // they never overlap).
        titleLabel.text = level.title
        titleLabel.position = CGPoint(x: 0, y: SKLayout.safeTop(self) - 70)
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.fit(maxWidth: SKLayout.safeWidth(self) * 0.95)
        hud.addChild(titleLabel)

        // Progress + stars on a second row.
        progressBar.position = CGPoint(x: -80, y: SKLayout.safeTop(self) - 122)
        progressBar.setProgress(0, animated: false)
        hud.addChild(progressBar)

        starsBadge.position = CGPoint(x: SKLayout.safeRight(self) - 70, y: SKLayout.safeTop(self) - 122)
        hud.addChild(starsBadge)

        // Bottom footer with instruction on top, two action buttons below.
        let bottom = SKCard(width: SKLayout.cardMaxWidth(self), height: 96, cornerRadius: 28)
        bottom.position = CGPoint(x: 0, y: SKLayout.safeBottom(self) + insets.bottom + bottom.frame.height / 2)
        hud.addChild(bottom)

        footer.text = "Tap numbers to add them to the row."
        footer.fontSize = 14
        footer.fit(maxWidth: bottom.frame.width - 32)
        footer.position = CGPoint(x: 0, y: 22)
        footer.horizontalAlignmentMode = .center
        bottom.addChild(footer)

        let buttonRow = SKNode()
        buttonRow.position = CGPoint(x: 0, y: -22)
        bottom.addChild(buttonRow)

        let reset = SKButton(title: "Reset", style: .ghost, action: { [weak self] in
            self?.resetSelection()
        })
        reset.setSize(width: 110, height: 46)
        reset.position = CGPoint(x: -bottom.frame.width / 2 + 70, y: 0)
        buttonRow.addChild(reset)

        let check = SKButton(title: "Check", style: .primary(color: SKTheme.blue), action: { [weak self] in
            self?.checkAnswer()
        })
        check.setSize(width: 140, height: 46)
        check.position = CGPoint(x: bottom.frame.width / 2 - 90, y: 0)
        buttonRow.addChild(check)
    }

    private func loadProblem(index: Int) {
        guard index < problemList.count else { completeLevel(); return }
        step = index
        let problem = problemList[index]
        target = problem.target
        tray = problem.tray
        selectedTiles.removeAll()
        currentSum = 0
        attempts = 0

        if let targetNode = room.childNode(withName: "target") as? SKLabelNode {
            targetNode.text = "\(target)"
        }
        progressBar.setProgress(Double(step) / Double(problemsPerLevel), animated: true)

        let answerRow = room.childNode(withName: "answerRow")
        answerRow?.removeAllChildren()

        let trayContainer = room.childNode(withName: "tray")
        trayContainer?.removeAllChildren()

        guard let trayContainer else { return }
        let columns = CGFloat(max(tray.count, 1))
        let tileSide: CGFloat = min(96, max(58, size.width / (columns + 2)))
        let spacing = tileSide + 18
        let totalWidth = columns * spacing - 18
        let startX = -totalWidth / 2 + tileSide / 2
        for (i, value) in tray.enumerated() {
            let tile = makeTile(value: value, size: tileSide)
            tile.position = CGPoint(x: startX + CGFloat(i) * spacing, y: 0)
            tile.name = "tile:\(value):\(i)"
            trayContainer.addChild(tile)
        }
        SpeechService.shared.speak(problem.prompt)
    }

    private func makeTile(value: Int, size: CGFloat) -> SKNode {
        let container = SKNode()
        let bg = SKShapeNode(rectOf: CGSize(width: size, height: size), cornerRadius: 18)
        bg.fillColor = SKTheme.paper
        bg.strokeColor = SKTheme.blue
        bg.lineWidth = 3
        bg.name = "tileBackground"
        container.addChild(bg)
        let label = SKLabelNode(text: "\(value)")
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = size * 0.46
        label.fontColor = SKTheme.ink
        label.verticalAlignmentMode = .center
        container.addChild(label)
        return container
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: room)
        guard let trayNode = room.childNode(withName: "tray") else { return }
        for node in trayNode.children {
            if let bg = node.childNode(withName: "tileBackground"),
               bg.contains(location) {
                addTileToAnswer(node: node)
                return
            }
        }
    }

    private func addTileToAnswer(node: SKNode) {
        guard let answerRow = room.childNode(withName: "answerRow"),
              let bg = node.childNode(withName: "tileBackground") as? SKShapeNode else { return }
        let labelText = (node.children.compactMap { $0 as? SKLabelNode }.first?.text) ?? "0"
        guard let value = Int(labelText) else { return }
        currentSum += value
        selectedTiles.append(node)
        node.removeFromParent()

        let copy = makeTile(value: value, size: bg.frame.width)
        let index = selectedTiles.count - 1
        let tileWidth = bg.frame.width
        let spacing: CGFloat = tileWidth + 14
        let totalWidth = CGFloat(max(problemList[step].answer.count, 1)) * spacing - 14
        let startX = -totalWidth / 2 + tileWidth / 2
        copy.position = CGPoint(x: startX + CGFloat(index) * spacing, y: 0)
        answerRow.addChild(copy)

        if let targetNode = room.childNode(withName: "target") as? SKLabelNode {
            targetNode.text = "\(max(0, target - currentSum))"
            targetNode.fontColor = (target - currentSum == 0) ? SKTheme.green : SKTheme.ink
        }
    }

    private func resetSelection() {
        guard let trayNode = room.childNode(withName: "tray"),
              let answerRow = room.childNode(withName: "answerRow") else { return }
        for tile in selectedTiles {
            trayNode.addChild(tile)
        }
        selectedTiles.removeAll()
        currentSum = 0
        answerRow.removeAllChildren()
        if let targetNode = room.childNode(withName: "target") as? SKLabelNode {
            targetNode.text = "\(target)"
            targetNode.fontColor = SKTheme.ink
        }
    }

    private func checkAnswer() {
        attempts += 1
        if currentSum == target {
            SpeechService.shared.playSuccessTone()
            SpeechService.shared.speak("That's right!")
            advance()
        } else {
            SpeechService.shared.playTryAgainTone()
            SpeechService.shared.speak("Not quite. Try again.")
            flashTray()
        }
    }

    private func flashTray() {
        guard let trayNode = room.childNode(withName: "tray") else { return }
        trayNode.run(.sequence([
            .colorize(with: SKTheme.pink, colorBlendFactor: 0.6, duration: 0.15),
            .colorize(with: .clear, colorBlendFactor: 0, duration: 0.25)
        ]))
    }

    private func advance() {
        let next = step + 1
        if next >= problemsPerLevel || next >= problemList.count {
            completeLevel()
        } else {
            loadProblem(index: next)
        }
    }

    private func completeLevel() {
        ProgressStore.shared.complete(level, stars: 3)
        SceneRouter.shared.goReward(level: level, stars: 3)
    }

    @objc private func confirmExit() {
        SpeechService.shared.stop()
        SceneRouter.shared.goMap(area: level.area)
    }

    private static func makeProblems(for level: LevelDefinition) -> [MathProblem] {
        let vocabulary = level.vocabulary
        let titleWords = vocabulary.isEmpty ? ["number"] : vocabulary
        return (0..<5).map { i in
            let first = Int.random(in: 2...7) + i
            let second = Int.random(in: 1...6) + i
            let target = first + second
            let extras: [Int] = (0..<3).map { _ in Int.random(in: 1...9) }
            let tray = ([first, second] + extras).shuffled()
            let word = titleWords[i % titleWords.count]
            return MathProblem(
                prompt: "Make \(target) with \(first) and \(second). Think of \(word).",
                target: target,
                tray: tray,
                answer: [first, second]
            )
        }
    }
}