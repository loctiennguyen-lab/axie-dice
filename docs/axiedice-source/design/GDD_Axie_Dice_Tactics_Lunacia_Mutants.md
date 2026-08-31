# DỰ ÁN AXIE DICE TACTICS: LUNACIA MUTANTS - GAME DESIGN DOCUMENT (GDD)

## 1. TỔNG QUAN DỰ ÁN (EXECUTIVE SUMMARY)

### 1.1. Thông tin chung

- **Tên dự án:** Axie Dice Tactics: Lunacia Mutants

- **Thể loại:** Single-Player Deterministic Tactical Roguelike / Dice Drafting

- **Nền tảng:** Web Browser (Desktop/Mobile PWA), tối ưu cho phát triển bằng AI Coding Assistant (Vibe Coding)

- **Mô hình thương mại:** Free-to-Play với hệ thống mở khóa Meta-Progression

- **IP tích hợp:** Axie Infinity (Chất liệu: Nhân vật Axie, 6 lớp Class, 6 Bộ phận cơ thể, Bối cảnh Lunacia & Quái vật Chimera)

### 1.2. Trụ cột Thiết kế (Core Design Pillars)

- **Minh bạch ****&**** Chiến thuật tuyệt đối (Deterministic Puzzle):** Loại bỏ hoàn toàn sự trừng phạt do may rủi. Người chơi nhìn thấy 100% ý định tấn công của kẻ địch và có quyền thử nghiệm, tính toán, hoàn tác (Undo) các nước đi trong lượt.

- **Sâu sắc trong tùy biến Gen (Modular Die Editing):** 6 mặt của xí ngầu tương ứng chính xác với 6 bộ phận cơ thể Axie. Quá trình chơi là quá trình ghép Gen, biến đổi bộ phận (Gene Mutation) để "build" nên viên xí ngầu bá đạo nhất.

- **Thân thiện tối đa với Vibe Coding (AI-Native Architecture):** Triệt tiêu hoàn toàn yếu tố vật lý thời gian thực. Toàn bộ game được thiết kế dưới dạng **Máy trạng thái rời rạc (Discrete State Machine)** và quản lý bằng dữ liệu cấu trúc (JSON Driven).

## 2. VÒNG LẶP LỐI CHƠI (GAME LOOPS)

### 2.1. Sơ đồ Vòng lặp tổng thể

[ MACRO LOOP: META PROGRESSION ]
  └── Mở khóa Class Axie ban đầu -> Thu thập Mảnh Gen -> Lai tạo (Breeding)
        │
[ MESO LOOP: RUN PROGRESSION (20 WAVES) ]
  └── Chọn đội hình 3 Axie -> Vượt 20 Màn chơi Chimera -> Nhận Mutation -> Đấu Boss
        │
[ MICRO LOOP: IN-COMBAT TURN ]
  ├── Phase 1: Roll & Reroll (Tung xí ngầu 3 Axie, khóa & đổ lại tối đa 2 lần)
  ├── Phase 2: Intent Analysis (Quan sát vị trí & hành động đã chốt của Chimera)
  ├── Phase 3: Tactical Execution (Gán xí ngầu, dùng Thẻ Năng Lượng, thử nghiệm & Undo)
  └── Phase 4: Enemy Phase (Chimera thực thi hành động) -> Chuyển lượt

### 2.2. Chi tiết Luồng xử lý một Lượt đấu (Micro Turn Execution Flow)

       ┌────────────────────────┐
       │     START PLAYER TURN  │
       └───────────┬────────────┘
                   │
                   ▼
       ┌────────────────────────┐
       │ Automatic Roll 3 Dice  │
       └───────────┬────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────┐
│           REROLL PHASE (Tối đa 2 lần)        │
│  - Chọn khóa (Hold) mặt xí ngầu ưng ý        │
│  - Đổ lại các mặt xí ngầu còn lại            │
└──────────────────┬───────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────┐
│          TACTICAL EXECUTION PHASE            │
│  - Gán mặt xí ngầu vào Mục tiêu               │
│  - Sử dụng Thẻ Năng Lượng Lunacia            │
│  - Hệ thống ghi nhận vào Stack (Hỗ trợ Undo) │
└─────────┬──────────────────────────┬─────────┘
          │                          │
   [Bấm Undo]                [Bấm End Turn]
          │                          │
          ▼                          ▼
