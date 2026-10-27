import SwiftData
import SwiftUI

/// First launch: language → three short intro pages → daily goal and an
/// optional reminder. No account; notification permission only if asked for.
/// The step is stored so a language change (which rebuilds the UI) keeps it.
struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @AppStorage(Prefs.onboarded) private var onboarded = false
    @AppStorage(Prefs.onboardingStep) private var step = 0
    @AppStorage(Prefs.dailyGoal) private var goal = Prefs.defaultGoal
    @AppStorage(Prefs.foodReminderOn) private var reminderOn = false
    @AppStorage(Prefs.foodReminderMinutes) private var reminderMinutes = Prefs.defaultFoodReminderMinutes

    private static let introPages = 1...3
    private static let goalStep = 4

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                Group {
                    switch step {
                    case 0: languageStep
                    case Self.introPages: IntroPage(page: step)
                    default: goalStep
                    }
                }
                .padding(.horizontal, Palette.Space.gutter)
                .padding(.vertical, Palette.Space.l)
                .id(step)
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
            }
            if Self.introPages.contains(step) {
                PageDots(count: Self.introPages.count, current: step - Self.introPages.lowerBound)
                    .padding(.bottom, Palette.Space.s)
            }
            bottomButton
        }
        .background(Palette.background)
        .animation(.easeInOut(duration: 0.3), value: step)
    }

    // MARK: - Chrome

    private var topBar: some View {
        HStack {
            if step > 0 {
                Button { step -= 1 } label: {
                    Image(systemName: "chevron.left").font(.title3.weight(.semibold))
                }
                .accessibilityLabel("Back")
            }
            Spacer()
        }
        .tint(Palette.iron)
        .frame(height: Palette.Size.touch)
        .padding(.horizontal, Palette.Space.gutter)
    }

    private var bottomButton: some View {
        Button(buttonTitle) {
            if step >= Self.goalStep { finish() } else { step += 1 }
        }
        .buttonStyle(.filled)
        .padding(.horizontal, Palette.Space.gutter)
        .padding(.vertical, Palette.Space.m)
    }

    private var buttonTitle: LocalizedStringKey {
        switch step {
        case 0: "Continue"
        case Self.goalStep...: "Start"
        default: "Next"
        }
    }

    // MARK: - Steps

    private var languageStep: some View {
        VStack(alignment: .leading, spacing: Palette.Space.xl) {
            Image("BrandMark")
                .resizable()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Palette.Space.s) {
                Text("Choose your language")
                    .font(Palette.display(.largeTitle))
                    .foregroundStyle(Palette.textPrimary)
                Text("You can change it later in Settings.")
                    .foregroundStyle(Palette.textSecondary)
            }
            LanguageList()
        }
    }

    private var goalStep: some View {
        VStack(alignment: .leading, spacing: Palette.Space.xl) {
            VStack(alignment: .leading, spacing: Palette.Space.s) {
                Text("Your daily goal")
                    .font(Palette.display(.largeTitle))
                    .foregroundStyle(Palette.textPrimary)
                Text("How many iron-rich food groups would you like on your plate each day?")
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Panel {
                VStack(alignment: .leading, spacing: Palette.Space.m) {
                    HStack {
                        Text("\(goal)")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Palette.iron)
                            .frame(minWidth: 56)
                        Text("food groups a day")
                            .font(.headline)
                            .foregroundStyle(Palette.textPrimary)
                        Spacer()
                        Stepper("Daily goal", value: $goal, in: 1...FoodGroup.allCases.count)
                            .labelsHidden()
                    }
                    // What a "food group" is, so the number means something.
                    HStack(spacing: Palette.Space.s) {
                        ForEach(FoodGroup.allCases) { food in
                            Text(food.emoji)
                                .font(.title3)
                                .frame(width: 40, height: 40)
                                .background(food.tint, in: Circle())
                        }
                    }
                    .accessibilityHidden(true)
                    Text("Six groups: red meat, seafood, poultry, beans, leafy greens, fortified grains.")
                        .font(.footnote)
                        .foregroundStyle(Palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Panel {
                VStack(alignment: .leading, spacing: Palette.Space.m) {
                    Toggle("Daily food reminder", isOn: $reminderOn)
                        .font(.headline)
                    if reminderOn {
                        DatePicker("Time", selection: reminderTime, displayedComponents: .hourAndMinute)
                    }
                    Text("You can change these any time in Settings.")
                        .font(.footnote)
                        .foregroundStyle(Palette.textSecondary)
                }
            }
        }
    }

    private var reminderTime: Binding<Date> {
        Binding(get: { .todayAt(minutes: reminderMinutes) }, set: { reminderMinutes = $0.minutesAfterMidnight })
    }

    private func finish() {
        Task {
            if reminderOn {
                reminderOn = await Reminders.requestPermission()
                await Reminders.sync(context)
            }
            step = 0
            onboarded = true
        }
    }
}

/// One intro page: an illustration, a title and a line of text.
private struct IntroPage: View {
    let page: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Palette.Space.xl) {
            illustration
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Palette.Space.s) {
                Text(title)
                    .font(Palette.display(.largeTitle))
                    .foregroundStyle(Palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(message)
                    .font(.body)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if page == 3 {
                CareNote(text: "Irovi is a wellness diary, not a medical device. It does not diagnose or recommend treatment. Talk to your doctor about your health.")
            }
        }
    }

    private var title: LocalizedStringKey {
        switch page {
        case 1: "Build an iron-rich plate"
        case 2: "Keep your blood results together"
        default: "Gentle reminders, fully private"
        }
    }

    private var message: LocalizedStringKey {
        switch page {
        case 1: "Tick the iron-rich food groups you eat each day and keep a streak going."
        case 2: "Add hemoglobin and ferritin from your lab report and see how they change over time."
        default: "Optional reminders for meals, your medicines and your next test. Everything stays on your iPhone."
        }
    }

    @ViewBuilder
    private var illustration: some View {
        switch page {
        case 1: PlateIllustration()
        case 2: ChartIllustration()
        default: PrivacyIllustration()
        }
    }
}

/// A plate with the six food groups around it.
private struct PlateIllustration: View {
    var body: some View {
        ZStack {
            Circle().fill(Palette.ironSoft).frame(width: 280, height: 280)
            Circle().fill(Palette.surface).frame(width: 170, height: 170)
                .shadow(color: Palette.ironDeep.opacity(0.18), radius: 16, y: 8)
            Circle().strokeBorder(Palette.border, lineWidth: 6).frame(width: 136, height: 136)
            Text(verbatim: "🩸").font(.system(size: 54))
            ForEach(Array(FoodGroup.allCases.enumerated()), id: \.offset) { index, food in
                let angle = Angle.degrees(Double(index) / 6 * 360 - 90)
                Text(food.emoji)
                    .font(.system(size: 28))
                    .frame(width: 58, height: 58)
                    .background(food.tint, in: Circle())
                    .overlay(Circle().strokeBorder(Palette.surface, lineWidth: 3))
                    .offset(x: cos(angle.radians) * 118, y: sin(angle.radians) * 118)
            }
        }
    }
}

/// A miniature results card with a rising line.
private struct ChartIllustration: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 36, style: .continuous).fill(Palette.amberSoft).frame(width: 300, height: 260)
            VStack(alignment: .leading, spacing: Palette.Space.m) {
                Text("Hemoglobin")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.textSecondary)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(verbatim: "12.1").font(.system(size: 40, weight: .bold, design: .rounded))
                    Text(verbatim: "g/dL").font(.subheadline).foregroundStyle(Palette.textSecondary)
                }
                GeometryReader { geo in
                    let points: [CGFloat] = [0.78, 0.66, 0.70, 0.48, 0.36, 0.18]
                    let step = geo.size.width / CGFloat(points.count - 1)
                    Path { path in
                        for (i, y) in points.enumerated() {
                            let point = CGPoint(x: CGFloat(i) * step, y: y * geo.size.height)
                            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
                        }
                    }
                    .stroke(Palette.iron, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    ForEach(Array(points.enumerated()), id: \.offset) { i, y in
                        Circle().fill(Palette.iron).frame(width: 12, height: 12)
                            .position(x: CGFloat(i) * step, y: y * geo.size.height)
                    }
                }
                .frame(height: 90)
            }
            .padding(Palette.Space.xl)
            .frame(width: 240)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Palette.Radius.card, style: .continuous))
            .shadow(color: Palette.ironDeep.opacity(0.15), radius: 18, y: 10)
        }
    }
}

/// Bell and lock cards: reminders and privacy.
private struct PrivacyIllustration: View {
    var body: some View {
        ZStack {
            Circle().fill(Palette.leafSoft).frame(width: 280, height: 280)
            card(symbol: "bell.badge.fill", tint: Palette.iron, soft: Palette.ironSoft)
                .rotationEffect(.degrees(-8))
                .offset(x: -58, y: -24)
            card(symbol: "lock.fill", tint: Palette.leaf, soft: Palette.leafSoft)
                .rotationEffect(.degrees(7))
                .offset(x: 62, y: 34)
        }
    }

    private func card(symbol: String, tint: Color, soft: Color) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 44, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: 120, height: 120)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).strokeBorder(soft, lineWidth: 4))
            .shadow(color: Palette.ironDeep.opacity(0.15), radius: 14, y: 8)
    }
}

private struct PageDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Palette.iron : Palette.border)
                    .frame(width: index == current ? 22 : 8, height: 8)
            }
        }
        .animation(.snappy, value: current)
        .accessibilityHidden(true)
    }
}
