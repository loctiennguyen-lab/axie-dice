# Ký số bản desktop (macOS notarize + Windows code signing)

Trạng thái: CHUẨN BỊ XONG, CHƯA CÓ CERT (28/10/2026). Script đã có, chỉ chạy dry-run được. Chưa có gì được ký thật.
Hôm nay: mac ký ad-hoc, Windows không ký, ai tải về phải bấm "Open Anyway" / "Run anyway" (xem `production/qa/l1-install-guide.md`).

Mọi con số giá/chính sách bên dưới là theo hiểu biết của mình, đã có thể đổi. Kiểm lại trên trang chính thức trước khi trả tiền.

## 1. Tóm tắt Liam phải làm

| Việc | Ai làm | Mất bao lâu | Tiền |
|---|---|---|---|
| Apple Developer Program (tài khoản tổ chức hoặc cá nhân) | Liam | cá nhân vài giờ đến 1-2 ngày; tổ chức cần số D-U-N-S, có thể 1-3 tuần | 99 USD/năm |
| Tạo cert "Developer ID Application" | Liam (chỉ Account Holder tạo được) | 15 phút | gồm trong 99 USD |
| `notarytool store-credentials` (một lần) | Liam | 5 phút | 0 |
| Chọn cách ký Windows (mục 5) và mua/đăng ký | Liam | vài ngày đến vài tuần (kiểm danh tính) | khoảng 10 USD/tháng đến vài trăm USD/năm |

Không gửi cho mình (hay ai) mật khẩu, file .p12/.pfx, app-specific password. Mọi thứ chỉ nằm trong keychain trên máy Liam.

## 2. macOS: lấy cert Developer ID Application (một lần)

1. Đăng ký https://developer.apple.com/programs/ (99 USD/năm). Nên dùng tài khoản tổ chức (Sky Mavis) nếu công ty cho, để tên hiện ra là công ty. Tổ chức cần D-U-N-S.
2. Chỉ **Account Holder** mới tạo được Developer ID. Vào developer.apple.com > Certificates > "+" > **Developer ID Application**.
3. Cách dễ nhất: mở Xcode > Settings > Accounts > chọn team > Manage Certificates > "+" > **Developer ID Application**. Cert và private key tự vào keychain login của máy này.
4. Kiểm:
   ```
   security find-identity -v -p codesigning
   ```
   phải thấy dòng `Developer ID Application: <Tên> (<TEAMID>)`. Private key chỉ có trên máy tạo cert. Nên export một bản .p12 có mật khẩu mạnh cất vào chỗ an toàn (password manager). File .p12 phải nằm NGOÀI repo (ví dụ `~/secrets/`), mất máy là phải xin cert mới.

## 3. macOS: lưu thông tin notarize vào keychain (một lần)

1. Vào https://account.apple.com > Sign-In and Security > App-Specific Passwords > tạo một cái tên "axie-notary".
2. Chạy (tự gõ, đừng dán vào chat):
   ```
   xcrun notarytool store-credentials axie-notary --apple-id "<apple id email>" --team-id "<TEAMID>"
   ```
   Nó sẽ hỏi app-specific password rồi lưu vào keychain dưới tên `axie-notary`. Script chỉ biết cái tên này (đổi bằng `AXIE_NOTARY_PROFILE`).
3. Kiểm (cần mạng, không in bí mật):
   ```
   bash tools/notarize_mac.sh --dry-run --check-profile
   ```
   Mong đợi: mọi dòng `ok`, kết thúc "dry-run: đủ điều kiện".
   Có nhiều identity Developer ID thì đặt `export AXIE_SIGN_IDENTITY="Developer ID Application: ... (TEAMID)"`.

## 4. macOS: chạy

Qua build (khuyên dùng), nhớ tắt Godot editor như mọi lần build:
```
AXIE_NOTARIZE_MAC=1 bash tools/build_desktop.sh macos
```
Dòng đầu của `BUILD_INFO.txt` giờ ghi trạng thái ký (mac=notarized/ad-hoc, windows=signed/unsigned). Thứ tự: kiểm điều kiện (vài giây, thiếu là dừng ngay, chưa tốn thời gian export) > export > ký trong ra ngoài (hardened runtime) > nộp Apple và chờ (thường vài phút, có khi lâu hơn) > staple > `spctl` > mới tạo zip và dmg từ app đã staple. Không có cờ thì flow y như cũ.

Chạy riêng trên một .app có sẵn: `bash tools/notarize_mac.sh --app đường/dẫn/AxieDice.app`.

