# Làm lại art: lượt 5, một icon Spike (chùm gai đá). Prompt cho Claude Design

**Cho Liam:**
- Dán phần dưới dòng `---` vào **cùng project Claude Design của lượt 34D** (nó còn nhớ style), đính kèm `send/AxieDice-art-batch5.zip`.
- Đường R như các lượt trước.
- Liam chốt 6/11:
  - Spike vẽ "chùm gai đá đỏ";
  - Pact dùng lá bài trăng có sẵn (`ui_mooncard`), sửa trong code;
  - Boss-clock đặt lên đĩa gỗ tối, sửa trong code.
  - Hai icon sau không gửi Claude Design.
- Art-director soát prompt 6/11, đã sửa theo góp ý: màu đích cụ thể, kiểm trên nền chip đỏ nâu, giữ 3 mũi ở 16 px.
- Vì sao làm lại: spike lượt 34D là cái búa, đọc ra "đập" chứ không phải "gai" (art-director soát 5/11). Kho không có hình thay được: quả cầu gai `spiky_ball_*` có mặt.
- Việc bên code khi nhận hàng:
  - chép đè `godot/assets/icons/hl/spike.png`, `spike_64.png`, `spike_32.png`;
  - chụp chip "BIG HIT IN n" ở 1280 và 1920 đặt cạnh chip lethal (1280 là cỡ quyết định);
  - chạy `t_art_batch34d`.

---

## What this is
One icon, in exactly the style of your batch 34D Part D icons ("richer painting": 5-tone facets, own-colour outline, top-left light). The batch-34D spike came out as a hammer and reads as "smash", not "spike". Redraw it.

**Meaning.** The icon sits on a small chip under an enemy's plate that says "BIG HIT IN 2": this enemy will land a very heavy blow in a few turns. Picture: **a cluster of 3 sharp stone spikes** (the middle one clearly the tallest) standing up out of a small cracked rock base. Static: no motion lines, dust or debris. It says "this is going to hurt".

## Must read apart from Lethal
`set/lethal_128.png` (a cherry-red arrowhead pointing **down**, with a cream rope band on its tang) sits in the same chip slot under the same enemy plate when a hit can knock out an Axie. The chip is a **dark red-maroon pill with a red border** (see both `context/` shots, under the enemy plate). The icon shows there at **about 14–16 px at 1280**. At that size the two must not be confused:
- **Shape first.** Spike points **up**: 3 tall wedges with clear gaps, the middle one dominant. Lethal is one shape pointing down. The silhouette alone, with no colour, must read "pointing up" on the dark chip.
- **Colour.** Spike tips: **orange-amber, hue about 20–30°** (e.g. `#e7883a` light, `#cc6a2c` base, `#9a4a24` shadow), with a pale cream highlight on the lit faces so they pop off the maroon chip. Base: **brown-grey rock** (`#7a6658` to `#5a463a`). No cherry or crimson anywhere: that is lethal's `gem_red`.

## Trace from (`refs/`)
- `s9a`: the spike **form only**. It has 5 smooth, soft-edged cones in a stone-ringed pool. Draw **3**, keep that soft rounded cone style (light facets are fine), and leave out the water and the ring stones.
- `ore_red_raw`: **facet structure and the dark rock** only (how the chunk breaks into planes). Do **not** take its hue: its reds are crimson, close to lethal.
- `stone_block`: the cracked texture of the base.
- `gem_red`: only to check you are **not** using its colour.

## Avoid
- a hammer, mace, axe or any handle (that was the problem);
- spikes as a crown or flower;
- a creature, face, eyes, teeth or claws; anything like the `spiky_ball` monsters;
- metal spikes and sparkle stars;
- a single downward point;
- black outline, drop shadow, glow or halo.

## Files
Same layout as your Part D icons (`set/` holds your 34D lethal, aid, attrition and boss-clock for comparison):
- `spike_128.png` master, plus `spike_64.png` and `spike_32.png` as **separate lower-detail redraws**: thicker spikes, fewer cracks, no pebbles. Sharpen after the downscale, as you did for the 34D icons. The 32 must still hold 3 distinct tips with clear gaps between them; the game shrinks it to 14–20 px. In the README, say what you removed at each size.
- RGBA, sRGB, transparent, tight but not cut off. Names exactly as listed.

## Self-check before delivery
Report each line as pass, fail or not measured:
- the 5 metrics (near-black ≤ 1 %, min V ≥ 0.20, coverage 0.37–0.83, grain 1.1–2.8, colours 16–160) on the 128 master;
- a strip at 28 / 24 / 20 / 16 / 14 px on **two backgrounds**: the maroon chip colour (sample it from the `context/` shots) and the wood panel `#3a2c24`. Put spike next to lethal, aid, attrition and boss-clock. Can spike and lethal be told apart at 16 and 14 px? Say how many of the 3 tips still show at 16 px.
- the same row as a flat silhouette (one colour) on the maroon chip: does spike still read "up" and lethal "down"?
- paste spike onto the real chip in **both** `context/` shots: the slot under the enemy plate, at the same pill size, and with the text "BIG HIT IN 2". Do not redesign the chip. Judge it at 1280;
- no creature, face, eyes, text or black outline; one light direction (top-left);
- every file delivered.

## Send back
`art-batch5/`: `spike_128.png`, `spike_64.png`, `spike_32.png`, the strip, the chip mock, and a short README (refs used and what you took from each, the metrics). Status `placeholder` until the owner approves it in the game.
