import SpriteKit
import UIKit

/// Immersive world map for Pip's World.
///
/// The menu is intentionally composed from independent layers: an ambient
/// world, moving decorations, chapter islands, context illustrations, and
/// individual lesson portals. Progress and the selected learning area change
/// those elements without changing the navigation model.
final class MenuScene: SKScene {

    private var observation: NSObjectProtocol?
    private var didBuildOnce = false

    private enum AreaFilter: Int, CaseIterable {
        case math, english, lifeSkills

        var title: String {
            switch self {
            case .math: return "Math"
            case .english: return "English"
            case .lifeSkills: return "Life Skills"
            }
        }

        var tint: UIColor {
            switch self {
            case .math: return SKTheme.blue
            case .english: return SKTheme.orange
            case .lifeSkills: return SKTheme.green
            }
        }

        var area: LearningArea {
            switch self {
            case .math: return .math
            case .english: return .english
            case .lifeSkills: return .lifeSkills
            }
        }
    }

    private enum PortalState {
        case locked, current, completed
    }

    private var activeFilter: AreaFilter = .math
    private var areaTabsParent: SKNode?
    private var worldParent: SKNode?
    private var starTallyText: SKLabel?

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKTheme.cream
        guard !didBuildOnce else { return }
        didBuildOnce = true

        SKAmbient.install(in: self, config: SKAmbient.Configuration(
            particleCount: 32,
            palette: [
                UIColor.white.withAlphaComponent(0.85),
                SKTheme.yellow.withAlphaComponent(0.48),
                SKTheme.pink.withAlphaComponent(0.35),
                SKTheme.green.withAlphaComponent(0.24),
            ],
            backgroundGradient: [
                UIColor(red: 0.82, green: 0.90, blue: 0.99, alpha: 1),
                SKTheme.cream,
                SKTheme.green.withAlphaComponent(0.24),
            ],
            driftSpeed: 6
        ))

        buildHeader()
        buildAreaTabs()
        rebuildWorldMap()
        buildFooter()

        observation = NotificationCenter.default.addObserver(
            forName: .progressStoreDidChange, object: nil, queue: .main
        ) { [weak self] _ in self?.refreshProgress() }

