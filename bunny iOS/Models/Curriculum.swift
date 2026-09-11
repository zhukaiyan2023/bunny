import Foundation

enum LearningArea: String, Codable, CaseIterable, Identifiable {
    case math = "Math"
    case english = "English"
    case lifeSkills = "Life Skills"
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .math: "plus.forwardslash.minus"
        case .english: "text.book.closed.fill"
        case .lifeSkills: "sun.max.fill"
        }
    }
}

enum SceneKind: String, Codable {
    case bakery, trainBuilder, bridge, rocket, garden
    case farm, balanceBridge, riverJumps, picnic, mountain
    case campfire, delivery, robotRepair, tower, cave
    case lilyPond, festival, castle, mirrorLake, spaceStation
    case measureGarden, clockTrain, toyShop, fairPicnic, market
    case wakeUp, bathroomMorning, brushTeeth, getDressed, breakfast
    case setTable, cooking, dinner, dishes, laundry
    case cleanBedroom, findTeddy, bathTime, bedtime, dayAtHome
    case rainbowRoom, cafe, bathroomRoutine, weatherWardrobe, homeSafety
    case street, morningCards, adventureBag, playground, helperFestival
}

struct LevelDefinition: Identifiable, Codable, Equatable {
    let id: String
    let area: LearningArea
    let title: String
    let scene: SceneKind
    let instruction: String
    let vocabulary: [String]
    let difficulty: Int
}

enum Curriculum {
    static let levels: [LevelDefinition] = {
        guard let url = Bundle.main.url(forResource: "levels", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let result = try? JSONDecoder().decode([LevelDefinition].self, from: data) else {
            return fallback
        }
        return result
    }()

    static func levels(in area: LearningArea) -> [LevelDefinition] {
        levels.filter { $0.area == area }
    }

    static let fallback = [
        LevelDefinition(id: "E05", area: .english, title: "Family Breakfast", scene: .breakfast,
                        instruction: "Pour the milk into the cup.", vocabulary: ["milk", "cup", "bowl", "spoon"], difficulty: 2)
    ]
}

