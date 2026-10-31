# 📘 Hướng Dẫn Làm Việc Nhóm với GitHub — DATN Dashboard Car

> Tài liệu này dành cho **tất cả thành viên** trong nhóm. Đọc kỹ trước khi bắt đầu làm việc.

---

## 📌 QUY TẮC BẮT BUỘC

| # | Quy tắc |
|---|---------|
| 1 | ❌ **KHÔNG** được push thẳng lên nhánh `main` |
| 2 | ✅ Mỗi người làm việc trên **branch riêng** của mình |
| 3 | ✅ Khi xong việc → tạo **Pull Request (PR)** để trưởng nhóm review |
| 4 | ✅ Chỉ merge vào `main` khi được **trưởng nhóm approve** |
| 5 | ✅ **Luôn pull code mới nhất** từ `main` trước khi bắt đầu làm |
| 6 | ✅ Commit message phải **rõ ràng, có ý nghĩa** (xem mẫu bên dưới) |
| 7 | ❌ **KHÔNG** commit file build, thư mục `build/`, file `.user` cá nhân |

---

## 🌿 QUY TẮC ĐẶT TÊN BRANCH

```
feature/ten-chuc-nang        ← làm tính năng mới
fix/ten-bug                  ← sửa lỗi
ui/ten-man-hinh              ← làm giao diện
docs/ten-tai-lieu            ← viết tài liệu
```

**Ví dụ thực tế:**
```
feature/speed-gauge
feature/bluetooth-connection
fix/temperature-display-crash
ui/dashboard-home-screen
```

---

## 🔤 QUY TẮC VIẾT COMMIT MESSAGE

### Cấu trúc:
```
[type]: mô tả ngắn gọn bằng tiếng Anh hoặc tiếng Việt
```

### Ví dụ:
```
feat: thêm màn hình hiển thị tốc độ
fix: sửa lỗi kết nối bluetooth bị crash
ui: cập nhật màu sắc dashboard
docs: thêm sơ đồ kết nối phần cứng
refactor: tối ưu lại class SensorManager
```

### Các type phổ biến:
| Type | Dùng khi |
|------|----------|
| `feat` | Thêm tính năng mới |
| `fix` | Sửa bug |
| `ui` | Thay đổi giao diện |
| `docs` | Thêm/sửa tài liệu |
| `refactor` | Tái cấu trúc code |
| `test` | Thêm test |
| `chore` | Cập nhật config, build |

---

## 🚀 HƯỚNG DẪN TỪNG BƯỚC

### ▶ BƯỚC 1 — Clone repo về máy (làm 1 lần duy nhất)

```bash
git clone https://github.com/dinhquanghaICTU/DATN_dashboard_car.git
cd DATN_dashboard_car
```

---

### ▶ BƯỚC 2 — Tạo branch riêng trước khi bắt đầu làm

```bash
# Đảm bảo đang ở main và code mới nhất
git checkout main
git pull origin main

# Tạo branch mới và chuyển sang branch đó
git checkout -b feature/ten-cua-ban
```

**Ví dụ:**
```bash
git checkout -b feature/speed-gauge
```

---

### ▶ BƯỚC 3 — Làm việc, commit thường xuyên

```bash
# Xem trạng thái file thay đổi
git status

# Thêm file vào staging (hoặc dùng . để thêm tất cả)
git add ten-file.cpp
git add .

# Commit với message rõ ràng
git commit -m "feat: thêm widget hiển thị tốc độ"
```

> 💡 **Mẹo:** Commit nhỏ và thường xuyên, đừng để dồn quá nhiều thay đổi vào 1 commit.

---

### ▶ BƯỚC 4 — Cập nhật code mới nhất từ main (làm thường xuyên)

Để tránh conflict nặng, hãy thường xuyên kéo code mới từ `main`:

```bash
# Lưu code đang làm
git add .
git commit -m "wip: đang làm tính năng X"

# Kéo code mới từ main về branch của bạn
git fetch origin
git rebase origin/main

# Nếu có conflict → giải quyết conflict → rồi tiếp tục
git rebase --continue
```

---

### ▶ BƯỚC 5 — Push branch lên GitHub

