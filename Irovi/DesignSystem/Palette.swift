import SwiftUI
import UIKit

/// Every visual token Irovi uses — colors, gradients, radii, spacing, type.
/// Change a value here and the whole app follows; views never hard-code a
/// color or a size.
///
/// Direction: fresh and lively. A ruby-to-raspberry accent for iron and
/// actions, leaf green for "done", and a soft pastel per food group, on a
/// clean warm-white background. Colors are (light, dark) 0xRRGGBB pairs; text
/// pairs keep WCAG contrast ≥ 4.5:1 (white on `iron` is 4.6:1).
enum Palette {
    // Surfaces
    static let background = dynamic(0xFFF7F4, 0x140E10)
    static let surface = dynamic(0xFFFFFF, 0x1E1618)
    static let surfaceAlt = dynamic(0xFBEEEA, 0x2A1F22)
    static let border = dynamic(0xF1E2DD, 0x3A2B2F)

    // Text
    static let textPrimary = dynamic(0x2A1B1F, 0xF5ECEE)
    static let textSecondary = dynamic(0x6F5A60, 0xC3AFB4)

    // Iron — primary actions, progress, hemoglobin
    static let iron = dynamic(0xD93A35, 0xFF7A6E)
    static let ironDeep = dynamic(0xA8124A, 0x8E0F3F)
    static let onIron = dynamic(0xFFFFFF, 0x2A0C0A)
    static let ironSoft = dynamic(0xFDE4E1, 0x3D1A1A)
    static let onIronSoft = dynamic(0x9E2420, 0xFFB4AB)

    // Leaf — plant foods, habits, goal reached
    static let leaf = dynamic(0x237A4B, 0x6CD39A)
    static let leafSoft = dynamic(0xDDF3E6, 0x163527)
    static let onLeafSoft = dynamic(0x17583A, 0xA6E9C4)

    // Amber — ferritin
    static let amber = dynamic(0xB45309, 0xFBBF24)
    static let amberSoft = dynamic(0xFEF0D9, 0x3A2A0C)

    /// Hero card background (white text sits on it).
    static let heroGradient = LinearGradient(
        colors: [dynamic(0xD93A35, 0xB8302B), dynamic(0xA8124A, 0x7A0D37)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    /// Floating add button.
    static let actionGradient = LinearGradient(
        colors: [dynamic(0xE8453C, 0xFF7A6E), dynamic(0xB8174A, 0xD9466E)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    enum Radius {
        static let card: CGFloat = 24
        static let tile: CGFloat = 20
        static let control: CGFloat = 14
    }

    enum Space {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let gutter: CGFloat = 20
    }

    enum Size {
        static let button: CGFloat = 52
        static let touch: CGFloat = 44
        static let fab: CGFloat = 60
    }

    /// Rounded display type for numbers and headings — part of Irovi's look.
    static func display(_ style: Font.TextStyle, weight: Font.Weight = .bold) -> Font {
        .system(style, design: .rounded).weight(weight)
    }

    fileprivate static func dynamic(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(rgb: dark) : UIColor(rgb: light) })
    }
}

extension FoodGroup {
    /// Pastel tile background for each food group (text stays `textPrimary`).
    var tint: Color {
        switch self {
        case .redMeat: Palette.dynamic(0xFDE4E1, 0x3A1A1C)
        case .seafood: Palette.dynamic(0xDDEEFB, 0x142636)
        case .poultry: Palette.dynamic(0xFEF0D9, 0x36260F)
        case .legumes: Palette.dynamic(0xEFE4FB, 0x271C38)
        case .greens: Palette.dynamic(0xDDF3E6, 0x143024)
        case .fortified: Palette.dynamic(0xFFF4CC, 0x332B10)
        }
    }
}

extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(red: CGFloat((rgb >> 16) & 0xFF) / 255,
                  green: CGFloat((rgb >> 8) & 0xFF) / 255,
                  blue: CGFloat(rgb & 0xFF) / 255,
                  alpha: 1)
    }
}
