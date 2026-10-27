import SwiftUI
import WidgetKit
#if IROVI_TESTS
@testable import Irovi // only when compiled into IroviTests, to render the widget in a test
#endif

struct PlateEntry: TimelineEntry {
    let date: Date
    let eaten: Set<FoodGroup>
    let goal: Int
    let streak: Int
}

struct PlateWidgetView: View {
    let entry: PlateEntry
    /// Only for rendering in tests; WidgetKit supplies the family otherwise.
    var familyOverride: WidgetFamily?
    @Environment(\.widgetFamily) private var environmentFamily
    private var family: WidgetFamily { familyOverride ?? environmentFamily }

    private var fraction: Double { ChecklistProgress.fraction(checked: entry.eaten.count, goal: entry.goal) }
    private var done: Bool { entry.eaten.count >= entry.goal }

    var body: some View {
        switch family {
        case .accessoryCircular:
            Gauge(value: fraction) {
                Image(systemName: "drop.fill")
            } currentValueLabel: {
                Text(verbatim: done ? "✓" : "\(entry.eaten.count)")
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .containerBackground(.clear, for: .widget)

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("Iron plate").font(.headline)
                Text(done ? "Goal reached today" : "\(entry.eaten.count) of \(entry.goal) food groups")
                    .font(.subheadline)
                if entry.streak > 0 {
                    Text(entry.streak == 1 ? "🔥 1 day in a row" : "🔥 \(entry.streak) days in a row")
                        .font(.caption)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .containerBackground(.clear, for: .widget)

        case .systemMedium:
            HStack(spacing: 16) {
                summary
                VStack(spacing: 8) {
                    ForEach([Array(FoodGroup.allCases.prefix(3)), Array(FoodGroup.allCases.suffix(3))], id: \.self) { row in
                        HStack(spacing: 8) {
                            ForEach(row) { food in
                                Text(food.emoji)
                                    .font(.title3)
                                    .frame(width: 40, height: 40)
                                    .background(.white.opacity(entry.eaten.contains(food) ? 0.95 : 0.18), in: Circle())
                                    .opacity(entry.eaten.contains(food) ? 1 : 0.55)
                            }
                        }
                    }
                }
            }
            .containerBackground(for: .widget) { Palette.heroGradient }

        default:
            summary
                .containerBackground(for: .widget) { Palette.heroGradient }
        }
    }

    /// Ring, count and streak in white, for the gradient Home Screen widgets.
    private var summary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's iron plate")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            HStack(spacing: 10) {
                ZStack {
                    Circle().stroke(.white.opacity(0.25), lineWidth: 7)
                    Circle()
                        .trim(from: 0, to: fraction)
                        .stroke(.white, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text(verbatim: done ? "✓" : "\(entry.eaten.count)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .frame(width: 52, height: 52)
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: "\(entry.eaten.count)/\(entry.goal)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("food groups")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            Spacer(minLength: 0)
            Text(verbatim: entry.streak > 0 ? "🔥 \(entry.streak)" : " ")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
