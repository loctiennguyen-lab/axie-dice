# Giao diện giữa các làn — L1 (chốt trước khi code)

Trạng thái: ĐỀ XUẤT (12/10) — chờ review agent khác + Liam duyệt. Chưa sửa dòng code nào.

Người viết: technical-director · 12/10/2026. Đầu vào: `production/l1-sprint-plan.md` (làn, file sở hữu),
`docs/architecture/server-authoritative-rng.md` (gọi tắt **ADR-RNG**), `design/proposals/relic-set-v2.md`, `ascension-v2.md`,
`monetization-v1.md`, `nhiem-vu-risk-to-earn.md`, và code hiện tại trên `godot-port` (số dòng ghi ở dưới là đọc ngày 12/10).

**Cách đọc:** mỗi mục là hợp đồng giữa hai hay nhiều làn: tên hàm, kiểu dữ liệu, file, ai sở hữu. Chỗ ghi
**"xác nhận khi code"** là chi tiết người làm được tự chốt miễn không đổi chữ ký. Chỗ ghi **[LIAM-n]** là việc Liam phải quyết
(gom ở mục 9). Đổi một chữ ký trong file này sau 13/10 = gửi yêu cầu cho làn sở hữu + báo làn I, không tự sửa.

Ba luật chung cho mọi làn:
1. **Không ai gọi `Rng.new`, `randi`, `randf` trong luật** (`scripts/core/`, `autoload/RunState.gd`, `reward_generator.gd`,
   `relic_hooks.gd`). Mọi lần rút luật đi từ một seed epoch (mục 1). RNG trang trí (VFX, bob, shake) vẫn dùng `randf`, như hôm nay.
   Làn I thêm test tĩnh `t_no_free_rng` (grep) vào suite.
2. **MON-13:** không file luật nào đọc trạng thái Aid/Continue. Test tĩnh `t_mon13` (grep `aid_`, `continue_used`, `boon_source`
   trong `scripts/core/` và các hàm luật của `RunState`). Hiệu ứng Aid đi qua API thuần nhận tham số (mục 3).
3. **Mọi ghi save qua `SaveStore`**, field meta mới phải vào `MetaState.reload_from_store()` (CLAUDE.md). Chỉ làn E sửa hai file đó.

---

## 1. EpochSource (làn A, server-side của làn S) — merge 17/10

### 1.1 File và chủ

| File | Chủ | Ghi chú |
|---|---|---|
| `godot/scripts/core/epoch_source.gd` | A | `class_name EpochSource`, lớp gốc. Trong `scripts/core` nên bị fingerprint (đúng: nó là luật) |
| `godot/scripts/core/epoch_reply.gd` | A | `class_name EpochReply`. **Tách file riêng:** GDScript chỉ cho một `class_name` mỗi file (bản đầu để cả hai trong `epoch_source.gd`, sẽ không parse) |
| `godot/scripts/core/epoch_canon.gd` | A | `class_name EpochCanon`: canon byte, hash chain, công thức seed HMAC (ADR-RNG §4.1). Hàm thuần, static |
| `godot/scripts/core/local_epoch_source.gd` | A | HMAC bằng khoá test, dùng cho test, dev, bot, sim |
| `godot/scripts/core/tape_epoch_source.gd` | A | Phát lại băng `[{seq, kind, args, seed, extra}]`: tutorial, `RunVerifier`, resume |
| `godot/scripts/net/remote_epoch_source.gd` | S | Bọc `RunSession` |
| `godot/scripts/net/run_session.gd` | S | WebSocket, hàng đợi `seq`, nối lại. Autoload `RunSession` trỏ tới đây (làn I đăng ký) để không làm đổi fingerprint `autoload/` mỗi lần sửa code mạng (ADR-RNG §4.5) |
| `godot/tests/data/epoch_golden.json` | A | Vector vàng canon + chain + seed. S chép nguyên file sang `worker/test/epoch_golden.json`; hai bên test cùng một file |

### 1.2 Giao diện (GDScript)

```gdscript
class_name EpochReply extends RefCounted
signal resolved
var done: bool = false
var ok: bool = false
var seed: int = 0              # 32 bit, 4 byte đầu HMAC, big-endian (ADR-RNG §4.1)
var code: String = ""          # "" | bad_request | out_of_order | rejected | expired | version | offline | timeout
var extra: Dictionary = {}     # dữ liệu kèm theo kind (xem bảng 1.3): row_types, run_id, h, log_len...

class_name EpochSource extends RefCounted
## Mở run. Local: tự sinh; Remote: POST /api/run rồi WS hello. extra = {run_id, commit, header:{newcomer, mission?, loadout}}
func start_run(params: Dictionary) -> EpochReply      # params: xem 3.6 RunParams
## Xin seed cho một ranh giới. Gửi kèm log_delta lấy từ action_log (Remote), Local bỏ qua.
func request(kind: String, args: Dictionary) -> EpochReply
## Aid không random (R4, R7). extra = {h, log_len, row_types?}. Local trả ngay ok=true.
func aid(aid_id: String, args: Dictionary) -> EpochReply
## Đóng run (H1 của ADR-RNG). outcome: "won" | "lost". Bỏ run đi đường khác (mục 6, abandon).
func close(outcome: String, summary: Dictionary) -> EpochReply
## Băng đã nhận trong run này, để lưu cùng run save và để resume/verify.
func tape() -> Array
func is_remote() -> bool
```

**Đánh số `seq` (chốt với làn S):** epoch `run_start` là `seq = 0`, các epoch sau tăng dần từ 1. Vector vàng và `LocalEpochSource` dùng đúng cách đánh số này; server theo đó.

Cách gọi chung: `var r := RunState.epoch.request(kind, args); if not r.done: await r.resolved; if not r.ok: <xử lý lỗi>`.
Local/Tape trả `done = true` ngay, nên test headless và `RunVerifier` chạy đồng bộ, không `await` frame nào.

**Quy tắc `await` (sửa 12/10, review):** (1) Engine (`scripts/core/`) không bao giờ `await`; chỉ các hàm bọc `request_*` trong `RunState` và UI gọi chúng mới `await`. Bot, verifier, test gọi bản đồng bộ với seed lấy từ băng. (2) Giữa lúc gửi yêu cầu và lúc có seed, **mọi thao tác khác phải bị chặn** (đổi log là sai `h`): `RunState.epoch_busy: bool`, `request_*` trả `{ok:false, code:"busy"}` nếu đang bận, UI khoá nút Undo/reroll/hết lượt/chọn node (U). Chuột bấm đúp một node là ca thật. (3) Hàm gọi `await` nằm trong autoload `RunState` (sống suốt run), không nằm trong scene; scene gọi `await RunState.request_*` phải kiểm `is_instance_valid(self) and is_inside_tree()` sau `await`, nếu không thì Godot in lỗi "Resumed function after await, but class instance is gone" và `run_tests.sh` tính đó là lỗi. (4) Seed đã nhận mà scene đã bị free: `RunState` giữ `epoch_tape` nên vẫn nhất quán, nhưng engine chưa tiêu thụ seed đó. Resume phải xử ca này: băng có epoch chưa tiêu thụ thì nạp lại và để người chơi làm tiếp từ đó (cùng seed).

`LocalEpochSource.new(local_key: PackedByteArray, local_run_secret: int)` — seed = cùng công thức ADR-RNG §4.1 với
`S_run` thay bằng khoá test. Thay mọi chỗ test đang truyền `run_seed`: test cũ chỉ đổi dòng khởi tạo (ADR-RNG §4.5).
`Crypto.hmac_digest` trên web: S kiểm trong spike 13/10; nếu web không có thì Local dùng SHA256 tự ghép (chỉ test).

