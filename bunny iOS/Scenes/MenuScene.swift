import SpriteKit
import UIKit

/// Main menu — Pip's World level path. Shows a winding path of level
/// nodes (one per LevelDefinition). Each node is in one of three
/// states: locked (gray, no number), current (Pip hovers here,
/// pulsing), or completed (gold star inside). Tap an unlocked level
/// to enter it. Three area tabs at the top switch between Math /
/// English / Life Skills.
///
/// Pillar 1 (Calm): pastel palette, slow drift, gentle pulse.
/// Pillar 4 (Privacy): everything local; nothing leaves the device.
/// Pillar 5 (Adult-gated): "For Grown-Ups" pill is visually separate
/// from the kid-facing path.
///
/// Storage strategy: nothing is stored as a class property. Every node
/// is created locally in `buildXxx()` and rebuilt on `didChangeSize`.
/// This sidesteps the "SKNode already has a parent" crash that bites
/// re-entrant `didMove → didMove` chains.
final class MenuScene: SKScene {

    private var observation: NSObjectProtocol?

    // MARK: - State

    private enum AreaFilter: Int, CaseIterable {
        case math, english, lifeSkills
        var title: String {
            switch self {
            case .math:       return "Math Kingdom"
            case .english:    return "English Village"
            case .lifeSkills: return "Life Skills Garden"
            }
        }
        var tint: UIColor {
            switch self {
            case .math:       return SKTheme.blue
            case .english:    return SKTheme.orange
            case .lifeSkills: return SKTheme.green
            }
        }
    }
    private var activeFilter: AreaFilter = .math

    // Cached positions for the level path (rebuilt per layout).
    // Each entry: (levelID, x, y, state)
    private struct LevelNode {
        let level: LevelDefinition
        let position: CGPoint
        let state: NodeState
        enum NodeState { case locked, current, completed }
    }
    private var nodes: [LevelNode] = []

    private var levelNodesParent: SKNode?
    private var areaTabsParent: SKNode?
    private var pipAvatar: SKSpriteNode?
    private var pipShadow: SKShapeNode?
    private var pipHalo: SKShapeNode?
    private var starTallyText: SKLabel?

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKTheme.cream

        // Sky → cream → grass gradient with floating pastel motes.
        SKAmbient.install(in: self, config: SKAmbient.Configuration(
            particleCount: 32,
            palette: [
                UIColor.white.withAlphaComponent(0.85),
                SKTheme.yellow.withAlphaComponent(0.55),
                SKTheme.pink.withAlphaComponent(0.45),
                SKTheme.green.withAlphaComponent(0.30),
            ],
            backgroundGradient: [
                UIColor(red: 0.82, green: 0.90, blue: 0.99, alpha: 1.0),
                SKTheme.cream,
                SKTheme.green.withAlphaComponent(0.30),
            ],
            driftSpeed: 7
        ))

        buildHeader()
        buildAreaTabs()
        rebuildPath()
        buildFooter()
        buildPipAvatar()
        buildParentButton()

        observation = NotificationCenter.default.addObserver(
            forName: .progressStoreDidChange, object: nil, queue: .main
        ) { [weak self] _ in self?.refreshProgress() }
        refreshProgress()

