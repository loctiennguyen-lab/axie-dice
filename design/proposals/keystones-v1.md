# Lõi chủ (Keystone) v1: 6 Lõi chủ chỉnh theo luật hiện tại (đề xuất, chờ Liam duyệt)

Ngày 10/2026. Chưa đổi code, chưa đổi knob, chưa commit. Thay mục 10 của `design/gdd/dice-depth-v4.md` (mục đó viết lúc Overcast còn là 3 mana / 1 viên,
Mặt Tạm còn 3 mana). Mọi số "ước" dưới đây là tính tay để chọn hướng, **sim quyết**, không lấy số tay làm bằng chứng.

Luật nền đang chạy (đọc từ `combat_tune.json` + `v4-mana-decisions.md`): hệ số mỗi viên `M = min(1 + bo_add + oc_add + core_add, m_cap 3.0)`;
BỘ ba/bốn/năm = ×1.3 / ×2.2 / ×2.6; Overcast 2 mana, +0.5 cho CẢ BỘ, 1 lần/lượt; Mặt Tạm chỉ 3→4, 2 mana, 1 lần/trận; Nứt 30% (giá trị /2);
An toàn lần 1 = 1 mana, lần 2 = 3 mana; Hold cap 1; `enemy_dmg_mult` 1.55. Mana nhận ~1.35/lượt, lượt có BỘ ~44%.
Sim hiện tại: random 11.0, spam 10.5, free_hold 10.5, expert 18.8.

Việc Lõi chủ phải làm: đổi cách chơi cả run (Liam: không lặp lối chơi) mà không làm game dễ đi. Nên mỗi Lõi chủ có một cái giá thật, và số khởi điểm
cố tình nghiêng về yếu (sim nâng lên sau, dễ hơn là hạ).

## Điều kiện chung (giữ từ mục 10 cũ)

- Chọn 1 trong 3 lúc bắt đầu run, giữ suốt run, không bán, không đổi, không cấp giữa run.
- Hệ số của Lõi chủ cộng vào túi M (không nhân chồng), nằm dưới `bo.m_cap`, không tính vào trần cộng phẳng +10.
- Lõi chủ **không phải** Lõi thường: không chiếm slot Lõi, không vào `core_offer`, không vào gacha Tinh Thể, không thuộc combo trong
  `core_combos.json`. Hiện thành một huy hiệu riêng cạnh CorePanel. (Giữ gacha-contract khỏi bị đụng.)
- Tên gọi: đã có relic `r_keystone` (chia 50% mặt khiên/hồi/mana cho hàng xóm slot 3, `relic_hooks.gd` ~1052). Trùng chữ "Keystone" với tên nhóm này.
  Cần Liam/UX chọn: đổi tên relic, hoặc gọi nhóm này khác trong game (ví dụ "Pillar"). Doc này tạm dùng "Lõi chủ".

## 0. Trọng tâm (phản hồi Liam sau b1393): Lõi chủ là mỏ neo, combo hợp thì "Thức tỉnh"

Liam chơi b1393: "chưa đủ hay, còn rời rạc, thiếu ĐỘT BIẾN khi chọn được combo Lõi đặc biệt". Thưởng combo hiện chỉ là trình diễn + 1 reroll. Hai chỗ hở, và Lõi chủ trả lời cả hai:

1. **Rời rạc** -> mỗi Lõi chủ là **mỏ neo** của một nhóm Lõi thường. Chọn Lõi chủ = chọn hướng build cho cả run; Lõi thường sau đó không còn là "mỗi lần một thẻ rời" mà là "mảnh nào hợp mỏ neo".
2. **Thiếu đột biến** -> khi người chơi ráp được **Cặp** của một combo thuộc nhóm hợp với Lõi chủ, Lõi chủ **Thức tỉnh** (Awakening): thêm một **luật mới** của trận (không chỉ cộng số), có banner + đổi huy hiệu Lõi chủ.

### 0.1 Mỏ neo: nhóm Lõi thường của từng Lõi chủ

Dữ liệu mới `godot/assets/data/rules/keystones.json` (file luật, có fingerprint): mỗi Lõi chủ khai `anchor_cores` (nhóm Lõi hợp) và `awaken_combos` (id combo trong `core_combos.json`).
Thành phần dưới đây suy từ `core_combos.json` (Cặp -> Đủ) và tên hook; **cần đối chiếu text relic thật trước khi chốt**, tôi chưa đọc hết hook từng Lõi.

| Lõi chủ | Nhóm Lõi mỏ neo (`anchor_cores`) | Combo thức tỉnh (`awaken_combos`) |
|---|---|---|
| Tam Tấu | `c_thorn_shield`, `c_living_wall`, `c_sonic_shield`, `c_elder_trunk`, `c_descend` | Golden Turtle Fortress, Shield Engine, Molting, Bramble Hide |
| Con Bạc | `c_sixth_die`, `c_collector`, `c_cascade`, `c_prism` | Dice Rainbow, Lunacia Rain (jackpot, vì có `c_sixth_die`) |
| Mỏ Mana | `c_mana_pool`, `c_deep_current`, `c_loop`, `c_tidecaller`, `c_overflow`, `c_mana_ward` | Endless Mana Loop, Rising Tide, Lakebed Fishing Rod |
| Đồng Tộc | `c_living_wall`, `c_early_scales`, `c_elder_trunk`, `c_nest`, `c_golden_egg` (Lõi theo thân/ổ cùng class) | Ancient Turtle, Bramble Hide, Golden Egg Blast |
| Giữ Lửa | `c_kindle`, `c_three_dice`, `c_finisher`, `c_chimera_hunt`, `c_hollow_core` | Lakebed Fishing Rod, Finishing Stroke, Slow Burn |
| Bàn Tay Lớn | `c_sixth_die`, `c_three_dice`, `c_collector`, `c_prism`, `c_overflow` | Dice Rainbow, Slow Burn, Lunacia Rain |

