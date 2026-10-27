import Foundation

/// Short reading cards. Content follows the NIH Office of Dietary Supplements
/// iron fact sheet and the WHO anaemia fact sheet; every article lists its
/// sources. The text lives in `Resources/Articles/articles.<language>.json`
/// (one file per language); emoji and sources are the same in every language.
struct Article: Identifiable, Hashable {
    struct Source: Hashable {
        let name: String
        let url: URL
    }

    let id: String
    let emoji: String
    let title: String
    let summary: String
    /// Paragraphs; a paragraph starting with "• " is shown as a bullet.
    let body: [String]
    let sources: [Source]

    /// Articles in the app's current language, falling back to English.
    static var all: [Article] {
        let code = AppLanguage.current.code
        if let cached = cache[code] { return cached }
        let articles = load(code) ?? load("en") ?? []
        cache[code] = articles
        return articles
    }

    static var tipOfTheDay: Article {
        let list = all
        let day = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 0
        return list[day % max(list.count, 1)]
    }

    nonisolated(unsafe) private static var cache: [String: [Article]] = [:]

    private struct Text: Decodable {
        let id: String
        let title: String
        let summary: String
        let body: [String]
    }

    private static let nih = Source(name: "NIH Office of Dietary Supplements: Iron",
                                    url: URL(string: "https://ods.od.nih.gov/factsheets/Iron-Consumer/")!)
    private static let who = Source(name: "World Health Organization: Anaemia",
                                    url: URL(string: "https://www.who.int/news-room/fact-sheets/detail/anaemia")!)

    private static let meta: [String: (emoji: String, sources: [Source])] = [
        "two-kinds": ("🥩", [nih]),
        "vitamin-c": ("🍊", [nih]),
        "tea-coffee": ("☕️", [nih]),
        "how-much": ("📏", [nih]),
        "hb-ferritin": ("🩸", [nih, who]),
        "doctor": ("🩺", [who, nih]),
    ]

    private static func load(_ code: String) -> [Article]? {
        guard let url = Bundle.main.url(forResource: "articles.\(code)", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let texts = try? JSONDecoder().decode([Text].self, from: data) else { return nil }
        return texts.compactMap { text in
            guard let info = meta[text.id] else { return nil }
            return Article(id: text.id, emoji: info.emoji, title: text.title, summary: text.summary,
                           body: text.body, sources: info.sources)
        }
    }
}
