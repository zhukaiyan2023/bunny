import SpriteKit
import UIKit

/// The shared immersive room. Renders one of the 15 BrightSprout home
/// backdrops, a few draggable props, and a glowing target zone. The user
/// drags props onto the target to advance the scene's micro-story.
final class ImmersiveMissionScene: SKScene {
    // MARK: - Layers

    /// Background illustration of the room.
    private let roomLayer = SKSpriteNode()
    /// Draggable prop sprites live here.
    private let itemsLayer = SKNode()
    /// Confetti, sparkles and other ephemeral effects.
    private let effectsLayer = SKNode()
    /// The glowing target zone showing where to drag the current prop.
    private let targetLayer = SKNode()
    /// A small in-scene story prompt drawn above the room.
    private let promptLayer = SKNode()
    /// The Pip character.
    private let pip = SKSpriteNode(texture: SKTexture(imageNamed: "PipWorldSprite"))
    /// A dimmer used by bedtime / wake-up scenes.
    private let dimmer = SKSpriteNode(color: .black, size: .zero)

    // MARK: - State

    private var identity = ""
    private var backgroundName = ""
    private var sceneKind: SceneKind?
    private var allItems: [String: MissionItem] = [:]
    private var itemNodes: [String: SKSpriteNode] = [:]
    private var availableIDs: Set<String> = []
    private(set) var completedItemIDs: Set<String> = []
    private var selectedItemID: String?
    private var draggedID: String?
    private var activeTouch: UITouch?
    private var currentAction: EnglishSceneAction?
    private var stepPrompt: String = "Find an object"
    private var explorationOnly = false

    // MARK: - Tunable layout values

    private var propSize: CGFloat { min(150, max(90, min(size.width, size.height) * 0.22)) }
    private var targetSize: CGFloat { propSize * 1.3 }
    /// Vertical inset (in scene points) reserved for the in-scene story prompt
    /// banner that sits just below the parent HUD.
    private var promptBandHeight: CGFloat { 70 }
    /// Bottom inset reserved for the parent footer.
    private var footerBandHeight: CGFloat { 120 }

    // MARK: - Callbacks