Cách kiểm sau khi xong (trên bản zip trong `build/`, giải nén bằng Finder hoặc `ditto -x -k`):
```
spctl -a -vv -t exec AxieDice.app        # phải có: source=Notarized Developer ID
xcrun stapler validate AxieDice.app      # phải có: The validate action worked!
codesign -dv --verbose=2 AxieDice.app    # Authority=Developer ID Application..., flags=...runtime
```
Test thật: tải zip từ trang /download bằng trình duyệt (để có cờ quarantine), mở ra, double-click. Không được còn hộp thoại "Open Anyway".

Phần đã làm trong script:
- Entitlements ở `tools/signing/macos.entitlements`: chỉ `disable-library-validation`, khớp preset macOS hiện tại. Không JIT, không sandbox. Mình KHÔNG kiểm được trên bản ký thật. Nếu sau khi notarize app crash ngay lúc mở: xem Console.app, rồi báo mình. Ngược lại, vì app hiện không có dylib/framework nào kèm theo, có thể thử bỏ cả entitlement này cho chặt hơn.
- Không dùng `codesign --deep` (Apple không khuyên). Script ký từng file Mach-O lồng bên trong trước, bundle sau.
- Apple từ chối thì script in ra lệnh `xcrun notarytool log <id> --keychain-profile axie-notary` để xem lý do.
- File .dmg vẫn tạo từ app đã staple nhưng bản thân dmg không ký, và `publish_desktop.sh` vốn không đăng dmg, nên không ảnh hưởng.
- Preset Godot (`codesign/codesign=1`, `notarization/notarization=0`) giữ nguyên: Godot vẫn ký ad-hoc lúc export, rồi script ký đè bằng `--force`.

## 5. Windows: chọn cách ký

Điều cần biết trước: từ giữa 2023, cert OV/EV mới theo quy định của CA/B Forum phải để private key trong phần cứng (USB token) hoặc HSM/cloud. Nghĩa là thường KHÔNG còn nhận được file .pfx để bỏ vào script. Cert .pfx cũ chỉ còn dùng được tới khi hết hạn.

| Lựa chọn | Giá tham khảo | Thời gian | Hợp với script `sign_windows.sh` không |
|---|---|---|---|
| A. Azure Trusted Signing (gần đây có thể đã đổi tên "Artifact Signing") | khoảng 10 USD/tháng gói Basic | vài ngày (xác minh danh tính) | Không trực tiếp. Dùng signtool + plugin của Microsoft (chỉ chạy trên Windows) hoặc công cụ như `jsign` có hỗ trợ. Cần viết thêm script. |
| B. Cert OV của CA (DigiCert, Sectigo, SSL.com...) | khoảng 200-500 USD/năm | 2-7 ngày, kiểm tổ chức | Có, nếu CA đưa token/cloud HSM mà hỗ trợ PKCS#11 (chế độ B trong script, chưa thử). Một số CA cloud (vd SSL.com eSigner) không dùng được với osslsigncode. |
| C. Cert EV | khoảng 300-700 USD/năm | 1-2 tuần | Như B, luôn là token/HSM. |

Điểm cần kiểm TRƯỚC khi chọn A: Trusted Signing chỉ nhận một số loại tổ chức/quốc gia và thường đòi tổ chức có lịch sử hoạt động vài năm. Sky Mavis nằm ngoài Mỹ/Canada/EU, mình chưa chắc được nhận. Liam hoặc công ty kiểm trên trang Microsoft.

Khuyến nghị:
1. Thử A trước nếu đủ điều kiện: rẻ nhất, không cần token vật lý, ký được từ CI. Cần thêm một script ký (mình viết khi Liam xác nhận được nhận), vì `sign_windows.sh` hiện chưa phủ.
2. Không đủ điều kiện thì B (OV) với CA cho PKCS#11 hoặc cert .pfx kiểu cũ. Hỏi CA câu: "có dùng được với osslsigncode trên macOS không?" trước khi mua.
3. EV chỉ đáng khi cần cho tới mức nhà phát hành lớn. Từ 2024 EV không còn được "bỏ qua SmartScreen ngay" như trước, xem dưới.

### SmartScreen: kỳ vọng đúng