Một Lõi thường có thể nằm trong hai nhóm (ví dụ `c_sixth_die` cho Con Bạc và Bàn Tay Lớn): cố ý, vì cùng Lõi mà khác mỏ neo thì ra build khác nhau.

**Nghiêng offer, không ép** (làm hết rời rạc nhưng không mất may rủi gacha): khi đã có Lõi chủ, `core_offer` nhân trọng số Lõi trong `anchor_cores` với `core.ks_bias` = 1.5 (1.0 = tắt; khoảng 1.0-2.0). Giữ nguyên bậc Tinh Thể, near-miss, reroll Lõi. Thẻ Lõi hợp hiện chip
"Hợp Lõi chủ: <tên>" (dùng chỗ chip "With: X, Y" đã có ở thẻ Core). Thẻ Lõi chủ cũng liệt kê nhóm hợp của nó ngay ở màn chọn (chọn có thông tin).

### 0.2 Thức tỉnh (Awakening)

- Điều kiện: có **Cặp** (2 Lõi, `combo_done[id] >= "pair"`) của bất kỳ combo trong `awaken_combos`. Thức tỉnh một lần mỗi run, ngay lúc `combo_formed` (dùng lại sự kiện và banner của gacha pack: banner Cặp 1.6 s,
  thêm dòng "AWAKENING: <Lõi chủ>" / "THỨC TỈNH"). Đủ (Lõi thứ ba) đẩy hiệu ứng thức tỉnh lên một nấc (cột "Đủ" dưới). Không có Cặp thì Lõi chủ vẫn chạy như mục 1, chưa có luật mới.
- Hiệu ứng thức tỉnh là **đổi luật**, không +%:

| Lõi chủ | Thức tỉnh (luật mới) | Đủ (nấc cao) | Knob |
|---|---|---|---|
| Tam Tấu -> **Bão Gai (Thorn Storm)** | BỘ nổ **hai lần mỗi lượt** (hai BỘ lớn nhất), và vụ nổ **xuyên khiên** của quái. Mỗi vụ giữ `tt.cap` | cap mỗi vụ +4; vụ nổ thứ hai không bị `-0.15` | `aw.tt.bursts` 2 (2), `aw.tt.pierce` 1, `aw.tt.cap_full` 20 |
| Con Bạc -> **Ván Gỡ (Second Chance)** | Liều làm Nứt thì được tung lại **đúng các viên Nứt** một lần, miễn phí, trong cùng lần Liều (không trừ tổng tung lại); nếu lần gỡ sạch Nứt thì vẫn tính là Liều sạch | gỡ được hai lần mỗi lượt | `aw.cb.redo_per_turn` 1 (1-2) |
| Mỏ Mana -> **Nhịp Đôi (Double Beat)** | Overcast dùng **hai lần mỗi lượt** (lần hai tốn 2 mana, tức giá thường) | lần hai tốn 1 mana | `aw.mm.oc_per_turn` 2, `aw.mm.oc2_cost` 2 (1-2) |
| Đồng Tộc -> **Huyết Mạch (Bloodline)** | BỘ thuần class đủ `dt.need` **không bị trừ mana**: Mặt Tạm miễn phí (0 mana) khi tạo BỘ ba thuần class thành bốn; vẫn 1 lần/trận | thêm 1 lần Mặt Tạm miễn phí mỗi trận (vẫn cấm bốn -> năm) | `aw.dt.wild_cost` 0, `aw.dt.wild_extra` 0 (0-1) |
| Giữ Lửa -> **Lửa Truyền (Kindred Flame)** | Hai viên Hold cùng lúc được tính **cùng part** với nhau khi hình thành BỘ lượt sau (Hold = cầu nối, tối đa tạo BỘ bốn) | viên mang sang không bị lọc ở lượt Hở boss: +0.50 nữa | `aw.gl.bridge` 1, `aw.gl.hollow_add` 0.50 |
| Bàn Tay Lớn -> **Bàn Tay Thứ Sáu (Sixth Hand)** | Mỗi lượt có BỘ bốn trở lên (lần đầu): tung ngay **một viên thưởng** vào bàn, dùng được lượt này, không vào BỘ đã chốt | viên thưởng thành BỘ được (tính BỘ lại) | `aw.bh.bonus_die` 1, `aw.bh.counts_full` 1 |

Mỗi hiệu ứng đều đổi cách ra quyết định trong trận (đánh hai nhịp, gỡ rồi cược tiếp, Overcast hai lần, Mặt Tạm miễn phí, Hold làm cầu nối, viên thưởng) chứ không chỉ to hơn.

**Đột biến nhìn thấy được** (theo luật "nội dung mới phải thấy khi chơi"): (1) banner lúc Cặp ráp xong; (2) huy hiệu Lõi chủ đổi khung vàng + tên thức tỉnh; (3) mỗi lần hiệu ứng mới phát trong trận có popup tên
(ví dụ "Thorn Storm: lần nổ thứ hai"); (4) màn kết run ghi "Thức tỉnh: <tên> (lượt N, trận M)". UI/âm do ux-designer/audio quyết, doc này chỉ yêu cầu bốn điểm hiện.

### 0.3 Nối với việc brainstorm "đột biến khi ráp combo"

Một agent khác đang làm `design/proposals/combo-mutation-brainstorm.md` (chưa có file lúc tôi viết). Hai thứ nối nhau như sau, **để Liam/lead chốt khi hai bên xong**:
- Lõi chủ thức tỉnh là **một loại đột biến** của combo: combo nào có trong `awaken_combos` của Lõi chủ đang giữ thì đột biến này chồng lên (hoặc thay) đột biến chung mà brainstorm kia chọn. Nếu brainstorm kia
  đề xuất đột biến riêng cho từng combo thì giữ hai tầng: tầng combo (ai ráp cũng có) + tầng Lõi chủ (chỉ khi Lõi chủ hợp). Không để hai tầng cùng đổi một luật (vd cả hai cho "nổ hai lần").
