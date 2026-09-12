import Foundation
import CoreGraphics

/// A single draggable object on a scene canvas.
struct MissionItem: Equatable {
    let id: String
    let imageName: String
    let label: String
}

/// Static drop target for legacy placement mechanics.
struct SceneDropTarget: Equatable {
    let label: String
    let x: Double
    let y: Double
}

/// The visual backdrop of a scene.
struct SceneRoom: Equatable {
    let assetName: String
    let ambience: String
}

/// One full home routine in the immersive game.
struct HomeMissionSpec: Equatable {
    let scene: SceneKind
    let title: String
    let room: SceneRoom
    let sequence: [String]
    let items: [MissionItem]
    let stepInstructions: [String]

    static func spec(for scene: SceneKind) -> HomeMissionSpec {
        switch scene {
        case .wakeUp: return wakeUp
        case .bathroomMorning: return bathroomMorning
        case .brushTeeth: return brushTeeth
        case .getDressed: return getDressed
        case .breakfast: return breakfast
        case .setTable: return setTable
        case .cooking: return cooking
        case .dinner: return dinner
        case .dishes: return dishes
        case .laundry: return laundry
        case .cleanBedroom: return cleanBedroom
        case .findTeddy: return findTeddy
        case .bathTime: return bathTime
        case .bedtime: return bedtime
        case .dayAtHome: return dayAtHome
        // Math scenes share one of four illustrated Math backdrops. Group
        // them by setting (bakery/market/festival/space) or fall back to the
        // generic outdoors scene for adventure / nature themes.
        case .bakery, .measureGarden: return mathBakery
        case .market, .fairPicnic: return mathMarket
        case .festival, .helperFestival, .castle: return mathFestival
        case .spaceStation, .rocket: return mathSpace
        default:
            return outdoorFallback(for: scene)
        }
    }

    /// Generic Math/Life Skills fallback: outdoor backdrop with no items, so
    /// the LessonPlanScene and any other spec consumer can still preview the
    /// scene without falling back to the English bedroom.
    private static func outdoorFallback(for scene: SceneKind) -> HomeMissionSpec {
        HomeMissionSpec(
            scene: scene,
            title: "Explore",
            room: SceneRoom(assetName: "MathOutdoors", ambience: "An outdoor scene"),
            sequence: [],
            items: [],
            stepInstructions: ["Tap any object to begin."]
        )
    }

    private static let mathBakery = HomeMissionSpec(
        scene: .bakery,
        title: "Bakery Box Rescue",
        room: SceneRoom(assetName: "MathBakery", ambience: "A friendly bakery"),
        sequence: [],
        items: [],
        stepInstructions: ["Tap any object to begin."]
    )

    private static let mathMarket = HomeMissionSpec(
        scene: .market,
        title: "Market Math",
        room: SceneRoom(assetName: "MathMarket", ambience: "An outdoor market"),
        sequence: [],
        items: [],
        stepInstructions: ["Tap any object to begin."]
    )

    private static let mathFestival = HomeMissionSpec(
        scene: .festival,
        title: "Festival Fun",
        room: SceneRoom(assetName: "MathFestival", ambience: "A bright festival"),
        sequence: [],
        items: [],
        stepInstructions: ["Tap any object to begin."]
    )

    private static let mathSpace = HomeMissionSpec(
        scene: .spaceStation,
        title: "Space Station",
        room: SceneRoom(assetName: "MathSpace", ambience: "A space station"),
        sequence: [],
        items: [],
        stepInstructions: ["Tap any object to begin."]
    )

    private static func item(_ id: String, _ image: String, _ label: String) -> MissionItem {
        MissionItem(id: id, imageName: image, label: label)
    }

    private static let wakeUp = HomeMissionSpec(
        scene: .wakeUp,
        title: "Wake Up, Pip!",
        room: SceneRoom(assetName: "Bedroom", ambience: "A cozy morning room"),
        sequence: ["lamp", "pajamas", "shirt"],
        items: [
            item("lamp", "TableLamp", "Table lamp"),
            item("pajamas", "Pajamas", "Pajamas"),
            item("shirt", "Shirt", "Shirt")
        ],
        stepInstructions: [
            "Tap the lamp to turn on the light.",
            "Fold the pajamas and put them on the bed.",
            "Pick up the shirt for later."
        ]
    )

