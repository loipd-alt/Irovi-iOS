import SwiftUI
import UIKit

/// Every visual token Irovi uses — colors, radii, spacing, type. Change a value
/// here and the whole app follows; views never hard-code a color or a size.
///
/// Direction: warm and food-like. Terracotta for iron and actions, leaf green
/// for plant foods and "done", on a cream background. Colors are
/// (light, dark) 0xRRGGBB pairs; text pairs keep WCAG contrast ≥ 4.5:1.
enum Palette {
    // Surfaces
    static let background = dynamic(0xFBF6F0, 0x17120F)
    static let surface = dynamic(0xFFFFFF, 0x221B17)
    static let surfaceAlt = dynamic(0xF4ECE3, 0x2C231E)
    static let border = dynamic(0xE9DFD5, 0x3A2F29)

    // Text
    static let textPrimary = dynamic(0x2B201B, 0xF3ECE6)
    static let textSecondary = dynamic(0x6E5F57, 0xBFB1A7)

    // Iron (primary actions, progress, chart)
    static let iron = dynamic(0xB5401E, 0xF08A63)
    static let onIron = dynamic(0xFFFFFF, 0x2A120A)
    static let ironSoft = dynamic(0xF8E3D9, 0x3D2219)
    static let onIronSoft = dynamic(0x8A2E12, 0xF6B79D)

    // Leaf (plant foods, habits, completed state)
    static let leaf = dynamic(0x2F7A3E, 0x6CC67E)
    static let leafSoft = dynamic(0xE2F0E3, 0x1E3324)
    static let onLeafSoft = dynamic(0x1F5A2C, 0x9BDDA8)

    enum Radius {
        static let card: CGFloat = 22
        static let tile: CGFloat = 18
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
    }

    /// Rounded display type for numbers and headings — part of Irovi's look.
    static func display(_ style: Font.TextStyle, weight: Font.Weight = .bold) -> Font {
        .system(style, design: .rounded).weight(weight)
    }

    private static func dynamic(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(rgb: dark) : UIColor(rgb: light) })
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
