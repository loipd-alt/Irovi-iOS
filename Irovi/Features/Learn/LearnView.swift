import SwiftUI

struct LearnView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Palette.Space.m) {
                    Text("Short reads on iron and your blood, with sources.")
                        .font(.subheadline)
                        .foregroundStyle(Palette.textSecondary)
                        .padding(.bottom, Palette.Space.s)
                    ForEach(Article.all) { article in
                        NavigationLink { ArticleView(article: article) } label: {
                            ArticleRow(article: article)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Palette.Space.gutter)
                .padding(.vertical, Palette.Space.l)
            }
            .background(Palette.background)
            .navigationTitle("Learn")
        }
    }
}

private struct ArticleRow: View {
    let article: Article

    var body: some View {
        HStack(alignment: .top, spacing: Palette.Space.m) {
            Text(article.emoji)
                .font(.title)
                .frame(width: 52, height: 52)
                .background(Palette.surfaceAlt, in: RoundedRectangle(cornerRadius: Palette.Radius.control, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Palette.Space.xs) {
                Text(article.title)
                    .font(.headline)
                    .foregroundStyle(Palette.textPrimary)
                    .multilineTextAlignment(.leading)
                Text(article.summary)
                    .font(.subheadline)
                    .foregroundStyle(Palette.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.textSecondary)
                .padding(.top, 4)
                .accessibilityHidden(true)
        }
        .padding(Palette.Space.l)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Palette.Radius.card, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct ArticleView: View {
    let article: Article

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Palette.Space.l) {
                Text(article.emoji)
                    .font(.system(size: 48))
                    .accessibilityHidden(true)
                Text(article.title)
                    .font(Palette.display(.title))
                    .foregroundStyle(Palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(article.body, id: \.self) { paragraph in
                    if paragraph.hasPrefix("• ") {
                        HStack(alignment: .firstTextBaseline, spacing: Palette.Space.s) {
                            Circle().fill(Palette.iron).frame(width: 6, height: 6)
                                .accessibilityHidden(true)
                            Text(String(paragraph.dropFirst(2)))
                        }
                        .foregroundStyle(Palette.textPrimary)
                    } else {
                        Text(paragraph)
                            .foregroundStyle(Palette.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                VStack(alignment: .leading, spacing: Palette.Space.s) {
                    Text("Sources")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.textSecondary)
                    ForEach(article.sources, id: \.self) { source in
                        Link(destination: source.url) {
                            Label(source.name, systemImage: "arrow.up.right.square")
                                .font(.subheadline)
                        }
                    }
                }
                .padding(.top, Palette.Space.s)
                CareNote(text: "General information only, not medical advice.")
            }
            .padding(.horizontal, Palette.Space.gutter)
            .padding(.vertical, Palette.Space.l)
        }
        .background(Palette.background)
        .navigationBarTitleDisplayMode(.inline)
    }
}