### 1.3 Danh sách kind, điểm gọi, hành động tiêu thụ

Đúng bảng ADR-RNG §4.2. Cột "Điểm gọi" là chỗ code hôm nay sẽ đổi (A sửa phần engine/`RunState`; **các scene gọi (CombatView, RunMap, shop/event/reward: U; MainMenu: L; DevReview) không do A sửa**, xem lớp tương thích ở 1.4. Sửa review 12/10: bản đầu cho A sửa luôn cả UI, đụng file U/L đang viết lại).

| kind | Ai xin | Seed dùng ở đâu (code hiện tại → mới) | args | Hành động tiêu thụ |
|---|---|---|---|---|
| `run_start` | `RunState.begin_run()` | `RunState.start_new_run` `_rng = Rng.new(p_seed)` (`:215`): relic khởi đầu, `boss_plan`, **hình dạng** map | mode, ascension | không có |
| `node` | `RunState.request_enter_node()` | combat: `combat_seed` (`:332`, bỏ `derive_combat_seed`) · shop: `_shop_rng` (`:655`) · event: chọn event (`:665-667`) · treasure. `extra.row_types` = loại node của hàng vừa lộ (M7) | node_id | `enter_node` |
| `end_turn` | `CombatView` trước `begin_end_turn` | `CombatEngine.begin_end_turn(seed)`: `_rng = Rng.new(seed)` rồi pha quái + roll lượt sau + ý định | turn | `end_turn` |
| `reroll` | `CombatView` (nút reroll, và khay Aid R2) | `CombatEngine.reroll_dice(uids, seed, from_aid)` | turn, k, source=`base`/`aid`, **uids** (ghi sổ, không vào seed) | `reroll_dice` |
| `reward` | `CombatView` khi `won` (tự động) | `RunState.apply_combat_result(res, reward_seed)` → `_set_pending_rewards` (`:557`) | node_id | không có |
| `reward_reroll` | màn reward (U) | `RunState.reroll_pending_rewards(seed)` (`:571`) | k | `reroll_rewards` |
| `event_choice` | màn event (U) | `RunState.choose_event_option(index, seed)` (`:679-687`) | index | `event_choose` |
| `shop_roll` | màn shop (U), chỉ khi `RunState.shop_item_needs_epoch(i)` | `RunState.try_buy_shop_item(i, seed)` (`:776-790`) | node_id, item | `shop_buy` |
| `shop_refresh` | khay Aid R6 | `RunState.refresh_shop(seed)` | node_id, k | `shop_refresh` (mới) |
| `continue` | màn thua trận (U) | `CombatEngine.continue_after_wipe(seed, heal_pct)` | node_id, attempt | `continue` (mới) |
| `pact_reroll` | màn pact (U), R5 | `RunState.reroll_pact_slot(slot, seed)` | node_id, slot | `pact_reroll` (mới) |

Không epoch: tutorial (băng dựng sẵn `godot/assets/tutorial/tape.json`, TapeEpochSource), DevReview (Local).
Trong một epoch mọi lần rút tiếp theo (mục tiêu ngẫu nhiên lúc thi triển `combat_engine.gd:842/895`, cantrip, relic hook
`bastionplate` rút `combat._rng`) đi tiếp stream đó; undo khôi phục con trỏ như hôm nay.

**Sắp uid trước khi rút** (ADR-RNG H3): A sắp `uids` tăng dần trong `reroll_dice` trước khi roll, nằm trong đợt bump 27/10.
Xác nhận khi code (cần đổi `t_replay`).

**`reward_generator.gd` không cần sửa cho epoch:** mọi hàm rút ở đó đã nhận `rng: Rng` làm tham số (`generate`, `pick_relic`,
`generate_shop_items`, `_make_*`). A chỉ đổi chỗ **tạo** Rng trong `RunState`. Vì vậy A không đụng file của B; điều kiện cứng
"random mới của B chỉ viết sau 17/10" vẫn giữ, nhưng chỉ có nghĩa: hàm mới của B nhận `rng: Rng` từ người gọi, không tự tạo.
`relic-set-v2.md` §4.5 ghi `offer_seed` dùng `derive_combat_seed`: **bỏ**, offer dùng seed của epoch `reward`/`reward_reroll`/`node`
(báo game-designer; hàm vẫn thuần và tất định theo seed).

### 1.4 Chữ ký engine/RunState đổi (A, xong 16/10)

```gdscript
# CombatEngine
func setup_new(combat_setup: Dictionary) -> void        # combat_setup.combat_seed = seed epoch `node`
func reroll_dice(uids: Array, seed: int, from_aid: bool = false) -> bool   # from_aid = true bỏ qua `if rerolls <= 0` ở đầu hàm (`combat_engine.gd:454`) và không trừ `rerolls`
func can_reroll(uids: Array, from_aid: bool = false) -> bool   # mới, hàm thuần, CombatView gọi TRƯỚC khi xin epoch (ADR-RNG §4.3 luật 5)
func begin_end_turn(seed: int) -> bool
func end_turn(seed: int) -> void                         # bản không pacing, cho bot/verifier
func can_end_turn() -> bool                              # đã có
func can_continue() -> bool                              # mới
func continue_after_wipe(seed: int, heal_pct: int) -> bool

# RunState (async wrapper = xin epoch rồi gọi bản đồng bộ; verifier/bot gọi thẳng bản đồng bộ với seed từ băng)
var epoch: EpochSource
func begin_run(params: Dictionary) -> Dictionary          # async; {ok, code}. Thay MainMenu tự randi() (`MainMenu.gd:120/583`): **L/M sửa MainMenu và Run Setup**, không phải A (MainMenu.gd là file của L)
func start_new_run_seeded(seed: int, params: Dictionary) -> void
# GIỮ `start_new_run(p_seed, team, mode, ascension, ranked)` và các hàm đồng bộ cũ (`enter_node(id, kind)`, `apply_combat_result(res)`,
# `reroll_pending_rewards()`, `choose_event_option(i)`, `try_buy_shop_item(i)`, `reroll_dice(uids)`, `begin_end_turn()`) làm lớp tương thích:
# seed bỏ trống/-1 thì hàm tự xin `epoch.request` và **chỉ hợp lệ khi `reply.done`** (Local/Tape), còn Remote thì `push_error`.
# Lý do: 17/10 A không phải sửa CombatView/RunMap/Shop/Event (U), MainMenu/TeamSelect (L), DevReview, ~18 test. Bản async do U/L/M tự
# nối trong file của mình trước 27/10, trước khi làn I bật cờ `remote` (28/10). Xoá lớp tương thích sau khi hết caller (làn I grep).
func request_enter_node(node_id: String, node_kind: String) -> Dictionary   # async
func enter_node(node_id: String, node_kind: String, seed: int) -> void
func apply_combat_result(res: Dictionary, reward_seed: int = 0) -> void     # reward_seed bỏ qua khi thua / boss cuối
func reroll_pending_rewards(seed: int) -> bool
func choose_event_option(index: int, seed: int) -> String
func shop_item_needs_epoch(index: int) -> bool
func try_buy_shop_item(index: int, seed: int = 0) -> bool
func refresh_shop(seed: int) -> bool
func reroll_pact_slot(slot: int, seed: int) -> bool
func reveal_rows(row_types: Dictionary) -> void           # {row:int -> Array[String]} từ extra.row_types / Scout
func request_epoch(kind: String, args: Dictionary) -> EpochReply   # tiện cho CombatView
```

### 1.5 ActionLog, save, verifier (A)