┌──────────────────┐       ┌──────────────────┐
│ Trả lại trạng thái│       │  EXECUTE PLAYER  │
│    đầu lượt      │       │     ACTIONS      │
└──────────────────┘       └─────────┬────────┘
                                     │
                                     ▼
                           ┌──────────────────┐
                           │   EXECUTE ENEMY  │
                           │      INTENTS     │
                           └─────────┬────────┘
                                     │
                                     ▼
                           ┌──────────────────┐
                           │   CHECK WIN/LOSS │
                           └──────────────────┘

## 3. THIẾT KẾ CƠ CHẾ CỐT LÕI (CORE MECHANICS & SYSTEMS)

### 3.1. Cấu trúc Viên Xí Ngầu Axie (Die Architecture)

Mỗi Axie trong đội hình sở hữu **1 viên xí ngầu 6 mặt**, đại diện trực tiếp cho **6 bộ phận cơ thể (Body Parts)**.

| Mặt Xí Ngầu | Bộ Phận | Loại Hành Động Mặc Định | Giá Trị Cơ Bản (Lvl 1) | Mục Tiêu Tác Động |
| --- | --- | --- | --- | --- |
| **Mặt 1** | **Mouth (Miệng)** | Tấn công (Damage) / Hút máu | 3 DMG | Đơn mục tiêu địch |
| **Mặt 2** | **Horn (Sừng)** | Tấn công Bạo kích / Xuyên Giáp | 4 DMG | Đơn mục tiêu địch |
| **Mặt 3** | **Back (Lưng)** | Tạo Giáp (Shield) / Buff Phòng thủ | 4 SHIELD | Bản thân hoặc Đồng đội |
| **Mặt 4** | **Tail (Đuôi)** | Tấn công Đa mục tiêu / Độc (Poison) | 2 DMG + 1 Poison | Toàn bộ hoặc Hàng ngang |
| **Mặt 5** | **Eyes (Mắt)** | Kỹ năng Nội tại (Cantrip) | Tự động kích hoạt | Tự động khi gieo trúng |
| **Mặt 6** | **Ears (Tai)** | Nạp Năng lượng (Energy) | +1 Energy | Quỹ Năng lượng chung |

### 3.2. Hệ thống Từ Khóa Kỹ Năng (Skill Keywords)

- **CANTRIP:** Mặt xí ngầu tự động thi triển hiệu ứng ngay lập tức khi vừa gieo trúng ở Reroll phase mà không cần kéo/thả thủ công, không tốn lượt dùng.

- **HEAVY:** Mặt xí ngầu bị khóa cứng khi gieo trúng, không được phép Reroll.

- **CLEAVE:** Gây 100% sát thương lên mục tiêu chính và 50% sát thương lan sang 2 mục tiêu kề cạnh.

- **GROWTH:** Tăng +1 giá trị cho mặt xí ngầu này sau mỗi lần sử dụng thành công trong cùng một trận đấu.

- **DECAY:** Giảm -1 giá trị cho mặt xí ngầu này sau mỗi lần sử dụng.

- **POISON [X]:** Gắn X tầng Độc lên mục tiêu. Cuối lượt của mục tiêu, rút X máu và giảm X xuống 1 tầng.

- **SHIELD PIERCE:** Sát thương bỏ qua toàn bộ giáp, trừ thẳng vào HP của mục tiêu.

- **VITAL:** Nhân đôi giá trị hành động nếu máu (HP) của Axie sử dụng đang đầy 100%.

### 3.3. Hệ thống Lớp Nhân Vật (Class Architecture & Synergies)

Đội hình thi đấu cố định bao gồm **3 Axie** xếp theo thứ tự hàng dọc: **Frontline (Tiền tuyến) - Midline (Trung tuyến) - Backline (Hậu tuyến)**.

