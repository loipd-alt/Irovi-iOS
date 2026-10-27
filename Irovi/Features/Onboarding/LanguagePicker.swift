import SwiftUI

/// Language choices, each in its own language so people can find theirs.
/// Changing it takes effect at once (the root view rebuilds).
struct LanguageList: View {
    @AppStorage(AppLanguage.key, store: AppLanguage.store) private var selection = AppLanguage.system.rawValue

    var body: some View {
        VStack(spacing: Palette.Space.s) {
            ForEach(AppLanguage.allCases) { language in
                let isOn = language.rawValue == selection
                Button {
                    selection = language.rawValue
                } label: {
                    HStack(spacing: Palette.Space.m) {
                        Group {
                            if let flag = language.flag {
                                Text(verbatim: flag).font(.title2)
                            } else {
                                Image(systemName: "globe").font(.title3.weight(.semibold)).foregroundStyle(Palette.iron)
                            }
                        }
                        .frame(width: 44, height: 44)
                        .background(Palette.surfaceAlt, in: Circle())
                        .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: language.nativeName)
                                .font(.body.weight(isOn ? .semibold : .regular))
                                .foregroundStyle(Palette.textPrimary)
                            if language == .system {
                                Text(verbatim: AppLanguage(rawValue: AppLanguage.system.code)?.nativeName ?? "English")
                                    .font(.footnote)
                                    .foregroundStyle(Palette.textSecondary)
                            }
                        }
                        Spacer()
                        if isOn {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Palette.iron)
                                .accessibilityHidden(true)
                        }
                    }
                    .padding(Palette.Space.m)
                    .background(isOn ? Palette.ironSoft : Palette.surface,
                                in: RoundedRectangle(cornerRadius: Palette.Radius.tile, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Palette.Radius.tile, style: .continuous)
                            .strokeBorder(isOn ? Palette.iron : Palette.border, lineWidth: isOn ? 2 : 1)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
    }
}

/// Settings → Language.
struct LanguageSettingsView: View {
    var body: some View {
        ScrollView {
            LanguageList()
                .padding(.horizontal, Palette.Space.gutter)
                .padding(.vertical, Palette.Space.l)
        }
        .background(Palette.background)
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
    }
}