- `ActionLog.header`: bỏ `seed`; thêm `run_id`, `client_nonce`, `loadout` (Dictionary, server ký ở bản sau L1), `newcomer: bool`,
  `mission: {}` (rỗng nếu không phải Nhiệm vụ: `{mission_id, tier, rules:[...], stake, m_base, m_scale, m_eff}`). Local giữ
  `local_secret` trong header chỉ cho test.
- `ALLOWED_FNS` thêm: `continue`, `pact_reroll`, `shop_refresh`, `aid_use` (chỉ DO ghi; client chỉ nối bản DO trả về),
  `tweak`, `hold_pick`, `loaded_pick`, `reorder_party`, `sell_relic`, `swap_on_full`, `pact_pick`. Tên dùng chữ thường `[a-z_]`
  (canon ADR-RNG §4.1). `CONTINUE`/`AID_USE` của monetization = `continue`/`aid_use` trong log.
- **`reroll_dice` phải ghi `from_aid`** (hôm nay `_log("reroll_dice", [uids])` không có, `combat_engine.gd:~484`): verifier replay qua `engine.reroll_dice(args[0])` (`run_verifier.gd:180`), nên reroll Aid lúc `rerolls == 0` sẽ bị từ chối khi replay. Thêm `args[1] = from_aid`; chữ ký log đổi nằm trong đợt bump 27/10.
- `aid_use` do DO ghi, nhưng client phải nối đúng dòng đó vào log của mình để `h` khớp, mà `aid_res` chỉ trả `h, log_len`. Vậy canon của dòng `aid_use` (tham số, thứ tự) phải cố định và nằm trong `epoch_golden.json`, client tự dựng từ `(aid_id, args)` rồi so `h` với `aid_res`.
- Run save (`RunState.to_data`): bỏ `rng_state`/`shop_rng_state`/`event_rng_state` khi không còn cần; thêm `run_id`, `epoch_tape`,
  `epoch_seq`, `relic_state`, `relic_stickers`, `pacts_taken`, `row_types_known`, `aid_uses` (mục 3.4). `SAVE_VERSION` 1 → 2; run dở
  bản cũ bị bỏ có thông báo. **Lưu ý:** `_shop_rng`/`_event_rng` hôm nay sống qua màn shop/event nhiều lần gọi (`try_buy_shop_item` rút tiếp `_shop_rng`; options event rút từ `_event_rng`). Chỉ bỏ `*_rng_state` khi các luồng đó dựng lại được từ seed epoch `node` trong `epoch_tape`; nếu không, giữ `shop_rng_state`/`event_rng_state` (xác nhận khi code, test resume giữa shop/event).
- `RunVerifier.verify(log: ActionLog, tape: Array, loadout: Dictionary) -> Dictionary` dùng `TapeEpochSource`. Ở L1 verifier
  chỉ chạy trong test (container để sau L1).

### 1.6 Lỗi và mất mạng (A + U + S)

`r.code` khác rỗng: CombatView huỷ overlay tung xúc xắc qua đường `_end_reroll_fx` có sẵn, hiện "Đang kết nối lại" (U vẽ, S báo
trạng thái qua `RunSession.state_changed(state: String)` với `online|reconnecting|offline|kicked|version`). Không tự xử thua.
Timeout mỗi yêu cầu 8 giây rồi thử lại cùng `seq` (S). `version` → màn "cần cập nhật bản mới".

---

## 2. Điểm gọi hook relic (A chèn 14–16/10, B viết thân)

### 2.1 Luật chia việc

- **A chỉ gọi các hàm đã có** trong `relic_hooks.gd`: `RelicHooks.fire(combat, event, ctx)`, `run_value_hook(combat, event, ctx, value)`,
  `sum/has/max_val/mul`. Chúng đã là no-op khi chưa relic nào khai báo event đó, nên điểm gọi rỗng chạy được ngay, không phải chờ B.
- Hook ngoài combat (H8) cần hàm nhận danh sách id thay vì `combat`. **B thêm trước (skeleton 14/10, sáng):**
  `static func run_fire(relic_ids: Array, event: String, ctx: Dictionary) -> void` và
  `static func run_value(relic_ids: Array, event: String, ctx: Dictionary, value: Variant) -> Variant` trong `relic_hooks.gd`.
- Handler trả dữ liệu bằng cách **ghi vào `ctx`** (ví dụ `ctx["veto"] = true`), vì `fire()` bỏ giá trị trả về.
- `fire()` duyệt theo `combat.relic_ids`, tức **thứ tự nhận** (H3 cần). RunState giữ thứ tự đó trong `owned_relic_ids` qua bán/đổi.
- Handler chỉ rút ngẫu nhiên từ `combat._rng` (trong trận) hoặc từ `rng` người gọi truyền vào (ngoài trận). Không tạo Rng.
- Handler gây damage: `DamagePipeline.resolve({... "attack": false, "src": null, "depth": depth + 1})`. Biến `depth` B thêm vào
  `damage_pipeline.gd` (file của B).

### 2.2 Tám hook

| # | Event (chuỗi) | Chỗ A chèn | `ctx` | Handler được làm |
|---|---|---|---|---|
| H1a | `before_reroll` | `reroll_dice`, sau khi lọc `list`, **trước** `rerolls -= 1` | `{combat, uids:Array[int], from_aid:bool, veto:false, mana_cost:0}` | Đặt `veto`, cộng `mana_cost`. A: veto → trả false không tốn gì; `mana < mana_cost` → false; còn lại trừ Mana rồi mới reroll. `can_reroll()` chạy cùng hook với `dry_run: true` để UI biết trước |
| H1b | `on_roll_settled` | Cuối `roll_all()` ngay sau `on_roll_end` (`combat_engine.gd:379`), và cuối `reroll_dice` sau `_resolve_cantrips()` | `{combat, rerolled_uids:Array[int]}` (rỗng ở roll đầu lượt) | Chỉ ghi cờ/bonus theo-roll, xoá rồi gắn lại; không bộ đếm (relic-set §5 H1) |
| H2 | `on_face_used` | Cuối `_exec_face` khi `true` (`:739`), sau `mark_used` | `{combat, unit, face:Dictionary, fi:int, target_uid:int, side:String, depth:int}` | Handler tự lọc `side == "p"`; đòn phụ depth+1 |
| H3 | `on_turn_end` | `begin_end_turn`, sau `first_used = false`, **trước** khối mana overflow (`:1031`) | `{combat}` | |
| H4 | `on_active_played` | Cuối `play_active` khi thành công, sau khi `mana_spent` đã cộng | `{combat, act_id:String, cost:int}` | Đếm theo `mana_spent // N` so với số đã thưởng (counter để trong `relic_combat`) |
| H5a | `on_combat_start` | `setup_new`, sau khối weaken A5, **trước** `on_turn_start` + `roll_all()` | `{combat, node_kind:String}` | Khởi tạo bộ đếm theo trận |
| H5b | `on_combat_end` | Lần gọi đầu `get_result()`, chặn lặp bằng cờ `_end_fired` trong `_state_dict` | `{combat, result:"won"/"lost", node_kind}` | Không chạy lúc cả đội chết mà người chơi còn đang ở màn Continue: `get_result()` chỉ được gọi khi trận thật sự kết thúc (thắng, hoặc thua đã từ chối Continue). Ghi `run_state` qua `ctx.combat.relic_run_out` |
| H6 | (state) `relic_state` | `RunState`: `var relic_state: Dictionary = {}` (id → Dictionary JSON thuần) + `relic_stickers: Dictionary` (id → `"eternal"`). Vào `to_data/from_data`, `pending_combat.relic_state` (bản sao), về lại qua `get_result()["relic_state"]` | | B chỉ đọc/ghi khoá của relic mình |
| H7 | `roll_edit`, `roll_face` | API mới trong engine (dưới). `roll_face`: trong `_roll_unit` (`:383`), `fi = int(RelicHooks.run_value_hook(self, "roll_face", {"combat": self, "unit": u}, fi))` | `roll_edit`: `{combat, kind, uid_a, uid_b, face_index, ok:false}` | `loadeddie`, `twinfates` rút thêm từ `combat._rng` trong `roll_face`; tweak/hold đặt `ok = true` và sửa mặt qua `Unit.set_roll` |
| H8 | `shop_relic_count`, `reward_card_count`, `reward_reroll_charges`, `on_relic_acquired` | `RunState`: `_open_shop`, `_reward_count`, khởi tạo charge, `acquire_relic` | `run_value(owned_relic_ids, event, {ascension, kind}, base)` / `run_fire(..., {relic_id, source})` | Không đổi giá/thu nhập (relic-set §3.7) |

