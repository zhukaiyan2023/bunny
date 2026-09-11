import Foundation
import CoreGraphics

enum EnglishMechanic: String, CaseIterable {
    case place, pour, brush, scrub, stir, fold, wear, toggleLight, reveal
}

/// Gesture evidence within an action target, expressed in normalized coordinates (-1...1).
/// Ending a gesture retains its earned progress. Accessibility actions are explicit alternatives.
struct EnglishActionProgress: Equatable {
    let mechanic: EnglishMechanic
    private(set) var progress: Double = 0
    private(set) var visited: Set<Int> = []
    var isComplete: Bool { progress >= 1 }

    private var isActive = false
    private var previousPoint: CGPoint?
    private var brushAnchor: CGPoint?
    private var strokeOrigin: CGPoint?
    private var sweptAngle: Double = 0
    private var heldSeconds: Double = 0

    init(mechanic: EnglishMechanic) { self.mechanic = mechanic }

    mutating func begin(at point: CGPoint) {
        guard !isComplete else { return }
        isActive = true
        previousPoint = Self.isFinite(point) ? point : nil
        brushAnchor = Self.isInside(point) ? point : nil
        strokeOrigin = Self.isInside(point) ? point : nil
    }

    mutating func move(to point: CGPoint) {
        guard isActive, !isComplete else { return }
        guard Self.isFinite(point) else {
            previousPoint = nil
            brushAnchor = nil
            strokeOrigin = nil
            return
        }
        defer { previousPoint = point }
        guard let previousPoint, Self.isInside(previousPoint), Self.isInside(point) else {
            brushAnchor = Self.isInside(point) ? point : nil
            strokeOrigin = Self.isInside(point) ? point : nil
            return
        }

        switch mechanic {
        case .brush, .scrub:
            // Merely touching every spot cannot count as brushing or scrubbing.
            // Accumulate small touch samples, so a gentle, slow stroke still works.
            guard let brushAnchor, Self.distance(brushAnchor, point) >= 0.06 else { return }
            for (index, spot) in Self.spots(for: mechanic).enumerated()
                where Self.distanceToSegment(spot, from: brushAnchor, to: point) <= 0.23 {
                visited.insert(index)
            }
            self.brushAnchor = point
            progress = Double(visited.count) / Double(Self.spots(for: mechanic).count)
        case .stir:
            guard Self.isInStirringRing(previousPoint), Self.isInStirringRing(point) else { return }
            var angle = atan2(Double(point.y), Double(point.x)) - atan2(Double(previousPoint.y), Double(previousPoint.x))
            if angle > .pi { angle -= 2 * .pi }
            if angle < -.pi { angle += 2 * .pi }
            // Crossing the bowl or jumping between opposite sides is not a circular stroke.
            guard abs(angle) <= .pi / 2 else { return }
            sweptAngle += angle
            progress = min(1, abs(sweptAngle) / (4 * .pi))
            if progress > 1 - 0.000_001 { progress = 1 }
        case .fold:
            guard let origin = strokeOrigin else { return }
            guard abs(point.y - origin.y) <= 0.6 else {
                strokeOrigin = point
                return
            }
            progress = max(progress, min(1, Double(abs(point.x - origin.x)) / 0.9))
        case .place, .pour, .wear, .toggleLight, .reveal:
            break
        }
    }

    mutating func end() {
        isActive = false
        previousPoint = nil
        brushAnchor = nil
        strokeOrigin = nil
    }

    mutating func advanceHeld(seconds: Double) {
        guard isActive, !isComplete, mechanic == .pour,
              seconds.isFinite, seconds > 0,
              let previousPoint, Self.isInside(previousPoint) else { return }
        heldSeconds += seconds
        progress = min(1, heldSeconds / 1.5)
    }

    /// A deliberate, repeatable button action supplies the same visible progress as a gesture.
    mutating func accessibleStep() {
        guard !isComplete else { return }
        switch mechanic {
        case .place, .wear, .toggleLight, .reveal:
            progress = 1
        case .pour:
            heldSeconds += 0.5
            progress = min(1, heldSeconds / 1.5)
        case .brush, .scrub:
            if let next = Self.spots(for: mechanic).indices.first(where: { !visited.contains($0) }) {
                visited.insert(next)
            }
            progress = Double(visited.count) / Double(Self.spots(for: mechanic).count)
        case .stir:
            // Continue the child's current direction when switching input method.
            sweptAngle += sweptAngle < 0 ? -.pi / 2 : .pi / 2
            progress = min(1, abs(sweptAngle) / (4 * .pi))
        case .fold:
            progress = min(1, progress + 0.5)
        }
    }

    static func spots(for mechanic: EnglishMechanic) -> [CGPoint] {
        switch mechanic {
        case .brush:
            [-0.32, 0.32].flatMap { y in
                [-0.58, 0.0, 0.58].map { x in CGPoint(x: x, y: y) }
            }
        case .scrub:
            (0..<6).map { index in
                let angle = Double(index) * .pi / 3
                return CGPoint(x: cos(angle) * 0.55, y: sin(angle) * 0.55)
            }
        default:
            []
        }
    }

    private static func isFinite(_ point: CGPoint) -> Bool {
        point.x.isFinite && point.y.isFinite
    }

    private static func isInside(_ point: CGPoint) -> Bool {
        isFinite(point) && abs(point.x) <= 1 && abs(point.y) <= 1
    }

    private static func isInStirringRing(_ point: CGPoint) -> Bool {
        let radius = hypot(point.x, point.y)
        return radius >= 0.25 && radius <= 1
    }

    private static func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }

    private static func distanceToSegment(_ point: CGPoint, from start: CGPoint, to end: CGPoint) -> CGFloat {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let squaredLength = dx * dx + dy * dy
        guard squaredLength > 0 else { return distance(point, start) }
        let amount = min(1, max(0, ((point.x - start.x) * dx + (point.y - start.y) * dy) / squaredLength))
        return distance(point, CGPoint(x: start.x + amount * dx, y: start.y + amount * dy))
    }
}
