import SpriteKit
import UIKit

/// Adult gate. Long-press the lock to enter the parent dashboard. Shows a
/// privacy preview so grown-ups know what the dashboard contains before they
/// commit to unlocking.
final class ParentGateScene: SKScene {
    private let title = SKLabel(text: "Grown-Ups Only", style: .headline, color: SKTheme.ink)
    private let prompt = SKLabel(text: "Press and hold the lock to enter", style: .body, color: SKTheme.ink.withAlphaComponent(0.65))
    private let hint = SKLabel(text: "Children: please ask a grown-up first", style: .caption, color: SKTheme.ink.withAlphaComponent(0.45))
    private var progress: SKShapeNode?
    private var lockIcon: SKShapeNode?
    private let lockCenter = CGPoint(x: 0, y: 0)
    private var holdTimer: Timer?
    private var accumulated: TimeInterval = 0
    private let requiredHold: TimeInterval = 1.6

    override func didMove(to view: SKView) {
        removeAllChildren()
        backgroundColor = SKTheme.cream
        title.removeFromParent()
        prompt.removeFromParent()
        hint.removeFromParent()
        progress?.removeFromParent()
        lockIcon?.removeFromParent()

        buildBackground()
        buildHeader()
        buildLock()
        buildPreview()
        buildBackButton()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        removeAllChildren()
        didMove(to: SKView())
    }

    // MARK: - Background

    private func buildBackground() {
        // Soft purple halo behind the lock to set the mood.
        let halo = SKShapeNode(circleOfRadius: min(size.width, size.height) * 0.28)
        halo.fillColor = SKTheme.purple.withAlphaComponent(0.10)
        halo.strokeColor = .clear
        halo.position = lockCenter
        addChild(halo)
        halo.run(.repeatForever(.sequence([
            .scale(to: 1.05, duration: 1.6),
            .scale(to: 1.0, duration: 1.6)
        ])))
    }

    // MARK: - Header

    private func buildHeader() {
        // Title sits a comfortable distance below the status bar.
        title.position = CGPoint(x: 0, y: SKLayout.safeTop(self) - 80)
        title.fit(maxWidth: SKLayout.safeWidth(self) * 0.9)
        addChild(title)

        // Prompt sits directly under the title.
        prompt.position = CGPoint(x: 0, y: title.position.y - 56)
        prompt.fit(maxWidth: SKLayout.safeWidth(self) * 0.9)
        addChild(prompt)

        // Hint hugs the very bottom of the safe area.
        hint.position = CGPoint(x: 0, y: -size.height / 2 + 110)
        hint.fit(maxWidth: SKLayout.safeWidth(self) * 0.9)
        addChild(hint)
    }

    // MARK: - Lock

    private func buildLock() {
        let ringRadius: CGFloat = 92

        let ring = SKShapeNode(circleOfRadius: ringRadius)
        ring.strokeColor = SKTheme.cardStroke
        ring.lineWidth = 10
        ring.fillColor = SKTheme.paper
        ring.position = lockCenter
        addChild(ring)
        lockIcon = ring

        // Progress arc that fills as the grown-up holds.
        let arc = SKShapeNode(circleOfRadius: ringRadius)
        arc.strokeColor = SKTheme.purple
        arc.lineWidth = 10
        arc.fillColor = .clear
        arc.position = lockCenter
        arc.zPosition = 1
        arc.strokeEnd = 0
        addChild(arc)
        progress = arc

        // Padlock body, slightly below the ring center so the shackle sits on top.
        let bodySize = CGSize(width: 80, height: 64)
        let bodyCenterY: CGFloat = -10
        let lockBody = SKShapeNode(rectOf: bodySize, cornerRadius: 12)
        lockBody.fillColor = SKTheme.ink
        lockBody.strokeColor = .clear
        lockBody.position = CGPoint(x: lockCenter.x, y: bodyCenterY)
        addChild(lockBody)

        // Padlock shackle drawn as an inverted-U path so it no longer reads
        // as a head sitting on top of the body.
        let shackleRadius: CGFloat = 22
        let legLength: CGFloat = 16
        let shacklePath = CGMutablePath()
        shacklePath.move(to: CGPoint(x: -shackleRadius, y: 0))
        shacklePath.addLine(to: CGPoint(x: -shackleRadius, y: legLength))
        // CGPath angles increase counter-clockwise from +x in math terms;
        // to make the arc travel OVER the top of the legs in a UIKit/SpriteKit
        // (y-up) scene we sweep clockwise from 180° to 0°, which passes
        // through 90° = "up" on screen.
        shacklePath.addArc(center: CGPoint(x: 0, y: legLength),
                           radius: shackleRadius,
                           startAngle: .pi,
                           endAngle: 0,
                           clockwise: true)
        shacklePath.addLine(to: CGPoint(x: shackleRadius, y: 0))
        let shackle = SKShapeNode(path: shacklePath, centered: false)
        shackle.strokeColor = SKTheme.ink
        shackle.lineWidth = 8
        shackle.lineCap = .round
        shackle.lineJoin = .round
        shackle.fillColor = .clear
        // Place the shackle so its legs dive into the body and the arch
        // arches above it.
        let bodyTopY = bodyCenterY + bodySize.height / 2
        shackle.position = CGPoint(x: lockCenter.x, y: bodyTopY - 4)
        addChild(shackle)

        // Keyhole in the center of the body.
        let keyhole = SKShapeNode(circleOfRadius: 6)
        keyhole.fillColor = SKTheme.cream
        keyhole.strokeColor = .clear
        keyhole.position = CGPoint(x: lockCenter.x, y: bodyCenterY - 4)
        addChild(keyhole)

        // Subtle "press" animation hint.
        ring.run(.repeatForever(.sequence([
            .scale(to: 1.04, duration: 1.4),
            .scale(to: 1.0, duration: 1.4)
        ])))
    }

