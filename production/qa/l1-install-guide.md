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

### Cách 1 (khuyên dùng): chuột phải → Open

1. Giải nén file `.zip` (nhấp đúp). Bạn sẽ có `AxieDice.app`. Nếu tải `.dmg`, kéo `AxieDice.app` vào
   thư mục `Applications`.
   Unzip the `.zip` (double-click). Or open the `.dmg` and drag `AxieDice.app` to `Applications`.
2. Vào Applications (hoặc thư mục bạn đã đặt app). **Chuột phải** (hoặc Control-click) `AxieDice.app`
   → chọn **Open** (Mở).
   Right-click (or Control-click) `AxieDice.app` → **Open**.
3. Hộp thoại hiện ra: "macOS cannot verify the developer..." hoặc "unidentified developer". Bấm **Open**.
   A dialog appears. Click **Open**.
4. Từ lần sau, nhấp đúp bình thường.
   After the first time, a normal double-click works.

### Cách 2: System Settings (macOS Sequoia trở lên)

Nếu chuột phải → Open không còn nút Open:
If right-click → Open does not show an Open button:

1. Thử mở app một lần (double-click), bấm **Done** hoặc **Cancel** khi được hỏi.
   Double-click the app once, then dismiss the warning.
2. Vào **System Settings → Privacy & Security**, kéo xuống mục bảo mật.
   Open **System Settings → Privacy & Security** and scroll down to the security section.
3. Bấm **Open Anyway** (Mở dù sao) cạnh thông báo về `AxieDice`, nhập mật khẩu máy.
   Click **Open Anyway** next to the message about `AxieDice`, then enter your password.

### Cách 3 (cho người rành): xóa cờ quarantine

Chỉ dùng khi hai cách trên không được. Lệnh này xóa cờ "tải từ internet" của riêng app đó:
Use only if the two methods above fail. This clears the download quarantine flag on that one app:

```
xattr -dr com.apple.quarantine /Applications/AxieDice.app
```

Đổi đường dẫn nếu bạn để app ở chỗ khác. Đừng chạy lệnh này với `sudo` và đừng áp dụng cho app khác.
Change the path if the app is elsewhere. Do not use `sudo`, and do not run it on other apps.

### Ghi chú macOS / macOS notes

- Bản này là x86_64 (Intel). Máy Apple Silicon (M1 trở lên) chạy qua Rosetta 2. Nếu máy chưa có,
  macOS sẽ hỏi cài Rosetta; bấm **Install** và đợi xong. Lệnh cài tay: `softwareupdate --install-rosetta --agree-to-license`.
  This build is Intel (x86_64). Apple Silicon Macs run it through Rosetta 2. If prompted, install Rosetta.
- Nếu app "bị hỏng" ("is damaged and can't be opened"): đó là cờ quarantine, làm theo Cách 3.
  If the app says it is "damaged", that is the quarantine flag. Use Method 3.
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

Gửi báo cáo theo mẫu trong `l1-test-plan.md` (mục 4). Kèm: phiên bản (tên file zip, hoặc dòng
`build:` trong file `BUILD_INFO.txt` nếu có), hệ điều hành, và ảnh chụp màn hình.
Send a report using the template in `l1-test-plan.md` section 4. Include the file name (build number),
OS version, and a screenshot.

Đừng xóa thư mục save khi báo lỗi. Có thể cần nó để tái hiện.
Do not delete the save folder before reporting. It may be needed to reproduce the bug.
