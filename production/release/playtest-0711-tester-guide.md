# Axie Dice: playtest nội bộ / internal playtest (từ 7/11/2026)

Cảm ơn bạn đã chơi thử. Axie Dice là game roguelike tung xúc xắc: chọn đội Axie, đi hết bản đồ, đánh boss. Đây là bản đang làm, còn lỗi. Bạn thấy chỗ nào khó chịu, khó hiểu hay chán thì cứ ghi lại, chuyện nhỏ cũng được.

Thanks for testing. Axie Dice is a dice roguelike. You pick a team of Axies, clear the map and beat the boss. It is a work in progress and has bugs. Anything that feels annoying, confusing or boring is worth writing down, even small things.

---

## 1. Chơi ở đâu / Where to play

| | Link | Ghi chú / Notes |
|---|---|---|
| **Desktop (nên dùng / recommended)** | https://axiedice.fun/download | Windows 10/11 64-bit, macOS (chip Apple hoặc Intel). Không có Linux. Bản b2484, 260–285 MB. / Windows 10/11 64-bit, macOS (Apple or Intel). No Linux. Build b2484, 260–285 MB. |
| Web | https://axiedice.fun | Chỉ Chrome hoặc Edge trên máy tính (Safari, Firefox chưa thử). **Lần đầu tải rất lâu, khoảng 1,5–5 phút (~380 MB). Không có thanh tiến độ. Cứ để yên, game không treo.** / Chrome or Edge on desktop only (Safari and Firefox not tested). **The first load is very slow, about 1.5–5 min (~380 MB). There is no progress bar. Leave it, it is not frozen.** |

Không hỗ trợ điện thoại. / Phones are not supported.

## 2. Cài và mở lần đầu / Install and first launch (desktop)

- **Mac:** nhấp đúp file zip để giải nén, kéo `AxieDice.app` vào thư mục **Applications**. / Unzip, then drag `AxieDice.app` into **Applications**.
- **Windows:** chuột phải file zip → **Extract All**, rồi mở file `.exe` trong thư mục vừa giải nén. Đừng mở thẳng trong zip. / Right-click the zip → **Extract All**, then run the `.exe` in the extracted folder. Don't run it from inside the zip.

App chưa được ký số nên máy sẽ cảnh báo. Đây là bình thường. / The app is not signed, so your OS will warn you. That is expected.

- **macOS 15 trở lên / macOS 15+:** nhấp đúp app, bấm **Done**. Vào **System Settings → Privacy & Security**, kéo xuống, bấm **Open Anyway**, nhập mật khẩu máy. / Double-click, click **Done**, then go to **System Settings → Privacy & Security** and click **Open Anyway**.
- **macOS 14 trở xuống / macOS 14 or older:** chuột phải vào app → **Open** → **Open**. / Right-click → **Open**.
- **App báo "bị hỏng" / "is damaged":** mở Terminal, chạy / open Terminal and run:
  `xattr -dr com.apple.quarantine /Applications/AxieDice.app`
- **Windows:** SmartScreen hiện "Windows protected your PC". Bấm **More info** → **Run anyway**.

**Khi có bản mới / When a new build is out:** game sẽ báo. / the game tells you.
- Desktop: bấm **Download the new version**, tải zip, giải nén, thay app cũ (Mac: kéo đè vào Applications, có thể phải làm lại bước Open Anyway). / Click **Download the new version**, unzip, replace the old app (Mac: drag over the old one in Applications; you may need Open Anyway again).
- Web: bấm **Reload the page**. / Click **Reload the page**.

## 3. Đăng nhập / Sign in

**Phải đăng nhập bằng Google mới chơi run được.** Xúc xắc được tung trên server, nên mỗi run cần tài khoản. Tiến độ được lưu theo tài khoản.

**You need to sign in with Google to play runs.** Dice are rolled on our server, so every run needs an account. Your progress is saved to your account.

Nút **"Play as guest"** (có chỗ ghi "Continue without signing in") chỉ cho chơi tutorial và xem quanh. Màn đăng nhập ghi khách chơi được run thường, nhưng thật ra không được. Cứ đăng nhập Google.

