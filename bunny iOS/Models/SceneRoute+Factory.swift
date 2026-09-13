import Foundation
import SpriteKit

/// The single source of truth for "what scene does this route become?".
/// Lives in a separate file so `SceneRoute.swift` can stay
/// Foundation-only (which `tools/run_unit_tests.sh` requires).
///
/// `GameViewController.present(_:transition:)` calls
/// `SceneRouter.makeScene(for:size:)` — adding a new route is one new
/// `case` in `SceneRoute.Route` plus one new `switch` arm here. No edits
/// to `GameViewController` are required.
extension SceneRouter {
    static func makeScene(for route: Route, size: CGSize) -> SKScene {
        switch route {
        case .menu:                  return MenuScene(size: size)
        case .map(let area):         return AreaScene(size: size, area: area)
        case .lesson(let lvl):       return LessonPlanScene(size: size, level: lvl)
        case .scene(let lvl):        return GameSceneFactory.makeScene(size: size, level: lvl)
        case .reward(let lvl, let stars):
                                          return RewardScene(size: size, level: lvl, stars: stars)
        case .parentGate:            return ParentGateScene(size: size)
        case .parentDashboard:       return ParentDashboardScene(size: size)
        case .achievements:          return AchievementsScene(size: size)
        case .welcome:               return WelcomeScene(size: size)
        case .parentPrimer:          return ParentPrimerScene(size: size)
        }
    }
}