    /// Fires whenever the user successfully places a prop.
    var onAttempt: ((String) -> Void)?
    /// Fires whenever the user taps a prop.
    var onSelectionChanged: ((String?) -> Void)?
    var inputEnabled = true {
        didSet { if !inputEnabled { cancelInteraction() } }
    }
    private(set) var isPerformingAction = false
    var actionProgress: Double = 0
    var onActionStateChanged: ((Bool, Double) -> Void)?

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKTheme.cream
        ensureLayers()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        cancelInteraction()
        layoutAll()
    }

    private func ensureLayers() {
        guard roomLayer.parent == nil else { return }
        addChild(roomLayer)
        addChild(itemsLayer)
        addChild(targetLayer)
        addChild(effectsLayer)
        addChild(promptLayer)
        addChild(pip)
        addChild(dimmer)
        pip.zPosition = 20
        itemsLayer.zPosition = 10
        targetLayer.zPosition = 8
        effectsLayer.zPosition = 30
        promptLayer.zPosition = 18
        dimmer.zPosition = 15
    }

    // MARK: - Configuration

    func configure(backgroundName: String, items: [MissionItem], completed: [MissionItem],
                   target: SceneDropTarget, placedItem: MissionItem?, helpItemID: String?,
                   reduceMotion: Bool, explorationOnly: Bool = false,
                   sceneKind: SceneKind? = nil, action: EnglishSceneAction? = nil) {
        ensureLayers()
        let newIdentity = "\(String(describing: sceneKind)):\(explorationOnly):\(action.map(String.init(describing:)) ?? "none")"
        if identity != newIdentity {
            identity = newIdentity
            itemsLayer.removeAllChildren()
            effectsLayer.removeAllChildren()
            targetLayer.removeAllChildren()
            promptLayer.removeAllChildren()
            allItems.removeAll()
            itemNodes.removeAll()
            completedItemIDs.removeAll()
            currentAction = nil
        }
        self.sceneKind = sceneKind
        self.explorationOnly = explorationOnly
        self.legacyTarget = target
        if self.backgroundName != backgroundName {
            self.backgroundName = backgroundName
            roomLayer.texture = SKTexture(imageNamed: backgroundName)
        }
        if let sceneKind {
            for item in HomeMissionSpec.spec(for: sceneKind).items { allItems[item.id] = item }
        }
        for item in items + completed { allItems[item.id] = item }
        availableIDs = Set(items.map(\.id))
        completedItemIDs.formUnion(completed.map(\.id))
        if let placedItem { completedItemIDs.insert(placedItem.id) }
        currentAction = action
        isPerformingAction = false
        actionProgress = 0
        onActionStateChanged?(false, 0)
        for (id, item) in allItems where itemNodes[id] == nil {
            let node = SKSpriteNode(texture: SKTexture(imageNamed: item.imageName))
            node.name = "prop:\(id)"
            itemsLayer.addChild(node)
            itemNodes[id] = node
        }
        cancelInteraction()
        layoutAll()
        // Slight entrance for every prop so the room feels alive on first show.
        for node in itemNodes.values where !node.hasActions() {
            node.alpha = 0
            node.run(.sequence([.wait(forDuration: 0.3),
                                .fadeIn(withDuration: 0.4)]))
        }
    }

    private var legacyTarget = SceneDropTarget(label: "", x: 0.5, y: 0.5)

    // MARK: - Layout

    private func layoutAll() {
        guard size.width > 0, size.height > 0 else { return }
        layoutRoom()
        layoutPrompt()
        layoutTarget()
        layoutPip()
        layoutItems()
    }

    private func layoutRoom() {
        // Cover the entire scene; the parent EnglishGameScene has already
        // reserved the top HUD + bottom footer area.
        let textureSize = roomLayer.texture?.size() ?? CGSize(width: 900, height: 600)
        let cover = max(size.width / max(1, textureSize.width),
                        size.height / max(1, textureSize.height))
        roomLayer.size = CGSize(width: textureSize.width * cover,
                                 height: textureSize.height * cover)
        roomLayer.position = .zero
        roomLayer.zPosition = 0
        dimmer.size = size
        dimmer.position = .zero
        dimmer.alpha = 0
    }

    private func layoutPrompt() {
        promptLayer.removeAllChildren()
        // A floating banner with the scene's story prompt and a small "↓"
        // hint pointing at the target zone.
        guard let action = currentAction else {
            buildPromptBanner(text: "Try touching things!")
            return
        }
        buildPromptBanner(text: storyPrompt(for: action))
    }

    private func buildPromptBanner(text: String) {
        let banner = SKShapeNode(rectOf: CGSize(width: SKLayout.cardMaxWidth(self) * 0.95, height: 56), cornerRadius: 28)
        banner.fillColor = SKTheme.ink.withAlphaComponent(0.78)
        banner.strokeColor = SKTheme.ink.withAlphaComponent(0)
        banner.position = CGPoint(x: 0, y: size.height / 2 - 70)
        promptLayer.addChild(banner)
        banner.zPosition = 0

        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = 16
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: 0)
        banner.addChild(label)

        // Pulsing arrow pointing down toward the target.
        let arrow = SKShapeNode(circleOfRadius: 8)
        arrow.fillColor = SKTheme.yellow
        arrow.strokeColor = SKTheme.ink.withAlphaComponent(0)
        arrow.position = CGPoint(x: 0, y: -banner.frame.height / 2 - 14)
        promptLayer.addChild(arrow)
        arrow.run(.repeatForever(.sequence([
            SKAction.moveBy(x: 0, y: -10, duration: 0.6),
            SKAction.moveBy(x: 0, y: 10, duration: 0.6)
        ])))
    }

    private func storyPrompt(for action: EnglishSceneAction) -> String {
        let verb: String
        switch action.mechanic {
        case .place: verb = "Move"
        case .pour: verb = "Pour"
        case .brush: verb = "Brush"
        case .scrub: verb = "Scrub"
        case .stir: verb = "Stir"
        case .fold: verb = "Fold"
        case .wear: verb = "Put on"
        case .toggleLight: verb = "Turn on"
        case .reveal: verb = "Find"
        }
        return "\(verb) the \(action.targetName.lowercased())"
    }

    private func layoutTarget() {
        targetLayer.removeAllChildren()
        guard let action = currentAction, !explorationOnly, !isPerformingAction else { return }
        let point = actionPoint(for: action.destination)
        let target = SKShapeNode(ellipseOf: CGSize(width: targetSize, height: targetSize * 0.55))
        target.fillColor = SKTheme.yellow.withAlphaComponent(0.25)
        target.strokeColor = SKTheme.yellow
        target.lineWidth = 4
        target.position = point
        target.zPosition = 0
        target.name = "target"
        targetLayer.addChild(target)

        // Soft halo behind the target.
        let halo = SKShapeNode(ellipseOf: CGSize(width: targetSize * 1.6, height: targetSize * 0.7))
        halo.fillColor = SKTheme.yellow.withAlphaComponent(0.10)
        halo.strokeColor = SKTheme.ink.withAlphaComponent(0)
        halo.position = point
        halo.zPosition = -1
        targetLayer.addChild(halo)
        halo.run(.repeatForever(.sequence([
            SKAction.scale(to: 1.10, duration: 1.2),
            SKAction.scale(to: 1.0, duration: 1.2)
        ])))

        // Label inside the target.
        let label = SKLabelNode(text: action.targetName)
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = 14
        label.fontColor = SKTheme.ink
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: 0)
        target.addChild(label)
    }

    private func layoutPip() {
        let size = min(self.size.height * 0.30, max(110, self.size.width * 0.22))
        pip.size = CGSize(width: size * 2 / 3, height: size)
        pip.position = CGPoint(x: -self.size.width * 0.32, y: -self.size.height * 0.30)
        pip.alpha = 1.0
        pip.removeAction(forKey: "idle")
        pip.run(.repeatForever(.sequence([
            .rotate(toAngle: 0.04, duration: 1.4),
            .rotate(toAngle: -0.04, duration: 1.4)
        ])), withKey: "idle")
        pip.run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 6, duration: 1.4),
            .moveBy(x: 0, y: -6, duration: 1.4)
        ])), withKey: "bob")
    }

    private func layoutItems() {
        let active = currentAction?.itemID
        let sorted = allItems.keys.sorted()
        // Hide props that don't belong to this scene's micro-story.
        for (id, node) in itemNodes {
            if !allItems.keys.contains(id) { node.isHidden = true; continue }
            let belongsToStory = sorted.first.map { _ in true } ?? true
            let inActive = id == active
            let isCompleted = completedItemIDs.contains(id)
            let inAvailable = availableIDs.contains(id)
            node.isHidden = !((inActive && inAvailable) || (!isCompleted && inAvailable && belongsToStory))
        }
        // Position visible props along a "shelf" at the bottom of the room.
        let visible = itemNodes.values.filter { !$0.isHidden }
        for (i, node) in visible.enumerated() {
            let count = max(visible.count, 1)
            let slot = CGFloat(i) - CGFloat(count - 1) / 2
            let x = slot * propSize * 1.05
            let y = -self.size.height * 0.30
            node.size = CGSize(width: propSize, height: propSize)
            node.zPosition = 10
            if node.name == draggedID { continue }
            node.removeAction(forKey: "hint")
            node.removeAction(forKey: "float")
            let id = node.name?.replacingOccurrences(of: "prop:", with: "") ?? ""
            if id == active {
                // The active prop gently bobs in place.
                node.position = CGPoint(x: x, y: y)
                node.alpha = 1.0
                node.run(.repeatForever(.sequence([
                    .moveBy(x: 0, y: -6, duration: 0.9),
                    .moveBy(x: 0, y: 6, duration: 0.9)
                ])), withKey: "float")
                addSelectionRing(to: node)
            } else {
                node.position = CGPoint(x: x, y: y)
                node.alpha = 0.85
                removeSelectionRing(from: node)
            }
            addShadow(to: node)
        }
    }

    private func addSelectionRing(to node: SKSpriteNode) {
        removeSelectionRing(from: node)
        let ring = SKShapeNode(circleOfRadius: node.size.width * 0.55)
        ring.fillColor = SKTheme.ink.withAlphaComponent(0)
        ring.strokeColor = SKTheme.yellow
        ring.lineWidth = 4
        ring.name = "selectionRing"
        ring.zPosition = -1
        ring.position = .zero
        node.addChild(ring)
        ring.run(.repeatForever(.sequence([
            SKAction.scale(to: 1.10, duration: 0.8),
            SKAction.scale(to: 1.0, duration: 0.8)
        ])))
    }

    private func removeSelectionRing(from node: SKSpriteNode) {
        node.childNode(withName: "selectionRing")?.removeFromParent()
    }

    private func addShadow(to node: SKSpriteNode) {
        if node.childNode(withName: "shadow") != nil { return }
        let shadow = SKShapeNode(ellipseOf: CGSize(width: node.size.width * 0.9,
                                                   height: node.size.height * 0.18))
        shadow.fillColor = SKTheme.ink.withAlphaComponent(0.22)
        shadow.strokeColor = SKTheme.ink.withAlphaComponent(0)
        shadow.name = "shadow"
        shadow.zPosition = -1
        shadow.position = CGPoint(x: 0, y: -node.size.height * 0.45)
        node.addChild(shadow)
    }

    private func actionPoint(for destination: CGPoint) -> CGPoint {
        // Centered band between top HUD reserve and bottom footer reserve.
        let usableTop = size.height / 2 - promptBandHeight
        let usableBottom = -size.height / 2 + footerBandHeight
        let usableHeight = usableTop - usableBottom
        let x = (destination.x - 0.5) * (size.width - propSize * 2)
        let y = usableBottom + destination.y * usableHeight
        return CGPoint(x: x, y: y)
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard inputEnabled, let touch = touches.first else { return }
        let location = touch.location(in: self)
        if let prop = propAt(location), !isPerformingAction {
            beginDrag(prop: prop, touch: touch)
            return
        }
        // If the user taps a placed prop, select it.
        if let prop = itemNodes.values.first(where: { $0.alpha > 0 && $0.contains(location) && !completedItemIDs.contains($0.name?.replacingOccurrences(of: "prop:", with: "") ?? "") }) {
            selectItem(prop.name?.replacingOccurrences(of: "prop:", with: "") ?? "")
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch), let id = draggedID else { return }
        let location = touch.location(in: self)
        itemNodes[id]?.position = location
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        defer { activeTouch = nil; draggedID = nil }
        guard let touch = activeTouch, let id = draggedID else { return }
        let location = touch.location(in: self)
        attemptPlace(itemID: id, at: location)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        cancelInteraction()
    }

    private func propAt(_ location: CGPoint) -> SKSpriteNode? {
        for (id, node) in itemNodes where node.alpha > 0 && !completedItemIDs.contains(id) {
            if node.contains(location) { return node }
        }
        return nil
    }

    private func beginDrag(prop: SKSpriteNode, touch: UITouch) {
        activeTouch = touch
        if let id = prop.name?.replacingOccurrences(of: "prop:", with: "") {
            draggedID = id
            prop.removeAction(forKey: "float")
            prop.zPosition = 12
            selectItem(id)
        }
    }

    private func cancelInteraction() {
        activeTouch = nil
        if let id = draggedID, let node = itemNodes[id] {
            node.zPosition = 10
            layoutItems()
        }
        draggedID = nil
    }

    // MARK: - Backwards-compat hooks (used by EnglishGameScene)
    func setSuspended(_ value: Bool) {
        inputEnabled = !value
        isPaused = value
    }
    func accessibleActionStep() { /* no-op for now */ }

    // MARK: - Placement

    private func attemptPlace(itemID: String, at location: CGPoint) {
        guard let node = itemNodes[itemID] else { return }
        let target = (targetLayer.childNode(withName: "target") as? SKShapeNode)?
            .convert(CGPoint(x: 0, y: 0), to: self) ?? .zero
        let hit = hypot(target.x - location.x, target.y - location.y) < targetSize
        if hit {
            // Snap to target and play a success effect.
            node.removeAllActions()
            node.position = target
            node.zPosition = 10
            completedItemIDs.insert(itemID)
            availableIDs.remove(itemID)
            spawnSuccessBurst(at: target)
            spawnTargetConfirm(at: target)
            onAttempt?(itemID)
            onSelectionChanged?(nil)
            // Reload after a short delay so the EnglishGameScene can advance.
            run(.sequence([.wait(forDuration: 0.6)])) { [weak self] in
                self?.layoutItems()
            }
        } else {
            // Bounce back to the original position.
            node.run(.sequence([
                .move(to: originalPosition(for: itemID), duration: 0.35)
            ]))
        }
    }

    private func originalPosition(for id: String) -> CGPoint {
        guard let node = itemNodes[id] else { return .zero }
        let count = max(itemNodes.values.filter { !$0.isHidden }.count, 1)
        guard let i = itemNodes.values.filter({ !$0.isHidden }).firstIndex(of: node) else { return .zero }
        let slot = CGFloat(i) - CGFloat(count - 1) / 2
        let x = slot * propSize * 1.05
        let y = -self.size.height * 0.30
        return CGPoint(x: x, y: y)
    }

    private func selectItem(_ id: String) {
        selectedItemID = id
        onSelectionChanged?(id)
    }

    // MARK: - Effects

    private func spawnSuccessBurst(at point: CGPoint) {
        for _ in 0..<12 {
            let confetti = SKShapeNode(rectOf: CGSize(width: 8, height: 14), cornerRadius: 2)
            confetti.fillColor = [SKTheme.pink, .systemTeal, SKTheme.yellow, SKTheme.purple, SKTheme.orange]
                .randomElement() ?? SKTheme.pink
            confetti.strokeColor = .clear
            confetti.position = point
            confetti.zPosition = 40
            effectsLayer.addChild(confetti)
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 80...160)
            let target = CGPoint(x: point.x + cos(angle) * dist, y: point.y + sin(angle) * dist)
            confetti.run(.sequence([
                .group([
                    .move(to: target, duration: 0.9),
                    .rotate(byAngle: CGFloat.random(in: -6...6), duration: 0.9)
                ]),
                .fadeOut(withDuration: 0.2),
                .removeFromParent()
            ]))
        }
        // Stars/sparkles
        for _ in 0..<6 {
            let star = SKShapeNode(circleOfRadius: 5)
            star.fillColor = SKTheme.yellow
            star.strokeColor = .clear
            star.position = point
            star.zPosition = 41
            effectsLayer.addChild(star)
            let target = CGPoint(x: point.x + CGFloat.random(in: -60...60),
                                 y: point.y + CGFloat.random(in: 40...120))
            star.run(.sequence([
                .group([.move(to: target, duration: 0.7), .scale(to: 0.1, duration: 0.7)]),
                .removeFromParent()
            ]))
        }
    }

    private func spawnTargetConfirm(at point: CGPoint) {
        let ring = SKShapeNode(circleOfRadius: targetSize * 0.6)
        ring.fillColor = .clear
        ring.strokeColor = SKTheme.green
        ring.lineWidth = 6
        ring.position = point
        ring.zPosition = 9
        effectsLayer.addChild(ring)
        ring.run(.sequence([
            .group([.scale(to: 1.5, duration: 0.4), .fadeOut(withDuration: 0.4)]),
            .removeFromParent()
        ]))
    }
}