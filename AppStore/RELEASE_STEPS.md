# Nộp Irovi lên App Store

Làm lần lượt từ trên xuống. Mọi nội dung cần dán đều nằm ngay trong file này (chỉ tiếng Anh).

**Thông tin chính**
- Tên trên store: `Irovi – Iron & Blood Health` · Tên dưới icon: `Irovi`
- Bundle ID: `com.irovi.app` · Version / Build: `1.0.0` / `1`
- Chỉ iPhone · Ngôn ngữ trang store: English (U.S.)
- Thu thập dữ liệu: **Không** (Data Not Collected)
- App **không** dùng HealthKit, camera, vị trí. Chỉ xin quyền thông báo khi người dùng bật nhắc.
- Có **widget** (`com.irovi.app.widget`), chia sẻ dữ liệu với app qua App Group `group.com.irovi.app`.

---

## Trước khi bắt đầu

- [ ] `Config/Signing.xcconfig`: sửa `DEVELOPMENT_TEAM` thành Team ID đúng (developer.apple.com › Membership).
- [ ] Có link **Privacy Policy riêng cho Irovi**: nội dung trong `docs/PRIVACY_POLICY.md`, điền ngày, tên, email rồi đưa lên web. Thay link vào `Config/Signing.xcconfig` dòng `IROVI_PRIVACY_URL`.
  ⚠️ Không dùng trang `https://nguyenhuydiem.netlify.app/policy` (viết cho game, ghi là có thu thập dữ liệu, trái với khai báo "Data Not Collected").
- [ ] Có link **Support URL** mở được, có email liên hệ.
- [ ] Xcode › Settings › Accounts: đăng nhập tài khoản Developer.
- [ ] **Cuffnote:** để nguyên, **không nộp lại**. Irovi là app khác, tạo bản ghi mới.

## 1. Tạo App Group và App ID

