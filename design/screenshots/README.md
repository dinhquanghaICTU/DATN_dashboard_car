# Ảnh chụp giao diện dashboard (800×480)

| File | Mô tả |
|------|-------|
| `00-before-old-ui.png` | Giao diện cũ (trước khi sửa) để so sánh |
| `01-theme-aqua.png` | Giao diện mới – theme AQUA (mặc định) |
| `02-theme-forest.png` | Giao diện mới – theme FOREST |
| `03-theme-amber.png` | Giao diện mới – theme AMBER |
| `04-alert-overheat-overspeed.png` | Trạng thái cảnh báo: nhiệt độ > 50 °C (khóa đèn, bật hazard) và tốc độ ≥ 80 km/h |

Ảnh được render từ chính các file QML (Qt 6, software backend) với dữ liệu giả lập
cho `vehicle` / `ledCtrl`, xi-nhan trái đang bật và BLE đang kết nối.

## Thay đổi chính
- **Bố cục rõ ràng hơn**: trái = pin + điều khiển đèn + theme, giữa = đồng hồ tốc độ, phải = nhiệt độ / motor / BLE.
  Bỏ phần hiển thị trùng lặp (trước đây tốc độ, RPM, nhiệt độ, pin xuất hiện 2–3 lần).
- **Đồng hồ tốc độ mới**: cung 270°, vạch chia 0–120 km/h không còn bị cắt chữ, vùng đỏ ≥ 80 km/h,
  số tốc độ lớn ở giữa, RPM dạng "pill" bên dưới, đèn xi-nhan ở 2 góc trên.
- **Thanh trạng thái dưới đồng hồ**: "ALL SYSTEMS NORMAL" / "OVER SPEED" / "ENGINE OVERHEAT · HAZARD ON".
- **Nút điều khiển đèn** dạng ô bấm có icon + nhãn, sáng theo trạng thái, hiện "LOCKED" khi quá nhiệt.
- **Top bar** gọn hơn (nền tối thay cho dải cyan đặc), thêm chip trạng thái **BLE**.
- **Font**: đổi `Courier New` (không có trên Raspberry Pi OS nên bị thay font ngẫu nhiên) sang `DejaVu Sans` (có sẵn).
- Thêm component dùng chung `ui/components/DashCard.qml`.