- Dữ liệu: `core_combos.json` giữ nguyên; thêm `keystones.json` tham chiếu `combo.id`. Nếu combo bị `hide_if_rules` thì Lõi chủ coi như không có combo đó (test).
- Độ khó chia chung một ngân sách: tổng mức tăng của đột biến combo + thức tỉnh phải nằm trong mục 3.4.

## 1. Sáu Lõi chủ

(Các số dưới là số **chưa thức tỉnh**. Thức tỉnh nằm ở mục 0.2.)

Id đề nghị: `ks_volley`, `ks_gambler`, `ks_mana_mine`, `ks_kin`, `ks_embers`, `ks_big_hand`. Số trong bảng là mặc định, knob ở cột phải.

### 1.1 Tam Tấu (Triple Burst, `ks_volley`)

- EN: "Each Set of 3+ bursts once per turn: every enemy takes 30% of the Set's total base value (55% for 4, 80% for 5, max 16 each). Your Set bonus is -0.15."
- VI: "Mỗi lượt, BỘ ba trở lên nổ một lần: mọi quái nhận 30% tổng giá trị gốc của BỘ (bốn viên 55%, năm viên 80%, tối đa 16 mỗi quái). Đổi lại thưởng BỘ của bạn -0.15."
- Hiệu ứng: nổ ở lần dùng viên đầu tiên của BỘ, một vụ nổ mỗi LƯỢT (chọn BỘ lớn nhất nếu có hai). Tổng = cộng `value` gốc (trước hệ số) các viên thật trong BỘ
  (mọi mặt có số; viên ảo không tính). Làm tròn lên. Đi qua `DamagePipeline` với `src` = viên kích nổ, `attack=false`, `from_burst=true` (không Plating, không crit,
  thorn quái không phản, N9). Ví dụ: Ba Sừng 5+3+4 = 12 -> `ceil(0.30x12)` = 4 cho mỗi quái; bốn viên 4+4+5+3 = 16 -> 9 mỗi quái.
- Knob: `tt.pct_3/4/5` 30/55/80 (khoảng 20-45 / 40-70 / 60-100), `tt.cap` 16 (10-24), `tt.bo_sub` 0.15 (0.05-0.30).
- Cái giá: (a) BỘ yếu hơn trên một mục tiêu: ba ×1.15, bốn ×2.05, năm ×2.45; (b) một quái thì nổ gần như vô dụng (lãi 4-9 mà mất 0.15 x tổng gốc ~ 2-3).
  Nên đây là Lõi chủ của người chọn đội/Lõi nhắm trận nhiều quái; boss một mình là lỗ nhẹ.
- Hợp: Lõi thường cho nhiều quái/lan: `c_thorn_shield`, `c_thorn_pact` (combo Bramble Hide), `c_plague_spread`, `c_finisher`. Hợp với đội dồn khiên/hồi vì tổng tính cả mặt khiên.
- Vì sao đổi cách chơi cả run: người chơi bắt đầu **săn BỘ để nổ**, không săn để nhân đòn đơn; chọn viên để dùng đầu tiên (kích nổ) thành quyết định mới;
  nhìn đường đi (nhiều quái hay boss) để quyết định tiêu mana săn BỘ hay không.

### 1.2 Con Bạc (Gambler, `ks_gambler`)

- EN: "Every Gamble that cracks no die gives your Sets +0.30 this turn (max +0.60). Gamble cracks 40%, and you must re-roll 2+ dice for it to count."
- VI: "Mỗi lần Liều mà không viên nào Nứt, mọi BỘ lượt này +0.30 (tối đa +0.60). Đổi lại Liều Nứt 40%, và phải tung lại từ 2 viên trở lên mới tính là Liều sạch."
- Hiệu ứng: `core_add = min(0.30 x số Liều sạch trong lượt, 0.60)`, cho viên đang nằm trong BỘ, tính lại ở mỗi `recompute_bo()`. Một Liều bị Nứt không xoá các Liều sạch trước,
  chỉ không cộng thêm. Reset ở `roll_all()`. Chỉ tính lần tung lại bằng chế độ Liều (rmode 0) vào `reroll_paid_k`; reroll của relic/Aid/Lõi (chỉ vào `hard_cap`, N1) không tính.
  Nứt 40% thay 30% chỉ áp cho Liều (An toàn không Nứt).
- Số: Liều 2 viên sạch = 0.6^2 = 36% (Liều thường 49%); Liều 3 viên sạch = 21.6%. Kỳ vọng thưởng mỗi Liều 2 viên = 0.36 x 0.30 = +0.11 hệ số trên BỘ; hai Liều tối đa +0.60.
- Knob: `cb.crack_pct` 40 (35-45), `cb.step` 0.30 (0.20-0.40), `cb.max` 0.60 (0.40-0.80), `cb.min_dice` 2 (2-3).
- Cái giá: Nứt cao hơn (cắt một nửa giá trị viên, kể cả viên đang nằm trong BỘ) và Liều ít viên không đủ để tính. Hết trần tung lại thì không gỡ được.
- Hợp: khiên/hồi bù lúc Nứt (`c_field_medic`, `c_gatekeeper`), `c_sixth_die` (nhiều viên để tung đủ 2), Lõi hưởng Nứt/Liều nếu có. Không hợp đội giòn cần đòn chắc.
- Vì sao đổi cách chơi: Liều từ "rẻ, dùng khi tiện" thành "cược đều mỗi lượt"; người chơi chủ động bỏ An toàn rẻ (1 mana) để lấy 2 lần cược; run nào cũng có khoảnh khắc
  "sạch cả hai" (gacha vui) và "Nứt hết" (đau nhưng tự chọn).

### 1.3 Mỏ Mana (Mana Mine, `ks_mana_mine`)