API H7 (A viết trong `combat_engine.gd`, mỗi hàm: kiểm `won/lost`, `phase == EXECUTE`, `_push_undo()`, `fire("roll_edit")`,
không `ok` thì `undo_stack.pop_back()` và trả false, có thì `_log(...)`):

```gdscript
func tweak(kind: String, uid_a: int, uid_b: int = -1) -> bool   # kind ∈ nudge_up|nudge_down|copy|swap|flip
func hold_pick(uid: int) -> bool                                 # amberdie
func loaded_pick(uid: int, face_index: int) -> bool              # loadeddie
func tweak_budget_left() -> int                                  # đọc relic_combat["tweak_left"], UI dùng
```

### 2.3 State relic trong trận

`CombatEngine` thêm `var relic_combat: Dictionary = {}` (JSON thuần) vào `_state_dict()` / `_apply_state_dict()`, nên undo và
save/resume khôi phục cùng lúc với Mana (relic-set §5 F-09). Khoá do B đặt, gợi ý: `tweak_left`, `mana_paid_<id>`, `reroll_refund_used`,
`chaos_rerolls`, `crescendo_ramp`, `amber_bank`, `deathspiral:<uid>`. Thêm `relic_run_in` (bản sao `relic_state` lúc vào trận) và
`relic_run_out` (bản sẽ trả về RunState). A thêm khung, test round-trip rỗng; B thêm test undo + save/resume cho từng hook (R13).

### 2.4 Ô relic 8 passive / 3 active (A gọi, B viết luật)

File mới **`godot/scripts/core/relic_slots.gd`** (B, `class_name RelicSlots`, static thuần). Skeleton có chữ ký thật, thân trả
"luôn cho nhận" — merge 14/10 sáng cùng skeleton `relic_hooks.gd`:

```gdscript
static func capacity(ascension: int, owned_ids: Array) -> Dictionary    # {passive: 8|7, active: 3|4, g: 1, a: 2}
static func check_add(owned_ids: Array, stickers: Dictionary, new_id: String, ascension: int, forced: bool) -> Dictionary
	# {ok:bool, needs_sell:bool, sell_from:Array[String], reason:String}  — bảng luật ô đầy relic-set §3.1
static func sell_price(relic_id: String, ascension: int) -> int          # 50% / 40% từ A1, làm tròn xuống
static func is_pact(relic_id: String) -> bool
```

`RunState` (A): `owned_relic_ids` (thứ tự nhận), `pacts_taken: Array[String]` (kể cả đã bán), `relic_stickers`;
`acquire_relic(id, source, sell_id := "") -> bool` (log `swap_on_full` khi có `sell_id`), `sell_relic(id) -> bool` (log `sell_relic`),
`reorder_party(order: Array[int]) -> bool` (log `reorder_party`, chỉ ở MAP). Passive: pact + relic khởi đầu `u_start` chiếm ô passive;
active `a_*` chiếm ô active. Số 8/7/3/4 nằm trong data relic (`relic_tuning.tres` của B), Ascension chỉ truyền `ascension`.

`RelicDef` (B) thêm: `tags: PackedStringArray` (≤2), `layer`, `mult_axis` (`""`/`"G"`/`"A:poison"`...), `pact_group`,
`requires_class`, `hidden_from_pool: bool` (cờ cắt §4 mục 7). `unit.gd` (B) thêm `slot: int` cho relic positional; A gán
`slot = roster_index` trong `_build_unit_from_roster` (xác nhận khi code: "kề" dùng chung với LINK `combat_engine.gd:751`).

---

## 3. Bề mặt luật Aid / Continue / Boon / Ascension / Nhiệm vụ (A) — U và E gọi

### 3.1 Dữ liệu luật (A, trong `godot/assets/data/rules/`)

| File | Nội dung |
|---|---|
| `ascension.json` | Mảng 0..10, mỗi phần tử: `{hp, dmg, boss_hp, shop_price_mult, sell_pct, reroll_base_delta, reroll_base_floor, clock:{start, step_pct, max_stacks}, eternal_max, forced_pact:"none"\|"first"\|"all", reward_cards, reward_reroll_max, passive_slots, elite_extra, extra_elite, weaken, continue_heal_pct}`. `ContentDB.ascension_mods(a)` đọc file này, giữ nguyên khoá cũ để code cũ không vỡ |
| `combat_tune.json` | `TUNE` hiện có + `attrition:{start, step_pct, cap_pct}`, `base_clock:{start, step_pct, max_stacks}` (A0–A3), `spike:{elite_period, boss_period, mult}`, `phase_thresholds`, `newcomer_runs: 5` |
| `mission_rules.json` | `standard:{enemy_dmg, elite_hp}`, `M1..M5` (mỗi luật một dict mod: `clock_start_override`, `spike_period_delta`, `extra_elite`, `enemy_dmg`, `boss_hp`) |
| `boons.json` | 8 Boon `{id, name_key, effect:{...}}`. **Danh sách 8 Boon chưa có trong spec** — D viết 13–14/10, xác nhận khi code |

Làn I: `assets/data/rules/` đổi kết quả run nhưng không nằm trong fingerprint. **Chỉ thêm vào `WATCHED_DIRS` là không đủ:** `t_rules_version._watched_files()` hiện chỉ lấy file `.gd`, không đệ quy (`ends_with(".gd")`). Làn I phải sửa hàm đó để lấy cả `.json`/`.tres` ở các thư mục sau, hoặc thêm vào `WATCHED_FILES`:
`res://assets/data/rules/*.json` (mới), `res://resources/relics/*.tres` + `relic_tuning.tres` (B thêm 133 relic, đổi kết quả run mà hôm nay **không** bị fingerprint, lỗ hổng có sẵn). Không thêm `assets/data/economy/` (không đổi kết quả run), `scripts/net/`, `scripts/meta/`. Làm cùng lúc với bump đầu tiên của `assets/data/rules/` (A, 14–16/10); bản fingerprint đổi vì sửa chính hàm này là lần "không bump" như mọi lần khác.

Làm tròn ≥ .5: một hàm `RulesMath.round_half_up(x: float) -> int` trong `scripts/core/rules_math.gd` (A). Mọi chỗ mới dùng nó.

### 3.2 Engine: HUD đọc gì (A → U)

```gdscript
func hud_state() -> Dictionary   # CombatEngine, hàm thuần, U gọi mỗi khi rebuild
# {
#   turn:int, rerolls:int, max_rerolls:int, mana:int, tweak_left:int,
#   clock: {active:bool, start_turn:int, turns_left:int, stacks:int, pct:int},     # boss; turns_left ≤ 0 khi đang enrage
#   attrition: {active:bool, start_turn:int, stacks:int, pct:int},
#   enemy_next: {uid:int -> {dmg:int, spike:bool, turns_to_spike:int}},         # MỘT số gộp: base × (1+enrage%+attrition%) × spike (monetization §1.2)
#   boss_phase: {uid:int -> {phase:int, thresholds:Array[int]}},
#   newcomer:bool
# }
```