[ CHIMERA ENEMIES ]   <--->   [ FRONT: Plant/Reptile ]
                              [ MID:   Beast/Bug     ]
                              [ BACK:  Aqua/Bird     ]

- **Class Plant:** HP cực lớn, chuyên tạo Giáp diện rộng và Hồi máu.

- **Class Beast:** HP trung bình, Sát thương bạo kích cực cao, sở hữu nhiều mặt Heavy/Growth.

- **Class Aqua:** Tốc độ cao, chuyên nạp điểm Axie Energy và sở hữu nhiều mặt Cantrip.

- **Class Reptile:** Giáp cao, phản đòn sát thương và gài trạng thái Poison.

- **Class Bug:** Làm suy yếu quái vật, giảm Sát thương của Chimera.

- **Class Bird:** HP thấp, sát thương bỏ qua Giáp, đánh thẳng vào hàng sau của địch.

### 3.4. Minh bạch Thông tin (Telegraphed Enemy Intent System)

Toàn bộ quái vật Chimera **bắt buộc phải công khai ý định ngay khi lượt bắt đầu**:

- ⚔️ **Red Sword [X]:** Sẽ tấn công vị trí Axie chỉ định với X sát thương.

- 🛡️ **Blue Shield [X]:** Sẽ tự tạo X giáp hoặc buff giáp cho đồng đội.

- ☣️ **Green Skull [X]:** Sẽ xả X tầng độc hoặc Debuff lên đội hình.

- 🥚 **Egg/Summon:** Sẽ triệu hồi thêm Chimera nhỏ vào lượt sau.

### 3.5. Cơ chế Năng Lượng & Thẻ Bài Lunacia (Global Energy Cards System)

- **Quỹ Năng Lượng (Energy Pool):** Tích lũy bằng cách kích hoạt các mặt xí ngầu thuộc bộ phận Ears/Tail của hệ Aqua/Bird. Điểm Energy được giữ lại qua các lượt trong cùng 1 trận chiến.

- **Cơ chế Thẻ bài:** Người chơi cầm trên tay tối đa 4 lá bài bổ trợ. Dùng Energy để xả bài.

┌─────────────────────────┐  ┌─────────────────────────┐
│     ANEMONE RESTORE     │  │       CHOMP STRIKE      │
│  [Cost: 2 Energy]       │  │  [Cost: 3 Energy]       │
│                         │  │                         │
│ Hồi 6 HP lập tức cho    │  │ Gây 5 Sát thương xuyên  │
│ Axie đứng Frontline.    │  │ giáp & Câm lặng mục     │
│                         │  │ tiêu trong 1 lượt.      │
└─────────────────────────┘  └─────────────────────────┘

### 3.6. Cơ chế Hoàn Tác Tự Do (Unlimited Undo Engine)

- **Nguyên lý hoạt động:** Mọi hành động chưa tạo ra sự thay đổi ngẫu nhiên mới được lưu vào `ActionStack`.

- **Thao tác:** Bấm nút **[UNDO]** (Ctrl+Z) sẽ phục hồi trạng thái game về đúng bước trước đó.

- **Giới hạn:** Không thể Undo sau khi người chơi bấm nút **[END TURN]**.

## 4. CẤU TRÚC RUN CHƠI & TIẾN TRÌNH METAGAME

### 4.1. Cấu trúc một Run chơi (20 Waves Breakdown)

Wave 01 - 03: Chimera cấp thấp (Tutorial & Warm-up)
Wave 04     : ELITE CHIMERA 1 (Thử thách sinh tồn đầu tiên)
Wave 05 - 07: Chimera phối hợp hệ nguyên tố
Wave 08     : BOSS 1: "Gooey King" (Phân tách quái nhỏ khi nhận DMG)
Wave 09 - 11: Chimera có trạng thái Poison & Stealth
Wave 12     : ELITE CHIMERA 2
Wave 13 - 15: Chimera có khả năng Buff Giáp & Hồi máu diện rộng
Wave 16     : BOSS 2: "Mecha Chimera" (Chuyên phản đòn & Sát thương diện rộng)
Wave 17 - 19: Đợt quái dồn dập độ khó cao nhất
Wave 20     : FINAL BOSS: "NIGHTMARE AGONY" (Đa giai đoạn)

