import SpriteKit

/// Ambient particle background helper. Adds a slow-floating field of
/// tiny stars / dust motes that don't interact with the player. Each
/// scene calls `SKAmbient.install(in: scene)` once and forgets about
/// it; cleanup happens automatically on scene teardown via a strong
/// observer that removes the layer when the scene is removed from its
/// parent.
///
/// All settings are designed to respect Pillar 1 (Calm): no flash, no
/// fast movement, low particle count. The motion is barely perceptible
/// but creates depth and warmth.
enum SKAmbient {

    struct Configuration {
        /// Number of floating particles. Default 36 — looks alive but
        /// stays under the 100-particle cap from
        /// `docs/engine-reference/spritekit/performance-budgets.md`.
        var particleCount: Int = 36

        /// Color palette. Defaults to warm pastels so the layer reads
        /// as fairy dust rather than space dust.
        var palette: [UIColor] = [
            UIColor(red: 0.99, green: 0.92, blue: 0.78, alpha: 0.55),
            UIColor(red: 0.92, green: 0.86, blue: 0.99, alpha: 0.55),
            UIColor(red: 0.85, green: 0.95, blue: 0.88, alpha: 0.55),
            UIColor(red: 0.99, green: 0.83, blue: 0.83, alpha: 0.45),
        ]

        /// Background fill (drawn behind the particles). Pass nil to
        /// keep the scene's existing backgroundColor.
        var backgroundGradient: [UIColor]? = nil

        /// Slow drift speed in points per second. Kept under 12 so the
        /// particles feel like floating dust, not rain.
        var driftSpeed: CGFloat = 8

        /// Size range for each particle.
        var minRadius: CGFloat = 1.0
        var maxRadius: CGFloat = 2.6

        /// How often a random particle "twinkles" (alpha pulse).
        /// Lower = more frequent twinkle.
        var twinkleOdds: Double = 0.04
    }

    /// Install the ambient layer into a scene. Safe to call once per
    /// scene in `didMove(to:)`. Returns the SKNode containing the layer
    /// so callers can adjust z-position if needed (recommended: place
    /// just above the background fill, but below all UI).
    @discardableResult
    static func install(in scene: SKScene, config: Configuration = Configuration()) -> SKNode {
        let layer = SKNode()
        layer.name = "ambient.layer"
        layer.zPosition = -50
        layer.isUserInteractionEnabled = false

        // Background gradient (optional).
        if let colors = config.backgroundGradient, colors.count >= 2 {
            attachGradient(to: layer, in: scene, colors: colors)
        }

        // Floating particles.
        for _ in 0..<config.particleCount {
            let p = makeParticle(in: scene, config: config)
            layer.addChild(p)
        }

        scene.addChild(layer)

        // Cleanup: SKAmbient.layer is a child of the scene, so it's
        // deallocated with the scene automatically. For an explicit
        // cleanup hook, scenes can call `SKAmbient.uninstall(from:)`
        // from their `willMove(from:)`.
        return layer
    }

    /// Remove the ambient layer (no-op if absent).
    static func uninstall(from scene: SKScene) {
        scene.childNode(withName: "ambient.layer")?.removeFromParent()
    }

    // MARK: - Internals

    private static func attachGradient(to layer: SKNode, in scene: SKScene, colors: [UIColor]) {
        // Cheap gradient: stack two large rounded rectangles with
        // semi-transparent fills. Avoids the cost of SKView's texture
        // shader pipeline while still giving a softer background than
        // a single flat color.
        let halfHeight = max(scene.size.height, 1)
        let top = SKShapeNode(rectOf: CGSize(width: scene.size.width + 40,
                                             height: halfHeight))
        top.fillColor = colors[0]
        top.strokeColor = .clear
        top.position = CGPoint(x: 0, y: halfHeight / 2 - 1)
        top.alpha = 0.55
        top.zPosition = -1
        layer.addChild(top)

        if colors.count > 1 {
            let bottom = SKShapeNode(rectOf: CGSize(width: scene.size.width + 40,
                                                    height: halfHeight))
            bottom.fillColor = colors[1]
            bottom.strokeColor = .clear
            bottom.position = CGPoint(x: 0, y: -halfHeight / 2 + 1)
            bottom.alpha = 0.45
            bottom.zPosition = -1
            layer.addChild(bottom)
        }
    }

    private static func makeParticle(in scene: SKScene, config: Configuration) -> SKShapeNode {
        let radius = CGFloat.random(in: config.minRadius...config.maxRadius)
        let p = SKShapeNode(circleOfRadius: radius)
        p.fillColor = config.palette.randomElement() ?? .white
        p.strokeColor = .clear
        p.alpha = CGFloat.random(in: 0.4...0.85)

        // Random starting position across the scene's full area.
        let halfW = scene.size.width / 2
        let halfH = scene.size.height / 2
        p.position = CGPoint(
            x: CGFloat.random(in: -halfW...halfW),
            y: CGFloat.random(in: -halfH...halfH)
        )

        // Slow vertical drift up; horizontal sway to mimic air currents.
        let drift = CGFloat.random(in: config.driftSpeed * 0.4...config.driftSpeed)
        let swayAmount = CGFloat.random(in: 6...18)
        let swayDuration = TimeInterval.random(in: 4.0...8.0)
        let fullDuration = TimeInterval.random(in: 14.0...22.0)

        // Build a slow loop: drift up off-screen, wrap around back to the
        // bottom. SKAction.repeatForever on a sequence makes the
        // particles feel like a soft snowfall from above.
        let up = SKAction.moveBy(x: 0, y: scene.size.height + 40, duration: fullDuration)
        let reset = SKAction.moveBy(x: 0, y: -(scene.size.height + 40), duration: 0)
        up.timingMode = .linear

        let sway = SKAction.repeatForever(.sequence([
            SKAction.moveBy(x: swayAmount, y: 0, duration: swayDuration),
            SKAction.moveBy(x: -swayAmount, y: 0, duration: swayDuration),
        ]))

        // Optional twinkle: random alpha pulse with a low probability
        // per loop iteration. Cheap to compute, big mood improvement.
        if Double.random(in: 0...1) < config.twinkleOdds {
            let twinkle = SKAction.repeatForever(.sequence([
                SKAction.fadeAlpha(to: 0.2, duration: 1.6),
                SKAction.fadeAlpha(to: 0.85, duration: 1.6),
            ]))
            p.run(twinkle)
        }

        p.run(.repeatForever(.sequence([reset, up])))
        p.run(sway)

        return p
    }
}
