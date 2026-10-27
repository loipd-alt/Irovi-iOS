# Nộp Irovi lên App Store

Làm lần lượt từ trên xuống. Nội dung để dán nằm trong `docs/ASO.md`.

**Thông tin chính**
- Tên trên store: `Irovi – Iron & Blood Health` · Tên dưới icon: `Irovi`
- Bundle ID: `com.irovi.app` · Version / Build: `1.0.0` / `1`
- Chỉ iPhone · Ngôn ngữ trang store: English (U.S.)
- Thu thập dữ liệu: **Không** (Data Not Collected)
- App **không** dùng HealthKit, camera, vị trí. Chỉ xin quyền thông báo khi người dùng bật nhắc.
- Có **widget** (`com.irovi.app.widget`), chia sẻ dữ liệu với app qua App Group `group.com.irovi.app`.

---

## Trước khi bắt đầu

- [ ] Có link **Privacy Policy riêng cho Irovi**: nội dung trong `docs/PRIVACY_POLICY.md`, điền ngày, tên, email rồi đưa lên web. ⚠️ Không dùng trang `/policy` chung (viết cho game, ghi là có thu thập dữ liệu).
- [ ] Xcode › Settings › Accounts: đăng nhập tài khoản Developer.
- [ ] **Bản ghi Cuffnote cũ:** để nguyên, **không nộp lại**. Irovi là app khác, tạo bản ghi mới.

## 1. Tạo App Group và App ID

Cách nhanh: trong Xcode, target **Irovi** và **IroviWidget** › Signing & Capabilities, chọn Team; để *Automatically manage signing* thì Xcode tự đăng ký các mục dưới. Nếu muốn làm tay trên [developer.apple.com](https://developer.apple.com/account/resources/identifiers/list) › Identifiers:

1. **+** › **App Groups** › Identifier: `group.com.irovi.app`
2. **+** › App IDs › App: Description `Irovi`, Bundle ID `com.irovi.app`, tích **App Groups** › Configure › chọn `group.com.irovi.app`
3. **+** › App IDs › App: Description `Irovi Widget`, Bundle ID `com.irovi.app.widget`, tích **App Groups** › chọn `group.com.irovi.app`

Thiếu App Group thì widget hiện trống (không lỗi app, nhưng nên làm đúng).

## 2. Tạo app

App Store Connect › Apps › **+** › New App: iOS · Name `Irovi – Iron & Blood Health` · English (U.S.) · Bundle ID `com.irovi.app` · SKU `irovi-ios-001`.

Lấy **Apple ID** (dãy số) ở General › App Information, điền vào `Config/Signing.xcconfig` dòng `IROVI_APP_STORE_ID` (không bắt buộc).

## 3. App Information

- Subtitle, Category, Age Rating, Content Rights: theo `docs/ASO.md`.
- License Agreement: mặc định Apple.

## 4. Pricing and Availability

- **Free**
- Bỏ tích "iPhone and iPad Apps on Apple Silicon Macs"

## 5. App Privacy

- Privacy Policy URL: link ở bước "Trước khi bắt đầu"
- Data Collection: **No, we do not collect data from this app** → **Publish**

## 6. Trang phiên bản 1.0

- **Ảnh:** tải 5 ảnh `01` → `05` từ `AppStore/screenshots/en/` (ô 6.9") **hoặc** `AppStore/screenshots/en-6.5/` (ô 6.5"). Một bộ là đủ.
- **Promotional Text, Description, Keywords:** chép từ `docs/ASO.md`.
- Support URL, Copyright, Version `1.0.0`.

## 7. App Review Information

- Bỏ tích **Sign-in required**
- Điền liên hệ (họ tên, điện thoại +84…, email)
- **Notes:** chép từ `docs/ASO.md` (nếu là tài khoản cá nhân thì xoá dòng "Published by…")

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
- [ ] Privacy Policy URL và Support URL mở được.
- [ ] Ảnh store đúng thư mục, đúng thứ tự.
- [ ] Mô tả không thêm tính năng app chưa có.

## Bị reject thì sao

Đọc lý do trong **App Review**, sửa, tăng **build** trong `project.yml` (`CURRENT_PROJECT_VERSION`), chạy `xcodegen generate`, rồi làm lại từ bước 8.