Cách nhanh: trong Xcode, target **Irovi** và **IroviWidget** › Signing & Capabilities, chọn Team; để *Automatically manage signing* thì Xcode tự đăng ký các mục dưới. Nếu muốn làm tay trên [developer.apple.com](https://developer.apple.com/account/resources/identifiers/list) › Identifiers:

1. **+** › **App Groups** › Identifier: `group.com.irovi.app`
2. **+** › App IDs › App: Description `Irovi`, Bundle ID `com.irovi.app`, tích **App Groups** › Configure › chọn `group.com.irovi.app`
3. **+** › App IDs › App: Description `Irovi Widget`, Bundle ID `com.irovi.app.widget`, tích **App Groups** › chọn `group.com.irovi.app`

Thiếu App Group thì widget hiện trống.

## 2. Tạo app

App Store Connect › Apps › **+** › New App:

| Ô | Điền |
|---|---|
| Platform | iOS |
| Name | `Irovi – Iron & Blood Health` |
| Primary Language | English (U.S.) |
| Bundle ID | `com.irovi.app` |
| SKU | `irovi-ios-001` |
| User Access | Full Access |

Lấy **Apple ID** (dãy số) ở General › App Information, điền vào `Config/Signing.xcconfig` dòng `IROVI_APP_STORE_ID` (không bắt buộc).

## 3. App Information

**Subtitle** (30 ký tự)
```text
Ferritin, hemoglobin & meals
```

| Ô | Điền |
|---|---|
| Primary category | **Health & Fitness** |
| Secondary category | **Food & Drink** |
| Content Rights | **No**, không có nội dung bên thứ ba |
| License Agreement | Mặc định của Apple |

**Age Rating**: tất cả mục bạo lực, người lớn, cờ bạc… chọn **None**. *Medical or Treatment Information* chọn **Infrequent / Mild** (app có bài đọc sức khỏe chung, khai trung thực an toàn hơn). Web access, User-generated content, Ads: **No**.

## 4. Pricing and Availability

- **Free**, không In-App Purchase
- Bỏ tích "iPhone and iPad Apps on Apple Silicon Macs"

## 5. App Privacy

- Privacy Policy URL: link trang riêng của Irovi (cùng link với `IROVI_PRIVACY_URL`)
- Data Collection: **No, we do not collect data from this app** → **Publish**

## 6. Trang phiên bản 1.0

**Ảnh:** ô **iPhone with Dynamic Island (medium display)** → tải 5 ảnh `01` → `05` từ `AppStore/screenshots/en-6.3/` (1206×2622). Các ô iPhone Duo, iPad, Apple Watch bỏ trống (app chỉ chạy iPhone). Nếu ô nào đòi 1320×2868 thì dùng `en/`, đòi 1284×2778 thì dùng `en-6.5/`.

**Promotional Text** (170)
```text
Build an iron-rich plate every day, keep your hemoglobin and ferritin results in one place, and learn the basics from trusted sources. No account, no ads.
```

**Keywords** (100)
```text
anemia,anaemia,tracker,diet,food,log,checklist,reminder,vitamin,spinach,vegetarian,hb,nutrition,lab
```

**Description**
```text
Irovi is a simple daily companion for people who want more iron in their diet.

YOUR DAY AT A GLANCE
See today's iron plate, your week and your latest blood results on one screen.

LOG IN A FEW TAPS
Tap + to log the iron-rich food groups you ate, today or yesterday: red meat, shellfish and fish, poultry, beans and tofu, dark leafy greens, and fortified grains. Set a daily goal and keep a streak going.

HELP YOUR BODY ABSORB IT
Two simple habits to tick off: vitamin C with a meal, and tea or coffee between meals.

LOOK BACK
A month calendar shows which days reached your goal. Tap any past day to see or edit what you logged.

ON YOUR HOME SCREEN
Add the Irovi widget to your Home Screen or Lock Screen to see today's progress and your streak. Tap it to log food.

YOUR BLOOD RESULTS
Type in the hemoglobin and ferritin numbers from your lab report and see them on a chart over time. Add a target your doctor gave you and plan your next blood test.

REMINDERS
Optional reminders for an iron-rich meal, for medicines you add yourself, and for the day of your next test.

LEARN THE BASICS
Short reads on iron in food, vitamin C, tea and coffee, daily needs, and what your results show, with sources from the US National Institutes of Health and the World Health Organization.

IN YOUR LANGUAGE
English, Vietnamese, Spanish, Portuguese (Brazil), French, German, Japanese and Indonesian. Switch any time in the app.

PRIVATE
No account, no ads, no tracking. Everything stays on your iPhone. Export your data as CSV or delete it any time.

PLEASE NOTE
Irovi is a wellness diary, not a medical device. It does not diagnose, treat or recommend medicines or doses. Always talk to your doctor about your health and your test results.
```

| Ô | Điền |
|---|---|
| Support URL | link trang hỗ trợ có email liên hệ |
| Marketing URL | để trống |
| Version | `1.0.0` |
| Copyright | `2026 <tên công ty>` |

## 7. App Review Information

- Bỏ tích **Sign-in required**
- Điền liên hệ (họ tên, điện thoại +84…, email)
- **Notes** (nếu nộp bằng tài khoản cá nhân thì xoá dòng cuối "Published by…"):

```text
Irovi is a wellness diary for people who want more iron in their diet. It is not a blood pressure or vital-signs log. It does not measure anything with the device's sensors, it does not diagnose, and it never recommends medicines, supplements or doses.

• No account or sign-in. Launch the app, go through the short welcome (language, three intro pages, daily goal), and every feature is available.
• Home tab: an overview of today, the week and the latest blood results. Tap "Log food" or the + button to tick iron-rich food groups and two absorption habits.
• History (Home → This week → History): month calendar of logged days; tap a past day to edit it.
• Widget (small, medium, Lock Screen): today's progress and streak from a summary the app writes to its App Group. Tapping it opens the food log.
• Blood tab: tap + to add a hemoglobin and/or ferritin result typed from a lab report; values are shown on a chart without any "low/normal/high" judgement. "Your doctor's target" is optional and only stores a number the user enters.
• Medicines (Settings → My medicines) are entered by the user for their own reminders only.
• Reminders are local notifications. Notification permission is requested only when the user turns a reminder on.
• Learn tab: short general nutrition articles with sources (NIH Office of Dietary Supplements, WHO).
• No HealthKit, no networking, no analytics, no ads, no third-party SDKs. All data stays on the device (App Privacy: Data Not Collected). Settings → Export / Delete all data.
• Published by <Company legal name>.
```

## 8. Build và upload

1. `xcodegen generate` (nếu vừa sửa `project.yml`), mở `Irovi.xcodeproj`.
2. Target **Irovi** và **IroviWidget** › Signing & Capabilities: chọn đúng Team, thấy mục **App Groups** có `group.com.irovi.app`.
3. Thiết bị **Any iOS Device (arm64)** › **Product › Archive** › **Validate App** › **Distribute App** › App Store Connect › Upload.
4. Chờ 10–30 phút để Apple xử lý build.

## 9. Gửi duyệt

Trang 1.0 › chọn build › **Add for Review** › **Submit to App Review**.

---

## Kiểm tra trước khi bấm Submit

- [ ] Chạy thử trên iPhone thật hoặc simulator, và trên **iPad** (Apple hay duyệt trên iPad): mở app, qua màn chào, tích món, thêm kết quả máu, bật nhắc, đọc bài, mở Lịch sử.
- [ ] Trên iPhone thật: thêm widget Irovi ra màn hình chính, kiểm tra số liệu khớp app và bấm vào thì mở màn Ghi món ăn.
- [ ] Privacy Policy URL và Support URL mở được, đúng nội dung của Irovi.
- [ ] Ảnh store đúng thư mục, đúng thứ tự.
- [ ] Mô tả không thêm tính năng app chưa có.

## Bị reject thì sao

- Lỗi thường (privacy, metadata, crash…): đọc lý do trong **App Review**, sửa, tăng **build** trong `project.yml` (`CURRENT_PROJECT_VERSION`), chạy `xcodegen generate`, rồi làm lại từ bước 8.
- Lỗi **4.3 Spam**: **dừng lại**, không sửa vài chỗ rồi nộp tiếp. Trả lời Apple trong Resolution Center trước.
