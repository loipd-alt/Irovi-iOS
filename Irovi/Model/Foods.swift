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
        case .redMeat: String(localized: "Red meat & liver")
        case .seafood: String(localized: "Shellfish & fish")
        case .poultry: String(localized: "Poultry & eggs")
        case .legumes: String(localized: "Beans & tofu")
        case .greens: String(localized: "Dark leafy greens")
        case .fortified: String(localized: "Fortified grains & seeds")
        }
    }

    var examples: String {
        switch self {
        case .redMeat: String(localized: "Beef, pork, lamb, liver")
        case .seafood: String(localized: "Clams, oysters, mussels, sardines")
        case .poultry: String(localized: "Chicken, duck, turkey, eggs")
        case .legumes: String(localized: "Lentils, beans, chickpeas, tofu")
        case .greens: String(localized: "Spinach, kale, amaranth, water spinach")
        case .fortified: String(localized: "Fortified cereal, oats, pumpkin seeds")
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
        case .vitaminC: String(localized: "Vitamin C with a meal")
        case .teaApart: String(localized: "Tea & coffee away from meals")
        }
    }

    var detail: String {
        switch self {
        case .vitaminC: String(localized: "Orange, guava, tomato, bell pepper")
        case .teaApart: String(localized: "Between meals rather than with them")
        }
    }
}