- EN: "First turn each Set forms naturally, gain +1 mana. Overcast costs 1 mana. Wild Face costs 3 mana."
- VI: "Lần đầu mỗi lượt BỘ hình thành tự nhiên, nhận +1 mana. Overcast chỉ tốn 1 mana. Đổi lại Mặt Tạm tốn 3 mana."
- Hiệu ứng: +1 mana khi `recompute_bo()` lần đầu trong lượt thấy một BỘ KHÔNG chứa viên Mặt Tạm (cờ `mana_bo_paid`; BỘ mất rồi hiện lại không trả lần hai).
  Overcast 2 -> 1 mana, `oc_add` giữ 0.5, vẫn cả BỘ và 1 lần/lượt. Mặt Tạm 2 -> 3 mana (còn 1 lần/trận, vẫn chỉ 3→4).
  Mana nhận tối đa +1/lượt từ Lõi này; Overcast 1 lần/lượt, nên lượt có BỘ tự nhiên: +1 mana rồi trả 1 mana cho Overcast = **hoà vốn, không có vòng tăng mana**.
- Knob: `mm.mana` 1 (0-1), `mm.oc_cost` 1 (1-2), `mm.wild_cost` 3 (3-4), `mm.wild_lock` 0 (đặt 1 = khoá Mặt Tạm hẳn, phương án giá nặng hơn).
- Cái giá: mất Mặt Tạm giá rẻ. Mặt Tạm đang đóng góp lớn (+2.84 dmg/lượt, sim OC2), Overcast mới +1.19. Nên giá thật. Nếu sim cho Mỏ Mana trội thì bật `mm.wild_lock`.
  (Bản cũ trừ 1 mặt mana, bỏ vì bước 0 đo mặt mana chỉ sinh 0.00-0.02 mana/lượt: giá rỗng.)
- Hợp: `c_mana_pool`, `c_deep_current`, `c_loop` (combo Endless Mana Loop), Lõi chi mana (Conduit `conduit_step` 3 chạy nhanh hơn khi Overcast 1 mana). Không hợp đội sống nhờ Mặt Tạm.
- Vì sao đổi cách chơi: mana từ khan thành dư vào lượt có BỘ; người chơi bỏ "chờ Mặt Tạm" và chuyển sang săn BỘ tự nhiên rồi Overcast đều; tiêu mana thừa vào An toàn lần 2.

### 1.4 Đồng Tộc (Kin, `ks_kin`)

- EN: "A Set with 3+ Axies of the same class gets +0.40. Any other Set gets -0.25."
- VI: "BỘ có ít nhất 3 viên cùng class thì +0.40 hệ số; BỘ không đạt thì -0.25."
- Hiệu ứng: mỗi BỘ đếm class của Axie chủ các viên trong BỘ (Mặt Tạm đếm class của viên thật; viên ảo/`is_token` không đếm). Lớn nhất >= `dt.need` thì `core_add` +0.40 cho mọi viên
  của BỘ đó; ngược lại -0.25. M không xuống dưới 1.00. Đã có `c_concord` thì không rút Đồng Tộc; đã có Đồng Tộc thì `core_offer` không đưa `c_concord` (lọc hai chiều, giữ như 3.10.8).
- Số: BỘ ba thuần = 1 + 0.3 + 0.4 = 1.70 (thay 1.30); BỘ ba tạp = 1.05.
- Knob: `dt.need` 3 (2-3), `dt.plus` 0.40 (0.25-0.60), `dt.minus` -0.25 (0 đến -0.5).
- Cái giá: đội đa dạng bị phạt trực tiếp, và Lõi này được offer sau khi đã chọn đội (người chơi thấy đội mình rồi mới chọn): chọn bừa khi đội tạp là lỗ.
- Hợp: đội 3+ cùng class, Lõi huyết thống/class, `c_elder_trunk`-kiểu Lõi theo class. Dễ thành Lõi trội nhất vì đội thuần (xem mục 3).
- Vì sao đổi cách chơi: kéo người chơi dựng đội thuần class cho run kế (draft có chủ đích), đổi lại mất tính "đủ passive khác nhau". UI phải hiện "đội bạn: 3 Beast, 2 Plant: Đồng Tộc đạt/không đạt".

### 1.5 Giữ Lửa (Embers, `ks_embers`)

- EN: "You can Hold 2 dice. A Held die you use next turn gets +0.50."
- VI: "Bạn Hold được 2 viên. Viên Hold dùng ở lượt sau mạnh thêm +0.50 hệ số."
- Hiệu ứng: `stash_cap` 2 qua hook sẵn có. Viên mang sang (`stash_carry`) có `core_add` +0.50 khi dùng (mặt dmg/khiên/hồi/độc), không cần nằm trong BỘ. Luật cũ giữ: không Hold lại viên vừa mang sang;
  hai viên Hold đều đếm BỘ ở lượt hiện tại và lượt sau.
- Tính cái giá (tại sao không trội): Hold 2 viên lượt n = lượt n chỉ dùng 3/5 viên. Lượt n+1: 2 viên mang sang x1.5 + 3 viên mới = 6 so với 5 (hai lượt: 3 + 6 = 9 so với 10 viên-tương-đương).
  Tức bonus +0.50 chỉ vừa bù nhịp mất; Hold liên tục mỗi lượt còn lỗ (mỗi lượt chỉ dùng 3 viên: 1 mới + 2 mang sang x1.5 = 4 so với 5). Lãi thật chỉ có khi **canh đúng lượt**:
  lượt Hở của boss (`boss_rhythm`: boss nhận +50%, gây -30%), lượt có `c_finisher`/Đòn Nạp, hoặc giữ viên lớn qua lượt không cần.
- Knob: `gl.cap` 2 (cố định 2), `gl.carry_add` 0.50 (0.30-0.70).
- Hợp: `c_kindle` (on_stash), lượt Hở boss, Lõi `charge` của quái cần canh nhịp. Yếu act 1 (bỏ nhịp), mạnh boss.
- Trùng cần xử: `c_steady_hold` đã cho `stash_cap` + `stash_repeat` (Hold lại viên mang sang). Chồng hai cái này = Hold hai viên mãi mãi. Lọc `c_steady_hold` khỏi offer khi có Giữ Lửa,
  và nếu đã có thì Giữ Lửa không ra trong 3 lựa chọn (như Concord/Đồng Tộc). `carry_add` không cộng dồn qua nhiều lượt.