### 4.2. Hệ thống Đột Biến Gen (Gene Mutation / Die Editing)

Sau mỗi Wave, người chơi chọn 1 trong 3 phần thưởng Đột biến Gen:

┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│ PART REPLACEMENT│     │   RUNE IMBUING  │     │ GENE OVERCLOCK  │
│ Thay thế 1 mặt  │     │ Gắn thêm 1 Từ   │     │ Tăng +50% giá   │
│  xí ngầu bằng 1 │     │ khóa (Cleave,   │     │ trị số của toàn │
│  Bộ phận Cấp 2  │     │ Cantrip...)     │     │ bộ 6 mặt xí ngầu│
└─────────────────┘     └─────────────────┘     └─────────────────┘

### 4.3. Tiến trình Meta (Meta-Progression & Breeding)

- **Tích lũy tài nguyên:** Kết thúc Run, nhận Mảnh Gen (Gene Shards) và Axie EXP.

- **Mở khóa Class mới:** Mở khóa các Class nâng cao hoặc Thẻ bài Lunacia mới.

- **Cơ chế Lai Tạo:** Kết hợp 2 Axie tạo ra F1 thừa hưởng tính trạng trội/lặn, tạo xí ngầu độc bản.

## 5. THIẾT KẾ GIAO DIỆN (UI/UX SPECIFICATION)

### 5.1. Bố cục Màn hình Chiến đấu

┌────────────────────────────────────────────────────────────────────────┐
│ [PAUSE]                WAVE 08/20 - BOSS BATTLE           [UNDO (Ctrl+Z)]│
├────────────────────────────────────────────────────────────────────────┤
│                       [ CHIMERA BOSS: GOOEY KING ]                     │
│                             HP: 85/120 | 🛡️ 12                        │
│                             Intent: ⚔️ 15 (Target: FRONT)             │
├────────────────────────────────────────────────────────────────────────┤
│   [ AXIE 1: PLANT (Front) ] [ AXIE 2: BEAST (Mid) ] [ AXIE 3: AQUA (Back)]│
│   HP: 32/45 | 🛡️ 8         HP: 22/28 | 🛡️ 0        HP: 20/24 | 🛡️ 0    │
│   ┌───────────────┐        ┌───────────────┐       ┌───────────────┐   │
│   │   [ FACE 3 ]  │        │   [ FACE 2 ]  │       │   [ FACE 6 ]  │   │
│   │   Back: 🛡️ 6  │        │   Horn: ⚔️ 8  │       │   Ears: ⚡ +2  │   │
│   └───────────────┘        └───────────────┘       └───────────────┘   │
│   [ ] Lock                 [x] Lock                [ ] Lock            │
├────────────────────────────────────────────────────────────────────────┤
│  ENERGY POOL: ⚡ 3/10    │ HAND CARDS: [Anemone Restore] [Chomp]       │
│  [ REROLL (1/2 LEFT) ]  │                       [ END TURN ]          │
└────────────────────────────────────────────────────────────────────────┘

## 7. CÂN BẰNG TOÁN HỌC & CHỈ SỐ CƠ BẢN

| Cấp Độ Wave | HP Trung Bình Chimera | Sát Thương Địch / Lượt | Tổng HP Đội Axie | Tổng Sát Thương Axie |
| --- | --- | --- | --- | --- |
| **Wave 1-3** | 12 - 18 HP | 3 - 5 DMG | 80 - 90 HP | 10 - 14 DMG |
| **Wave 4 (Elite)** | 35 HP | 8 DMG (Diện rộng) | 80 - 90 HP | 14 - 18 DMG |
| **Wave 8 (Boss)** | 120 HP | 12 DMG + Summons | 100 - 115 HP | 20 - 28 DMG |
| **Wave 20 (Final)** | 500 HP (2 Phase) | 30 DMG / Lượt | 140 - 160 HP | 50 - 70 DMG |
