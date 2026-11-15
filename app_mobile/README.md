# 🏎️ DATN Car Controller - Android Mobile App (BLE)

Ứng dụng Android điều khiển xe thông minh đồ án tốt nghiệp qua Bluetooth Low Energy (BLE), kết nối trực tiếp với ứng dụng Qt6 C++ chạy trên Raspberry Pi 4.

---

## 📁 Cấu Trúc Thư Mục (Clean Architecture / MVVM)

```text
app/src/main/java/com/example/app_mobile/
├── data/
│   ├── ble/
│   │   ├── BleConstants.kt           # Khai báo UUID Service, Characteristic, Tên thiết bị
│   │   ├── BleConnectionState.kt     # Các trạng thái kết nối BLE (State Pattern)
│   │   ├── BleDeviceItem.kt          # Model thiết bị BLE quét được
│   │   └── BleManager.kt             # Engine Bluetooth LE (Quét, Kết nối GATT, Gửi dữ liệu)
│   └── model/
│       └── CarCommand.kt             # Danh mục lệnh điều khiển xe (Động cơ & Đèn)
│
├── ui/
│   ├── components/
│   │   ├── ConnectionStatusCard.kt   # Card trạng thái BLE, nút Dò xe, ngắt kết nối
│   │   ├── DirectionControlPad.kt    # Cụm D-PAD điều khiển (Tiến, Lùi, Trái, Phải, STOP)
│   │   ├── LightControlBar.kt        # Thanh điều khiển 4 đèn (Xi-nhan T/P, Đèn Pha, Hazard)
│   │   ├── SpeedControlCard.kt       # Thanh trượt PWM (30-100%) và nút chọn nhanh ECO/MAX
│   │   └── DeviceScanDialog.kt       # Hộp thoại danh sách quét thiết bị xung quanh
│   ├── screens/
│   │   └── CarDashboardScreen.kt     # Màn hình Cockpit điều khiển chính
│   ├── theme/
│   │   ├── Color.kt                  # Bảng màu Dark Cyber Cockpit (Neon Cyan, Amber, Crimson)
│   │   ├── Theme.kt                  # Material3 Theme
│   │   └── Type.kt                   # Typography
│   └── viewmodel/
│       └── CarViewModel.kt           # Quản lý State, xử lý sự kiện cảm ứng và lệnh BLE
│
├── util/
│   └── BlePermissionManager.kt       # Xử lý cấp quyền BLE cho Android 8 -> Android 15
└── MainActivity.kt                   # Khởi chạy Jetpack Compose và kiểm tra quyền
```

---

## 📡 Giao Thức BLE Chuẩn Qt6

| Thuộc tính | Giá trị |
| :--- | :--- |
| **Tên thiết bị BLE (Local Name)** | `DATN-Car` |
| **Service UUID** | `12345678-1234-1234-1234-123456789abc` |
| **Characteristic UUID** | `12345678-1234-1234-1234-123456789abd` |
| **Kiểu truyền (Properties)** | `Write Without Response` / `Write Request` |

### Bảng mã lệnh gửi từ App sang Xe:
- **Động cơ:**
  - `F:<tốc độ>`: Tiến (ví dụ: `F:70`, `F:100`)
  - `B:<tốc độ>`: Lùi (ví dụ: `B:70`)
  - `L:<tốc độ>`: Quay trái (ví dụ: `L:70`)
  - `R:<tốc độ>`: Quay phải (ví dụ: `R:70`)
  - `S`: Dừng xe ngay lập tức (Nhả tay khỏi nút hoặc bấm nút STOP)
- **Hệ thống đèn:**
  - `TL`: Bật/Tắt xi-nhan Trái (Toggle Left)
  - `TR`: Bật/Tắt xi-nhan Phải (Toggle Right)
  - `HAZ`: Bật/Tắt đèn cảnh báo khẩn cấp (Toggle Hazard)
  - `LAMP`: Bật/Tắt đèn pha trước (Toggle Headlight)

---

## 🚀 Cài Đặt File APK Vào Điện Thoại

File APK đã được biên dịch sẵn tại:
- **Đường dẫn nhanh:** `DATN_Car_Controller.apk` (nằm ngay thư mục gốc `app_mobile`)
- **Đường dẫn build:** `app/build/outputs/apk/debug/app-debug.apk`

### Cách 1: Cài đặt trực tiếp qua lệnh ADB (nếu cắm cáp Type-C vào máy tính)
```bash
adb install -r /home/quanghaictu/DATN_dashboard_car/app_mobile/DATN_Car_Controller.apk
```

### Cách 2: Copy file APK vào điện thoại
Copy file [DATN_Car_Controller.apk](file:///home/quanghaictu/DATN_dashboard_car/app_mobile/DATN_Car_Controller.apk) qua Zalo/Drive/Cáp truyền file vào điện thoại Android và bấm Cài đặt (Install).
