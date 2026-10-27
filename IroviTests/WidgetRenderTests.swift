import SwiftUI
import WidgetKit
import XCTest
@testable import Irovi

/// Renders the widget views to images (attached to the test result) so their
/// layout can be checked without adding them to a Home Screen.
@MainActor
final class WidgetRenderTests: XCTestCase {
    func testRenderHomeScreenWidgets() throws {
        let entry = PlateEntry(date: .now, eaten: [.redMeat, .greens], goal: 3, streak: 5)
        let sizes: [(WidgetFamily, CGSize, String)] = [
            (.systemSmall, CGSize(width: 170, height: 170), "small"),
            (.systemMedium, CGSize(width: 364, height: 170), "medium"),
        ]
        for (family, size, name) in sizes {
            let view = PlateWidgetView(entry: entry, familyOverride: family)
                .padding(16)
                .frame(width: size.width, height: size.height)
                .background(Palette.heroGradient)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            let renderer = ImageRenderer(content: view)
            renderer.scale = 3
            let image = try XCTUnwrap(renderer.uiImage, "\(name) widget did not render")
            XCTAssertEqual(image.size.width, size.width, accuracy: 1)
            let attachment = XCTAttachment(image: image)
            attachment.name = "widget-\(name)"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
}