    // MARK: - Privacy preview

    private func buildPreview() {
        // Three preview cards: stars, time, scenes — what the dashboard shows.
        let previewContainer = SKNode()
        // Sit the preview below the halo so the screen reads top-to-bottom
        // (title → prompt → lock → preview → hint → back).
        let haloRadius = min(size.width, size.height) * 0.28
        let previewY = lockCenter.y - haloRadius - 30
        previewContainer.position = CGPoint(x: 0, y: previewY)
        addChild(previewContainer)

        let previewTitle = SKLabel(text: "Inside you'll see", style: .caption, color: SKTheme.ink.withAlphaComponent(0.55))
        previewTitle.fontSize = 14
        previewTitle.position = CGPoint(x: 0, y: 58)
        previewContainer.addChild(previewTitle)

        let chipWidth: CGFloat = 96
        let chipHeight: CGFloat = 44
        let chipSpacing: CGFloat = 12
        let chips: [(String, UIColor, UIColor)] = [
            ("Stars", SKTheme.yellow, SKTheme.ink),
            ("Time", SKTheme.blue, .white),
            ("Scenes", SKTheme.green, .white)
        ]
        let totalWidth = CGFloat(chips.count) * chipWidth + CGFloat(chips.count - 1) * chipSpacing
        let baseX = -totalWidth / 2 + chipWidth / 2
        for (i, info) in chips.enumerated() {
            let chip = SKShapeNode(rectOf: CGSize(width: chipWidth, height: chipHeight), cornerRadius: 18)
            chip.fillColor = info.1
            chip.strokeColor = .clear
            chip.position = CGPoint(x: baseX + CGFloat(i) * (chipWidth + chipSpacing), y: 0)
            previewContainer.addChild(chip)

            let text = SKLabel(text: info.0, style: .button, color: info.2)
            text.fontSize = 16
            text.fit(maxWidth: chipWidth * 0.8)
            text.position = CGPoint(x: chip.position.x, y: 0)
            previewContainer.addChild(text)
        }
    }

    // MARK: - Back

    private func buildBackButton() {
        let card = SKCard(width: 220, height: 60, cornerRadius: 28, fill: SKTheme.paper)
        card.position = CGPoint(x: 0, y: SKLayout.safeBottom(self) + 50)
        addChild(card)
        let label = SKLabel(text: "Back", style: .button, color: SKTheme.ink)
        label.fontSize = 22
        label.fit(maxWidth: 200)
        label.position = CGPoint(x: 0, y: 0)
        card.addChild(label)
        let tap = UITapGestureRecognizer(target: self, action: #selector(goBack))
        card.addGestureRecognizer(tap)
    }

    // MARK: - Input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        // Only count touches inside the lock ring, not the Back button or chips.
        if let ring = lockIcon, ring.frame.insetBy(dx: -16, dy: -16).contains(location) {
            beginHold()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let ring = lockIcon else { return }
        let location = touch.location(in: self)
        if !ring.frame.insetBy(dx: -16, dy: -16).contains(location) {
            cancelHold()
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        cancelHold()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        cancelHold()
    }

    private func beginHold() {
        guard holdTimer == nil else { return }
        accumulated = 0
        progress?.strokeColor = SKTheme.purple
        progress?.strokeEnd = 0
        holdTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            self.accumulated += timer.timeInterval
            let frac = min(1.0, self.accumulated / self.requiredHold)
            self.progress?.strokeEnd = CGFloat(frac)
            if frac >= 1.0 {
                timer.invalidate()
                self.holdTimer = nil
                SceneRouter.shared.goParent()
            }
        }
    }

    private func cancelHold() {
        holdTimer?.invalidate()
        holdTimer = nil
        accumulated = 0
        progress?.strokeEnd = 0
    }

    @objc private func goBack() {
        cancelHold()
        SceneRouter.shared.goHome()
    }
}
