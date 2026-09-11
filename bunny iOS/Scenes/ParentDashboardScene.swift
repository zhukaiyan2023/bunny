import SpriteKit
import UIKit

/// Read-only parent dashboard. Shows three top-line stats (stars, scenes played,
/// scenes completed), a recent activity list, a family practice checkbox and a
/// privacy reassurance note.
final class ParentDashboardScene: SKScene {
    private let scrollNode = SKNode()

    override func didMove(to view: SKView) {
        backgroundColor = SKTheme.cream
        scrollNode.removeFromParent()
        buildBackground()
        buildHeader()
        buildStats()
        buildRecentPractice()
        buildFamilyPractice()
        buildPrivacyNote()
        buildResetButton()
        buildCloseButton()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        removeAllChildren()
        didMove(to: SKView())
    }

    private func buildBackground() {
        // Soft green ground so the dashboard feels like the same world as the
        // child-facing menu.
        let ground = SKShapeNode(rectOf: CGSize(width: size.width + 40, height: size.height * 0.30))
        ground.fillColor = SKTheme.green.withAlphaComponent(0.10)
        ground.strokeColor = .clear
        ground.position = CGPoint(x: 0, y: SKLayout.safeBottom(self) - size.height * 0.04)
        addChild(ground)
    }

    private func buildHeader() {
        let title = SKLabel(text: "Family Report", style: .title, color: SKTheme.ink)
        title.fontSize = 38
        title.position = CGPoint(x: 0, y: SKLayout.safeTop(self) - 70)
        addChild(title)

        let subtitle = SKLabel(text: "What Pip has been learning", style: .caption, color: SKTheme.ink.withAlphaComponent(0.6))
        subtitle.fontSize = 15
        subtitle.position = CGPoint(x: 0, y: SKLayout.safeTop(self) - 104)
        addChild(subtitle)

        // Back chevron in the top-left.
        let back = SKHUD.makeCircleButton(symbol: "chevron.left", diameter: 52)
        back.position = CGPoint(x: SKLayout.safeLeft(self) + 32, y: SKLayout.safeTop(self) - 40)
        let tap = UITapGestureRecognizer(target: self, action: #selector(goHome))
        back.addGestureRecognizer(tap)
        addChild(back)
    }

    private func buildStats() {
        let store = ProgressStore.shared
        let card = SKCard(width: SKLayout.cardMaxWidth(self), height: 170, cornerRadius: 28)
        card.position = CGPoint(x: 0, y: SKLayout.safeTop(self) - 240)
        addChild(card)

        addStat(parent: card, x: -card.frame.width / 4,
                bigValue: "\(store.totalStars)", bigColor: SKTheme.yellow,
                caption: "Stars", icon: "⭐", iconColor: SKTheme.yellow)
        addStat(parent: card, x: 0,
                bigValue: "\(store.totalAttempts)", bigColor: SKTheme.blue,
                caption: "Played", icon: "🕐", iconColor: SKTheme.blue)
        addStat(parent: card, x: card.frame.width / 4,
                bigValue: "\(store.completed.count)", bigColor: SKTheme.green,
                caption: "Finished", icon: "✅", iconColor: SKTheme.green)
    }

    private func addStat(parent: SKCard, x: CGFloat, bigValue: String,
                         bigColor: UIColor, caption: String, icon: String,
                         iconColor: UIColor) {
        let icon = SKLabelNode(text: icon)
        icon.fontSize = 22
        icon.fontName = "AvenirNext-Heavy"
        icon.position = CGPoint(x: x, y: 44)
        parent.addChild(icon)

        let value = SKLabel(text: bigValue, style: .title, color: bigColor)
        value.fontSize = 36
        value.position = CGPoint(x: x, y: 8)
        parent.addChild(value)

        let cap = SKLabel(text: caption, style: .caption, color: SKTheme.ink.withAlphaComponent(0.6))
        cap.fontSize = 13
        cap.position = CGPoint(x: x, y: -32)
        parent.addChild(cap)
    }

    private func buildRecentPractice() {
        scrollNode.removeAllChildren()
        let store = ProgressStore.shared
        let sectionTitle = SKLabel(text: "Recent practice", style: .headline, color: SKTheme.ink)
        sectionTitle.fontSize = 20
        sectionTitle.position = CGPoint(x: SKLayout.safeLeft(self) + 24, y: SKLayout.safeTop(self) - 370)
        sectionTitle.horizontalAlignmentMode = .left
        scrollNode.addChild(sectionTitle)

        let recent = Array(store.scenePractices.suffix(4))
        if recent.isEmpty {
            let placeholder = SKLabel(text: "No practice sessions yet — play a level to see updates here.",
                                      style: .body,
                                      color: SKTheme.ink.withAlphaComponent(0.55))
            placeholder.fontSize = 14
            placeholder.position = CGPoint(x: 0, y: SKLayout.safeTop(self) - 430)
            placeholder.horizontalAlignmentMode = .center
            placeholder.fit(maxWidth: SKLayout.safeWidth(self) * 0.85)
            scrollNode.addChild(placeholder)
        } else {
            for (index, practice) in recent.enumerated() {
                guard let level = Curriculum.levels.first(where: { $0.id == practice.levelID }) else { continue }
                let row = SKCard(width: SKLayout.cardMaxWidth(self), height: 64, cornerRadius: 16)
                row.position = CGPoint(x: 0, y: SKLayout.safeTop(self) - 430 - CGFloat(index) * 74)
                scrollNode.addChild(row)
                let dot = SKShapeNode(circleOfRadius: 7)
                dot.fillColor = level.area == .english ? SKTheme.orange : (level.area == .math ? SKTheme.blue : SKTheme.green)
                dot.strokeColor = .clear
                dot.position = CGPoint(x: -row.frame.width / 2 + 26, y: 0)
                row.addChild(dot)
                let label = SKLabel(text: level.title, style: .body, color: SKTheme.ink)
                label.position = CGPoint(x: -row.frame.width / 2 + 48, y: 0)
                label.horizontalAlignmentMode = .left
                label.fit(maxWidth: row.frame.width * 0.5)
                row.addChild(label)
                let detail = SKLabel(text: "\(practice.completedCount)/\(practice.steps.count) steps",
                                     style: .caption,
                                     color: SKTheme.ink.withAlphaComponent(0.6))
                detail.position = CGPoint(x: row.frame.width / 2 - 18, y: 0)
                detail.horizontalAlignmentMode = .right
                row.addChild(detail)
            }
        }
        addChild(scrollNode)
    }

    private func buildFamilyPractice() {
        let store = ProgressStore.shared
        let y = SKLayout.safeBottom(self) + 230
        let card = SKCard(width: SKLayout.cardMaxWidth(self), height: 92, cornerRadius: 22)
        card.position = CGPoint(x: 0, y: y)
        addChild(card)

        let title = SKLabel(text: "Family practice", style: .body, color: SKTheme.ink)
        title.fontSize = 16
        title.position = CGPoint(x: -card.frame.width / 2 + 22, y: 14)
        title.horizontalAlignmentMode = .left
        card.addChild(title)

        let subtitle = SKLabel(text: "Try a real-life challenge together",
                               style: .caption,
                               color: SKTheme.ink.withAlphaComponent(0.6))
        subtitle.fontSize = 12
        subtitle.position = CGPoint(x: -card.frame.width / 2 + 22, y: -14)
        subtitle.horizontalAlignmentMode = .left
        card.addChild(subtitle)

        let checkbox = SKShapeNode(rectOf: CGSize(width: 32, height: 32), cornerRadius: 8)
        checkbox.fillColor = store.familyPractice.contains("any") ? SKTheme.green : SKTheme.paper
        checkbox.strokeColor = SKTheme.ink
        checkbox.lineWidth = 2
        checkbox.position = CGPoint(x: card.frame.width / 2 - 32, y: 0)
        card.addChild(checkbox)
    }

    private func buildPrivacyNote() {
        let note = SKLabel(text: "All data stays on this device. No ads. No tracking.",
                           style: .caption,
                           color: SKTheme.ink.withAlphaComponent(0.5))
        note.fontSize = 11
        note.horizontalAlignmentMode = .center
        note.position = CGPoint(x: 0, y: SKLayout.safeBottom(self) + 130)
        note.fit(maxWidth: SKLayout.safeWidth(self) * 0.9)
        addChild(note)
    }

    private func buildCloseButton() {
        let close = SKButton(title: "Close", style: .primary(color: SKTheme.purple), action: { [weak self] in
            _ = self
            SceneRouter.shared.goHome()
        })
        close.setSize(width: 240, height: 64)
        close.position = CGPoint(x: 0, y: SKLayout.safeBottom(self) + 60)
        addChild(close)
    }

    /// S2 wiring — adds a "Reset Progress" button per PRD. Wipes
    /// ProgressStore (Pillar 3: never lossy — requires confirmation by
    /// living behind the parent gate) and routes to `.welcome` so the
    /// onboarding flow runs again.
    private func buildResetButton() {
        let reset = SKButton(title: "Reset Progress",
                             style: .secondary(color: SKTheme.orange),
                             action: { [weak self] in
            _ = self
            ProgressStore.shared.resetAllProgress()
            SceneRouter.shared.goWelcome()
        })
        reset.setSize(width: 240, height: 56)
        reset.position = CGPoint(x: 0, y: SKLayout.safeBottom(self) + 140)
        addChild(reset)

        let note = SKLabel(text: "Wipes all stars and progress. Onboarding will run again.",
                           style: .caption, color: SKTheme.ink.withAlphaComponent(0.5))
        note.fontSize = 11
        note.horizontalAlignmentMode = .center
        note.fit(maxWidth: SKLayout.safeWidth(self) * 0.85)
        note.position = CGPoint(x: 0, y: SKLayout.safeBottom(self) + 195)
        addChild(note)
    }

    @objc private func goHome() {
        SceneRouter.shared.goHome()
    }
}