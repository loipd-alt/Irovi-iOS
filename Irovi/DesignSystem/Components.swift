import SwiftUI

/// A white panel with a soft, warm shadow — the base block of every screen.
struct Panel<Content: View>: View {
    var padding: CGFloat = Palette.Space.l
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Palette.Radius.card, style: .continuous))
            .shadow(color: Color(red: 0.35, green: 0.18, blue: 0.1).opacity(0.08), radius: 14, y: 6)
    }
}

/// Small uppercase-free section title with an optional trailing accessory.
struct SectionTitle<Accessory: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder var accessory: Accessory

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(Palette.display(.title3))
                .foregroundStyle(Palette.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            accessory
        }
    }
}

extension SectionTitle where Accessory == EmptyView {
    init(_ title: LocalizedStringKey) {
        self.title = title
        self.accessory = EmptyView()
    }
}

/// Full-width filled action.
struct FilledButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: Palette.Size.button)
            .foregroundStyle(Palette.onIron)
            .background(Palette.iron, in: RoundedRectangle(cornerRadius: Palette.Radius.control, style: .continuous))
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.4)
    }
}

/// Full-width tinted secondary action.
struct TintedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: Palette.Size.button)
            .foregroundStyle(Palette.onIronSoft)
            .background(Palette.ironSoft, in: RoundedRectangle(cornerRadius: Palette.Radius.control, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

extension ButtonStyle where Self == FilledButtonStyle {
    static var filled: FilledButtonStyle { FilledButtonStyle() }
}

extension ButtonStyle where Self == TintedButtonStyle {
    static var tinted: TintedButtonStyle { TintedButtonStyle() }
}

/// Equal-width choice chips in a soft track (used for metric and unit pickers).
struct ChoiceTrack<Value: Hashable>: View {
    let options: [Value]
    @Binding var selection: Value
    let label: (Value) -> LocalizedStringKey

    var body: some View {
        HStack(spacing: Palette.Space.xs) {
            ForEach(options, id: \.self) { option in
                let isOn = option == selection
                Button {
                    withAnimation(.snappy) { selection = option }
                } label: {
                    Text(label(option))
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .foregroundStyle(isOn ? Palette.onIron : Palette.textSecondary)
                        .background(isOn ? Palette.iron : .clear,
                                    in: RoundedRectangle(cornerRadius: Palette.Radius.control - 4, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .padding(Palette.Space.xs)
        .background(Palette.surfaceAlt, in: RoundedRectangle(cornerRadius: Palette.Radius.control, style: .continuous))
    }
}

/// Footnote that reminds the user the app is not medical advice.
struct CareNote: View {
    let text: LocalizedStringKey

    var body: some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: "stethoscope")
        }
        .font(.footnote)
        .foregroundStyle(Palette.textSecondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
