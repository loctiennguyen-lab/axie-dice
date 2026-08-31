# UI FEEDBACK — Axie Dice Tactics v0.4
> File này do DEV TOOLS trong game tạo ra. Áp dụng đúng từng mục bên dưới.

## 1. STYLE ĐÃ CHỈNH BẰNG SLIDER (18)
```css
:root{
  --ui-scale: 1;   /* Phóng to toàn bộ UI — mặc định 1 */
  --spr-w: 96px;   /* Kích thước sprite Axie — mặc định 86px */
  --unit-w: 166px;   /* Bề ngang thẻ nhân vật — mặc định 166px */
  --bg: #3c081b;   /* Màu nền — mặc định #0f0d17 */
  --pan: #232323;   /* Màu panel — mặc định #1e1b2c */
  --line: #791a3e;   /* Màu viền — mặc định #443c66 */
  --txt: #ffffff;   /* Màu chữ chính — mặc định #ece8f8 */
  --dim: #919191;   /* Màu chữ phụ — mặc định #8f88ad */
  --spr-big: 170px;   /* Sprite BOSS — mặc định 150px */
  --intent-v: 16px;   /* Cỡ SỐ ý định của địch — mặc định 17px */
  --radius: 14px;   /* Bo góc (0 = pixel thuần) — mặc định 0px */
  --float-sz: 26px;   /* Cỡ số sát thương bay lên — mặc định 19px */
  --die-w: 166px;   /* Bề ngang xí ngầu — mặc định 166px */
  --die-h: 112px;   /* Chiều cao xí ngầu — mặc định 118px */
  --die-num: 31px;   /* Cỡ CHỮ SỐ trên xí ngầu — mặc định 27px */
  --die-kw: 10px;   /* Cỡ chữ keyword trên xí ngầu — mặc định 8px */
  --zone-gap: 10px;   /* Khoảng cách giữa các thẻ — mặc định 9px */
  --hp-h: 15px;   /* Chiều cao thanh máu — mặc định 16px */
}
```

## 2. GHI CHÚ THEO ELEMENT (4)

### MÀN HÌNH: MENU

**[1] `.screen.menu > .ver`**
- Kích thước hiện tại: 1260×11 @ 234,712
- Nội dung: "Gene Shard kiếm được trong run sẽ cộng vào ví khi run kết th"
- Style hiện tại: font-size:10px · color:rgb(90, 83, 120) · background:rgba(0, 0, 0, 0) · border:0px rgb(90, 83, 120) · padding:0px · gap:normal
- **YÊU CẦU SỬA:** thay dòng này bằng dong chữ "đây là sản phẩm phát triển độc lập bởi Liam"

### MÀN HÌNH: CODEX

**[2] `.screen.menu.codex > .cxshell > .cxpane > div > .cxtable[2/3]`**
- Kích thước hiện tại: 980×578 @ 487,297
- Nội dung: "CLASST1T2T3PLANTSprout (HP 17)Bracken (HP 25)Elder Bramble ("
- Style hiện tại: font-size:16px · color:rgb(255, 255, 255) · background:rgba(0, 0, 0, 0) · border:2px rgb(53, 47, 82) · padding:0px · gap:normal
- **YÊU CẦU SỬA:** T3 đang bị nhảy dòng, tôi muốn "Class T1 T2 T3" đều là 1 dòng

### MÀN HÌNH: GUIDE

**[3] `.screen.menu.guide`**
- Kích thước hiện tại: 1260×970 @ 234,4
- Nội dung: "ĐỘI HÌNH MẪU4 lối chơi đã được kiểm chứng — bấm để nạp thẳng"
- Style hiện tại: font-size:16px · color:rgb(255, 255, 255) · background:rgba(0, 0, 0, 0) · border:0px rgb(255, 255, 255) · padding:16px 0px 0px · gap:normal
- **YÊU CẦU SỬA:** - Tôi muốn cả team Axie thành 1 hàng ngang
- dòng chữ "dùng đội hình này" của cả 4 đội hình mẫu phải được để thẳng hàng

### MÀN HÌNH: MAP

**[4] `.screen.map`**
- Kích thước hiện tại: 1260×970 @ 234,6
- Nội dung: "WAVE1257911 340A2CHỌN ĐƯỜNG ĐISỰ KIỆNLựa chọn risk/reward. K"
- Style hiện tại: font-size:16px · color:rgb(255, 255, 255) · background:rgba(0, 0, 0, 0) · border:0px rgb(255, 255, 255) · padding:0px · gap:normal
- **YÊU CẦU SỬA:** Tôi muốn có thêm ô setting để có thể bật tắc điều chỉnh âm lượng nhạc, rết trận đấu hoặc quay về menu.

---
_Tổng: 4 ghi chú · 18 style override_