- Ký xong KHÔNG có nghĩa hết cảnh báo ngay. Windows SmartScreen tính uy tín theo file hash và theo nhà phát hành. File mới, ít người tải, thì vẫn có thể hiện "Windows protected your PC" dù đã ký.
- Có ký thì dòng đầu đổi từ "Unknown publisher" thành tên công ty, và uy tín gắn vào cert (không bị reset mỗi lần build mới như file không ký). Tải càng nhiều người dùng thì cảnh báo càng mất, thường mất vài tuần.
- Trước đây EV cho uy tín tức thì; hiện nay (theo hiểu biết của mình) Microsoft đã bỏ chuyện đó, EV chỉ khá hơn OV một chút.
- Cert phải gia hạn và đổi cert thì có thể phải gây dựng lại uy tín. Giữ nguyên tên tổ chức trong cert giữa các lần gia hạn.
- Trang /download nên giữ hướng dẫn "More info > Run anyway" thêm một thời gian sau khi bật ký.

### Chuẩn bị dùng script (chế độ pfx hoặc token)

```
brew install osslsigncode
export AXIE_WIN_CERT=$HOME/secrets/axie-win.pfx       # NGOÀI repo
security add-generic-password -a "$USER" -s axie-win-cert -w   # nhập mật khẩu khi được hỏi. Nên dùng keychain, tránh `export AXIE_WIN_CERT_PASSWORD=...` vì mật khẩu vào lịch sử shell
bash tools/sign_windows.sh --dry-run                  # phải báo đủ điều kiện
AXIE_SIGN_WINDOWS=1 bash tools/build_desktop.sh windows
```
Chế độ token: đặt `AXIE_WIN_PKCS11_MODULE`, `AXIE_WIN_PKCS11_CERTS`, `AXIE_WIN_PKCS11_KEY` (xem đầu file `tools/sign_windows.sh`). Chưa thử, sẽ cần chỉnh khi có token thật.

Sau khi ký: script tự verify (cần 'Signature verification: ok' và có timestamp), không đạt thì giữ nguyên exe gốc và dừng. Cert .pfx cũ mà OpenSSL 3 không đọc được thì xem ghi chú `-legacy` đầu `sign_windows.sh`. Chữ ký làm exe to hơn vài KB, `publish_desktop.sh` tự tính lại sha256 từ zip nên không cần làm gì thêm. BẮT BUỘC mở thử exe đã ký trên một máy Windows thật (Godot gắn pck vào exe, mình chưa thử ký loại file này), và chuột phải > Properties > Digital Signatures phải thấy tên công ty và timestamp.

## 6. Rollback

- Cờ tắt = hành vi cũ. Không đặt `AXIE_NOTARIZE_MAC` / `AXIE_SIGN_WINDOWS` thì build ra ad-hoc/unsigned như hôm nay, không script nào của đợt này chạy.
- Bản ký lỗi (mở không lên, crash): build lại không cờ rồi đăng như thường. Rollback trên R2 dùng cách cũ trong `tools/publish_desktop.sh` (`--prev` và `downloads/old/`).
- Notarize bị Apple từ chối: không có gì bị đăng, build dừng. Đây là cổng, không phải sự cố.
- Cert bị lộ/nghi lộ: Apple, Certificates > Revoke cert Developer ID đó; Windows: báo CA thu hồi. Tạo cert mới. Nhớ thu hồi cả app-specific password.
- Việc rút lại cert chỉ ảnh hưởng bản ký bằng cert đó.

## 7. Những thứ KHÔNG được làm

- Không commit cert/khoá/mật khẩu. `.gitignore` đã chặn: `*.p12 *.pfx *.p8 *.cer *.csr *.certSigningRequest *.keychain *.keychain-db *.mobileprovision *.provisionprofile *.jks *.keystore`. Không chặn `.pem/.crt/.der` (chưa kiểm repo có file hợp lệ loại này không), nên đừng để chúng trong repo. Cert luôn để ngoài repo; script cũng từ chối cert nằm trong repo (đã giải symlink).
- Không dán mật khẩu vào chat hoặc truyền qua dòng lệnh.
- Không ký trên máy chia sẻ mà người khác đọc được keychain.

## 8. Trạng thái kiểm

Đã chạy: `bash -n` cả 3 script; `--dry-run` của `notarize_mac.sh` và `sign_windows.sh` (đúng kỳ vọng: báo thiếu cert/profile/osslsigncode, thoát mã 1, không ký gì); `AXIE_NOTARIZE_MAC=1 bash tools/build_desktop.sh macos` dừng ngay ở bước kiểm điều kiện.
Chưa chạy được (vì chưa có cert): ký thật, notarize thật, staple, `spctl`, ký Windows, chế độ PKCS#11, mở thử bản ký trên máy sạch.
