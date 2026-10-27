import SwiftData
import SwiftUI

/// Two short steps: what Irovi is (and is not), then the daily goal and an
/// optional reminder. No account; notification permission only if asked for.
struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @AppStorage(Prefs.onboarded) private var onboarded = false
    @AppStorage(Prefs.dailyGoal) private var goal = Prefs.defaultGoal
    @AppStorage(Prefs.foodReminderOn) private var reminderOn = false
    @AppStorage(Prefs.foodReminderMinutes) private var reminderMinutes = Prefs.defaultFoodReminderMinutes

    @State private var step = 0

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                Group {
                    if step == 0 { welcome } else { setup }
                }
                .padding(.horizontal, Palette.Space.gutter)
                .padding(.top, Palette.Space.xl)
                .padding(.bottom, Palette.Space.l)
            }
            bottomBar
        }
        .background(Palette.background)
        .animation(.easeInOut(duration: 0.25), value: step)
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: Palette.Space.xl) {
            Image("BrandMark")
                .resizable()
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Palette.Space.s) {
                Text("Eat for iron. Keep an eye on your blood.")
                    .font(Palette.display(.largeTitle))
                    .foregroundStyle(Palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("A simple daily companion for people who want more iron in their diet.")
                    .font(.body)
                    .foregroundStyle(Palette.textSecondary)
            }
            VStack(spacing: Palette.Space.m) {
                point("🥬", "Tick the iron-rich foods you ate today")
                point("🩸", "Keep your hemoglobin and ferritin results in one place")
                point("⏰", "Gentle reminders for meals, your own medicines and your next test")
            }
            CareNote(text: "Irovi is a wellness diary, not a medical device. It does not diagnose or recommend treatment. Talk to your doctor about your health.")
        }
    }

    private var setup: some View {
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

    private var bottomBar: some View {
        Button(step == 0 ? "Continue" : "Start") {
            if step == 0 { step = 1 } else { finish() }
        }
        .buttonStyle(.filled)
        .padding(.horizontal, Palette.Space.gutter)
        .padding(.vertical, Palette.Space.m)
        .background(Palette.background)
    }

    private var reminderTime: Binding<Date> {
        Binding(get: { .todayAt(minutes: reminderMinutes) }, set: { reminderMinutes = $0.minutesAfterMidnight })
    }

    private func point(_ emoji: String, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: Palette.Space.m) {
            Text(emoji)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(Palette.surfaceAlt, in: Circle())
                .accessibilityHidden(true)
            Text(text)
                .font(.body)
                .foregroundStyle(Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
            Spacer(minLength: 0)
        }
    }

    private func finish() {
        Task {
            if reminderOn {
                reminderOn = await Reminders.requestPermission()
                await Reminders.sync(context)
            }
            onboarded = true
        }
    }
}
