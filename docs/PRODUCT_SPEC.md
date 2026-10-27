# Irovi — Product spec v1.0

**Một câu:** Irovi giúp người muốn cải thiện sức khỏe máu **ăn đủ thực phẩm giàu sắt mỗi ngày** và **theo dõi chỉ số Hb / ferritin** qua các lần xét nghiệm.

- Tên trên store: `Irovi – Iron & Blood Health` · Tên dưới icon: `Irovi`
- Bundle ID: `com.irovi.app` · iOS 17+ · iPhone · English + Tiếng Việt
- Không tài khoản, không máy chủ, không AI, không quảng cáo. Dữ liệu chỉ ở trên máy.

Lý do chọn hướng này: xem `MARKET_RESEARCH.md` (nhóm duy nhất vừa nhiều người cần vừa chưa có app tốt, ít giống Blood Tracker).

---

## 1. Người dùng

Người thiếu sắt / thiếu máu hoặc muốn phòng tránh: phụ nữ (kinh nhiều, mang thai), người ăn chay, người hay hiến máu, người được bác sĩ dặn ăn nhiều sắt.

## 2. Tính năng (4 phần)

**2.1 Hôm nay (checklist ăn uống)**
- 6 nhóm thực phẩm giàu sắt, bấm để đánh dấu đã ăn hôm nay: thịt đỏ & gan · hải sản & cá · gia cầm & trứng · đậu, đậu phụ · rau lá xanh đậm · ngũ cốc tăng cường sắt, hạt.
- Mục tiêu: số nhóm mỗi ngày (mặc định 3, sửa được 1–6). Vòng tiến độ + chuỗi ngày đạt mục tiêu.
- 2 thói quen hỗ trợ hấp thu: ăn kèm vitamin C; để trà/cà phê xa bữa ăn.
- Thuốc bác sĩ kê (nếu người dùng tự thêm): đánh dấu đã uống hôm nay.

**2.2 Chỉ số máu**
- Nhập kết quả xét nghiệm: ngày, Hb (g/dL hoặc g/L), ferritin (ng/mL), ghi chú.
- Biểu đồ theo thời gian cho từng chỉ số; tuỳ chọn đường "mục tiêu bác sĩ đưa".
- Ngày xét nghiệm lần tới + nhắc.
- **Không** đánh giá cao/thấp, không ngưỡng tự động. Luôn ghi "hỏi bác sĩ kết quả có ý nghĩa gì".

**2.3 Nhắc nhở**
- Nhắc ăn món giàu sắt (một giờ mỗi ngày).
- Nhắc thuốc do người dùng tự nhập (tên + giờ). **App không gợi ý thuốc hay liều.**
- Nhắc ngày xét nghiệm lần tới.
- Chỉ xin quyền thông báo khi người dùng bật nhắc lần đầu.

**2.4 Tìm hiểu**
- 6 bài ngắn, mỗi bài có nguồn (NIH Office of Dietary Supplements, WHO): hai loại sắt trong thực phẩm; ăn kèm vitamin C; trà/cà phê/canxi; nhu cầu sắt theo độ tuổi; Hb và ferritin là gì; khi nào nên đi khám.

**Cài đặt:** mục tiêu mỗi ngày, nhắc nhở, danh sách thuốc, đơn vị Hb, ngôn ngữ (theo cài đặt iPhone), xuất CSV, xoá toàn bộ dữ liệu, quyền riêng tư, giới thiệu + lưu ý y tế.

**Onboarding:** 2 màn: giới thiệu + lưu ý "không phải thiết bị y tế" → chọn mục tiêu mỗi ngày, bật nhắc (tuỳ chọn).

## 3. Khác Blood Tracker thế nào

| | Blood Tracker | Irovi |
|---|---|---|
| Việc hằng ngày | Đo huyết áp/đường huyết, ghi số | Tích các nhóm thực phẩm giàu sắt đã ăn |
| Chỉ số | Huyết áp, đường huyết, SpO₂, mỡ máu | Hb, ferritin (thỉnh thoảng) |
| Lõi | Nhật ký bệnh mạn tính | Ăn uống đủ sắt cho sức khỏe máu |
| Apple Health, quét phiếu, báo cáo PDF | Có | Không |
| Code / thiết kế / tên / icon | — | Mới hoàn toàn |

## 4. Thiết kế

- Màu: **đỏ đất nung** (sắt, máu) + **xanh lá** (rau) trên nền **kem ấm**. Khác teal (Blood Tracker) và tím (Cuffnote).
- Chữ số và tiêu đề dùng SF Rounded. Mọi màu, bo góc, khoảng cách nằm trong một file `Irovi/DesignSystem/Palette.swift`.
- 3 tab: **Today · Blood · Learn**. Cài đặt: nút bánh răng ở Today.
- Icon: đĩa ăn màu kem trên nền đỏ đất nung, trong đĩa có giọt máu và chiếc lá.

## 5. Quy định Apple (đã rà)

- 4.3: ý tưởng, code, thiết kế, metadata đều mới.
- 1.4.1 / 1.4.2: không chẩn đoán, không đánh giá chỉ số, không tư vấn thuốc hay liều; thông tin dinh dưỡng có nguồn; luôn nhắc hỏi bác sĩ.
- 4.2: đủ chức năng (checklist, chỉ số + biểu đồ, nhắc, bài đọc).
- 5.1.1: chỉ xin quyền thông báo, xin đúng lúc. Data Not Collected. Có `PrivacyInfo.xcprivacy`.
- 2.4.1: kiểm tra chạy trên iPad (chế độ iPhone) trước khi nộp.

## 6. Ngoài phạm vi v1.0

Ghi bữa ăn chi tiết theo mg, widget, gói trả phí, đồng bộ iCloud, Apple Health. Làm ở bản sau nếu cần.
