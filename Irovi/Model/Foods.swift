import Foundation

/// The six iron-rich food groups on the daily checklist. Grouping follows the
/// NIH Office of Dietary Supplements iron fact sheet (heme iron from meat,
/// seafood and poultry; non-heme iron from plants and fortified foods).
enum FoodGroup: String, CaseIterable, Identifiable, Codable {
    case redMeat, seafood, poultry, legumes, greens, fortified

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .redMeat: "🥩"
        case .seafood: "🦪"
        case .poultry: "🍗"
        case .legumes: "🫘"
        case .greens: "🥬"
        case .fortified: "🥣"
        }
    }

    var name: String {
        switch self {
        case .redMeat: localized("Red meat & liver")
        case .seafood: localized("Shellfish & fish")
        case .poultry: localized("Poultry & eggs")
        case .legumes: localized("Beans & tofu")
        case .greens: localized("Dark leafy greens")
        case .fortified: localized("Fortified grains & seeds")
        }
    }

    var examples: String {
        switch self {
        case .redMeat: localized("Beef, pork, lamb, liver")
        case .seafood: localized("Clams, oysters, mussels, sardines")
        case .poultry: localized("Chicken, duck, turkey, eggs")
        case .legumes: localized("Lentils, beans, chickpeas, tofu")
        case .greens: localized("Spinach, kale, amaranth, water spinach")
        case .fortified: localized("Fortified cereal, oats, pumpkin seeds")
        }
    }

    /// Heme iron (animal foods) is absorbed more easily than plant iron.
    var isHeme: Bool { [.redMeat, .seafood, .poultry].contains(self) }
}

/// Two habits that help the body absorb iron from food.
enum IronHabit: String, CaseIterable, Identifiable, Codable {
    case vitaminC, teaApart

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .vitaminC: "🍊"
        case .teaApart: "☕️"
        }
    }

    var name: String {
        switch self {
        case .vitaminC: localized("Vitamin C with a meal")
        case .teaApart: localized("Tea & coffee away from meals")
        }
    }

    var detail: String {
        switch self {
        case .vitaminC: localized("Orange, guava, tomato, bell pepper")
        case .teaApart: localized("Between meals rather than with them")
        }
    }
}
