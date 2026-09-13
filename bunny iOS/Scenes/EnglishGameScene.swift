import SpriteKit
import UIKit

/// Drives the English scene through the shared `ImmersiveMissionScene` plus
/// a SpriteKit HUD that replaces the SwiftUI `GameChrome`.
final class EnglishGameScene: SKScene {
    let level: LevelDefinition
    private let room = ImmersiveMissionScene()
    private let hud = SKNode()
    private let instructionCard = SKNode()
    private let progressBar = SKProgressBar(width: 320)
    private let starsBadge = SKHUD.makeStars(filled: 0, size: 22)
    private let footerLabel = SKLabel(text: "", style: .body, color: SKTheme.ink)
    private var session: ScenePracticeSession
    private var step = 0
    private var pendingItemID: String?
    private var selectedItemID: String?
    private var placedItemID: String?
    private var isEvaluating = false
    private var isCompleting = false
    private var isPerformingAction = false
    private var actionProgress: Double = 0
    private var transitionTask: Task<Void, Never>?
    private var isSuspended = false
    private var didShowExitConfirm = false
    private var speechResume = false
    private var wasSuspended = false

    init(size: CGSize, level: LevelDefinition) {
        self.level = level
        let spec = HomeMissionSpec.spec(for: level.scene)
        session = ScenePracticeSession(levelID: level.id, itemIDs: spec.sequence)
        super.init(size: size)
        scaleMode = .resizeFill
    }
    required init?(coder aDecoder: NSCoder) { fatalError() }

    deinit {
        SpeechService.shared.stopSpeech()
        transitionTask?.cancel()
        NotificationCenter.default.removeObserver(self)
    }

