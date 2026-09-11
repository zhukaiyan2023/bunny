import SpriteKit

/// A circular progress ring made from two SKShapeNode arcs. Use it to
/// show fractional completion in a compact space (level select, world
/// cards, dashboards). Animates smoothly when `setProgress(_:)` is
/// called.
final class ProgressRing: SKNode {
    private let track: SKShapeNode
    private let fill: SKShapeNode
    private let radius: CGFloat
    private let lineWidth: CGFloat
    private var progress: CGFloat = 0

    init(radius: CGFloat,
         lineWidth: CGFloat,
         trackColor: SKColor,
         fillColor: SKColor) {
        self.radius = radius
        self.lineWidth = lineWidth

        track = SKShapeNode(circleOfRadius: radius)
        track.strokeColor = trackColor
        track.fillColor = .clear
        track.lineWidth = lineWidth

        fill = SKShapeNode(circleOfRadius: radius)
        fill.strokeColor = fillColor
        fill.fillColor = .clear
        fill.lineWidth = lineWidth

        super.init()

        track.name = "progressRing.track"
        fill.name = "progressRing.fill"
        addChild(track)
        addChild(fill)

        // Render as a thin donut by drawing two strokes and using line
        // width to give the donut shape.
        track.zPosition = 0
        fill.zPosition = 1

        renderFill(progress: 0)
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    /// Update progress (0.0 to 1.0). Animated by default.
    func setProgress(_ value: CGFloat, animated: Bool = true) {
        let clamped = max(0, min(1, value))
        progress = clamped
        if animated {
            fill.run(.customAction(withDuration: 0.5) { [weak self] _, t in
                guard let self else { return }
                self.renderFill(progress: clamped * t)
            })
        } else {
            renderFill(progress: clamped)
        }
    }

    private func renderFill(progress: CGFloat) {
        // Render an arc from -90° (top) clockwise by `progress * 2π`.
        let startAngle: CGFloat = -.pi / 2
        let endAngle = startAngle + (.pi * 2 * progress)
        if progress <= 0.0001 {
            fill.path = nil
            return
        }
        let path = CGMutablePath()
        path.addArc(center: .zero,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false)
        fill.path = path
    }
}