- Vì sao đổi cách chơi: lượt thành bài toán nhịp (giữ cho lượt Hở, đừng xả) thay vì "dùng hết"; bổ sung đúng cho lối chơi Hold hiện có nhưng bắt người chơi nhìn trước boss.

### 1.6 Bàn Tay Lớn (Big Hand, `ks_big_hand`) — mới, thêm cho đủ đa dạng

- EN: "Sets of 3 give no bonus. Sets of 4 get +0.40 more, Sets of 5 get +0.40 more."
- VI: "BỘ ba không còn thưởng. BỘ bốn thêm +0.40, BỘ năm thêm +0.40."
- Hiệu ứng: `bo_add_3` thành 0 (BỘ ba ×1.0, vẫn là BỘ: tính Concord/BỘ cho Lõi khác, chỉ không thưởng hệ số); `bo_add_4` 1.2 -> 1.6 (×2.6); `bo_add_5` 1.6 -> 2.0 (×3.0, đúng `m_cap`).
  Hệ quả: BỘ năm + Overcast vượt trần 3.0, phần dư mất (UI hiện "đã chạm trần").
- Số hợp lý theo 4.2: 5 part, 1 lần tung lại an toàn: bốn+ 19.7%, ba+ 65%. Mất ~0.9 VTĐ trên ~40% lượt (BỘ ba), lãi 1.6-2 VTĐ trên 20-30% lượt (bốn+): ước hoà vốn, phương sai cao.
- Knob: `bh.add_3` 0 (0-0.15), `bh.add_4_plus` 0.40 (0.25-0.60), `bh.add_5_plus` 0.40 (cố định để năm vừa chạm trần).
- Cái giá: lượt ra BỘ ba không còn thưởng; bắt buộc đi săn bốn (mất mana An toàn lần 2, hoặc Mặt Tạm). Mặt Tạm 3→4 thành rất lời (+1.6 hệ số x 4 viên).
- Hợp: `c_sixth_die` (nhiều viên hơn, dễ bốn), `c_three_dice` (đổi nhịp), Lõi thưởng Mặt Tạm/reroll, Overcast khi BỘ bốn (2.6 + 0.5 = 3.1 chạm trần, vẫn lãi 0.4).
- Vì sao đổi cách chơi: mọi lượt thành "đi săn bốn hay chấp nhận trắng tay"; run không còn là chuỗi BỘ ba nhẹ nhàng, mà ngắt giữa lượt lười và lượt bùng nổ. Gacha vui nhất ở bộ bốn/năm.

### 1.7 Bảng so sánh nhanh

| Lõi chủ | Đổi cái gì | Cái giá | Mạnh khi | Dễ thành trội nếu sai số |
|---|---|---|---|---|
| Tam Tấu | AoE từ BỘ | -0.15 hệ số BỘ, một quái thì nhỏ | nhiều quái, đội dồn khiên | pct quá cao + mặt khiên tính vào tổng |
| Con Bạc | cược Liều | Nứt 40%, phải 2 viên | tung nhiều, có hồi bù | cb.step cao |
| Mỏ Mana | Overcast rẻ + mana | Mặt Tạm 3 mana | ra BỘ đều | Mặt Tạm giá rẻ không còn là giá thật |
| Đồng Tộc | thưởng theo class | BỘ tạp -0.25 | đội thuần | **cao nhất** (dt.plus) |
| Giữ Lửa | Hold 2 | nhịp mất (3/5 viên) | boss Hở | không (tự giới hạn nhịp) |
| Bàn Tay Lớn | chỉ BỘ ≥4 | BỘ ba mất thưởng | săn bốn, Mặt Tạm | add_4 cao |

## 2. Cách chọn

- **Mở từ đâu**: stage 3 (`runs_completed >= 3`, server đo bằng `run_finish`; tài khoản `runs_with_battle >= 5` vào thẳng stage 3), đúng bảng 3.8 của GDD. Stage 1-2 không có Lõi chủ.
  Lần đầu mở, màn kết run kế phải báo "Mới mở: Lõi chủ" (đúng luật "Mới mở" đang có ở 3.8). Khuyến nghị giữ sáu Lõi chủ mở cùng lúc; nếu thấy quá ngợp thì chia
  hai đợt (Tam Tấu/Giữ Lửa/Con Bạc trước, ba cái còn lại từ run 6), nhưng chỉ làm khi playtest cho thấy ngợp.
- **Rút**: 3 trong 6 (không lặp, mỗi Lõi chủ ra ở ~50% run). Pool trừ: `ks_kin` nếu đã có `c_concord` khởi đầu (kho/Vault); `ks_embers` nếu đã có `c_steady_hold`. Nếu pool còn < 3 thì bù lại bằng cái bị loại ngẫu nhiên.
  Ba lựa chọn xếp theo thứ tự cố định theo seed (không để client xáo).
- **Seed `keystone`** (N10): `seed = H(account_id, runs_with_battle, "keystone")`, epoch kind `keystone` (từ vựng `epoch_args.json`, `k = 0`), Worker tự tính lại bộ ba; client không rút.
  `runs_with_battle` ở đây chỉ tăng khi trận đầu của run **kết thúc** (thắng hoặc thua), không phải khi mở run. Bỏ run trước trận đầu rồi mở lại thì ra cùng bộ ba (N10). Chi phí tối thiểu để câu lại
  một bộ ba = đánh xong một trận đầu (~2-3 phút) và bỏ run: chấp nhận được vì mỗi lần cũng chỉ đổi 1/20 tổ hợp. Hành động `pick_keystone(index)` (0..2) vào ActionLog và `ALLOWED_FNS` ở cả ba chỗ;
  index ngoài 0..2, chọn lần hai, hoặc stage < 3 thì `false`. Worker từ chối khi `pick` không khớp bộ ba (mã `pin_mismatch`/`stage_mismatch`, N4).