    override func didMove(to view: SKView) {
        removeAllChildren()
        backgroundColor = SKTheme.cream
        // Detach any nodes that survived a previous tear-down so the scene
        // can be safely rebuilt when didMove is called twice (SpriteKit calls
        // didChangeSize → didMove during initial presentation).
        room.removeFromParent()
        hud.removeFromParent()
        instructionCard.removeFromParent()
        NotificationCenter.default.addObserver(self, selector: #selector(willResign),
                                               name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
        prepareItemOrder()
        installRoom()
        installHUD()
        installExitOverlay()
        configureRoom()
        runOpeningSequence()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        removeAllChildren()
        didMove(to: SKView())
    }

    // MARK: - Layout

    private func installRoom() {
        // Reserve a band at the top for HUD and at the bottom for the footer
        // so the immersive room is fully visible without overlapping UI.
        let topReserve = SKLayout.safeInsets(in: self).top + 96
        let bottomReserve = SKLayout.safeInsets(in: self).bottom + 110
        let roomHeight = max(280, size.height - topReserve - bottomReserve)
        let card = SKCard(width: size.width + 8, height: roomHeight, cornerRadius: 0, fill: SKTheme.paper)
        card.position = CGPoint(x: 0, y: bottomReserve + roomHeight / 2 - size.height / 2)
        card.zPosition = 0
        addChild(card)
        room.size = card.frame.size
        room.scaleMode = .resizeFill
        // Place the room scene at the card's centre so items inside the room
        // appear at the correct screen position.
        room.position = card.position
        room.zPosition = 1
        addChild(room)
    }

    private func installHUD() {
        hud.zPosition = 50
        hud.removeAllChildren()
        addChild(hud)

        let insets = SKLayout.safeInsets(in: self)
        let topBar = SKCard(width: min(SKLayout.cardMaxWidth(self), size.width * 0.96), height: 96, cornerRadius: 32, fill: SKTheme.paper)
        topBar.position = CGPoint(x: 0, y: SKLayout.safeTop(self) - insets.top - topBar.frame.height / 2)
        hud.addChild(topBar)

        let title = SKLabel(text: level.title, style: .body, color: SKTheme.ink)
        title.position = CGPoint(x: -topBar.size.width / 2 + 32, y: 14)
        title.horizontalAlignmentMode = .left
        title.fit(maxWidth: topBar.size.width * 0.55)
        topBar.addChild(title)
        let progress = SKLabel(text: "\(step + 1) / \(HomeMissionSpec.spec(for: level.scene).sequence.count)",
                               style: .caption, color: SKTheme.ink.withAlphaComponent(0.6))
        progress.position = CGPoint(x: -topBar.size.width / 2 + 32, y: -20)
        progress.horizontalAlignmentMode = .left
        topBar.addChild(progress)

        progressBar.position = CGPoint(x: 0, y: -10)
        progressBar.setProgress(0, animated: false)
        topBar.addChild(progressBar)

        starsBadge.position = CGPoint(x: topBar.size.width / 2 - 80, y: 8)
        topBar.addChild(starsBadge)

        // Two-line footer: instruction on top, action buttons below. Keeps the
        // chrome compact even on compact phones.
        let footer = SKCard(width: min(SKLayout.cardMaxWidth(self), size.width * 0.96), height: 100, cornerRadius: 30, fill: SKTheme.paper)
        footer.position = CGPoint(x: 0, y: SKLayout.safeBottom(self) + insets.bottom + footer.frame.height / 2)
        hud.addChild(footer)

        footerLabel.removeFromParent()
        footer.addChild(footerLabel)
        footerLabel.position = CGPoint(x: 0, y: 26)
        footerLabel.horizontalAlignmentMode = .center
        footerLabel.fit(maxWidth: footer.size.width - 32)

        let buttonRow = SKNode()
        buttonRow.position = CGPoint(x: 0, y: -18)
        footer.addChild(buttonRow)

        let exitNew = SKButton(title: "Exit", style: .ghost, action: { [weak self] in
            self?.confirmExit()
        })
        exitNew.setSize(width: 84, height: 50)
        exitNew.position = CGPoint(x: -footer.size.width / 2 + 58, y: 0)
        buttonRow.addChild(exitNew)

        let replay = SKButton(title: "Replay", style: .secondary(color: SKTheme.blue), action: { [weak self] in
            self?.replayInstruction()
        })
        replay.setSize(width: 120, height: 50)
        replay.position = CGPoint(x: -20, y: 0)
        buttonRow.addChild(replay)

        let helpNew = SKButton(title: "Help", style: .secondary(color: SKTheme.purple), action: { [weak self] in
            self?.showHelp()
        })
        helpNew.setSize(width: 110, height: 50)
        helpNew.position = CGPoint(x: footer.size.width / 2 - 75, y: 0)
        buttonRow.addChild(helpNew)
    }

    private func installExitOverlay() {
        instructionCard.removeAllChildren()
    }

    // MARK: - Game state

    private var spec: HomeMissionSpec { .spec(for: level.scene) }
    private var itemOrder: [MissionItem] = []

    private func prepareItemOrder() {
        guard itemOrder.isEmpty else { return }
        var order = spec.items.shuffled()
        if order.map(\.id) == spec.sequence {
            order = Array(order.dropFirst()) + Array(order.prefix(1))
        }
        itemOrder = order
    }

    private func expectedItem() -> MissionItem? {
        guard step < spec.sequence.count else { return nil }
        return spec.items.first { $0.id == spec.sequence[step] }
    }

    private func currentAction() -> EnglishSceneAction {
        .make(scene: level.scene, itemID: expectedItem()?.id ?? "")
    }

    private func currentBackground() -> String {
        let scene = level.scene
        guard scene == .dayAtHome, let id = expectedItem()?.id else { return spec.room.assetName }
        switch id {
        case "shirt", "pajamas": return "BedroomScene"
        case "toothbrush": return "Bathroom"
        default: return "DiningRoom"
        }
    }

    private func configureRoom() {
        room.onSelectionChanged = { [weak self] id in
            self?.pendingItemID = id
            self?.selectedItemID = id
            self?.refreshFooter()
        }
        room.onAttempt = { [weak self] id in self?.attempt(id) }
        room.onActionStateChanged = { [weak self] performing, value in
            guard let self else { return }
            let started = performing && !self.isPerformingAction
            self.isPerformingAction = performing
            self.actionProgress = value
            if started && !self.isEvaluating && !self.isSuspended {
                self.footerLabel.text = self.currentAction().gesturePrompt
                SpeechService.shared.speak(self.currentAction().gesturePrompt)
            }
            self.refreshFooter()
        }
        let action = currentAction()
        let target = SceneDropTarget(label: action.targetName,
                                     x: action.destination.x,
                                     y: action.destination.y)
        room.configure(backgroundName: currentBackground(),
                       items: visibleItems(),
                       completed: spec.items.filter { isCompleted($0.id) },
                       target: target,
                       placedItem: spec.items.first { $0.id == placedItemID },
                       helpItemID: session.helpLevel >= 3 ? expectedItem()?.id : nil,
                       reduceMotion: false,
                       sceneKind: level.scene,
                       action: action)
        room.inputEnabled = !isSuspended && !isEvaluating && !isCompleting
        refreshFooter()
    }

    private func isCompleted(_ id: String) -> Bool {
        session.index > (spec.sequence.firstIndex(of: id) ?? Int.max)
    }

    private func visibleItems() -> [MissionItem] {
        let remaining = itemOrder.filter { !isCompleted($0.id) }
        guard session.helpLevel >= 2, let expected = expectedItem() else { return remaining }
        let allowed = Set([expected.id] + remaining.filter { $0.id != expected.id }.prefix(1).map(\.id))
        return remaining.filter { allowed.contains($0.id) }
    }

    private func refreshFooter() {
        if isPerformingAction {
            footerLabel.text = currentAction().gesturePrompt
        } else if pendingItemID == nil {
            footerLabel.text = "Tap or move an object."
        } else {
            footerLabel.text = "Now tap \(currentAction().targetName.lowercased())."
        }
        progressBar.setProgress(Double(step) / Double(max(spec.sequence.count, 1)), animated: true)
    }

    private func runOpeningSequence() {
        refreshFooter()
        SpeechService.shared.speak(spec.stepInstructions[min(step, spec.stepInstructions.count - 1)])
    }

    private func attempt(_ itemID: String) {
        guard step < spec.sequence.count, !isEvaluating, !isCompleting, !isSuspended else { return }
        guard spec.items.contains(where: { $0.id == itemID }), !isCompleted(itemID) else { return }
        pendingItemID = nil
        guard session.attempt(itemID) else {
            showHelp()
            return
        }
        isEvaluating = true
        room.inputEnabled = false
        SpeechService.shared.playSuccessTone()
        placedItemID = itemID
        footerLabel.text = actionPhrase(for: itemID)
        SpeechService.shared.speak(actionPhrase(for: itemID), style: .encouraging) { [weak self] in self?.advanceStep() }
        transitionTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(12))
            guard !Task.isCancelled, let self else { return }
            self.advanceStep()
        }
        ProgressStore.shared.savePractice(session.practice)
        configureRoom()
    }

    private func advanceStep() {
        guard isEvaluating, !isCompleting, !isSuspended else { return }
        transitionTask?.cancel()
        step = session.index
        placedItemID = nil
        isEvaluating = false
        isPerformingAction = false
        actionProgress = 0
        if session.isFinished {
            isCompleting = true
            ProgressStore.shared.complete(level, stars: 3)
            SceneRouter.shared.goReward(level: level, stars: 3)
        } else {
            SpeechService.shared.speak(spec.stepInstructions[min(step, spec.stepInstructions.count - 1)])
            configureRoom()
        }
    }

    private func replayInstruction() {
        guard !isEvaluating, !isCompleting, !isSuspended else { return }
        session.replay()
        ProgressStore.shared.savePractice(session.practice)
        SpeechService.shared.speak(isPerformingAction ? currentAction().gesturePrompt
                                       : spec.stepInstructions[min(step, spec.stepInstructions.count - 1)],
                                   style: .slow)
    }

    private func showHelp() {
        session.requestHelp()
        ProgressStore.shared.savePractice(session.practice)
        let action = currentAction()
        let line: String
        if session.helpLevel >= 3 {
            line = "Let's do it together. " + action.gesturePrompt
        } else if session.helpLevel >= 2 {
            line = "Let's look at these two. " + action.gesturePrompt
        } else {
            line = "Let's listen together. " + action.gesturePrompt
        }
        footerLabel.text = line
        SpeechService.shared.speak(line, style: .slow)
        configureRoom()
    }

    private func confirmExit() {
        guard !didShowExitConfirm else { return }
        didShowExitConfirm = true
        let card = SKCard(width: min(size.width * 0.78, 520), height: 240, cornerRadius: 30)
        card.position = .zero
        card.zPosition = 300
        addChild(card)
        let title = SKLabel(text: "Leave this mission?", style: .headline, color: SKTheme.ink)
        title.position = CGPoint(x: 0, y: 70)
        card.addChild(title)
        let body = SKLabel(text: "Your completed actions are saved in your practice report.",
                           style: .body, color: SKTheme.ink.withAlphaComponent(0.7))
        body.position = CGPoint(x: 0, y: 14)
        body.fit(maxWidth: card.frame.width - 40)
        card.addChild(body)
        let stay = SKButton(title: "Stay", style: .secondary(color: SKTheme.blue), action: { [weak self] in
            self?.didShowExitConfirm = false
            self?.removeChildren(in: [card])
        })
        stay.setSize(width: 170, height: 60)
        stay.position = CGPoint(x: -100, y: -76)
        card.addChild(stay)
        let leave = SKButton(title: "Leave", style: .primary(color: SKTheme.orange), action: { [weak self] in
            self?.didShowExitConfirm = false
            SpeechService.shared.stop()
            SceneRouter.shared.goMap(area: self?.level.area ?? .english)
        })
        leave.setSize(width: 170, height: 60)
        leave.position = CGPoint(x: 100, y: -76)
        card.addChild(leave)
    }

    private func actionPhrase(for itemID: String) -> String {
        switch (level.scene, itemID) {
        case (.breakfast, "bowl"): return "The bowl is on the table."
        case (.breakfast, "milk"): return "The milk is pouring."
        case (.breakfast, "spoon"): return "The spoon is ready."
        case (.brushTeeth, "toothpaste"): return "Squeeze the toothpaste."
        case (.brushTeeth, "toothbrush"): return "Brush in little circles."
        case (.brushTeeth, "cup"): return "Rinse with water."
        case (.cooking, "bowl"): return "The mixing bowl is ready."
        case (.cooking, "milk"): return "Pour the milk slowly."
        case (.cooking, "spoon"): return "Stir, stir, stir!"
        case (.cooking, "plate"): return "Dinner is served."
        case (.dishes, "plate"): return "Put the plate in the sink."
        case (.dishes, "sponge"): return "Scrub with the sponge."
        case (.dishes, "towel"): return "Dry the clean plate."
        case (.dishes, "bowl"): return "The bowl is clean."
        case (.bedtime, "pajamas"): return "Pajamas are on."
        case (.bedtime, "teddy"): return "Teddy is tucked in."
        case (.bedtime, "lamp"): return "Good night, Pip."
        default:
            if let index = spec.sequence.firstIndex(of: itemID) {
                return "You did it! " + spec.stepInstructions[index]
            }
            return "Thank you for helping me!"
        }
    }

    @objc private func willResign() {
        wasSuspended = isSuspended
        isSuspended = true
        SpeechService.shared.stop()
        ProgressStore.shared.savePractice(session.practice)
        room.setSuspended(true)
        room.inputEnabled = false
    }
    @objc private func didBecomeActive() {
        if !wasSuspended { isSuspended = false }
        room.setSuspended(false)
        room.inputEnabled = !isSuspended && !isEvaluating && !isCompleting
    }
}
