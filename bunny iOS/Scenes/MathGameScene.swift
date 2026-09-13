import SpriteKit
import UIKit

/// Math challenge scene. Each level presents a target number and a tray of
/// animated number tiles. Players drag tiles into the answer slot to combine
/// them. Streaks award bonus stars; persistence unlocks the next scene.
final class MathGameScene: SKScene {
    let level: LevelDefinition
    private let room = SKNode()
    private var targetNumberLabel: SKLabelNode?
    private var answerRowNode: SKNode?
    private var trayContainerNode: SKNode?
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
        removeAllChildren()
        backgroundColor = SKTheme.cream
        hud.removeFromParent()
        footer.removeFromParent()
        progressBar.removeFromParent()
        titleLabel.removeFromParent()
        starsBadge.removeFromParent()

        // Calm floating particles behind the math room.
        SKAmbient.install(in: self, config: SKAmbient.Configuration(
            particleCount: 24,
            palette: [
                SKTheme.yellow.withAlphaComponent(0.45),
                SKTheme.pink.withAlphaComponent(0.35),
                SKTheme.green.withAlphaComponent(0.30),
            ],
            backgroundGradient: [SKTheme.cream, SKTheme.blue.withAlphaComponent(0.10)],
            driftSpeed: 5
        ))

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
        let roomY = bottomReserve + usableHeight / 2 - size.height / 2

        // Immersive backdrop: pick a Math scene asset that fits the level's
        // SceneKind. Reuses the same image names HomeMissionSpec.spec(for:)
        // maps to (bakery / market / festival / space / outdoors fallback).
        // Sits at zPosition 0 inside `room` so the target card and answer
        // row appear on top of it.
        let backdropImage = MathGameScene.backdropImage(for: level.scene)
        let backdropTexture = SKTexture(imageNamed: backdropImage)
        // SKTexture.init never returns nil on iOS, but the underlying image
        // may be missing for a level whose image wasn't bundled. Texture size
        // is the cheapest signal: an empty texture has zero width.
        let textureSize = backdropTexture.size()
        if textureSize.width > 0 && textureSize.height > 0 {
            let backdrop = SKSpriteNode(texture: backdropTexture)
            backdrop.name = "backdrop"
            let cover = max(size.width / max(1, textureSize.width),
                            usableHeight / max(1, textureSize.height))
            backdrop.size = CGSize(width: textureSize.width * cover,
                                   height: textureSize.height * cover)
            backdrop.position = CGPoint(x: 0, y: roomY)
            backdrop.zPosition = 0
            room.addChild(backdrop)

            // Tinted overlay so the target card / answer row / tray remain
            // readable regardless of which backdrop is loaded.
            let overlay = SKShapeNode(rectOf: CGSize(width: size.width + 20,
                                                     height: usableHeight))
            overlay.fillColor = SKTheme.cream.withAlphaComponent(0.18)
            overlay.strokeColor = .clear
            overlay.position = CGPoint(x: 0, y: roomY)
            overlay.zPosition = 1
            room.addChild(overlay)
        } else {
            // Fallback to the flat coloured band if no image is bundled.
            let backdrop = SKShapeNode(rectOf: CGSize(width: size.width + 20, height: usableHeight))
            backdrop.fillColor = SKTheme.blue.withAlphaComponent(0.10)
            backdrop.strokeColor = .clear
            backdrop.position = CGPoint(x: 0, y: roomY)
            room.addChild(backdrop)
        }

        let targetCard = SKCard(width: min(SKLayout.cardMaxWidth(self), 320), height: 150, cornerRadius: 30)
        targetCard.position = CGPoint(x: 0, y: roomY + usableHeight * 0.32)
        targetCard.fillColor = SKTheme.paper
        targetCard.name = "targetCard"
        targetCard.zPosition = 5
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
        targetNumberLabel = targetNumber

        let answerRow = SKNode()
        answerRow.name = "answerRow"
        answerRow.position = CGPoint(x: 0, y: roomY + 8)
        room.addChild(answerRow)
        answerRowNode = answerRow

        let trayContainer = SKNode()
        trayContainer.name = "tray"
        // Pull the tray well above the bottom edge so the number tiles
        // aren't clipped behind the footer / safe-area or hidden by the
        // backdrop image's lower band.
        trayContainer.position = CGPoint(x: 0, y: roomY + 30)
        room.addChild(trayContainer)
        trayContainerNode = trayContainer
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
        // Bumped to 130pt so the instruction row + a 46pt button row +
        // 16pt breathing room on each side all fit without overlap.
        let bottom = SKCard(width: SKLayout.cardMaxWidth(self), height: 130, cornerRadius: 28)
        bottom.position = CGPoint(x: 0, y: SKLayout.safeBottom(self) + insets.bottom + bottom.frame.height / 2)
        hud.addChild(bottom)

        footer.text = "Tap numbers to add them to the row."
        footer.fontSize = 14
        footer.fit(maxWidth: bottom.frame.width - 32)
        footer.position = CGPoint(x: 0, y: 38)
        footer.horizontalAlignmentMode = .center
        bottom.addChild(footer)

        let buttonRow = SKNode()
        buttonRow.position = CGPoint(x: 0, y: -25)
        bottom.addChild(buttonRow)

