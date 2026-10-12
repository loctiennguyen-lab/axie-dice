# Hướng dẫn cài Axie Dice L1 (bản thử nội bộ, chưa ký) / Install guide (unsigned L1 test build)

Trạng thái: NHÁP (12/10/2026). Chưa thử trên máy sạch. Mục "Cấu hình tối thiểu" còn là ô trống
cho tới khi lane R đo xong. Bản này viết cho người test, nên giữ ngắn.

Draft status: 12/10/2026. Not yet tested on a clean machine. The minimum specs section is a placeholder
until lane R measures them.

---

## 1. Trước khi bắt đầu / Before you start

- Tải đúng file cho máy bạn. Tên file có `macos` hoặc `windows`.
  Download the file that matches your system. The name contains `macos` or `windows`.
- Kiểm tra file không bị hỏng: so SHA-256 với file `.sha256` đi kèm (nếu người gửi có đưa).
  Check the SHA-256 against the `.sha256` file if one was sent with the link.
- Bản này KHÔNG được ký và KHÔNG qua Apple/Microsoft kiểm duyệt. Hệ điều hành sẽ cảnh báo. Đây là
  dự kiến, không phải virus. Chỉ mở file từ người gửi link bạn tin.
  This build is NOT signed and NOT notarized. The OS will warn you. That is expected. Only open files
  from the person who sent you the link.

---

## 2. macOS

### Cách 1 (macOS 15 Sequoia trở lên, gồm macOS 26): System Settings

Từ macOS 15, chuột phải → Open không còn bỏ qua cảnh báo cho app chưa ký. Làm theo các bước này:
From macOS 15, right-click → Open no longer bypasses the warning for unsigned apps. Use these steps:

1. Giải nén file `.zip` (nhấp đúp). Bạn sẽ có `AxieDice.app`. Nếu tải `.dmg`, kéo `AxieDice.app` vào
   `Applications`. Unzip, or drag the app out of the `.dmg` into `Applications`.
2. Nhấp đúp `AxieDice.app`. Cảnh báo hiện ra, bấm **Done** (không bấm Move to Trash).
   Double-click the app; when the warning appears click **Done** (not Move to Trash).
3. Vào **System Settings → Privacy & Security**, kéo xuống mục Security.
   Open **System Settings → Privacy & Security** and scroll to Security.
4. Bấm **Open Anyway** cạnh thông báo về `AxieDice`, nhập mật khẩu máy, rồi bấm **Open Anyway** lần nữa.
   Click **Open Anyway** next to the message about `AxieDice`, enter your password, confirm.
5. Từ lần sau, nhấp đúp bình thường. After the first time, a normal double-click works.

### Cách 2 (macOS 14 Sonoma trở xuống): chuột phải → Open

1. **Chuột phải** (hoặc Control-click) `AxieDice.app` → **Open**. Right-click → **Open**.
2. Hộp thoại "unidentified developer" hiện ra, bấm **Open**. Click **Open** in the dialog.

### Cách 3 (cho người rành, mọi phiên bản): xóa cờ quarantine

Chỉ dùng khi hai cách trên không được, hoặc app báo "damaged". Lệnh này xóa cờ "tải từ internet" của riêng app đó:
Use only if the two methods above fail. This clears the download quarantine flag on that one app:

```
xattr -dr com.apple.quarantine /Applications/AxieDice.app
```

Đổi đường dẫn nếu bạn để app ở chỗ khác. Đừng chạy lệnh này với `sudo` và đừng áp dụng cho app khác.
Change the path if the app is elsewhere. Do not use `sudo`, and do not run it on other apps.

### Ghi chú macOS / macOS notes

- Bản này là universal: chạy native trên cả Apple Silicon và Intel (macOS 11 trở lên cho Apple Silicon, 10.13 cho Intel). Không cần Rosetta.
  This build is universal (native on Apple Silicon and Intel). No Rosetta needed.
- Nếu app "bị hỏng" ("is damaged and can't be opened"): đó là cờ quarantine, làm theo Cách 3.
  If the app says it is "damaged", that is the quarantine flag. Use Method 3.
- Log nằm ở `logs/godot.log` cùng thư mục save. Logs are in `logs/godot.log` inside the same folder.
- Dữ liệu (save) nằm ở `~/Library/Application Support/Godot/app_userdata/Axie Dice (Godot port)/`.
  Save data is stored there.

---

## 3. Windows

1. Giải nén `AxieDice-…-windows.zip` (chuột phải → Extract All). Bạn có `AxieDice.exe`.
   Extract the zip. You get `AxieDice.exe`.
2. Nhấp đúp `AxieDice.exe`. Màn hình **Windows protected your PC** (SmartScreen) hiện ra.
   Double-click `AxieDice.exe`. The **Windows protected your PC** screen appears.
3. Bấm **More info** (Thêm thông tin), rồi bấm **Run anyway** (Vẫn chạy).
   Click **More info**, then **Run anyway**.
4. Nếu Windows Defender báo file có thể nguy hiểm và xóa: mở **Windows Security → Protection history**,
   chọn mục vừa bị chặn, bấm **Allow** (nếu máy có quyền). Nếu máy công ty chặn, báo người gửi.
   If Defender quarantines the file, use Protection history to allow it, if your account has permission.
   If a work PC blocks it, tell the sender.

### Ghi chú Windows / Windows notes

- Mẹo: chuột phải file `.zip` → Properties → tick **Unblock** → OK TRƯỚC khi giải nén, đỡ bị SmartScreen hỏi.
  Tip: right-click the zip → Properties → **Unblock** before extracting.
- Bản này chỉ x86_64. Máy Windows ARM không chạy được (chạy qua giả lập có thể lỗi).
  x86_64 only. Windows on ARM is not supported in this build.
- Cần driver đồ hoạ cập nhật (DirectX 12 hoặc Vulkan). Nếu app đen màn hình hoặc crash khi mở, cập nhật driver GPU rồi thử lại.
- Dữ liệu (save) nằm ở `%APPDATA%\Godot\app_userdata\Axie Dice (Godot port)\`.

---

## 4. Cấu hình tối thiểu / Minimum specs

Ô trống, lane R điền sau khi đo trên máy sạch (mục 5 của `l1-test-plan.md`). Không ghi con số đoán.
Placeholder. Lane R fills these in after measuring on clean machines.

| | macOS | Windows |
|---|---|---|
| Hệ điều hành | TBD | TBD |
| CPU | TBD | TBD |
| RAM | TBD | TBD |
| GPU / đồ hoạ | TBD | TBD |
| Ổ cứng trống | TBD (app ~ size của zip, cộng save) | TBD |
| Mạng | Cần để đăng nhập và gửi kết quả run | Cần để đăng nhập và gửi kết quả run |

---

## 5. Khi gặp lỗi / If something goes wrong

Gửi báo cáo theo mẫu trong `l1-test-plan.md` (mục 4). Kèm file log (`logs/godot.log` trong thư mục save, xem test plan mục 4b), phiên bản (tên file zip, hoặc dòng
`build:` trong file `BUILD_INFO.txt` nếu có), hệ điều hành, và ảnh chụp màn hình.
Send a report using the template in `l1-test-plan.md` section 4. Include the file name (build number),
OS version, and a screenshot.

Đừng xóa thư mục save khi báo lỗi. Có thể cần nó để tái hiện.
Do not delete the save folder before reporting. It may be needed to reproduce the bug.
