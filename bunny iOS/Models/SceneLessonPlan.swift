import Foundation

enum LessonMoment: String, CaseIterable, Identifiable {
    case story = "Watch the Scene"
    case explore = "Tap & Discover"
    case listen = "Listen & Say"
    case drag = "Move & Match"
    case order = "Put It in Order"
    case mission = "Scene Mission"
    case finale = "Little Story"
    case together = "Try It Together"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .story: "play.rectangle.fill"
        case .explore: "hand.tap.fill"
        case .listen: "waveform"
        case .drag: "hand.draw.fill"
        case .order: "arrow.up.arrow.down"
        case .mission: "flag.checkered"
        case .finale: "book.closed.fill"
        case .together: "figure.2.and.child.holdinghands"
        }
    }
}

struct SceneLessonPlan {
    let sceneTitle: String
    let invitation: String
    let realWorldChallenge: String
    let moments: [LessonMoment]

    static func make(for level: LevelDefinition) -> SceneLessonPlan {
        let challenge: String
        switch level.scene {
        case .breakfast:
            challenge = "At breakfast, ask your grown-up: “May I have the spoon, please?”"
        case .brushTeeth:
            challenge = "Brush together. Say: toothpaste, brush, rinse, clean."
        case .bedtime:
            challenge = "At bedtime, name your pajamas, blanket, and lamp."
        case .cooking:
            challenge = "Help mix a safe snack. Say: pour, mix, stir, careful."
        case .dishes:
            challenge = "Help with one cup. Say: wash, rinse, dry, put away."
        case .getDressed:
            challenge = "Choose clothes for the weather and name what you wear."
        case .cleanBedroom:
            challenge = "Pick up three toys. Put one under and one beside something."
        case .wakeUp:
            challenge = "In the morning, turn on a light with your grown-up. Say: Good morning! Then fold your pajamas."
        case .bathroomMorning:
            challenge = "Get your towel, toothbrush and cup ready with a grown-up. Ask: May I have my towel, please?"
        case .setTable:
            challenge = "Help set a real table. Put a spoon beside a plate and say: The spoon is beside the plate."
        case .dinner:
            challenge = "At dinner, ask a family member: May I have the cup, please? Then say: Thank you!"
        case .laundry:
            challenge = "Help put a shirt in the laundry basket. Find a pair of socks and fold a towel together."
        case .findTeddy:
            challenge = "Hide a teddy with your grown-up. Take turns saying: Look beside the lamp. Look behind the basket."
        case .bathTime:
            challenge = "After a bath with your grown-up, say: Rinse, dry, pajamas. Tell them what comes next."
        case .dayAtHome:
            challenge = "Tell your grown-up about your day: First I got dressed. Then I ate breakfast. Finally, I put on my pajamas."
        default:
            let words = level.vocabulary.prefix(3).joined(separator: ", ")
            challenge = "Find a moment at home to use these words: \(words)."
        }

        return SceneLessonPlan(
            sceneTitle: level.title,
            invitation: invitation(for: level.scene),
            realWorldChallenge: challenge,
            moments: LessonMoment.allCases
        )
    }
    private static func invitation(for scene: SceneKind) -> String {
        switch scene {
        case .wakeUp: "Good morning! Help me turn on the light and get ready for the day."
        case .bathroomMorning: "Let's get the bathroom ready. I need my towel, toothbrush and water."
        case .brushTeeth: "My teeth need cleaning. Help me brush and rinse!"
        case .getDressed: "Let's get dressed and put our night clothes away."
        case .breakfast: "I'm hungry! Let's get my breakfast ready together."
        case .setTable: "Our family is coming to eat. Will you help me set the table?"
        case .cooking: "Let's make something together. Get the bowl, pour and stir!"
        case .dinner: "Dinner is ready! Please help me with my plate, bowl, cup and spoon."
        case .dishes: "We enjoyed our food. Now let's wash and dry the dishes."
        case .laundry: "Our clothes need a wash. Let's fill the basket and tidy up."
        case .cleanBedroom: "Let's make our room cosy. Help me put our things away."
        case .findTeddy: "Where is Teddy? Help me look around the bedroom."
        case .bathTime: "Bath time is over. Let's rinse, dry off and get dressed."
        case .bedtime: "I'm sleepy. Let's get Teddy ready and turn off the light."
        case .dayAtHome: "What a busy day! Let's get ready from morning to bedtime."
        default: "Will you help me today?"
        }
    }

}

/// Observable practice evidence, never a diagnosis or a speech-recognition score.
struct SceneStepEvidence: Codable, Equatable {
    let itemID: String
    var incorrectAttempts = 0
    var replays = 0
    var hints = 0
    var completed = false
    var independent: Bool { completed && incorrectAttempts == 0 && replays == 0 && hints == 0 }
}

struct ScenePractice: Codable, Identifiable, Equatable {
    let id: UUID
    let levelID: String
    let startedAt: Date
    var steps: [SceneStepEvidence]
    var finishedAt: Date?
    var independentCount: Int { steps.filter(\.independent).count }
    var completedCount: Int { steps.filter(\.completed).count }
    var needsPractice: Bool { finishedAt != nil && independentCount < steps.count }

    init(levelID: String, itemIDs: [String], now: Date = Date()) {
        id = UUID()
        self.levelID = levelID
        startedAt = now
        steps = itemIDs.map { SceneStepEvidence(itemID: $0) }
    }
}

/// One shared state machine for every home scene. Unknown/duplicate input is ignored.
struct ScenePracticeSession {
    private(set) var practice: ScenePractice
    private(set) var index = 0
    var isFinished: Bool { index == practice.steps.count }
    var helpLevel: Int {
        guard !isFinished else { return 0 }
        let step = practice.steps[index]
        return min(3, max(step.incorrectAttempts, step.hints))
    }
    init(levelID: String, itemIDs: [String]) {
        practice = ScenePractice(levelID: levelID, itemIDs: itemIDs)
    }
    mutating func replay() {
        guard !isFinished else { return }
        practice.steps[index].replays += 1
    }
    mutating func requestHelp() {
        guard !isFinished else { return }
        practice.steps[index].hints += 1
    }
    mutating func attempt(_ itemID: String, now: Date = Date()) -> Bool {
        guard !isFinished,
              practice.steps.contains(where: { $0.itemID == itemID && !$0.completed }) else { return false }
        guard practice.steps[index].itemID == itemID else {
            practice.steps[index].incorrectAttempts += 1
            return false
        }
        practice.steps[index].completed = true
        index += 1
        if isFinished { practice.finishedAt = now }
        return true
    }
}