        refreshProgress()
        SpeechService.shared.speak("Hello! Pick a place to explore.")
        Feedback.shared.tap()
    }

    deinit {
        if let observation { NotificationCenter.default.removeObserver(observation) }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        if let observation {
            NotificationCenter.default.removeObserver(observation)
            self.observation = nil
        }
        didBuildOnce = false
        removeAllChildren()
        SKAmbient.uninstall(from: self)
        areaTabsParent = nil
        worldParent = nil
        starTallyText = nil
        didMove(to: SKView())
    }

    // MARK: - Header and filters

    private func buildHeader() {
        let safeTop = SKLayout.safeTop(self)

        let title = SKLabelNode(text: "Pip's World")
        title.fontName = "AvenirNext-Heavy"
        title.fontSize = 28
        title.fontColor = SKTheme.ink
        title.horizontalAlignmentMode = .center
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: 0, y: safeTop - 34)
        addChild(title)

        let subtitle = SKLabelNode(text: "Explore a living world of little discoveries")
        subtitle.fontName = "AvenirNext-Medium"
        subtitle.fontSize = 12.5
        subtitle.fontColor = SKTheme.ink.withAlphaComponent(0.62)
        subtitle.horizontalAlignmentMode = .center
        subtitle.verticalAlignmentMode = .center
        subtitle.position = CGPoint(x: 0, y: safeTop - 60)
        addChild(subtitle)

        // Small "Replay intro" link in the top-right so kids who skipped
        // onboarding can still meet Pip. Routes to WelcomeScene; the
        // onboardingComplete flag is independent of this — replaying the
        // intro doesn't reset progress.
        let replay = SKLabelNode(text: "Replay intro ↻")
        replay.fontName = "AvenirNext-DemiBold"
        replay.fontSize = 13
        replay.fontColor = SKTheme.blue
        replay.verticalAlignmentMode = .center
        replay.horizontalAlignmentMode = .right
        replay.position = CGPoint(x: SKLayout.safeRight(self) - 14, y: safeTop - 34)
        replay.name = "replay-intro"
        addChild(replay)
        let replayTap = UITapGestureRecognizer(target: self, action: #selector(handleReplayIntro))
        replayTap.name = "replay-intro"
        addGestureRecognizer(replayTap)
    }

    @objc private func handleReplayIntro(_ recognizer: UITapGestureRecognizer) {
        guard recognizer.name == "replay-intro" else { return }
        SceneRouter.shared.goWelcome()
    }

    private func buildAreaTabs() {
        let safeTop = SKLayout.safeTop(self)
        let safeWidth = SKLayout.safeWidth(self)
        let tabY = safeTop - 104
        let tabHeight: CGFloat = 44
        let gap: CGFloat = 8
        let tabWidth = (safeWidth - gap * 2) / 3
        let tabs = SKNode()
        addChild(tabs)
        areaTabsParent = tabs

        for (index, area) in AreaFilter.allCases.enumerated() {
            let x = -safeWidth / 2 + tabWidth / 2 + CGFloat(index) * (tabWidth + gap)
            let pill = SKShapeNode(rectOf: CGSize(width: tabWidth, height: tabHeight),
                                    cornerRadius: tabHeight / 2)
            let selected = activeFilter == area
            pill.fillColor = selected ? area.tint.withAlphaComponent(0.18) : SKTheme.paper
            pill.strokeColor = selected ? area.tint : SKTheme.ink.withAlphaComponent(0.14)
            pill.lineWidth = selected ? 2.2 : 1
            pill.position = CGPoint(x: x, y: tabY)
            pill.userData = NSMutableDictionary()
            pill.userData?["area"] = area.rawValue
            tabs.addChild(pill)

            let label = SKLabelNode(text: area.title)
            label.fontName = selected ? "AvenirNext-Heavy" : "AvenirNext-DemiBold"
            label.fontSize = area == .lifeSkills ? 11 : 13
            label.fontColor = selected ? area.tint : SKTheme.ink.withAlphaComponent(0.72)
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.position = CGPoint(x: x, y: tabY)
            tabs.addChild(label)

            let tap = UITapGestureRecognizer(target: self, action: #selector(handleAreaTap(_:)))
            pill.addGestureRecognizer(tap)
        }
    }

    @objc private func handleAreaTap(_ recognizer: UITapGestureRecognizer) {
        guard let skView = self.view else { return }
        let scenePoint = skView.convert(recognizer.location(in: skView), to: self)
        guard let tapped = nodes(at: scenePoint).first(where: { $0.userData?["area"] != nil }),
              let raw = tapped.userData?["area"] as? Int,
              let next = AreaFilter(rawValue: raw),
              next != activeFilter else { return }

        Feedback.shared.tap()
        activeFilter = next
        areaTabsParent?.removeFromParent()
        buildAreaTabs()
        rebuildWorldMap()
    }

    // MARK: - World map

    private func rebuildWorldMap() {
        worldParent?.removeFromParent()
        worldParent = nil

        let levels = Curriculum.levels(in: activeFilter.area)
        guard !levels.isEmpty else { return }

        let safeTop = SKLayout.safeTop(self)
        let safeBottom = SKLayout.safeBottom(self)
        let safeWidth = SKLayout.safeWidth(self)
        let worldTop = safeTop - 140
        let worldBottom = safeBottom + 72
        let worldHeight = max(420, worldTop - worldBottom)
        let worldCenterY = (worldTop + worldBottom) / 2
        let mapWidth = safeWidth - 20

        let world = SKNode()
        world.position = CGPoint(x: 0, y: worldCenterY)
        addChild(world)
        worldParent = world

        let surface = SKShapeNode(rectOf: CGSize(width: mapWidth, height: worldHeight), cornerRadius: 30)
        surface.fillColor = SKTheme.paper.withAlphaComponent(0.36)
        surface.strokeColor = activeFilter.tint.withAlphaComponent(0.20)
        surface.lineWidth = 1.5
        world.addChild(surface)

        buildWorldDecor(in: world, mapWidth: mapWidth, mapHeight: worldHeight)

        let mapTitle = SKLabelNode(text: activeFilter.title + " world")
        mapTitle.fontName = "AvenirNext-Heavy"
        mapTitle.fontSize = 14
        mapTitle.fontColor = activeFilter.tint
        mapTitle.horizontalAlignmentMode = .center
        mapTitle.verticalAlignmentMode = .center
        mapTitle.position = CGPoint(x: 0, y: worldHeight / 2 - 22)
        world.addChild(mapTitle)

        let pip = SKSpriteNode(texture: SKTexture(imageNamed: "PipWorldSprite"))
        let pipTextureSize = pip.texture?.size() ?? .zero
        if pipTextureSize.width > 0, pipTextureSize.height > 0 {
            let scale = min(30 / pipTextureSize.width, 48 / pipTextureSize.height)
            pip.size = CGSize(width: pipTextureSize.width * scale,
                              height: pipTextureSize.height * scale)
            pip.position = CGPoint(x: mapWidth / 2 - 34, y: worldHeight / 2 - 26)
            pip.zPosition = 2
            world.addChild(pip)
            pip.run(.repeatForever(.sequence([
                .moveBy(x: 0, y: 4, duration: 1.1),
                .moveBy(x: 0, y: -4, duration: 1.1),
            ])))
        }

        let chapterSize = 5
        let chapterCount = Int(ceil(Double(levels.count) / Double(chapterSize)))
        let columns = SKLayout.isLandscape(self) ? min(3, chapterCount) : min(2, chapterCount)
        let gap: CGFloat = 10
        let cardHeight: CGFloat = SKLayout.isLandscape(self) ? 146 : 166
        let cardWidth = (mapWidth - 24 - CGFloat(columns - 1) * gap) / CGFloat(columns)
        let totalWidth = CGFloat(columns) * cardWidth + CGFloat(columns - 1) * gap
        let leftX = -totalWidth / 2 + cardWidth / 2
        let topLocalY = worldHeight / 2 - 42 - cardHeight / 2

        for chapterIndex in 0..<chapterCount {
            let start = chapterIndex * chapterSize
            let end = min(start + chapterSize, levels.count)
            let chapterLevels = Array(levels[start..<end])
            let row = chapterIndex / columns
            let column = chapterIndex % columns
            let position = CGPoint(
                x: leftX + CGFloat(column) * (cardWidth + gap),
                y: topLocalY - CGFloat(row) * (cardHeight + gap)
            )
            let chapter = makeChapterCard(levels: chapterLevels,
                                          chapterIndex: chapterIndex,
                                          width: cardWidth,
                                          height: cardHeight)
            chapter.position = position
            world.addChild(chapter)
        }
    }

    private func buildWorldDecor(in world: SKNode, mapWidth: CGFloat, mapHeight: CGFloat) {
        let tint = activeFilter.tint

        let riverPath = CGMutablePath()
        riverPath.move(to: CGPoint(x: -mapWidth * 0.52, y: -mapHeight * 0.20))
        riverPath.addCurve(to: CGPoint(x: mapWidth * 0.52, y: mapHeight * 0.18),
                           control1: CGPoint(x: -mapWidth * 0.12, y: -mapHeight * 0.42),
                           control2: CGPoint(x: mapWidth * 0.08, y: mapHeight * 0.42))
        let river = SKShapeNode(path: riverPath)
        river.strokeColor = tint.withAlphaComponent(0.12)
        river.lineWidth = 30
        river.lineCap = .round
        river.zPosition = -3
        world.addChild(river)

        for index in 0..<4 {
            let island = SKShapeNode(ellipseOf: CGSize(width: 150, height: 48))
            island.fillColor = (index.isMultiple(of: 2) ? SKTheme.green : tint).withAlphaComponent(0.14)
            island.strokeColor = .clear
            island.position = CGPoint(
                x: CGFloat(index % 2 == 0 ? -1 : 1) * (mapWidth * 0.28),
                y: -mapHeight * 0.34 + CGFloat(index / 2) * 42
            )
            island.zPosition = -2
            world.addChild(island)
        }

        for (index, position) in [
            CGPoint(x: -mapWidth * 0.34, y: mapHeight * 0.38),
            CGPoint(x: mapWidth * 0.34, y: mapHeight * 0.34),
            CGPoint(x: mapWidth * 0.40, y: -mapHeight * 0.30),
        ].enumerated() {
            let cloud = makeCloud()
            cloud.position = position
            cloud.alpha = 0.70
            cloud.zPosition = -1
            world.addChild(cloud)
            let direction: CGFloat = index.isMultiple(of: 2) ? 1 : -1
            cloud.run(.repeatForever(.sequence([
                .moveBy(x: direction * 18, y: 3, duration: 3.5 + Double(index)),
                .moveBy(x: -direction * 18, y: -3, duration: 3.5 + Double(index)),
            ])))
        }

        for index in 0..<10 {
            let mote = SKShapeNode(circleOfRadius: index.isMultiple(of: 3) ? 3 : 2)
            mote.fillColor = [SKTheme.yellow, SKTheme.pink, tint][index % 3].withAlphaComponent(0.45)
            mote.strokeColor = .clear
            mote.position = CGPoint(
                x: -mapWidth * 0.42 + CGFloat((index * 47) % 90) / 90 * mapWidth * 0.84,
                y: -mapHeight * 0.38 + CGFloat((index * 61) % 80) / 80 * mapHeight * 0.76
            )
            mote.zPosition = -1
            world.addChild(mote)
            mote.run(.repeatForever(.sequence([
                .moveBy(x: 0, y: 5 + CGFloat(index % 3) * 3, duration: 1.8 + Double(index % 4) * 0.3),
                .moveBy(x: 0, y: -5 - CGFloat(index % 3) * 3, duration: 1.8 + Double(index % 4) * 0.3),
            ])))
        }
    }

    private func makeCloud() -> SKNode {
        let cloud = SKNode()
        let base = SKShapeNode(rectOf: CGSize(width: 58, height: 14), cornerRadius: 7)
        base.fillColor = UIColor.white.withAlphaComponent(0.72)
        base.strokeColor = .clear
        cloud.addChild(base)
        let puffs: [(CGFloat, CGFloat)] = [(-18, 10), (0, 15), (18, 9)]
        for (x, radius) in puffs {
            let puff = SKShapeNode(circleOfRadius: radius)
            puff.fillColor = UIColor.white.withAlphaComponent(0.72)
            puff.strokeColor = UIColor.clear
            puff.position = CGPoint(x: x, y: 7)
            cloud.addChild(puff)
        }
        return cloud
    }

    private func makeChapterCard(levels: [LevelDefinition],
                                 chapterIndex: Int,
                                 width: CGFloat,
                                 height: CGFloat) -> SKNode {
        let card = SKCard(width: width, height: height, cornerRadius: 22,
                          fill: SKTheme.paper.withAlphaComponent(0.92),
                          stroke: activeFilter.tint.withAlphaComponent(0.26))

        let imageBack = SKShapeNode(ellipseOf: CGSize(width: 86, height: 48))
        imageBack.fillColor = activeFilter.tint.withAlphaComponent(0.18)
        imageBack.strokeColor = .clear
        imageBack.position = CGPoint(x: -width / 2 + 46, y: 34)
        card.addChild(imageBack)

        if let imageName = contextAsset(for: activeFilter.area, chapterIndex: chapterIndex) {
            let sprite = SKSpriteNode(texture: SKTexture(imageNamed: imageName))
            let textureSize = sprite.texture?.size() ?? .zero
            if textureSize.width > 0, textureSize.height > 0 {
                let scale = min(64 / textureSize.width, 46 / textureSize.height)
                sprite.size = CGSize(width: textureSize.width * scale, height: textureSize.height * scale)
                sprite.position = imageBack.position
                sprite.zPosition = 1
                card.addChild(sprite)
                sprite.run(.repeatForever(.sequence([
                    .moveBy(x: 0, y: 3, duration: 1.7),
                    .moveBy(x: 0, y: -3, duration: 1.7),
                ])))
            }
        }

        let chapterLabel = SKLabelNode(text: "CHAPTER " + String(chapterIndex + 1))
        chapterLabel.fontName = "AvenirNext-Heavy"
        chapterLabel.fontSize = 8
        chapterLabel.fontColor = activeFilter.tint
        chapterLabel.horizontalAlignmentMode = .left
        chapterLabel.verticalAlignmentMode = .center
        chapterLabel.position = CGPoint(x: -width / 2 + 82, y: 51)
        card.addChild(chapterLabel)

        let title = SKLabelNode(text: chapterTitle(for: activeFilter.area, index: chapterIndex))
        title.fontName = "AvenirNext-Heavy"
        title.fontSize = 13
        title.fontColor = SKTheme.ink
        title.horizontalAlignmentMode = .left
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: -width / 2 + 82, y: 32)
        card.addChild(title)

        let completedCount = levels.filter { ProgressStore.shared.completed.contains($0.id) }.count
        let progress = SKLabelNode(text: String(completedCount) + "/" + String(levels.count))
        progress.fontName = "AvenirNext-DemiBold"
        progress.fontSize = 10
        progress.fontColor = SKTheme.ink.withAlphaComponent(0.55)
        progress.horizontalAlignmentMode = .left
        progress.verticalAlignmentMode = .center
        progress.position = CGPoint(x: -width / 2 + 82, y: 15)
        card.addChild(progress)

        let portalPositions: [CGPoint] = levels.count >= 5
            ? [CGPoint(x: -44, y: -26), CGPoint(x: 0, y: -26), CGPoint(x: 44, y: -26),
               CGPoint(x: -22, y: -60), CGPoint(x: 22, y: -60)]
            : [CGPoint(x: -44, y: -44), CGPoint(x: 0, y: -44), CGPoint(x: 44, y: -44),
               CGPoint(x: -22, y: -88), CGPoint(x: 22, y: -88)]

        let orderedLevels = Curriculum.levels(in: activeFilter.area)
        for (index, level) in levels.enumerated() {
            let portalState = portalState(for: level, orderedLevels: orderedLevels)
            let portal = makePortal(level: level, state: portalState,
                                    tint: activeFilter.tint,
                                    at: portalPositions[index])
            card.addChild(portal)
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleLevelTap(_:)))
            portal.addGestureRecognizer(tap)
        }

        return card
    }

    private func makePortal(level: LevelDefinition,
                            state: PortalState,
                            tint: UIColor,
                            at position: CGPoint) -> SKShapeNode {
        let portal = SKShapeNode(rectOf: CGSize(width: 44, height: 44), cornerRadius: 22)
        portal.position = position
        portal.userData = NSMutableDictionary()
        portal.userData?["levelID"] = level.id

        switch state {
        case .current:
            portal.fillColor = tint
            portal.strokeColor = UIColor.white.withAlphaComponent(0.92)
            portal.lineWidth = 2.2
            portal.run(.repeatForever(.sequence([
                .scale(to: 1.08, duration: 0.85),
                .scale(to: 1.0, duration: 0.85),
            ])))
        case .completed:
            portal.fillColor = SKTheme.yellow
            portal.strokeColor = SKTheme.orange
            portal.lineWidth = 1.8
        case .locked:
            portal.fillColor = SKTheme.cream.withAlphaComponent(0.88)
            portal.strokeColor = SKTheme.ink.withAlphaComponent(0.25)
            portal.lineWidth = 1.4
        }

        let label = SKLabelNode(text: displayNumber(for: level))
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = 13
        label.fontColor = state == .locked ? SKTheme.ink.withAlphaComponent(0.48) : SKTheme.ink
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        portal.addChild(label)

        return portal
    }

    private func portalState(for level: LevelDefinition,
                             orderedLevels: [LevelDefinition]) -> PortalState {
        let store = ProgressStore.shared
        if store.completed.contains(level.id) { return .completed }
        if orderedLevels.first(where: { !store.completed.contains($0.id) })?.id == level.id {
            return .current
        }
        return .locked
    }

    // MARK: - Footer and interaction

    private func buildFooter() {
        let safeWidth = SKLayout.safeWidth(self)
        let safeBottom = SKLayout.safeBottom(self)
        let gap: CGFloat = 10
        let progressWidth = min(164, safeWidth * 0.47)
        let parentWidth = safeWidth - progressWidth - gap
        let footerY = safeBottom + 30

        let progressCard = SKCard(width: progressWidth, height: 50, cornerRadius: 25,
                                  fill: SKTheme.paper)
        progressCard.position = CGPoint(x: -(parentWidth + gap) / 2, y: footerY)
        addChild(progressCard)

        let stars = SKHUD.makeStars(filled: 0, size: 14, spacing: 3)
        stars.position = CGPoint(x: -progressWidth * 0.23, y: 7)
        progressCard.addChild(stars)

        let tally = SKLabel(text: "0 / 150 stars", style: .caption,
                            color: SKTheme.ink.withAlphaComponent(0.72))
        tally.fontSize = 11
        tally.position = CGPoint(x: 0, y: -10)
        progressCard.addChild(tally)
        starTallyText = tally

        let parent = SKShapeNode(rectOf: CGSize(width: parentWidth, height: 50), cornerRadius: 25)
        parent.fillColor = SKTheme.purple.withAlphaComponent(0.88)
        parent.strokeColor = .clear
        parent.position = CGPoint(x: (progressWidth + gap) / 2, y: footerY)
        addChild(parent)

        let label = SKLabelNode(text: "For Grown-Ups")
        label.fontName = "AvenirNext-DemiBold"
        label.fontSize = 13
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        parent.addChild(label)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleParent))
        parent.addGestureRecognizer(tap)
    }

    @objc private func handleLevelTap(_ recognizer: UITapGestureRecognizer) {
        guard let skView = self.view else { return }
        let scenePoint = skView.convert(recognizer.location(in: skView), to: self)
        guard let tapped = nodes(at: scenePoint).first(where: { $0.userData?["levelID"] != nil }),
              let id = tapped.userData?["levelID"] as? String,
              let level = Curriculum.levels.first(where: { $0.id == id }) else { return }

        let orderedLevels = Curriculum.levels(in: level.area)
        if !ProgressStore.shared.completed.contains(level.id),
           !isUnlocked(level: level, orderedLevels: orderedLevels) {
            Feedback.shared.tryAgain()
            return
        }
        Feedback.shared.tap()
        SceneRouter.shared.goScene(level: level)
    }

    private func isUnlocked(level: LevelDefinition, orderedLevels: [LevelDefinition]) -> Bool {
        guard let index = orderedLevels.firstIndex(of: level), index > 0 else { return true }
        return ProgressStore.shared.completed.contains(orderedLevels[index - 1].id)
            || ProgressStore.shared.recommendedLevel.id == level.id
    }

    @objc private func handleParent() {
        Feedback.shared.tap()
        SceneRouter.shared.goParentGate()
    }

    private func refreshProgress() {
        starTallyText?.text = String(ProgressStore.shared.totalStars) + " / 150 stars"
        if worldParent != nil { rebuildWorldMap() }
    }

    // MARK: - Context

    private func contextAsset(for area: LearningArea, chapterIndex: Int) -> String? {
        let assets: [String]
        switch area {
        case .math:
            assets = ["MathBakery", "MathOutdoors", "MathMarket", "MathFestival", "MathSpace"]
        case .english:
            assets = ["BedroomScene", "Bathroom", "DiningRoom", "LaundryRoom", "Kitchen"]
        case .lifeSkills:
            assets = ["BedroomScene", "Bathroom", "Kitchen", "LaundryRoom", "DiningRoom"]
        }
        return assets[chapterIndex % assets.count]
    }

    private func chapterTitle(for area: LearningArea, index: Int) -> String {
        let titles: [String]
        switch area {
        case .math:
            titles = ["Bakery Street", "Garden Trail", "Market Square", "Festival Park", "Space Station"]
        case .english:
            titles = ["Morning Home", "Family Time", "Bedroom Stories", "Bath & Bedtime", "Home Adventures"]
        case .lifeSkills:
            titles = ["Rainbow Room", "Morning Routine", "Home Helpers", "Daily Practice", "Big Adventures"]
        }
        return titles[index % titles.count]
    }

    private func displayNumber(for level: LevelDefinition) -> String {
        level.id.drop(while: { $0.isLetter }).description
    }
}
