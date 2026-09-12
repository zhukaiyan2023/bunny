import UIKit
import SpriteKit

/// The single immersive game window. Hosts the SKView and routes scenes
/// driven by `SceneRouter.shared.route`. Listens to
/// `.sceneRouterDidChange` and swaps the SKView's scene with a fade
/// transition. Initial route is computed in `viewDidLoad`:
///   - Launch argument `-route <value>` wins (debug only).
///   - Otherwise: `.welcome` if `!ProgressStore.onboardingComplete`,
///     else `.menu`.
///
/// The class is platform-thin — no OS-conditional compilation. All
/// routing lives in `SceneRouter`. All scene instantiation lives in
/// `makeScene(for:size:)` here so it stays in one auditable place.
final class GameViewController: UIViewController {

    private var observation: NSObjectProtocol?
    private let host = SKView(frame: .zero)

    override func loadView() {
        // Always build a fresh container + SKView so the scene's coordinate
        // system matches the device bounds regardless of storyboard setup.
        // Use the window's safe bounds so the SKView is created at the
        // correct size for the current orientation on first load.
        let initialFrame = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.coordinateSpace.bounds ?? CGRect(x: 0, y: 0, width: 402, height: 874)
        let container = UIView(frame: initialFrame)
        container.backgroundColor = SKTheme.cream
        host.frame = container.bounds
        host.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.allowsTransparency = false
        host.ignoresSiblingOrder = true
        host.preferredFramesPerSecond = 60
        host.isMultipleTouchEnabled = false
        container.addSubview(host)
        view = container
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // Force a redraw at the new size so the scene always fills the view.
        coordinator.animate(alongsideTransition: { [weak self] _ in
            guard let self else { return }
            self.present(SceneRouter.shared.route, transition: nil)
        })
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ProgressStore.shared.bootstrap()

        // Pick initial route. Launch arg overrides; otherwise onboarding
        // status decides.
        if !hasLaunchRoute() {
            let initial: SceneRouter.Route = ProgressStore.shared.onboardingComplete
                ? .menu
                : .welcome
            SceneRouter.shared.go(initial)
        }

        present(SceneRouter.shared.route, transition: nil)

        observation = NotificationCenter.default.addObserver(
            forName: .sceneRouterDidChange, object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.present(SceneRouter.shared.route, transition: SKTransition.fade(withDuration: 0.28))
        }
    }

    deinit {
        if let observation { NotificationCenter.default.removeObserver(observation) }
    }

    /// Returns true if the launch arg `-route <value>` was provided.
    /// `SceneRouter.init()` consumes it and updates its initial route.
    private func hasLaunchRoute() -> Bool {
        ProcessInfo.processInfo.arguments.contains("-route")
    }

    private func present(_ route: SceneRouter.Route, transition: SKTransition?) {
        let size = host.bounds.size
        let scene = makeScene(for: route, size: size)
        scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        scene.scaleMode = .resizeFill
        if let transition {
            host.presentScene(scene, transition: transition)
        } else {
            host.presentScene(scene)
        }
    }

    /// The single place that decides which concrete SKScene subclass to
    /// instantiate for a given route. Adding a new route requires adding
    /// exactly one new `case` here.
    private func makeScene(for route: SceneRouter.Route, size: CGSize) -> SKScene {
        switch route {
        case .menu:
            return MenuScene(size: size)
        case .map(let area):
            return AreaScene(size: size, area: area)
        case .lesson(let level):
            return LessonPlanScene(size: size, level: level)
        case .scene(let level):
            return GameSceneFactory.makeScene(size: size, level: level)
        case .reward(let level, let stars):
            return RewardScene(size: size, level: level, stars: stars)
        case .parentGate:
            return ParentGateScene(size: size)
        case .parentDashboard:
            return ParentDashboardScene(size: size)
        case .achievements:
            return AchievementsScene(size: size)
        case .welcome:
            return WelcomeScene(size: size)
        case .parentPrimer:
            return ParentPrimerScene(size: size)
        }
    }
}