    private static let bathroomMorning = HomeMissionSpec(
        scene: .bathroomMorning,
        title: "Bathroom Morning",
        room: SceneRoom(assetName: "Bathroom", ambience: "A fresh bathroom"),
        sequence: ["towel", "toothbrush", "cup"],
        items: [
            item("towel", "Towel", "Towel"),
            item("toothbrush", "Toothbrush", "Toothbrush"),
            item("cup", "Cup", "Cup")
        ],
        stepInstructions: [
            "Hang the towel on the towel rail.",
            "Place the toothbrush in the holder.",
            "Fill the cup with water."
        ]
    )

    private static let brushTeeth = HomeMissionSpec(
        scene: .brushTeeth,
        title: "Brush Your Teeth",
        room: SceneRoom(assetName: "Bathroom", ambience: "Squeaky-clean teeth time"),
        sequence: ["toothpaste", "toothbrush", "cup"],
        items: [
            item("toothpaste", "Toothpaste", "Toothpaste"),
            item("toothbrush", "Toothbrush", "Toothbrush"),
            item("cup", "Cup", "Cup")
        ],
        stepInstructions: [
            "Squeeze the toothpaste onto the toothbrush.",
            "Brush in little circles.",
            "Rinse with water from the cup."
        ]
    )

    private static let getDressed = HomeMissionSpec(
        scene: .getDressed,
        title: "Get Dressed",
        room: SceneRoom(assetName: "Bedroom", ambience: "Pick your outfit"),
        sequence: ["shirt", "pants", "socks", "shoes"],
        items: [
            item("shirt", "Shirt", "Shirt"),
            item("pants", "Shirt", "Pants"),
            item("socks", "Socks", "Socks"),
            item("shoes", "Socks", "Shoes")
        ],
        stepInstructions: [
            "Put on your shirt.",
            "Now put on your pants.",
            "Pull up your socks.",
            "Step into your shoes."
        ]
    )

    private static let breakfast = HomeMissionSpec(
        scene: .breakfast,
        title: "Family Breakfast",
        room: SceneRoom(assetName: "DiningRoom", ambience: "A warm dining room"),
        sequence: ["bowl", "milk", "spoon"],
        items: [
            item("bowl", "Bowl", "Bowl"),
            item("milk", "MilkCarton", "Milk"),
            item("spoon", "Spoon", "Spoon")
        ],
        stepInstructions: [
            "Place the bowl on the table.",
            "Pour the milk into the bowl.",
            "Stir with the spoon."
        ]
    )

    private static let setTable = HomeMissionSpec(
        scene: .setTable,
        title: "Set the Table",
        room: SceneRoom(assetName: "DiningRoom", ambience: "Get the table ready"),
        sequence: ["plate", "cup", "spoon", "bowl"],
        items: [
            item("plate", "Plate", "Plate"),
            item("cup", "Cup", "Cup"),
            item("spoon", "Spoon", "Spoon"),
            item("bowl", "Bowl", "Bowl")
        ],
        stepInstructions: [
            "Place the plate on the table.",
            "Put the cup above the plate.",
            "Set the spoon beside the plate.",
            "Add the bowl on the table."
        ]
    )

    private static let cooking = HomeMissionSpec(
        scene: .cooking,
        title: "Cook with the Family",
        room: SceneRoom(assetName: "Kitchen", ambience: "Family kitchen smells like cinnamon"),
        sequence: ["bowl", "milk", "spoon", "plate"],
        items: [
            item("bowl", "Bowl", "Mixing bowl"),
            item("milk", "MilkCarton", "Milk"),
            item("spoon", "Spoon", "Spoon"),
            item("plate", "Plate", "Plate")
        ],
        stepInstructions: [
            "Place the mixing bowl on the counter.",
            "Pour the milk into the bowl.",
            "Stir the milk with the spoon.",
            "Serve it on the plate."
        ]
    )

    private static let dinner = HomeMissionSpec(
        scene: .dinner,
        title: "Dinner Together",
        room: SceneRoom(assetName: "DiningRoom", ambience: "The family gathers"),
        sequence: ["plate", "bowl", "cup", "spoon"],
        items: [
            item("plate", "Plate", "Plate"),
            item("bowl", "Bowl", "Bowl"),
            item("cup", "Cup", "Cup"),
            item("spoon", "Spoon", "Spoon")
        ],
        stepInstructions: [
            "Pass the plate, please.",
            "Pass the bowl, please.",
            "Pour a drink into the cup.",
            "Hand over the spoon."
        ]
    )