EventBus thêm (A sở hữu `autoload/EventBus.gd` trong L1): `combat_clock_changed(state: Dictionary)`,
`combat_attrition_changed(state: Dictionary)`, `party_revived(uids: Array, heal_pct: int)`, `boss_spike_warned(uid: int, turns: int)`.
Chỉ để trình bày, không ai trong luật nghe.

### 3.3 Hàm hiệu ứng (A). Không lưu cờ "đã mua"

| Aid | Đường server (ADR-RNG §4.9) | Hàm engine/RunState | Ghi chú MON-13 |
|---|---|---|---|
| R1 Continue | `epoch.request("continue", {node_id, attempt})`, trả tiền trong cùng yêu cầu | `CombatEngine.continue_after_wipe(seed, heal_pct)` với `heal_pct = ContentDB.ascension_mods(asc).continue_heal_pct` (40 / 25 từ A6) | Hồi đội thật (không token) `ceil(max_hp × pct/100)`, địch giữ HP/phase/bộ đếm spike, clock và attrition về 0 (engine lưu `clock_turn_base = turn`), roll lượt mới bằng seed. `attempt` là đếm số lần hồi sinh trong trận, là trạng thái trận chứ không phải trạng thái mua |

> **Rủi ro L1 chấp nhận (S, 12/10):** giá Continue 90 vs 180 (boss) đọc từ dòng `enter_node` do client gửi; server chưa có bản đồ node từ seed nên không kiểm được loại node. Client gian lận có thể luôn khai node thường: mất tối đa 90 Gem/run (R1 cap_run = 1). Sửa đúng khi server sinh map từ seed (P0 thật).

| R2 Reroll thêm | `request("reroll", {..., source:"aid"})` | `reroll_dice(uids, seed, from_aid = true)`: không trừ `rerolls` | Hook H1 chạy y như reroll thường (luật không phân biệt). `twinfates` không coi đây là nguồn relic vì nó không tăng `max_rerolls` |
| R4 Hoãn đồng hồ | `epoch.aid("delay_clock", {node_id})` | `CombatEngine.delay_clock(turns: int)` (turns từ `aid_catalog`, dự kiến 2) | Chỉ dời `clock_turn_base` |
| R5 Đổi pact | `request("pact_reroll", {node_id, slot})` | `RunState.reroll_pact_slot(slot, seed)` | |
| R6 Làm mới shop | `request("shop_refresh", {node_id, k})` | `RunState.refresh_shop(seed)` | |
| R7 Scout | `epoch.aid("scout", {node_id})` → `extra.row_types` | `RunState.reveal_rows(row_types)` | Local tính `row_types` bằng `EpochCanon.row_type_seed(row)` |
| Boon | trong `start_run` params `loadout.boon_id` | `RunState.start_new_run_seeded` áp effect từ `boons.json` | Boon là loadout đầu run, không phải cờ trong luật |

Mọi hàm trên chỉ nhận số (seed, pct, turns), không nhận "nguồn".

### 3.4 Ai giữ đếm Aid (để UI hiện trần, resume)

- `RunState.aid_uses: Array[Dictionary]` `[{aid, node_id, turn}]`, chỉ ghi bằng `RunState.record_aid_use(aid, node_id)`, chỉ đọc
  bằng `aid_uses_view()`. Trong save. **`t_mon13` cấm mọi hàm luật đọc nó.**
- Có chào hay không, giá bao nhiêu: **`godot/scripts/meta/aid_catalog.gd` (E)**, `class_name AidCatalog`, static:
  `offer(aid_id: String, ctx: Dictionary) -> Dictionary` → `{show:bool, enabled:bool, price:int, reason:String}`.
  `ctx` do UI dựng từ `RunState.aid_context()` (A): `{mode, mission:bool, newcomer:bool, ascension, node_kind, in_shop, at_pact,
  party_wiped, rerolls_left, clock_turns_left, uses: aid_uses_view(), boon_used:bool, vip:bool, free_continue_left:bool}`.
  Luật trần (6 / 4, từng loại, 1 Boon) nằm ở đây cho UI; server kiểm lại.
- Run Nhiệm vụ / newcomer: `AidCatalog.offer` trả `show = false` cho mọi Aid (trừ Continue miễn phí mẫu khi newcomer, A0–A2).

### 3.5 Luật Nhiệm vụ trong engine (A)

`pending_combat` thêm `mission_rules: Array[String]` (từ header). Engine đọc `mission_rules.json` qua
`ContentDB.mission_mods(rules: Array) -> Dictionary` và nhân vào cùng chỗ với `run_mods`. `M1` ghi đè `clock.start`, không cộng chồng.
M2 cần spike theo lịch; nếu A chưa làm spike thì generator của E không chọn M2 (game-designer đã ghi phương án thay M4).

### 3.6 RunParams (M dựng ở Run Setup, A nhận)

```
{ mode:"short"|"full", ascension:int, kind:"normal"|"daily"|"ranked"|"mission", team_keys:Array[String],
  loadout:{boon_id:String, boon_source:String, unlocks:Array[String], vault_ids:Array[String]},
  mission_offer_id:String  # chỉ kind == mission
}
```
Server trả `header.newcomer`, `header.mission` (stake, m_eff chốt), `run_id`. A ghi vào ActionLog header. Daily seed: server cấp như mọi
run (Daily dùng chung luật, khác thưởng). Xác nhận khi code với D: Daily có cần cùng một bản đồ cho mọi người không — nếu cần thì
`run_start` của Daily lấy từ seed ngày chứ không từ `S_run`.

---

## 4. CombatView ↔ CombatStage3D (U ↔ C) — chốt trước 14/10

**Quyết định:** giữ kiểu **gọi hàm theo uid** đang có, không đổi sang `play_event(ev)`. Lý do: engine đã phát sự kiện qua `EventBus`,
CombatView đang giữ nhịp (pacing, `disable_juice_for_tests`), và Stage3D đã có ~15 hàm dùng thật. Thêm một lớp `play_event` chỉ nhân
đôi chỗ dịch sự kiện. C chỉ sửa `CombatStage3D.*`, `BattleBackdrop.gd`, `monster_art.gd`, `monster_anim.gd`; U chỉ gọi.

### 4.1 API Stage3D (đã có, giữ nguyên chữ ký)

```gdscript
signal unit_clicked(uid: int)
signal unit_inspect_requested(uid: int)
func spawn_unit(uid: int, cls: String, is_enemy: bool, slot_index: int, slot_count: int,
		is_boss: bool = false, unit_key: String = "", genes: String = "") -> void
func reseat_side(uids: Array, is_enemy: bool) -> void
func has_unit(uid: int) -> bool
func set_alive(uid: int, alive: bool) -> void
func set_targetable(uid: int, v: bool) -> void
func get_unit_screen_pos(uid: int, height_offset: float) -> Vector2   # FEET_HEIGHT / CHEST_HEIGHT / HEAD_HEIGHT
func play_action(uid: int, face_type: String = "", target_uid: int = -1, vfx_key: String = "") -> void   # xác nhận tham số cuối khi code
static func action_motion_duration() -> float
func play_hit_reaction(uid: int) -> void
func play_death(uid: int) -> void
func play_victory_march(uids: Array, distance: float, duration: float) -> void   # await được
func shake(amplitude: float, duration: float) -> void                            # await được
func dispose_all() -> void
```

### 4.2 API mới cho L1 (C viết, U gọi)