        SpeechService.shared.speak("Hello! Pick a level to play.")
        Feedback.shared.tap()
    }

    deinit { if let observation { NotificationCenter.default.removeObserver(observation) } }

    override func didChangeSize(_ oldSize: CGSize) {
        removeAllChildren()
        SKAmbient.uninstall(from: self)
        nodes = []
        levelNodesParent = nil
        areaTabsParent = nil
        pipAvatar = nil
        pipShadow = nil
        pipHalo = nil
        starTallyText = nil
        didMove(to: SKView())
    }

    // MARK: - Header

    private func buildHeader() {
        let safeTop = SKLayout.safeTop(self)

        // Title — small, centered, never overflows.
        let title = SKLabelNode(text: "Pip's World")
        title.fontName = "AvenirNext-Heavy"
        title.fontSize = 26
        title.fontColor = SKTheme.ink
        title.horizontalAlignmentMode = .center
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: 0, y: safeTop - 50)
        addChild(title)

        // Subtitle — also centered.
        let sub = SKLabelNode(text: "Tap a level to play")
        sub.fontName = "AvenirNext-Medium"
        sub.fontSize = 13
        sub.fontColor = SKTheme.ink.withAlphaComponent(0.6)
        sub.horizontalAlignmentMode = .center
        sub.verticalAlignmentMode = .center
        sub.position = CGPoint(x: 0, y: safeTop - 78)
        addChild(sub)
    }

    // MARK: - Area tabs

    private func buildAreaTabs() {
        let safeTop = SKLayout.safeTop(self)
        let safeWidth = SKLayout.safeWidth(self)
        let tabY = safeTop - 115
        let tabs = SKNode()
        tabs.position = .zero
        addChild(tabs)
        areaTabsParent = tabs

        let tabWidth: CGFloat = (safeWidth - 24) / 3
        let tabHeight: CGFloat = 36
        let xs: [CGFloat] = [
            -safeWidth / 2 + 12 + tabWidth / 2,
            0,
            safeWidth / 2 - 12 - tabWidth / 2,
        ]
        // Short labels so the pill never wraps — caused the duplicate
        // appearance in the previous build because the pill's height was
        // anchored and the text overflowed visually.
        let shortLabels: [AreaFilter: String] = [
            .math:       "Math",
            .english:    "English",
            .lifeSkills: "Life Skills",
        ]
        for (i, area) in AreaFilter.allCases.enumerated() {
            let pill = SKShapeNode(rectOf: CGSize(width: tabWidth - 8, height: tabHeight),
                                    cornerRadius: tabHeight / 2)
            pill.fillColor = activeFilter == area
                ? area.tint.withAlphaComponent(0.18)
                : SKTheme.paper
            pill.strokeColor = activeFilter == area
                ? area.tint
                : SKTheme.ink.withAlphaComponent(0.15)
            pill.lineWidth = activeFilter == area ? 2 : 1
            pill.position = CGPoint(x: xs[i], y: tabY)
            pill.userData = NSMutableDictionary()
            pill.userData?["area"] = area.rawValue
            tabs.addChild(pill)

            let label = SKLabelNode(text: shortLabels[area]!)
            label.fontName = activeFilter == area ? "AvenirNext-Heavy" : "AvenirNext-DemiBold"
            label.fontSize = 13
            label.fontColor = activeFilter == area ? area.tint : SKTheme.ink.withAlphaComponent(0.7)
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.position = CGPoint(x: xs[i], y: tabY)
            tabs.addChild(label)

            let tap = UITapGestureRecognizer(target: self,
                                             action: #selector(handleAreaTap(_:)))
            pill.addGestureRecognizer(tap)
        }
    }

    @objc private func handleAreaTap(_ recognizer: UITapGestureRecognizer) {
        guard let skView = self.view,
              let viewPoint = recognizer.location(in: skView) as CGPoint?,
              let scenePoint = skView.convert(viewPoint, to: self) as CGPoint? else { return }
        let tappedNodes = self.nodes(at: scenePoint)
        guard let tapped = tappedNodes.first(where: { $0.userData?["area"] != nil }),
              let raw = tapped.userData?["area"] as? Int,
              let next = AreaFilter(rawValue: raw) else { return }
        guard next != activeFilter else { return }
        Feedback.shared.tap()
        activeFilter = next
        // Rebuild everything that depends on the filter.
        areaTabsParent?.removeFromParent()
        levelNodesParent?.removeFromParent()
        pipAvatar?.removeFromParent()
        pipShadow?.removeFromParent()
        pipHalo?.removeFromParent()
        buildAreaTabs()
        rebuildPath()
        buildPipAvatar()
    }

    // MARK: - Path / level nodes

    private func rebuildPath() {
        let store = ProgressStore.shared
        let levels = Curriculum.levels(in: filterArea)
        let safeTop = SKLayout.safeTop(self)
        let safeBottom = SKLayout.safeBottom(self)
        let safeWidth = SKLayout.safeWidth(self)

        // Path bounds (vertical band). Start below the tabs (which sit
        // around safeTop - 115) and above the footer at safeBottom + 50.
        // The first level node's avatar halo sits ~102pt above the path
        // top — push the path down so the halo never bleeds into the tab
        // row above.
        let pathTop = safeTop - 290
        let pathBottom = safeBottom + 160
        let pathHeight = pathTop - pathBottom
        let pathMidX = 0.0
        let pathSwayAmp = min(safeWidth * 0.32, 130)

        // Group container so we can rebuild cleanly.
        let container = SKNode()
        container.position = .zero
        addChild(container)
        levelNodesParent = container

        // 1. Draw the path ribbon (a curving cream stripe behind the
        //    nodes — gives the eye a visual "track" to follow).
        let ribbon = makePathRibbon(width: 26, top: pathTop,
                                     bottom: pathBottom,
                                     midX: pathMidX, sway: pathSwayAmp,
                                     tint: activeFilter.tint)
        container.addChild(ribbon)

        // 2. Place one node per level on the sine path.
        nodes = []
        let n = levels.count
        guard n > 0 else { return }
        for (i, level) in levels.enumerated() {
            let t = CGFloat(i) / CGFloat(max(1, n - 1))
            // Sinuous curve: 1.5 full waves across the path.
            let x = pathMidX + sin(t * .pi * 1.6) * pathSwayAmp
            let y = pathTop - t * pathHeight
            let state = computeState(level: level, store: store, totalCount: n)
            let node = makeLevelNode(level: level, state: state, tint: activeFilter.tint, at: CGPoint(x: x, y: y))
            container.addChild(node)

            let tap = UITapGestureRecognizer(target: self,
                                             action: #selector(handleLevelTap(_:)))
            node.addGestureRecognizer(tap)
            node.userData = NSMutableDictionary()
            node.userData?["levelID"] = level.id

            nodes.append(LevelNode(level: level, position: CGPoint(x: x, y: y), state: state))
        }
    }

    private func makePathRibbon(width: CGFloat,
                                top: CGFloat,
                                bottom: CGFloat,
                                midX: CGFloat,
                                sway: CGFloat,
                                tint: UIColor) -> SKNode {
        let path = UIBezierPath()
        let n = 40
        let dy = (top - bottom) / CGFloat(max(1, n - 1))
        let half = width / 2
        var points: [CGPoint] = []
        for i in 0..<n {
            let t = CGFloat(i) / CGFloat(max(1, n - 1))
            let x = midX + sin(t * .pi * 1.6) * sway
            let y = top - CGFloat(i) * dy
            points.append(CGPoint(x: x, y: y))
        }
        path.move(to: CGPoint(x: points[0].x, y: points[0].y + half))
        for p in points {
            path.addLine(to: CGPoint(x: p.x, y: p.y + half))
        }
        for p in points.reversed() {
            path.addLine(to: CGPoint(x: p.x, y: p.y - half))
        }
        path.close()
        let shape = SKShapeNode(path: path.cgPath, centered: false)
        shape.fillColor = tint.withAlphaComponent(0.10)
        shape.strokeColor = tint.withAlphaComponent(0.35)
        shape.lineWidth = 1.5
        return shape
    }

    private func computeState(level: LevelDefinition,
                               store: ProgressStore,
                               totalCount: Int) -> LevelNode.NodeState {
        if store.completed.contains(level.id) {
            return .completed
        }
        // Find the first not-completed level IN THE CURRENT FILTER.
        // store.recommendedLevel is global, not filter-local, so we
        // recompute per-area.
        let areaLevels = Curriculum.levels(in: filterArea)
        if let current = areaLevels.first(where: { !store.completed.contains($0.id) }),
           current.id == level.id {
            return .current
        }
        // Not completed and not current → locked.
        return .locked
    }

    private func makeLevelNode(level: LevelDefinition,
                                state: LevelNode.NodeState,
                                tint: UIColor,
                                at position: CGPoint) -> SKNode {
        let node: SKNode
        let isLocked = state == .locked
        let isCompleted = state == .completed
        let isCurrent = state == .current

        let radius: CGFloat = isCurrent ? 26 : 22
        let circle = SKShapeNode(circleOfRadius: radius)
        if isLocked {
            circle.fillColor = SKTheme.ink.withAlphaComponent(0.08)
            circle.strokeColor = SKTheme.ink.withAlphaComponent(0.18)
        } else if isCompleted {
            circle.fillColor = SKTheme.yellow
            circle.strokeColor = SKTheme.orange
        } else {
            // Current
            circle.fillColor = tint
            circle.strokeColor = tint
        }
        circle.lineWidth = 3
        node = circle
        node.position = position
        node.alpha = isLocked ? 0.55 : 1.0

        if !isLocked {
            let num = SKLabelNode(text: level.id.replacingOccurrences(of: "L", with: "")
                                                     .replacingOccurrences(of: "M", with: "")
                                                     .replacingOccurrences(of: "E", with: ""))
            num.fontName = "AvenirNext-Heavy"
            num.fontSize = isCurrent ? 18 : 14
            num.fontColor = isCompleted ? SKTheme.ink : .white
            num.verticalAlignmentMode = .center
            num.horizontalAlignmentMode = .center
            num.position = .zero
            node.addChild(num)
        }

        if isCompleted {
            // Gold star icon to make completion unmistakable.
            let star = SKLabelNode(text: "★")
            star.fontSize = 18
            star.fontColor = SKTheme.orange
            star.verticalAlignmentMode = .center
            star.horizontalAlignmentMode = .center
            star.position = .zero
            star.zPosition = 1
            node.addChild(star)
        }

        if isCurrent {
            // Soft pulse so the current level reads as "tap me now".
            circle.run(.repeatForever(.sequence([
                SKAction.scale(to: 1.10, duration: 0.9),
                SKAction.scale(to: 1.00, duration: 0.9),
            ])))
        }

        // Subtle shadow underneath the node for depth.
        let shadow = SKShapeNode(circleOfRadius: radius)
        shadow.fillColor = SKTheme.ink.withAlphaComponent(0.10)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -2)
        shadow.zPosition = -1
        node.addChild(shadow)

        return node
    }

    @objc private func handleLevelTap(_ recognizer: UITapGestureRecognizer) {
        guard let skView = self.view else { return }
        let viewPoint = recognizer.location(in: skView)
        let scenePoint = skView.convert(viewPoint, to: self)
        let tappedNodes = self.nodes(at: scenePoint)
        guard let tapped = tappedNodes.first(where: { $0.userData?["levelID"] != nil }),
              let id = tapped.userData?["levelID"] as? String,
              let level = Curriculum.levels.first(where: { $0.id == id }) else { return }
        // Locked levels ignore taps.
        if !ProgressStore.shared.completed.contains(level.id) {
            let isUnlocked = isUnlocked(level: level)
            if !isUnlocked {
                Feedback.shared.tryAgain()
                return
            }
        }
        Feedback.shared.tap()
        SceneRouter.shared.goScene(level: level)
    }

    private func isUnlocked(level: LevelDefinition) -> Bool {
        let store = ProgressStore.shared
        let areaLevels = Curriculum.levels(in: filterArea)
        guard let idx = areaLevels.firstIndex(of: level) else { return false }
        if idx == 0 { return true }
        return store.completed.contains(areaLevels[idx - 1].id)
            || store.recommendedLevel.id == level.id
    }

    private var filterArea: LearningArea {
        switch activeFilter {
        case .math: return .math
        case .english: return .english
        case .lifeSkills: return .lifeSkills
        }
    }

    // MARK: - Pip avatar (hovers above the current node)

    private func buildPipAvatar() {
        // Find the current node position.
        guard let currentNode = nodes.first(where: { $0.state == .current }) else {
            return
        }
        let pos = currentNode.position

        let halo = SKShapeNode(circleOfRadius: 38)
        halo.fillColor = SKTheme.yellow.withAlphaComponent(0.55)
        halo.strokeColor = .clear
        halo.position = CGPoint(x: pos.x, y: pos.y + 64)
        addChild(halo)
        pipHalo = halo

        // Soft shadow under Pip
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 50, height: 10))
        shadow.fillColor = SKTheme.ink.withAlphaComponent(0.16)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: pos.x, y: pos.y + 40)
        addChild(shadow)
        pipShadow = shadow

        let pip = SKSpriteNode(texture: SKTexture(imageNamed: "PipWorldSprite"))
        let h: CGFloat = 56
        pip.size = CGSize(width: h * 2 / 3, height: h)
        pip.position = CGPoint(x: pos.x, y: pos.y + 64)
        addChild(pip)
        pipAvatar = pip

        // Idle bob + slight horizontal sway.
        pip.run(.repeatForever(.sequence([
            SKAction.moveBy(x: 0, y: -5, duration: 1.2),
            SKAction.moveBy(x: 0, y: 5, duration: 1.2),
        ])))
        halo.run(.repeatForever(.sequence([
            SKAction.scale(to: 1.08, duration: 1.6),
            SKAction.scale(to: 1.00, duration: 1.6),
        ])))
        shadow.run(.repeatForever(.sequence([
            SKAction.scaleX(to: 1.10, duration: 1.2),
            SKAction.scaleX(to: 0.90, duration: 1.2),
        ])))
    }

    // MARK: - Footer

    private func buildFooter() {
        let safeWidth = SKLayout.safeWidth(self)
        let safeBottom = SKLayout.safeBottom(self)

        let card = SKCard(width: 200, height: 56, cornerRadius: 28,
                          fill: SKTheme.paper)
        card.position = CGPoint(x: -safeWidth * 0.30, y: safeBottom + 50)
        addChild(card)

        let stars = SKHUD.makeStars(filled: 0, size: 16, spacing: 4)
        stars.position = CGPoint(x: -45, y: 4)
        card.addChild(stars)

        let tally = SKLabel(text: "0 / 150", style: .caption,
                            color: SKTheme.ink.withAlphaComponent(0.75))
        tally.fontSize = 12
        tally.position = CGPoint(x: 0, y: -12)
        tally.horizontalAlignmentMode = .center
        card.addChild(tally)
        starTallyText = tally
    }

    private func buildParentButton() {
        let safeWidth = SKLayout.safeWidth(self)
        let safeBottom = SKLayout.safeBottom(self)

        let pill = SKShapeNode(rectOf: CGSize(width: 240, height: 56),
                                cornerRadius: 28)
        pill.fillColor = SKTheme.purple.withAlphaComponent(0.85)
        pill.strokeColor = .clear
        pill.lineWidth = 0
        pill.position = CGPoint(x: safeWidth * 0.30, y: safeBottom + 50)
        addChild(pill)

        let label = SKLabelNode(text: "For Grown-Ups")
        label.fontName = "AvenirNext-DemiBold"
        label.fontSize = 16
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = .zero
        pill.addChild(label)

        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(handleParent))
        pill.addGestureRecognizer(tap)
    }

    // MARK: - Actions

    @objc private func handleParent() {
        Feedback.shared.tap()
        SceneRouter.shared.goParentGate()
    }

    private func refreshProgress() {
        let store = ProgressStore.shared
        starTallyText?.text = "\(store.totalStars) / 150"
    }
}