```bash
# Push branch của bạn lên GitHub (lần đầu)
git push -u origin feature/ten-cua-ban

# Những lần sau chỉ cần
git push
```

---

### ▶ BƯỚC 6 — Tạo Pull Request trên GitHub

1. Vào: **https://github.com/dinhquanghaICTU/DATN_dashboard_car**
2. Sẽ thấy thông báo **"Compare & pull request"** → Click vào
3. Điền thông tin PR:

```
Title:   feat: Thêm màn hình hiển thị tốc độ

Description:
## Đã làm gì?
- Thêm SpeedGauge widget hiển thị tốc độ xe
- Kết nối với SensorManager để nhận dữ liệu real-time
- Animation kim đồng hồ mượt mà

## Test như thế nào?
- Build trên máy desktop: OK ✅
- Test với dữ liệu giả: OK ✅

## Có breaking change không?
Không
```

4. Click **"Create pull request"**
5. **Chờ trưởng nhóm review** — KHÔNG tự merge!

---

### ▶ BƯỚC 7 — Xử lý khi trưởng nhóm yêu cầu sửa

Khi nhận được comment "Request changes":

```bash
# Sửa code theo yêu cầu...

# Commit thay đổi
git add .
git commit -m "fix: sửa theo review - đổi màu gauge"

# Push lên (PR tự động cập nhật)
git push
```

→ Comment lại trên PR: "Đã sửa xong, anh/chị check lại nhé"

---

## ⚠️ XỬ LÝ CONFLICT

Conflict xảy ra khi 2 người sửa cùng 1 file. Đừng hoảng loạn!

```bash
# Khi rebase bị conflict, Git sẽ báo file nào conflict
# Mở file đó, bạn sẽ thấy:

<<<<<<< HEAD (code của bạn)
    speed = newSpeed * 1.1;
=======
    speed = newSpeed;
>>>>>>> origin/main (code từ main)

# Sửa lại thành code đúng, xóa các dòng <<<, ===, >>>
    speed = newSpeed * 1.1;  // giữ lại cái đúng

# Sau đó
git add ten-file-da-fix.cpp
git rebase --continue
```

> 💡 Nếu không tự giải quyết được → **hỏi trưởng nhóm**, đừng commit đại.

---

## 📋 CHECKLIST TRƯỚC KHI TẠO PR

```
□ Code đã build thành công trên máy mình chưa?
□ Đã test chức năng đang làm chưa?
□ Đã pull code mới nhất từ main chưa?
□ Commit message có rõ ràng không?
□ Có commit nhầm file build/ hoặc .user không?
□ Đã viết mô tả PR đầy đủ chưa?
```

---

## 🔄 SƠ ĐỒ TỔNG QUAN

```
main (nhánh chính - KHÔNG được đụng vào)
 │
 ├─── feature/speed-gauge (thành viên A làm)
 │         │
 │         └── commit → commit → Push → PR → Review → ✅ Merge
 │
 ├─── feature/bluetooth (thành viên B làm)
 │         │
 │         └── commit → commit → Push → PR → Review → ❌ Sửa → ✅ Merge
 │
 └─── fix/temperature-crash (thành viên C làm)
           │
           └── commit → Push → PR → Review → ✅ Merge
```

---

## 📞 KHI NÀO CẦN HỎI TRƯỞNG NHÓM?

- Không biết tạo branch như thế nào
- Bị conflict không tự giải quyết được
- Build lỗi không rõ nguyên nhân
- Không biết file mình nên sửa là file nào
- PR bị từ chối nhưng không hiểu lý do

---

## 🛠️ CÁC LỆNH GIT HAY DÙNG NHẤT

```bash
git status                    # Xem file nào đang thay đổi
git log --oneline -10         # Xem 10 commit gần nhất
git diff                      # Xem chi tiết thay đổi
git stash                     # Tạm cất code đang làm
git stash pop                 # Lấy lại code đã cất
git branch                    # Xem danh sách branch
git branch -d ten-branch      # Xóa branch đã merge
git checkout ten-branch       # Chuyển sang branch khác
git reset --soft HEAD~1       # Hoàn tác commit cuối (giữ code)
```

---

*Tài liệu được tạo cho nhóm DATN Dashboard Car — Cập nhật: 10/2026*