```gdscript
func get_unit_anchor(uid: int, anchor: StringName) -> Vector2   # &"feet" &"chest" &"head" &"intent" &"nameplate"; toạ độ trong Stage3D, U cộng position
func play_spawn(uid: int) -> void                                # quái con, Egg (đi cùng EventBus.unit_spawned)
func play_boss_phase(uid: int, phase: int) -> void               # EventBus.boss_phase_changed(uid) hôm nay KHÔNG mang `phase` (`EventBus.gd:27`): U đọc phase từ `hud_state().boss_phase[uid].phase`, hoặc A thêm tham số `phase` vào signal
func set_enrage(uid: int, stacks: int) -> void                   # tint/aura theo bậc; 0 = tắt
func play_revive(uids: Array) -> void                            # Continue; await được
func set_focus(uid: int) -> void                                 # -1 = bỏ; hover/target preview
static func anim_duration(unit_key: String, clip: StringName) -> float   # U dùng để giữ nhịp; 0 nếu không có clip
```

Mọi hàm `await` được phải trả ngay khi `uid` không tồn tại. Thiếu model/clip thì rơi về placeholder như hôm nay, không lỗi.

### 4.3 Sổ model Atia (C)

File `godot/assets/atia/atia_models.json`, đọc qua `MonsterArt.resolve(unit_key: String, is_boss: bool) -> Dictionary`
(trong `monster_art.gd`, C). `BOSS_MODELS` trong `CombatStage3D.gd:135` chuyển vào file này.

```json
{
  "version": 1,
  "models": {
    "<enemy_key>": {
      "kind": "glb",                       // "glb" | "sprite" | "placeholder"
      "path": "res://assets/atia/<file>.glb",
      "height_m": 2.55,
      "facing_deg": 0,
      "anims": {"idle": "Idle", "attack": "Attack01", "cast": "Skill01", "hit": "Hit", "die": "Die", "spawn": ""},
      "anim_speed": {"attack": 1.0},
      "fallback_sprite": "alpha-wolf"      // MonsterArt.MONSTER_SPRITES key, dùng khi glb lỗi
    }
  }
}
```

Danh sách key: `ContentDB.enemies` + `ContentDB.bosses` (A). A **đóng băng 27 key ngày 13/10** (17 thường, 4 elite, 6 boss); thêm/đổi key
sau đó phải báo C. C thêm test `t_atia_coverage`: mọi key resolve được ra một trong ba kind, mọi `path` tồn tại, mọi `anims` có trong model.

Nhịp: U gọi `play_action` khi nhận `EventBus.face_used`, `play_hit_reaction` khi `hit_landed`, `play_death` khi `unit_died` (như hôm nay
`CombatView.gd:2943-2971`). Không bên nào đọc state engine trong Stage3D.

---

## 5. Dữ liệu economy (E) + MetaState/SaveStore

### 5.1 File JSON trong `godot/assets/data/economy/` (E sở hữu, có `"version": n` ở đầu mỗi file)

| File | Khoá chính | Số đã chốt (nguồn) |
|---|---|---|
| `gem.json` | `gift:{per_day, balance_cap, source_tag, reset_at:"L2"}`, `season_gift:{total, milestones:[{pass_level, gems}]}`, `vip_trial:{days, once_per_account}` | 300/ngày, trần 900, `playtest_grant`; 180 = 90 ở lv10 + 90 ở lv20; thử VIP 7 ngày (phase-plan "Gem tặng ở L1", monetization T2a) |
| `aid_prices.json` | `aids:{R1:{price, boss_price, vip_price, boss_vip_price, cap_run, cap_battle_by_asc:[...]}, R2:{price, pack3}, R4, R5, R6, R7, R8, R9}`, `total_cap:{a0_a8:6, a9_a10:4}`, `boon_counts_in_total:true`, `free_continue:{per_account:1, max_asc:2}` | PA-1: R1 90/180 (VIP 68/135), R2 15 (gói 3 = 38), R4 60, R5 15, R6 18, R7 12, Boon 38, Kit 60 |
| `echobox.json` | `boxes:{normal:{ticket_cost, table:[{id, rarity, weight}], pity:{...}, dup_convert:{...}}, season:{..., full_set_pity:80}}` | Từ `echobox-pass-v2.md` (E điền; pity đủ bộ ≤ 80 phải giữ) |
| `pass_v2.json` | `season_id, weeks, levels:[{lv, xp, free:[reward], premium:[reward]}], post30_loop:{...}` | Premium từ mùa 2: L1 chỉ đọc `free` |
| `daily.json` | `daily_reward:{shards:60, stone:500}`, `reset:"00:00 UTC"` | |
| `missions.json` | `tiers:{N1..N6:{mode, ascension, stake, m_base, m_scale, stone, unlock_win_asc, house_level, enabled}}`, `rule_sets:{N2:{A:["M3"], B:["M2"]}, ...}`, `house:[{level, cost_shards, cost_stone}]`, `stone_day_cap:150`, `payout_cap:20000` | N1–N4 bật, N5/N6 `enabled:false` ở L1; m 1,60/1,95/2,45/3,30; cược 300/500/800/1.200 |
| `land_tiers.json` | `tiers:[{tier, cost_stone, cost_shards}]` | Chỉ hiện giá ở L1 |

Định nghĩa luật M1–M5 (con số làm đổi trận) nằm ở `rules/mission_rules.json` của A, **không** ở đây; `missions.json` chỉ tham chiếu mã.

Loader: `godot/scripts/meta/economy_db.gd` (E), autoload `EconomyDB` trỏ tới đó (làn I đăng ký; nằm ngoài `autoload/` để không đổi
fingerprint). API: `EconomyDB.get_table(name: String) -> Dictionary`, `EconomyDB.version(name) -> int`. Không ai đọc JSON trực tiếp.

### 5.2 Field mới trong MetaState (E) — mỗi field phải có ở khai báo, `reload_from_store()`, và dict ghi save

| Field | Kiểu | Ai đọc | Ghi chú |
|---|---|---|---|
| `stone` | int | M (Land, Nhiệm vụ), L (giá tier) | Land Stone |
| `gems_cache` | int | M (store, khay Aid hiện số dư), U | **Chỉ là bộ đệm hiển thị nếu [LIAM-2] chọn Gem ở server** |
| `gem_claim_next_utc` | int (unix) | M (badge) | Cache từ server |
| `tickets` | Dictionary `{normal:int, season:int}` | M | |
| `echobox_pity` | Dictionary | E logic | |
| `cosmetics_owned` | Array[String] | M, U | |
| `pass_season` | Dictionary `{id, xp, level, claimed_free:Array[int]}` | M | Pass v2; `battle_pass_*` cũ giữ tới khi E chuyển xong |
| `vip_until_utc` / `vip_trial_used` | int / bool | M, `AidCatalog` | |
| `mission_house_level` | int | M | |
| `asc_wins` | Dictionary `{asc:int -> wins:int}`, `full_a9_won: bool` | M (mở bậc Nhiệm vụ) | Ghi ở `RunState.end_run` → **A gọi** `MetaState.record_run_outcome(params, won)` (E viết hàm này), A không ghi field trực tiếp |
| `aid_hints_off` | bool | U | Settings "tắt gợi ý Aid" |
| `last_daily_reward_utc` | String | M | |

Hàm E cung cấp cho làn khác (không ai khác sửa field): `add_stone(n)`, `spend(currency: String, n: int, reason: String) -> bool`,
`record_run_outcome(params, won)`, `apply_server_wallet(snapshot: Dictionary)` (S gọi sau khi gọi server), `badge_count(screen_id) -> int`.
`RunState.end_run` vẫn gọi `add_shards` như hôm nay.

---

## 6. Client ↔ server tối thiểu (S)