- **Ranked**: có dùng, cùng luật. Lý do: run ranked đã được replay-verify (ActionLog), bộ ba do server seed nên không câu được; 3 lựa chọn giảm may rủi của bộ ba;
  nếu bỏ Lõi chủ ở ranked thì đúng chế độ người chơi giỏi nhất lại chơi ít khác biệt nhất. Rủi ro: hai người có bộ ba khác sức mạnh trên bảng xếp hạng. Giảm bằng chỉ tiêu "chênh winrate <= 5 điểm" (mục 3)
  và ghi Lõi chủ lên thẻ run (`RunCard`). Nếu sau playtest thấy bảng bị lệch, phương án dự phòng: ranked cố định bộ ba theo mùa. Chưa làm vì bỏ mất "khác nhau mỗi run".
- **Không gacha hoá**: không reroll Lõi chủ (không dùng `core_rerolls`), để bộ ba có trọng lượng. Combo của Lõi thường không bao gồm Lõi chủ.

## 3. Cân bằng

### 3.1 Vấn đề chọn-trong-3

Chọn 1 trong 3 làm tăng sức mạnh kể cả khi mỗi Lõi chủ trung bình = 0: chọn tốt nhất trong 3 mẫu có độ lệch chuẩn s cho +0.85s. Nên mục tiêu cho từng Lõi chủ khi bị **ép chọn** là win-rate expert
15.5-20.5 (trung bình ~18, thấp hơn mốc 18.8 không-Lõi-chủ khoảng 0.5-1), để khi chọn tự do expert ra ~19.5-21. Cần đo lại mốc "không Lõi chủ" ở stage 3 (không nhất thiết bằng 18.8: mốc đó có thể chưa tách theo stage).

### 3.2 Ước tính tay (không phải bằng chứng)

Giả định mốc: expert 18.8, random 11.0, spam 10.5. Δ là điểm win so với không Lõi chủ, khi bot bị ép chọn Lõi đó.

| Lõi chủ | Δ expert ước | Δ random ước | Δ spam ước | Ghi chú |
|---|---|---|---|---|
| Tam Tấu | +1.5 | +0.5 | +1.0 | spam dồn dmg, ít BỘ, nhưng trận nhiều quái ăn nổ; theo dõi spam (ngưỡng 12) |
| Con Bạc | +1.0 | -1.0 | 0 | random Liều bừa nên Nứt nặng, giữ random <= 12 |
| Mỏ Mana | +0.5 | 0 | 0 | giá Mặt Tạm có thể quá nhẹ, nếu +2 thì bật `mm.wild_lock` |
| Đồng Tộc | +2.0 đội thuần / -2.0 tạp | ±1 | ±1 | trung bình ~0 nhưng phương sai lớn, chọn đúng thì lên cao |
| Giữ Lửa | 0 | -1.0 | -0.5 | random không biết canh nhịp |
| Bàn Tay Lớn | +0.5 | -1.0 | -0.5 | random ít ra bốn |

Trung bình expert ~+0.9 (ép chọn), expert chọn tự do ước ~+2.2 (=> ~21, trong 20±3 nhưng sát trên). Random/spam <= 12 giữ được, spam là chỗ phải canh (Tam Tấu).
**Nếu expert-chọn-tự-do vượt 23**: không hạ `enemy_dmg_mult` toàn cục (stage 1-2 ăn theo). Thêm `difficulty.stage3_dmg_mult` (mặc định 1.00, thử 1.03-1.06), chỉ áp từ stage 3. Đây là gate knob mới, cần Liam duyệt trước khi thêm.

### 3.3 Kế hoạch sim

Cùng bộ sim `sim-v4-metric-*`, 4 bot (random, spam, free_hold, expert), stage 3 A0 offline.

0. **Mốc**: bot x 2000 run "không Lõi chủ" ở stage 3, cặp seed (dùng lại seed bộ đo cũ để so được 18.8).
1. **Ép chọn** (`forced_ks`): mỗi Lõi chủ x 4 bot x 2000 run (expert 3000 để CI ±1.4), cùng cặp seed với mốc. Ghi win, dmg/lượt, và theo từng Lõi: số lần nổ (Tam Tấu), Liều sạch/Nứt (Con Bạc),
   mana nhận/tiêu (Mỏ Mana), tỉ lệ BỘ thuần class (Đồng Tộc), số lần Hold 2 viên và dùng đúng lượt Hở (Giữ Lửa), phân bố BỘ ba/bốn/năm (Bàn Tay Lớn). Đồng Tộc tách theo "đội thuần / tạp".
2. **Chọn tự do** (`expert_pick`): đo tỉ lệ chọn bằng bot chọn theo bảng win-rate từ bước 1 chia theo nhóm đội (thuần/tạp, số quái đầu) = cận trên "chọn tốt nhất". Với mỗi bộ ba tự do.
   Bot expert vẫn cần một bản "mù" (chọn theo heuristic cố định) để so; nếu hai bản lệch xa thì tỉ lệ chọn là do heuristic, đừng kết luận.
3. **Điều kiện qua**:
   - Mỗi Lõi chủ expert chọn 10-25% (tính trên tất cả run, mỗi cái xuất hiện ~50% run: tức chọn 20-50% khi có mặt).
   - Win-rate expert giữa các Lõi chủ, tính trên **run đã chọn** (dân số thực sự chơi nó): max - min <= 5 điểm. Chỉ số phụ: ép chọn <= 7 điểm (vì Đồng Tộc có đội tạp).
   - Expert (chọn tự do) 20 ±3; random <= 12, spam <= 12 cho mỗi Lõi chủ ép chọn; expert - free_hold không hẹp đi so với mốc (+7.7 dmg/lượt).
   - Không Lõi chủ nào đóng góp < +1.0 dmg/lượt hoặc < ... (quy tắc cắt lỗ cũ: nếu sau 2 vòng một Lõi chủ vẫn thua mốc >2 điểm và không ai chọn thì bỏ, đừng chỉnh mãi).