    private static let dishes = HomeMissionSpec(
        scene: .dishes,
        title: "Wash the Dishes",
        room: SceneRoom(assetName: "Kitchen", ambience: "Splashy sink time"),
        sequence: ["plate", "sponge", "towel"],
        items: [
            item("plate", "Plate", "Plate"),
            item("sponge", "Sponge", "Sponge"),
            item("towel", "Towel", "Towel")
        ],
        stepInstructions: [
            "Place the plate in the sink.",
            "Scrub the plate with the sponge.",
            "Dry the clean plate with the towel."
        ]
    )

    private static let laundry = HomeMissionSpec(
        scene: .laundry,
        title: "Laundry Day",
        room: SceneRoom(assetName: "LaundryRoom", ambience: "Warm clean clothes"),
        sequence: ["socks", "shirt", "towel"],
        items: [
            item("socks", "Socks", "Socks"),
            item("shirt", "Shirt", "Shirt"),
            item("towel", "Towel", "Towel")
        ],
        stepInstructions: [
            "Match the socks.",
            "Put the shirt in the laundry basket.",
            "Fold the towel on the folding table."
        ]
    )

    private static let cleanBedroom = HomeMissionSpec(
        scene: .cleanBedroom,
        title: "Clean the Bedroom",
        room: SceneRoom(assetName: "Bedroom", ambience: "Tidy-up time"),
        sequence: ["pajamas", "teddy", "lamp"],
        items: [
            item("pajamas", "Pajamas", "Pajamas"),
            item("teddy", "TeddyBear", "Teddy"),
            item("lamp", "TableLamp", "Lamp")
        ],
        stepInstructions: [
            "Put the pajamas in the laundry basket.",
            "Place teddy on the bed.",
            "Move the lamp onto the bedside table."
        ]
    )

    private static let findTeddy = HomeMissionSpec(
        scene: .findTeddy,
        title: "Where Is My Teddy?",
        room: SceneRoom(assetName: "Bedroom", ambience: "Peek-a-boo!"),
        sequence: ["lamp", "shirt", "teddy"],
        items: [
            item("lamp", "TableLamp", "Lamp"),
            item("shirt", "Shirt", "Shirt"),
            item("teddy", "TeddyBear", "Teddy")
        ],
        stepInstructions: [
            "Look beside the lamp.",
            "Look behind the basket.",
            "Tap to bring Teddy to Pip."
        ]
    )

    private static let bathTime = HomeMissionSpec(
        scene: .bathTime,
        title: "Bath Time",
        room: SceneRoom(assetName: "Bathroom", ambience: "Bubbly bath time"),
        sequence: ["cup", "towel", "pajamas"],
        items: [
            item("cup", "Cup", "Cup"),
            item("towel", "Towel", "Towel"),
            item("pajamas", "Pajamas", "Pajamas")
        ],
        stepInstructions: [
            "Rinse with the cup.",
            "Dry off with the towel.",
            "Put on cozy pajamas."
        ]
    )

    private static let bedtime = HomeMissionSpec(
        scene: .bedtime,
        title: "Time for Bed",
        room: SceneRoom(assetName: "BedroomScene", ambience: "Softly glowing nightlight"),
        sequence: ["pajamas", "teddy", "lamp"],
        items: [
            item("pajamas", "Pajamas", "Pajamas"),
            item("teddy", "TeddyBear", "Teddy"),
            item("lamp", "TableLamp", "Lamp")
        ],
        stepInstructions: [
            "Put on your pajamas.",
            "Tuck Teddy into bed.",
            "Turn off the lamp."
        ]
    )

    private static let dayAtHome = HomeMissionSpec(
        scene: .dayAtHome,
        title: "A Day at Home",
        room: SceneRoom(assetName: "DiningRoom", ambience: "A whole day at home"),
        sequence: ["shirt", "toothbrush", "bowl", "pajamas"],
        items: [
            item("shirt", "Shirt", "Shirt"),
            item("toothbrush", "Toothbrush", "Toothbrush"),
            item("bowl", "Bowl", "Bowl"),
            item("pajamas", "Pajamas", "Pajamas")
        ],
        stepInstructions: [
            "Get dressed for the day.",
            "Brush your teeth.",
            "Eat from the bowl.",
            "Change into pajamas for bed."
        ]
    )
}