### 6.1 Chặn đầu: desktop chưa đăng nhập được

`AccountService.gd:24` ghi rõ: bản desktop không có cookie nên luôn là khách và node này không làm gì. L1 là bản **tải về**. Không
có đăng nhập desktop thì không có ví, không có sổ Gem tặng theo tài khoản, không có cọc Nhiệm vụ (C3: khách không ví). **[LIAM-1]** (Nếu chọn (a): màn đăng nhập desktop nằm trong `AccountUI.gd` + `Account` của làn U, `AccountService.gd` của S; U phải có việc này trong lịch, chưa có.)

### 6.2 HTTP (Worker `axie-dice`, auth = Bearer cho desktop, cookie cho web; ADR-RNG §4.8)

| Endpoint | Vào | Ra | Ghi D1 |
|---|---|---|---|
| (theo [LIAM-1]) `GET /auth/login?desktop=1&challenge&port&state` → `POST /auth/desktop/token` | code + verifier | `{access, refresh, expires_in}` | `sessions` |
| `POST /auth/refresh` | refresh | cặp mới | xoay vòng |
| `POST /api/run` | RunParams (3.6) + `client_nonce`, `rules_version` | `{run_id, run_token, commit, ws_url, header:{newcomer, mission?}}` | 1 batch: 1 run mở/tài khoản (`UNIQUE WHERE state IN pending,open`), kiểm newcomer, Nhiệm vụ: kiểm bậc + trừ cọc + ledger `stake:{run_id}`; Boon: kiểm + trừ nguồn |
| `GET /api/run/open` | — | `{run_id?, ws_url?, header?}` | — | 
| `POST /api/run/:id/abandon` | — | `{ok}` | `runs.state = abandoned`, mission lost |
| `GET /api/run/:id/ws` | nâng cấp WS | | |
| `POST /api/gem/claim` | — | `{granted, balance, next_claim_utc}` | ledger `grant:{player}:{yyyy-mm-dd}` (UTC server), cộng tối đa tới trần 900 |
| `GET /api/wallet` | — | `{gem, ledger_tail:[...]}` (thêm `shards`, `stone` nếu [LIAM-2] chọn ví server) | — |
| `POST /api/vip/trial` | — | `{vip_until}` | 1 lần/tài khoản |
| `GET /api/missions/board` | — | `{date, tiers:[{tier, rule_set, stake, m_eff, unlocked}]}` | Seed bảng `H(ngày UTC, "nv", rules_version)` |
| `/api/me`, `/api/save` | có sẵn | | PUT `/api/save` bỏ qua `gems_cache` (và ví nếu ở server) |

### 6.3 WebSocket RunDO

Đúng giao thức ADR-RNG §4.6, cộng hai mở rộng nhỏ (`extra` trong `epoch_res`/`aid_res` cho `row_types`, `summary` trong `run_close`; technical-director cập nhật ADR): `hello{run_token,last_seq}` → `welcome{seq,h,log_len}` | `resync{tail}`;
`epoch_req{seq,kind,args,log_delta,h,log_len}` → `epoch_res{seq,seed,extra?}` | `epoch_err{seq,code}`;
`aid_req{seq,aid,args,log_delta,h,log_len}` → `aid_res{seq,h,log_len,extra?}`; `run_close{seq,log_delta,h,log_len,outcome,summary}` →
`closed{seq}`; `bye{reason}`. Trả tiền Aid có random và Continue nằm trong chính `epoch_req` (ví Gem). `extra.row_types` cho kind `node`
và Scout. Canon + hash chain theo `epoch_golden.json` chung.

`summary` của `run_close` (telemetry L1, không verify): `{outcome, battles_done, last_node_kind, boss_hp_left_pct, turns, aid_uses,
continue_used, xp, shards_earned, mission_won}`. Server ghi `runs` + bảng `run_results`; Nhiệm vụ ghi payout **chưa verify**
(`payout:{run_id}`, trạng thái `unverified`) — xem [LIAM-3].

### 6.4 Để sau L1

Container verifier + thưởng do server tính (P3), escrow đầy đủ và ví Shard/Stone ở server (trừ khi [LIAM-2] chọn khác), loadout ký
(`LOADOUT_KEY`), công bố `S_run`, Bayes `m_scale` (chỉ ghi số liệu), đếm IP/ASN cho khách, Steam, xuất/xoá dữ liệu, thanh toán.

### 6.5 Cách bật online thật (chuẩn bị, chưa bật; L1-B1)

Bật bằng 2 project setting, đặt trong `godot/project.godot` mục `[axie]` (KHÔNG dùng `override.cfg`: file đó chỉ có ở worktree, không vào bản export):

```
[axie]
epoch_source="remote"   ; RunState.begin_run dùng RemoteEpochSource + RunSession (xúc xắc do server tung)
gem_wallet="remote"     ; AccountService gắn RemoteGemWallet khi đã đăng nhập, đăng xuất thì về ví local
```

- Mặc định `local` / `local` (không có dòng nào = tắt). Bật cả hai cùng lúc.
- `axie/server_url` mặc định `https://axiedice.fun` (Worker `axie-dice`); đổi khi thử staging.
- Preset export (Web / macOS / Windows) cần: không `exclude_filter` loại `scripts/net/*` (hiện chỉ loại tests/tools/prototypes, ổn); không cần `custom_features`. Cờ nằm trong `project.godot` nên tự đi theo bản build; kiểm lại sau khi bật rằng `export_presets.cfg` không có preset nào ghi đè.
- Worker phải nhận RULES_VERSION của client: thêm giá trị mới vào `SUPPORTED_RULE_VERSIONS` (`worker/src/run_do.js`) mỗi lần đổi `ActionLog.RULES_VERSION`; `worker/test/rules_supported.test.mjs` đỏ nếu quên. Worker chỉ kiểm chuỗi hash, không chạy lại luật chiến đấu (chưa có verifier, mục 6.4), nên chưa chống gian lận kết quả run.
- Bị đóng 1008 'auth' (token cũ/bị thu hồi): RunSession gọi lại `GET /api/run/open` đúng 1 lần, lấy token mới, hello lại; lần 2 liên tiếp thì đóng (`expired`). Test: `t_run_session` (`_auth_refresh`, `_both_remote`).
- Không có run thì `RunSession` tắt `_process`; `attach()` bật lại, `closed/idle` tắt.
- **Rủi ro (chưa có verifier P3):** server chỉ kiểm chuỗi hash nên thắng/thua, tiền thưởng nhiệm vụ, điều kiện quà mùa và điểm bảng xếp hạng đang tin client trong giới hạn cho phép. Không trao Gem hay phần thưởng tiền thật theo kết quả run cho đến khi có verifier P3.

---

## 7. Land hub ↔ màn meta (L ↔ M)

- **Điều hướng:** `godot/scenes/land/LandNav.gd` (L), `class_name LandNav`, static:
  `open(screen_id: StringName, params: Dictionary = {}) -> void`, `back_to_land() -> void`, `current_params() -> Dictionary`.
  Bảng `SCREENS` (L giữ, chốt đủ id ngày 13/10, M gửi yêu cầu nếu cần thêm):
  `&"run_setup"` → `res://scenes/run_setup/RunSetup.tscn`, `&"echobox"`, `&"pass"`, `&"missions"`, `&"store"`, `&"vault"`, `&"codex"`,
  `&"settings"`, `&"guides"`, `&"unlocks"`, `&"team_select"`, `&"account"`. Màn chưa có thì trỏ màn cũ (ví dụ `pass` → `scenes/pass/Pass.tscn`).