4. **Vòng chỉnh**: mỗi vòng chỉ đổi một knob chính của một Lõi chủ. Thứ tự nghi ngờ: Đồng Tộc `dt.plus` (0.40 -> 0.35 trước), Tam Tấu `tt.pct`, Mỏ Mana `mm.wild_lock`, rồi mới tới `stage3_dmg_mult`.
5. **Cỡ mẫu**: 18% win với 2000 run có CI ±1.7; chênh giữa hai Lõi chủ cặp seed ±2. Nếu max-min rơi 4-6 thì tăng lên 4000 trước khi kết luận.

### 3.4 Thức tỉnh và độ khó (expert 20 ±3)

Thức tỉnh là thêm sức mạnh có điều kiện, nên phải bù ở chỗ khác:
- Ước tay: trong run đã thức tỉnh, expert +4 đến +6 điểm win so với cùng Lõi chủ chưa thức tỉnh; tỉ lệ run expert chase combo thức tỉnh được ~30-45% (có `core.ks_bias` 1.5) => cộng trung bình ~+1.5-2.5 điểm.
  Cộng với ~+1 từ chọn-trong-3 (3.2) => expert ~22-23, sát trần 23. Vì vậy **hạ số mục 1 trước** (ví dụ `tt.pct` -5, `dt.plus` 0.35, `cb.step` 0.25) khi bật thức tỉnh, không nâng độ khó quái.
- Chỉ tiêu thêm: (a) % run expert thức tỉnh 25-45% (dưới 25%: nhóm Lõi quá khó gom, tăng `core.ks_bias`; trên 45%: nới quá, hạ); (b) win thức tỉnh - win chưa thức tỉnh <= +6 trong cùng Lõi chủ;
  (c) max-min win giữa các Lõi chủ <= 5 áp dụng cho **cả** run thức tỉnh và chưa; (d) random/spam không thức tỉnh được nhiều (họ chọn Lõi bừa), kiểm <= 12 khi bật.
- Sim bật hai cờ: `awaken_off` (mục 1 thuần) trước, rồi `awaken_on`. Bot expert thêm chính sách "chase" (chọn Lõi trong `anchor_cores` khi offer), bản "mù" so sánh.
  Mỗi vòng chỉ đổi một knob. Dùng lại `godot/tools/sim_combo_draw.tscn` để lấy tần suất ráp Cặp.
- Nếu thức tỉnh một Lõi chủ nào làm win vượt +6: hạ nấc "Đủ" trước, không bỏ luật mới (luật mới là thứ Liam đòi).

## 4. Rủi ro lỗ hổng luật và test cần có

