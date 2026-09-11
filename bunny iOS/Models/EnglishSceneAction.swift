import Foundation

struct EnglishSceneAction: Equatable {
    let itemID: String
    let mechanic: EnglishMechanic
    let targetName: String
    /// Top-left normalized room coordinates.
    let destination: CGPoint

    var gesturePrompt: String {
        switch mechanic {
        case .pour: "Hold to pour. Lift your finger to stop."
        case .brush: "Brush across all the teeth."
        case .scrub: "Rub away all the spots."
        case .stir: "Move the spoon around the bowl."
        case .fold: "Slide across to fold it."
        case .wear: "Help Pip put it on."
        case .toggleLight: "Tap the lamp."
        case .reveal: "Tap to look here."
        case .place: "Move it into place."
        }
    }
    var accessiblePrompt: String {
        switch mechanic {
        case .pour: "Pour a little"
        case .brush: "Brush the next teeth"
        case .scrub: "Clean the next spot"
        case .stir: "Stir a little"
        case .fold: "Fold the next side"
        default: "Put it in place"
        }
    }

    static func make(scene: SceneKind, itemID id: String) -> Self {
        func action(_ mechanic: EnglishMechanic, _ label: String, _ x: Double, _ y: Double) -> Self {
            .init(itemID: id, mechanic: mechanic, targetName: label, destination: CGPoint(x: x, y: y))
        }
        switch scene {
        case .wakeUp:
            if id == "lamp" { return action(.toggleLight, "Lamp", 0.72, 0.65) }
            if id == "pajamas" { return action(.fold, "Bed", 0.30, 0.30) }
            return action(.wear, "Pip", 0.22, 0.40)
        case .brushTeeth:
            if id == "toothpaste" { return action(.place, "Toothbrush", 0.45, 0.53) }
            return action(id == "toothbrush" ? .brush : .pour, "Pip", 0.32, 0.62)
        case .bathroomMorning:
            if id == "cup" { return action(.pour, "Tap", 0.22, 0.54) }
            return action(.place, id == "towel" ? "Towel rail" : "Toothbrush holder", id == "towel" ? 0.80 : 0.30, 0.50)
        case .getDressed:
            return id == "pajamas" ? action(.place, "Laundry basket", 0.16, 0.75) : action(.wear, "Pip", 0.35, id == "socks" ? 0.82 : 0.63)
        case .breakfast:
            if id == "milk" { return action(.pour, "Bowl", 0.50, 0.58) }
            if id == "spoon" { return action(.place, "Bowl", 0.56, 0.59) }
            return action(.place, id == "cup" ? "Beside the bowl" : "Table", id == "cup" ? 0.68 : 0.48, 0.59)
        case .cooking:
            if id == "milk" { return action(.pour, "Mixing bowl", 0.52, 0.53) }
            if id == "spoon" { return action(.stir, "Mixing bowl", 0.52, 0.53) }
            return action(.place, id == "plate" ? "Serving area" : "Counter", id == "plate" ? 0.73 : 0.52, 0.56)
        case .dishes:
            if id == "plate" { return action(.place, "Sink", 0.22, 0.57) }
            return action(.scrub, id == "towel" ? "Drying area" : "Sink", id == "towel" ? 0.60 : 0.24, 0.55)
        case .bedtime:
            if id == "lamp" { return action(.toggleLight, "Lamp", 0.46, 0.40) }
            return id == "pajamas" ? action(.wear, "Pip", 0.32, 0.65) : action(.place, "Bed", 0.29, 0.56)
        case .setTable:
            switch id {
            case "cup": return action(.place, "Above the plate", 0.49, 0.45)
            case "spoon": return action(.place, "Beside the plate", 0.66, 0.59)
            case "bowl": return action(.place, "Table", 0.33, 0.54)
            default: return action(.place, "Table", 0.49, 0.60)
            }
        case .dinner:
            return action(id == "cup" ? .pour : .place, "Pip", 0.36 + (id == "bowl" ? 0.18 : 0), 0.61)
        case .laundry:
            if id == "towel" { return action(.fold, "Folding table", 0.67, 0.55) }
            return action(.place, id == "socks" ? "Matching sock" : "Laundry basket", id == "socks" ? 0.63 : 0.22, 0.70)
        case .cleanBedroom:
            if id == "pajamas" { return action(.place, "Laundry basket", 0.16, 0.74) }
            return action(.place, id == "lamp" ? "Bedside table" : "Bed", id == "lamp" ? 0.46 : 0.30, id == "lamp" ? 0.40 : 0.58)
        case .findTeddy:
            if id == "teddy" { return action(.place, "Pip", 0.35, 0.64) }
            return action(.reveal, id == "lamp" ? "Beside the lamp" : "Behind the basket", id == "lamp" ? 0.46 : 0.17, id == "lamp" ? 0.40 : 0.73)
        case .bathTime:
            return action(id == "cup" ? .pour : id == "towel" ? .scrub : .wear, "Pip", 0.40, 0.65)
        case .dayAtHome:
            if id == "toothbrush" { return action(.brush, "Pip", 0.32, 0.62) }
            return id == "bowl" ? action(.place, "Breakfast table", 0.52, 0.56) : action(.wear, "Pip", 0.35, 0.65)
        default: return action(.place, "Table", 0.52, 0.56)
        }
    }
}