- **Màn meta không `change_scene` về MainMenu nữa**, chỉ gọi `LandNav.back_to_land()`. Nút Back của `DangoScreen` (U) đổi đúng một chỗ.
- **Nhà → màn:** `godot/assets/land/houses.json` (L): `[{house_id, screen_id, badge_screen_id, unlock:{min_runs?}}]`. L đọc badge qua
  `MetaState.badge_count(screen_id)` (E). Không màn meta nào biết nó được mở từ nhà nào.
- **MainMenu:** L sở hữu `MainMenu.gd`/`TeamSelect.gd`; MainMenu thành Land (cảnh đầu do làn I đổi trong `project.godot`).
  Các lối hôm nay ở `MainMenu.gd:220/923-960` chuyển thành nhà hoặc menu phụ của Land.
- **Vào run:** Run Setup (M) dựng RunParams → `await RunState.begin_run(params)` (A) → ok thì `change_scene` sang RunMap (U).
  Lỗi (`code`) thì Run Setup hiện lỗi. "Tiếp tục run": Land hỏi `RunState.has_open_run()` (A; Remote: qua `GET /api/run/open`).
- **Hết run:** Result (U) → `LandNav.back_to_land()` hoặc `LandNav.open(&"missions")` với run Nhiệm vụ.

---

## 8. Thứ tự merge và cái được stub

| Ngày | Merge (làn I) | Người khác stub gì cho tới lúc đó |
|---|---|---|
| 13/10 | Khoá chạy Godot (`with_lock.sh`), cờ `SKIP=t_rules_version`, file này | — |
| 14/10 sáng | **E (thêm, review 12/10):** `MetaState.record_run_outcome(params, won)` và `badge_count(screen_id)` bản no-op (A gọi trong `RunState.end_run`, L đọc badge; thiếu thì PR 17/10 của A vỡ). **B skeleton:** `run_fire`/`run_value` trong `relic_hooks.gd`, `relic_slots.gd` (chữ ký thật, thân "cho nhận"), field mới `RelicDef` + `unit.slot` mặc định. **E:** file JSON rỗng-đúng-schema + `EconomyDB`. **C:** `atia_models.json` + `MonsterArt.resolve()` trả đúng hành vi hôm nay. **L:** `LandNav` trỏ màn cũ | Không đổi hành vi, không đổi kết quả run |
| 14–16/10 | A làm trên worktree: EpochSource + Local + Tape + canon/vector vàng, chữ ký mới (1.4), điểm hook rỗng (2.2), khung state relic, `ascension.json`/`combat_tune.json`, `hud_state()` | U dùng `hud_state()` giả (dict hằng) trong `CombatView`; M dùng `RunState.start_new_run` cũ |
| **17/10** | **A merge** (một PR). Từ đây B viết random mới (pact, loaded_pick) và nội dung relic; U nối `hud_state()` thật | S đã có `RemoteEpochSource` chạy với staging nhưng sau cờ `axie/epoch_source = "local"` (làn I thêm vào `project.godot`) |
| 18–23/10 | (A: tách hình dạng/loại node ở bước này, nên trước đó `extra.row_types` của Local trả rỗng và client đọc loại node từ `map_graph` như hôm nay) · S: `RemoteEpochSource` + endpoints 6.2 (merge khi qua review, cờ vẫn local trên `godot-port`) · A: Continue/Aid/clock/attrition/Nhiệm vụ · E: logic + `AidCatalog` · C/U/L/M theo lịch | M stub server bằng `FakeServer` (`scripts/net/fake_server.gd`, S viết 15/10, cùng chữ ký 6.2, trả dữ liệu cố định) |
| 27/10 | Gộp combat A+B, bump `RULES_VERSION`, cập nhật fingerprint | |
| 28/10 | Bật cờ `remote` cho bản RC; tutorial dùng Tape; dev/test vẫn Local | |

Điều kiện cứng: không ai merge code gọi `derive_combat_seed` sau 17/10; A xoá hàm này trong PR 17/10 (DevReview
`DevReviewController.gd:41` chuyển sang Local, A sửa, vì file đó chưa ai sở hữu).

---

## 9. Cần Liam quyết

**[LIAM-1] Đăng nhập trên bản desktop ở L1.** Hôm nay desktop chỉ chơi được như khách, không có tài khoản server.
- (a) **Làm login desktop qua Worker** (loopback + PKCE, ADR-RNG §4.8, đã duyệt C5): S thêm ~2–3 ngày, token lưu file mã hoá
  (Keychain để sau). Giữ đúng C3.
- (b) Cho tài khoản thiết bị do server cấp **được có ví** ở L1 (phá C3 tạm thời cho playtest nội bộ): ~1 ngày, nhưng người test đổi máy
  là mất tiến trình và số liệu theo người bị nhiễu.
- (c) Gem/Nhiệm vụ chỉ trên bản web: trái với "khuyến khích tải bản desktop".
**Đề xuất (a)**, (b) là phương án dự phòng nếu S trễ tới 20/10.

**[LIAM-2] Gem ở đâu ở L1.** Kế hoạch sprint đề xuất mọi tiền tệ nằm trong save, server chỉ ghi sổ.
- (a) Như kế hoạch: Gem, Shard, Stone đều trong save; server ghi sổ để đối soát. Đơn giản nhất, nhưng server không kiểm được trần
  900 hay trừ Gem trong `epoch_req(continue)`, và người test sửa save là có Gem vô hạn.
- (b) **Gem ở server** (bảng `wallets` chỉ cho Gem, trừ trong RunDO đúng ADR-RNG §4.9), Shard/Stone vẫn trong save.
  Thêm ~1 ngày cho S; đúng thứ L1 muốn đo (Aid/Continue bằng Gem tặng), và là phần đầu của P0 thật.
**Đề xuất (b).**

**[LIAM-3] Thưởng Nhiệm vụ khi chưa có verifier.** Cọc trừ ở server lúc tạo run, nhưng thắng/thua do client báo. Đề xuất: chấp nhận
cho nội bộ, payout ghi `unverified`, Shard cộng vào save như run thường; người chơi gian lận thì đối soát sau từ log trên DO. Nếu
Liam không chấp nhận thì phải đưa verifier vào L1 (không kịp) hoặc tắt Nhiệm vụ (§4 mục 11 của sprint plan).

**[LIAM-4] Không có mạng thì sao.** Bản RC dùng `remote`: server sập là không vào run mới được (tutorial vẫn chạy). Đề xuất giữ đúng
"online-only" như ADR; cắt §4 mục 12 của sprint plan (xúc xắc local) chỉ là đường lùi khi RunDO hỏng trên mạng thật.

Câu nhỏ cho D (không cần Liam): danh sách 8 Boon (3.1), Daily có dùng chung bản đồ không (3.6), hook H1 có chạy với reroll từ Aid
không (đề xuất có, 3.3).

## Quyết định điều phối (12/10, sau review godot-specialist)
- **PR của làn A chia hai:** 17/10 chỉ gồm seam (canon, golden vector, Local/Tape, đổi chữ ký engine/RunState + lớp
  tương thích, verifier). 20/10 gồm điểm gọi hook H1–H8, `ascension.json`/`combat_tune.json`, `hud_state`.
- **Làn B không chờ:** từ 14/10 viết dữ liệu 133 relic (`.tres`) và thân relic chỉ dùng hook đã có; relic cần hook mới
  viết sau 20/10. Nhờ vậy trễ 3 ngày của hook không thành trễ của cả làn B.
- `epoch_golden.json` phải có trước đêm 14/10 cho làn S.
- `boons.json`: làn D viết nội dung, làn A sở hữu file (D gửi qua A).
- `get_result()` có tác dụng phụ: A đổi sang `finalize()` rõ ràng nếu kịp trong PR 17/10, nếu không giữ cờ `_end_fired`.