        // Reset (left) + Check (right) with explicit centering math so
        // the two never overlap regardless of card width.
        let resetWidth: CGFloat = 110
        let checkWidth: CGFloat = 140
        let gap: CGFloat = 24
        let totalRow = resetWidth + checkWidth + gap
        let leftX  = -totalRow / 2 + resetWidth / 2
        let rightX = -totalRow / 2 + resetWidth + gap + checkWidth / 2

        let reset = SKButton(title: "Reset", style: .ghost, action: { [weak self] in
            self?.resetSelection()
        })
        reset.setSize(width: resetWidth, height: 46)
        reset.position = CGPoint(x: leftX, y: 0)
        buttonRow.addChild(reset)

        let check = SKButton(title: "Check", style: .primary(color: SKTheme.blue), action: { [weak self] in
            self?.checkAnswer()
        })
        check.setSize(width: checkWidth, height: 46)
        check.position = CGPoint(x: rightX, y: 0)
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

        // Update the target number directly via the cached reference rather
        // than walking the scene tree with childNode(withName:). Earlier
        // builds did the walk and SpriteKit returned nil even though the
        // node was clearly in the tree (the recursive-enumerate log showed
        // it as the last node), so the player always saw "?" instead of
        // the actual target.
        targetNumberLabel?.text = "\(target)"

        progressBar.setProgress(Double(step) / Double(problemsPerLevel), animated: true)

        answerRowNode?.removeAllChildren()

        trayContainerNode?.removeAllChildren()

        guard let trayContainer = trayContainerNode else { return }
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
        guard let trayNode = trayContainerNode else { return }
        for node in trayNode.children {
            // `contains` expects the point in the node's parent coordinate
            // space. The touch is in `room` coordinates, while each tile is
            // nested under the tray container; comparing them directly made
            // every number tile look untappable.
            guard let parent = node.parent else { continue }
            let tilePoint = parent.convert(location, from: room)
            if node.contains(tilePoint) {
                addTileToAnswer(node: node)
                return
            }
        }
    }

    private func addTileToAnswer(node: SKNode) {
        guard let answerRow = answerRowNode,
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

        if let targetNode = targetNumberLabel {
            targetNode.text = "\(max(0, target - currentSum))"
            targetNode.fontColor = (target - currentSum == 0) ? SKTheme.green : SKTheme.ink
        }
    }

    private func resetSelection() {
        guard let trayNode = trayContainerNode,
              let answerRow = answerRowNode else { return }
        for tile in selectedTiles {
            trayNode.addChild(tile)
        }
        selectedTiles.removeAll()
        currentSum = 0
        answerRow.removeAllChildren()
        if let targetNode = targetNumberLabel {
            targetNode.text = "\(target)"
            targetNode.fontColor = SKTheme.ink
        }
    }

    private func checkAnswer() {
        attempts += 1
        if currentSum == target {
            Feedback.shared.success()
            SpeechService.shared.playSuccessTone()
            SpeechService.shared.speak("That's right!")
            burst(target: currentSum)
            advance()
        } else {
            Feedback.shared.tryAgain()
            SpeechService.shared.playTryAgainTone()
            // Pillar 1 (Calm): keep the spoken message short and friendly.
            // Pillar X (Don't trap a stuck kid): after a few misses, suggest
            // a tip instead of just repeating the same "try again".
            let prompt: String
            if attempts >= 3 {
                // problemList[step].answer is [first, second]. After 3
                // missed attempts, suggest the actual pair so the child
                // isn't stuck guessing.
                let nums = problemList[step].answer
                if nums.count == 2 {
                    prompt = "Try \(nums[0]) + \(nums[1])."
                } else {
                    prompt = "Not quite. Try again."
                }
            } else {
                prompt = "Not quite. Try again."
            }
            SpeechService.shared.speak(prompt)
            flashTray()
        }
    }

    /// Particle burst at the target-card position when the child
    /// answers correctly. ~24 motes that radiate outward and fade.
    private func burst(target: Int) {
        guard let targetNode = targetNumberLabel else { return }
        let palette: [UIColor] = [
            SKTheme.yellow, SKTheme.green, SKTheme.blue, SKTheme.pink,
        ]
        for _ in 0..<24 {
            let mote = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
            mote.fillColor = palette.randomElement() ?? SKTheme.yellow
            mote.strokeColor = .clear
            mote.position = targetNode.position
            room.addChild(mote)
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 60...120)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance
            mote.run(.sequence([
                .group([
                    SKAction.moveBy(x: dx, y: dy, duration: 0.6),
                    SKAction.fadeOut(withDuration: 0.6),
                    SKAction.scale(to: 0.2, duration: 0.6),
                ]),
                .removeFromParent(),
            ]))
        }
    }

    private func flashTray() {
        guard let trayNode = trayContainerNode else { return }
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

    /// Picks the Math-scene backdrop image that matches the level's SceneKind,
    /// falling back to MathOutdoors for anything not explicitly mapped. Same
    /// bucket logic as `HomeMissionSpec.spec(for:)` so Math lessons share
    /// visual continuity with the lesson preview.
    private static func backdropImage(for scene: SceneKind) -> String {
        switch scene {
        case .bakery, .measureGarden:        return "MathBakery"
        case .market, .fairPicnic:           return "MathMarket"
        case .festival, .helperFestival, .castle: return "MathFestival"
        case .spaceStation, .rocket:         return "MathSpace"
        default:                              return "MathOutdoors"
        }
    }
}
