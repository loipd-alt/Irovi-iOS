import Foundation

/// Short reading cards. Content follows the NIH Office of Dietary Supplements
/// iron fact sheet and the WHO anaemia fact sheet; every article lists its
/// sources. Text is kept here (not in the string catalog) because it is long
/// prose; the language follows the app's current localization.
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

    static var all: [Article] { isVietnamese ? vi : en }

    static var tipOfTheDay: Article {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 0
        return all[day % all.count]
    }

    private static var isVietnamese: Bool {
        Bundle.main.preferredLocalizations.first?.hasPrefix("vi") == true
    }

    private static let nih = Source(name: "NIH Office of Dietary Supplements: Iron",
                                    url: URL(string: "https://ods.od.nih.gov/factsheets/Iron-Consumer/")!)
    private static let who = Source(name: "World Health Organization: Anaemia",
                                    url: URL(string: "https://www.who.int/news-room/fact-sheets/detail/anaemia")!)

    private static let en: [Article] = [
        Article(id: "two-kinds", emoji: "🥩", title: "Two kinds of iron in food",
                summary: "Iron from meat and seafood is absorbed more easily than iron from plants.",
                body: [
                    "Food contains two forms of iron. Heme iron comes from meat, seafood and poultry. Non-heme iron comes from plants such as beans, lentils, tofu and dark leafy greens, and from fortified foods like some breakfast cereals.",
                    "Your body absorbs heme iron more easily than non-heme iron. Eating meat, seafood or poultry together with plant foods also helps you absorb more of the iron from the plants.",
                    "If you eat little or no meat, plant foods can still give you iron. Pair them with foods rich in vitamin C to help absorption.",
                ], sources: [nih]),
        Article(id: "vitamin-c", emoji: "🍊", title: "Vitamin C helps plant iron",
                summary: "Pair beans, greens and grains with fruit or vegetables rich in vitamin C.",
                body: [
                    "Vitamin C helps your body absorb non-heme iron, the kind found in plant foods and fortified cereals.",
                    "Easy pairs: lentils with tomatoes, spinach with a squeeze of lime, fortified cereal with strawberries or an orange, tofu stir-fried with bell peppers or broccoli.",
                    "Guava, citrus fruit, kiwi, strawberries, tomatoes, peppers and broccoli are all good sources of vitamin C.",
                ], sources: [nih]),
        Article(id: "tea-coffee", emoji: "☕️", title: "Tea, coffee and calcium",
                summary: "Some drinks and foods can lower how much iron you absorb from a meal.",
                body: [
                    "Tea and coffee contain polyphenols, and dairy foods contain calcium. Both can reduce how much iron your body absorbs from the same meal.",
                    "You don't need to give them up. Many people simply have tea or coffee between meals rather than with an iron-rich meal.",
                    "If you take calcium supplements, ask your doctor or pharmacist about the best time to take them.",
                ], sources: [nih]),
        Article(id: "how-much", emoji: "📏", title: "How much iron do people need?",
                summary: "Daily needs depend on age, sex and pregnancy.",
                body: [
                    "The US National Institutes of Health recommends these daily amounts of iron:",
                    "• Men 19 and older: 8 mg",
                    "• Women 19–50: 18 mg",
                    "• Women 51 and older: 8 mg",
                    "• During pregnancy: 27 mg",
                    "• While breastfeeding (ages 19–50): 9 mg",
                    "• Teens 14–18: 11 mg for boys, 15 mg for girls",
                    "People who eat no meat may need about 1.8 times these amounts, because iron from plants is absorbed less easily.",
                    "Don't take iron supplements unless your doctor recommends them. Too much iron can be harmful, and iron supplements are a common cause of poisoning in young children, so keep them out of reach.",
                ], sources: [nih]),
        Article(id: "hb-ferritin", emoji: "🩸", title: "What hemoglobin and ferritin show",
                summary: "Two common blood test results, in plain words.",
                body: [
                    "Hemoglobin is the protein in red blood cells that carries oxygen around your body.",
                    "Ferritin is a protein that stores iron. A ferritin test gives an idea of how much iron your body has in reserve.",
                    "Healthy ranges differ between labs and depend on things like age, sex and pregnancy. Irovi doesn't judge your numbers. Ask your doctor what your results mean for you.",
                ], sources: [nih, who]),
        Article(id: "doctor", emoji: "🩺", title: "When to talk to a doctor",
                summary: "Some signs are worth checking rather than guessing.",
                body: [
                    "According to the World Health Organization, anaemia can cause tiredness, weakness, dizziness and shortness of breath.",
                    "Talk to a doctor if you often feel unusually tired or short of breath, if you have heavy periods, if you are pregnant or planning a pregnancy, or before starting any iron supplement.",
                    "A blood test is the only way to know your iron levels. Irovi helps you keep track of your food and results. It can't tell you whether you have anaemia.",
                ], sources: [who, nih]),
    ]

    private static let vi: [Article] = [
        Article(id: "two-kinds", emoji: "🥩", title: "Hai loại sắt trong thức ăn",
                summary: "Sắt từ thịt và hải sản được cơ thể hấp thu dễ hơn sắt từ thực vật.",
                body: [
                    "Thức ăn có hai dạng sắt. Sắt heme có trong thịt, hải sản và gia cầm. Sắt không heme có trong thực vật như đậu, đậu lăng, đậu phụ, rau lá xanh đậm, và trong thực phẩm bổ sung sắt như một số loại ngũ cốc ăn sáng.",
                    "Cơ thể hấp thu sắt heme dễ hơn sắt không heme. Ăn thịt, hải sản hoặc gia cầm cùng với thực phẩm thực vật cũng giúp hấp thu thêm sắt từ thực vật.",
                    "Nếu bạn ăn ít hoặc không ăn thịt, thực vật vẫn cung cấp sắt. Hãy ăn kèm thực phẩm giàu vitamin C để hấp thu tốt hơn.",
                ], sources: [nih]),
        Article(id: "vitamin-c", emoji: "🍊", title: "Vitamin C giúp hấp thu sắt từ thực vật",
                summary: "Ăn đậu, rau xanh, ngũ cốc kèm trái cây hoặc rau giàu vitamin C.",
                body: [
                    "Vitamin C giúp cơ thể hấp thu sắt không heme, loại sắt có trong thực vật và ngũ cốc bổ sung sắt.",
                    "Vài cách kết hợp dễ làm: đậu lăng nấu cà chua, rau bina vắt thêm chanh, ngũ cốc ăn sáng với dâu tây hoặc cam, đậu phụ xào ớt chuông hoặc bông cải xanh.",
                    "Ổi, cam quýt, kiwi, dâu tây, cà chua, ớt chuông và bông cải xanh đều giàu vitamin C.",
                ], sources: [nih]),
        Article(id: "tea-coffee", emoji: "☕️", title: "Trà, cà phê và canxi",
                summary: "Một số đồ uống và thực phẩm có thể làm giảm lượng sắt hấp thu từ bữa ăn.",
                body: [
                    "Trà và cà phê có polyphenol, còn sữa và các món từ sữa có canxi. Cả hai đều có thể làm giảm lượng sắt cơ thể hấp thu từ cùng bữa ăn.",
                    "Bạn không cần bỏ hẳn. Nhiều người chỉ cần uống trà, cà phê giữa các bữa thay vì ngay trong bữa ăn giàu sắt.",
                    "Nếu bạn uống viên canxi, hãy hỏi bác sĩ hoặc dược sĩ thời điểm uống phù hợp.",
                ], sources: [nih]),
        Article(id: "how-much", emoji: "📏", title: "Mỗi người cần bao nhiêu sắt?",
                summary: "Nhu cầu mỗi ngày tuỳ theo tuổi, giới tính và việc mang thai.",
                body: [
                    "Viện Y tế Quốc gia Hoa Kỳ (NIH) khuyến nghị lượng sắt mỗi ngày như sau:",
                    "• Nam từ 19 tuổi: 8 mg",
                    "• Nữ 19–50 tuổi: 18 mg",
                    "• Nữ từ 51 tuổi: 8 mg",
                    "• Khi mang thai: 27 mg",
                    "• Khi cho con bú (19–50 tuổi): 9 mg",
                    "• Tuổi 14–18: nam 11 mg, nữ 15 mg",
                    "Người không ăn thịt có thể cần khoảng 1,8 lần các mức trên, vì sắt từ thực vật khó hấp thu hơn.",
                    "Đừng tự uống viên sắt nếu bác sĩ không khuyên. Thừa sắt có thể gây hại, và viên sắt là nguyên nhân ngộ độc thường gặp ở trẻ nhỏ, nên hãy để xa tầm tay trẻ em.",
                ], sources: [nih]),
        Article(id: "hb-ferritin", emoji: "🩸", title: "Hemoglobin và ferritin cho biết điều gì",
                summary: "Hai chỉ số xét nghiệm máu thường gặp, giải thích dễ hiểu.",
                body: [
                    "Hemoglobin (Hb) là protein trong hồng cầu, mang oxy đi khắp cơ thể.",
                    "Ferritin là protein dự trữ sắt. Xét nghiệm ferritin cho biết phần nào lượng sắt cơ thể đang dự trữ.",
                    "Khoảng bình thường khác nhau giữa các phòng xét nghiệm và tuỳ theo tuổi, giới tính, việc mang thai. Irovi không đánh giá chỉ số của bạn. Hãy hỏi bác sĩ kết quả có ý nghĩa gì với bạn.",
                ], sources: [nih, who]),
        Article(id: "doctor", emoji: "🩺", title: "Khi nào nên đi khám",
                summary: "Có những dấu hiệu nên đi kiểm tra thay vì tự đoán.",
                body: [
                    "Theo Tổ chức Y tế Thế giới, thiếu máu có thể gây mệt mỏi, yếu sức, chóng mặt và khó thở.",
                    "Hãy đi khám nếu bạn thường xuyên mệt bất thường hoặc khó thở, kinh nguyệt nhiều, đang mang thai hoặc định có thai, hoặc trước khi bắt đầu uống bất kỳ viên sắt nào.",
                    "Chỉ xét nghiệm máu mới cho biết lượng sắt của bạn. Irovi giúp bạn theo dõi bữa ăn và kết quả, nhưng không thể cho biết bạn có bị thiếu máu hay không.",
                ], sources: [who, nih]),
    ]
}
