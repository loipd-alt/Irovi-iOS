import SwiftUI

/// Brand moment on launch: the icon, name and promise on the hero gradient.
/// Shown for about a second, then fades into the app.
struct SplashView: View {
    @State private var appeared = false

    var body: some View {
        ZStack {
            Palette.heroGradient.ignoresSafeArea()
            VStack(spacing: Palette.Space.l) {
                Image("BrandMark")
                    .resizable()
                    .frame(width: 112, height: 112)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(color: .black.opacity(0.25), radius: 20, y: 10)
                Text(verbatim: "Irovi")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Iron & blood health")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .scaleEffect(appeared ? 1 : 0.86)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.6)) { appeared = true }
        }
        .accessibilityElement(children: .combine)
    }
}