**"Play as guest"** (sometimes shown as "Continue without signing in") only lets you play the tutorial and look around. The sign-in screen says guests can play normal runs. They can't. Please sign in with Google.

## 4. Nên thử gì / What to try

1. Chơi tutorial, rồi chơi **đủ 5 run** (thua sớm cũng tính, miễn đã vào ít nhất 1 trận). Thoát giữa run cũng được, lần sau vào chơi tiếp. / Play the tutorial, then play **5 runs** (an early loss counts as long as you fought at least one battle). You can quit mid-run and continue later.
2. Daily chơi được ngay sau khi đăng nhập. Sau 5 run, Nhiệm vụ (Missions) và Ranked mở ra. Thử một Nhiệm vụ N1. / Daily is open as soon as you sign in. After 5 runs, Missions and Ranked unlock. Try one N1 Mission.
3. Ghé Land, Store, Echo Box, Pass, đổi skin xúc xắc / khung avatar. / Look around Land, Store, Echo Box, Pass, and try a dice skin or avatar frame.

Gem trong bản này là Gem tặng (300 Gem mỗi ngày, bấm nhận), **không có tiền thật**. / Gems in this build are free (300 a day, claim them), **no real money anywhere**.

## 5. Báo lỗi và góp ý / Report bugs and feedback

Ghi vào Google Sheet / Use the Google Sheet: https://docs.google.com/spreadsheets/d/1-ArjPLvRbCgo1gjFsdXqqC77xCq4DJawOzqzupse49o/edit?usp=sharing

Kẹt không vào được game (ví dụ đăng nhập lỗi): nhắn **[tên / kênh Slack — Liam điền]**. / Can't get into the game at all (e.g. sign-in fails): message **[name / Slack channel — Liam fills in]**.

Mỗi dòng một chuyện. Nên có / One issue per row, ideally with:
- Máy: Mac / Windows / Web (trình duyệt nào). / Device: Mac / Windows / Web (which browser).
- Bản build (ghi trên trang download, hiện tại **b2484**). / Build number (shown on the download page, currently **b2484**).
- Bạn đang làm gì, thấy gì, mong thấy gì. / What you were doing, what happened, what you expected.
- Ảnh chụp màn hình nếu được. / A screenshot if you can.
- Mức độ: crash / kẹt không chơi tiếp được / sai / khó chịu / góp ý. / Severity: crash / stuck / wrong / annoying / idea.

Góp ý kiểu "chỗ này chán", "không hiểu cái này để làm gì" cũng rất có ích. / "This part is boring" or "I don't get what this is for" is useful too.

## 6. Lưu ý / Good to know

- **Dữ liệu playtest sẽ bị xoá hết** khi kết thúc giai đoạn thử, dự kiến **[ngày — Liam điền]** (tiến độ, Gem, lịch sử run). / **All playtest progress will be wiped** when the test ends, around **[date — Liam fills in]** (progress, Gems, run history).
- Game cần mạng khi đang trong run. Mất mạng giữa trận thì game sẽ báo. Nếu kẹt, ghi lại vào sheet. / Runs need an internet connection. If it drops mid-fight the game tells you. If you get stuck, please log it.
- Ngôn ngữ trong game: tiếng Anh. / In-game language: English.

## 7. Lỗi đã biết / Known issues

Không cần báo lại mấy lỗi này. / No need to report these again.

- Web lần đầu tải rất lâu, không có thanh tiến độ (xem mục 1). / The web build's first load is very slow and has no progress bar (see section 1).
- Màn đăng nhập ghi khách chơi được run thường. Không đúng, phải đăng nhập. / The sign-in screen says guests can play normal runs. They can't.
- Nút mua bằng USD trong Store bị tắt. Cố ý, bản này không bán gì. / The USD buttons in the Store are disabled on purpose. Nothing is for sale in this build.
- Trong trận, bốn nút Undo / Hold / Wild / Overcast khi bị tắt không nói lý do. / In combat, the Undo / Hold / Wild / Overcast buttons don't say why they are disabled.
- Nhãn trạng thái của quái (ví dụ PSN) có lúc bị đẩy lên sát mép trên màn trong lượt quái. / Enemy status labels (e.g. PSN) can sit at the very top edge during the enemy turn.
