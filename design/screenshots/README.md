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

## Bố cục (theo phác thảo)
- **Cột trái**: pin dạng cục pin điện thoại (phần trăm nằm trong pin, đổi màu xanh / vàng / đỏ theo mức pin,
  nhấp nháy khi < 10 %), ngay dưới là **nhiệt độ động cơ** kèm thanh 20–80 °C (vạch đỏ ở 50 °C). Dưới cùng là chọn theme.
- **Cột giữa**: đồng hồ tốc độ 0–120 km/h (vùng đỏ ≥ 80), RPM, m/s, mũi tên xi-nhan, banner trạng thái;
  bên dưới là khung **LIGHTS** (LEFT / HAZARD / RIGHT / LAMP), khóa khi quá nhiệt.
- **Cột phải**: **bản đồ giả lập** (đường phố, sông, công viên, lộ trình). Xe chạy dọc lộ trình theo tốc độ đo được
  (tăng tốc ×4 cho dễ thấy), hiển thị tốc độ, quãng đường còn lại và ETA; đến đích thì chạy lại từ đầu.

## Thay đổi kỹ thuật
- Component mới: `DashCard.qml` (khung thẻ dùng chung), `LightsPanel.qml`, `MapPanel.qml`.
- Bỏ `RightStatsPanel.qml` (các chỉ số đã chuyển sang cột trái / giữa).
- Top bar nền tối, thêm chip trạng thái **BLE**.
- Font `Courier New` → `DejaVu Sans` (có sẵn trên Raspberry Pi OS).