| Rủi ro | Cách bịt | Test |
|---|---|---|
| Câu bộ ba bằng bỏ run (N10) | seed `(account, runs_with_battle)`, đếm khi trận đầu kết thúc | `t_keystone_pin`: bỏ run trước trận => cùng bộ ba; sau một trận xong => khác; hai tài khoản khác nhau => khác |
| Client tự đổi lựa chọn / chọn ngoài bộ ba | `pick_keystone` trong ActionLog, Worker tính lại bộ ba, `pin_mismatch` | `t_keystone_pick_action` (index 0..2, lần hai false, stage < 3 false, ngoài bộ ba false), Worker test `pin_mismatch`/`stage_mismatch`, replay + 7 tamper (như `t_replay`) |
| Tam Tấu + thorn quái phản | `from_burst`, thorn không phản lên viên kích (N9) | `t_keystone_volley_thorn`: nổ không làm viên kích mất máu |
| Tam Tấu + Overcast/Con Bạc/Mặt Tạm tăng vụ nổ | tổng tính từ `value` GỐC, không dùng M | `t_keystone_volley_base`: bật Overcast/Con Bạc, nổ không đổi; Mặt Tạm: viên ảo không vào tổng |
| Tam Tấu + nhiều quái (boss gọi quái) | `tt.cap` 16 mỗi quái, một vụ mỗi lượt | `t_keystone_volley_cap`: 5 quái, tổng sát thương nổ tối đa 5x16, không có vụ nổ thứ hai |
| Tam Tấu + mặt khiên/hồi: khiên vừa chặn vừa nổ | giữ `tt.cap` và pct thấp, sim đo; nếu trội thì chỉ tính mặt dmg | `t_keystone_volley_defensive` ghi giá trị, sim quyết |
| Con Bạc fish bằng Liều 1 viên | `cb.min_dice` 2 | `t_keystone_gambler_min_dice` |
| Con Bạc + undo/replay: Hoàn tác rồi Liều lại để tránh Nứt | khoá `(rmode, uids)` + `k` của 3.10.2 giữ kết quả; tally Liều sạch phải hoàn theo undo | `t_keystone_gambler_undo`: undo + Liều lại cho cùng kết quả, tally khớp |
| Con Bạc + Overcast + BỘ năm vượt trần | `m_cap` 3.0 chặn | `t_keystone_mcap`: tổng core_add + oc_add + bo_add không vượt 3.0 ở mọi Lõi chủ |
| Mỏ Mana: vòng mana (BỘ mất/hiện, undo/redo) | `mana_bo_paid` 1 lần/lượt, chỉ BỘ tự nhiên; undo hoàn cờ cùng mana | `t_keystone_mana_loop`: mana mỗi lượt từ Lõi <= +1; lặp hình thành/phá BỘ không trả hai; undo/redo không lãi mana |
| Mỏ Mana + `combo_endless_mana` (`c_mana_pool`, `c_deep_current`, `c_loop`) + `mana.max` | Overcast 1 mana + Conduit nhanh có thể thành vòng | sim đo `mana_in`/`mana_spent` cho ba Lõi này + Mỏ Mana; `t_keystone_mana_combo` kiểm mana không vượt `mana.max` và không có chuỗi vô hạn |
| Đồng Tộc + Concord / Vault khởi đầu / Lõi thêm giữa run | lọc hai chiều pool đầu và `core_offer` | `t_keystone_filters`: có `c_concord` thì không ra Đồng Tộc; có Đồng Tộc thì `core_offer` không đưa `c_concord` |
| Đồng Tộc: viên token/Egg/viên ảo đếm class | không đếm `is_token`/ảo | `t_keystone_kin_token` |
| Giữ Lửa + `c_steady_hold` (Hold lặp) | lọc `c_steady_hold`, `carry_add` không cộng dồn | `t_keystone_filters` (cùng test), `t_keystone_embers_nostack`: viên Hold lặp nhiều lượt vẫn +0.50 |
| Giữ Lửa + `c_kindle`/`c_three_dice` auto-hold: vượt cap 2 | cap cứng 2 từ Lõi chủ, hook khác không cộng thêm | `t_keystone_embers_cap` |
| Bàn Tay Lớn: BỘ ba "vẫn là BỘ" nên Lõi khác vẫn kích? | `bo_add_3 = 0` chỉ đổi hệ số, không đổi định nghĩa BỘ | `t_keystone_bighand_def`: BỘ ba vẫn trigger Concord/Lõi BỘ, hệ số = 1.0 |
| Cạnh tranh nhau với relic `r_keystone` (trùng tên) | đổi tên một trong hai | test không có gì; kiểm UI thủ công |
| Thức tỉnh sai lúc (Cặp mất/hiện, undo, nhận Lõi giữa run) | thức tỉnh là cờ `awakened` trong RunState, set ở `combo_formed` (Cặp), lưu save + replay, không tắt khi Lõi bị mất | `t_keystone_awaken_flag`: một lần mỗi run; save/load/replay giữ; undo trong trận không đụng |
| Bão Gai nổ hai lần + thorn/xuyên khiên quá mạnh với boss | `tt.cap` mỗi vụ, `from_burst` không crit/Plating, xuyên khiên chỉ khiên quái (không Plating boss) | `t_keystone_awaken_volley`: hai vụ, trần mỗi quái mỗi vụ, Plating boss vẫn chặn |
| Ván Gỡ tạo vòng tung vô hạn / né Nứt | gỡ một lần mỗi Liều, không trừ `max_total`, khoá `(rmode, uids, k)` giữ kết quả | `t_keystone_awaken_gambler`: không vượt `hard_cap`, undo cho kết quả cũ |
| Nhịp Đôi: Overcast hai lần + `c_mana_pool`/`c_loop` thành vòng mana | lần hai tốn 2 mana, nhận mana từ Lõi chủ <= +1/lượt | `t_keystone_awaken_mana`: mana ròng mỗi lượt không dương khi chỉ Overcast; chạy cả `combo_endless_mana` |
| Huyết Mạch: Mặt Tạm miễn phí + `Mặt Tạm 1 lần/trận` | vẫn per_battle, vẫn cấm bốn -> năm, BỘ Mặt Tạm không trả +1 mana (Mỏ Mana không trùng nhóm này) | `t_keystone_awaken_kin` |
| Lửa Truyền: cầu nối Hold tạo BỘ năm | bridge chỉ tạo tối đa BỘ bốn | `t_keystone_awaken_embers`: hai Hold + ba viên cùng part vẫn không thành năm |
| Bàn Tay Thứ Sáu: viên thưởng tạo vòng (BỘ bốn -> thưởng -> BỘ năm -> thưởng) | lần đầu mỗi lượt, viên thưởng không phát thưởng lần nữa | `t_keystone_awaken_sixth`: không dây chuyền |
| `core.ks_bias` làm lệch gacha Tinh Thể hoặc bậc | chỉ nhân trọng số trong cùng bậc, không đổi xác suất bậc, `core_skipped_t` giữ | `t_keystone_bias` + `t_gacha_guards` xanh |
| Combo thức tỉnh bị ẩn bởi luật run (`hide_if_rules`) | loại khỏi `awaken_combos` lúc run | `t_keystone_awaken_hidden` |
| Replay cũ không hợp | bump `RULES_VERSION`, `SUPPORTED_RULE_VERSIONS`, fingerprint `t_rules_version` | `t_rules_version` |
| Stage 3 và `core_offer` nhìn thấy Lõi chủ | Lõi chủ không nằm trong `core_offer`/gacha | `t_keystone_not_in_core_offer`, `t_gacha_guards` giữ xanh |

Sàn suite phải tăng bằng số file test mới, đổi `technical-preferences.md` cùng commit.

## 5. Câu hỏi cho Liam (tối đa 3)

1. **Ranked có dùng Lõi chủ không?** Khuyến nghị: có, cùng luật, bộ ba do server seed, thẻ run hiện Lõi chủ. Đổi lại bảng xếp hạng có thêm may rủi của bộ ba (giữ <= 5 điểm bằng sim).
   Phương án khác: ranked cố định bộ ba theo mùa.
2. **Thức tỉnh bật khi ráp Cặp (2 Lõi) hay phải ráp Đủ (3 Lõi)?** Khuyến nghị: Cặp thức tỉnh (luật mới), Đủ lên nấc cao. Lý do: Liam đòi đột biến xảy ra trong run; Đủ hiếm, nếu chờ Đủ thì phần lớn run
   không bao giờ thấy. Tôi cũng đề nghị giữ sáu Lõi chủ mở cùng lúc ở stage 3 (20 bộ ba), và nối với brainstorm "đột biến combo" theo mục 0.3 (hai tầng, không cùng đổi một luật).
3. **Thêm knob `difficulty.stage3_dmg_mult` (chỉ khi sim cần) và đổi tên "Keystone" vì trùng relic `r_keystone`** chấp nhận không? Khuyến nghị: chấp nhận, đổi tên nhóm trong game
   (relic giữ nguyên vì đã có save), và chỉ thêm knob nếu expert chọn-tự-do vượt 23.

## Ý thêm (không làm)

- Lõi chủ phòng thủ/chống spam-attack (kiểu "khiên nở thành thưởng") để lại cho vòng sau, vì Tam Tấu đã tính cả mặt khiên; nên đo xong v1 mới thêm.
- Quá nhiều chữ trong thẻ Lõi chủ: mỗi cái giữ 1 câu EN + 1 câu VI như trên, chi tiết (số/ví dụ) nằm trong Codex.
