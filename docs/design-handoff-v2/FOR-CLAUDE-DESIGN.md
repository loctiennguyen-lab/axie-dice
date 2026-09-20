# How to hand a UI design to this codebase

**Audience:** whoever produces the design (Claude Design, or a human designer).
**Purpose:** so that the thing you deliver can be implemented directly, without the implementer
having to arbitrate contradictions, re-measure your numbers, or discover that a rule you wrote
cannot physically hold in this engine.

This is not a style guide. The visual direction in `design_handoff_axie_dice_ui/` is good and is
not in question. This document is about the **shape of the delivery** — three passes have now
been handed over, and each one lost most of its value to the same handful of interface problems.
Every rule below exists because something concrete went wrong.

---

## 0. What this project is, in the four facts that constrain a design

| | |
| --- | --- |
| Engine | Godot 4.7.2, GDScript. Source lives in `godot/`. |
| Canvas | `window/stretch/mode="canvas_items"`, **`window/stretch/aspect="keep"`**, 1920×1080. |
| Design system | `godot/scenes/shared/DangoTheme.gd` (tokens, surfaces, chips, type, letter-spacing) and `DangoScreen.gd` (screen shell). Asset-path translation lives in `MockupAssets.gd`. |
| Authority | The four mockups in `docs/design-handoff-v2/mockups-v2/`. Nothing else. |

> ### ⚠ THIS SECTION WAS REVERSED ON 20 SEP 2026. READ IT EVEN IF YOU READ THIS FILE BEFORE.
>
> Until today this project ran `aspect="expand"`, which grows the logical viewport with the
> window — a 2387×1540 window laid out in ~1920×1238 logical pixels. This file therefore used to
> open by telling you that **"1920×1080 is a minimum, not a canvas"** and that absolute
> coordinates were the root cause of everything going wrong.
>
> **That is no longer true.** The project owner has ruled that the mockups are to be reproduced
> exactly, and exactness is only well-defined on a fixed canvas, so the project now runs
> `aspect="keep"`. The logical canvas is **exactly 1920×1080 on every window**, with letterbox
> bars on anything that is not 16:9 — a cost accepted knowingly.
>
> The consequence for you is the opposite of what this file used to say: **an absolute
> coordinate from a mockup is now correct, and translating it into a relationship is now the
> error.** Section 1 below has been rewritten accordingly. If you are working from a cached or
> quoted copy of the old §0/§1, discard it.

---

## 1. Give numbers, exactly as the mockup has them

The four mockups are HTML with inline styles. Every width, height, padding, radius, border
width, gap, font-size and `letter-spacing` in that markup is the specification. Quote it.

**Write:** `stat ribbon: height 106, top 558, left/right inset 80`.
**Not:** `stat ribbon, 28px below the party block, full content width`.

The second sentence is what the previous version of this file asked for, and on a fixed canvas
it is strictly worse: it throws away a number the design already decided and hands the
implementer a judgement call. Three rounds of judgement calls is how the build drifted.

Two things that follow:

- **Do not re-derive a number.** If the mockup's markup says `width:176px`, the answer is 176 —
  not "about 180", not "the width of the longest name plus padding". Read the attribute.
- **Do not round a number to satisfy a rule you remember.** The old test file enforced a 12px
  type floor and a uniform 48px safe area. Both have been deleted, precisely because they were
  overriding the mockup's own 9px, 10px and 11px type and its 28/30/42/44/56/64 insets. If a
  number in the mockup looks illegal to you, it is legal now; quote it anyway and say why it
  looked wrong, and the implementer will check the test rather than bend the design.

The one place relationships still beat coordinates is **a set of positions that the engine
generates rather than authors** — the run-map graph beyond the mockup's twelve drawn nodes, or a
list longer than the mockup's demo data. There, give the rule (`lane pitch 370, row pitch 118`)
as well as the drawn example, because the implementer has to produce nodes the mockup never drew.

---

## 2. Separate what you OBSERVED from what you INFERRED

Four items in the last-but-one pass were false positives, and all four came from reading a static
screenshot as if it were the code:

| Claim | What was actually true |
| --- | --- |
| "Every HP bar is green regardless of percentage — a mechanical regression" | `HPBar._draw()` has called `hp_color(pct)` unconditionally since its first commit. The capture was taken on turn 1, when every unit is at full HP. There was nothing to colour differently. |
| "END TURN is white on orange" | It had already been inked at `INK_ON_PRIMARY` (measured by pixel: 42,21,5). Only a stale code comment said otherwise. |
| "24 identical green Pass tiles — claimed and claimable are indistinguishable" | The state ladder was implemented correctly. The save used for the capture had XP maxed and nothing ever claimed, so *every tile genuinely was claimable*. |
| "Relic chips are the only blue objects and ignore rarity" | Rarity colouring worked. That run's three relics happened to share a rarity. |

Each of those cost a round trip: implement, discover nothing was wrong, report back, re-verify.

**What to do instead — two cheap habits:**

- **State the data state of every capture you reason from.** "Captured at turn 1, all units full
  HP" / "Captured on a save with 0 claims and max XP". The moment that line exists, three of the
  four above become self-evidently unprovable from that image.
- **Mark each finding `OBSERVED` or `INFERRED`.** OBSERVED = "this pixel is this colour, this text
  is clipped, this row is cut by the screen edge" — a screenshot proves these and they are your
  strongest output. INFERRED = "therefore the code does X". Inferences are welcome and often
  right; they just need to be labelled so the implementer verifies before rewriting.

A finding phrased as *"the HP bars all read green in this capture — if that is not because every
unit is at full HP, then `hp_color()` is not being applied"* would have cost nothing and been
correct either way.

---

## 3. Ship specifications, not source code

The last pass shipped three `.gd` files. All three had defects that only appear at runtime:

- `t_ui_laws.gd` — a GDScript parse error (this project treats warnings as errors, so an inferred
  `Variant` type fails the build); it instantiated `Result.tscn`, whose `_ready()` writes the
  **player's real save file**; and it **hung** rather than failing, because it added twelve scenes
  to the tree and never freed them — Combat keeps timers and audio running, so `quit()` never
  arrives. Two of these were found stuck at 29 and 18 minutes, blocking the whole suite.
- `DangoScreen.gd` — assumed every scene root is a `Control`. `Combat.tscn` and `RunMap.tscn` have
  `Node2D` roots, so `build(self, ...)` cannot be called on them at all.

None of this is a criticism of the design thinking in those files — `DangoScreen`'s shell is the
right idea and is now in the build. The problem is that **code you cannot run is a liability
dressed as a shortcut.** The implementer must debug someone else's untested file before they can
start their own work, and a hanging test is worse than a missing one.

**So:**

- Prefer prose + a short pseudo-code sketch over a complete file. A twelve-line sketch of
  `fit_or_scroll()` conveys everything and carries no runtime risk.
- If you do ship code, **label it `UNTESTED — never executed`** at the top of the file. That one
  line changes how it is treated.
- If you ship a **test**, be aware it is the highest-risk artifact you can send, because it runs
  against a live project. In this repo a test must: free every node it creates, wrap anything that
  touches `MetaState` in `SaveGuard` (`godot/tests/save_guard.gd`), and never rely on the ambient
  save file for its arrange step.

---

## 4. One document, one normative section, zero contradictions

The last pass contained a direct self-contradiction:

- §1 item 1: *"`window/stretch/aspect="keep"` in `project.godot`."*
- RC1, same file: *"**Fix — keep `expand`.** Do not switch to `aspect="keep"`. Letterboxing would
  throw away real screen width and leave black bars on a wide monitor."*
- `START-HERE.md`: *"keep `stretch/aspect="expand"`"*

Two sources against one line. The implementer had to arbitrate a decision that changes the shape
of every screen in the game, and then defend the choice. That is not a decision an implementer
should be making alone.

**Practical rules:**

- **One file is normative.** If you ship a summary and a detail document, say which one wins, and
  put the machine-readable list of changes in only one of them.
- **A "root cause" section and a "do this" section must agree.** If they disagree, the do-list is
  the one that gets executed, and your reasoning is lost.
- When you supersede an earlier pass, say which specific items are superseded. "This file replaces
  FIX-PASS-01" left ~20 still-open items from the old file in limbo; some were re-listed, some
  silently dropped, and the implementer could not tell which was intended.

---

## 5. Say what a rule applies to, exhaustively

This one you already identified yourself, and it is worth keeping at the front:

> "Enemy nameplates are half size" was implemented as *enemy-only*, and the party plates were left
> at 132px with 11px text and text-measured widths — five plates, five different widths, a shield
> badge cutting an HP number in half.

The fix is a sentence pattern: **state the set.** "Every nameplate — party and enemy — is 196×64."
"All ten Codex tabs." "All six meta screens." Where you mean *every*, write *every*; where you
genuinely mean one instance, say why the others are excluded.

---

## 6. Know which things this repo will not let you change

Not obstacles to design — just facts worth knowing before you spend a section on something that
cannot land as written.

- **`res://scripts/core/` and `res://autoload/` are fingerprinted** by `t_rules_version`. Any edit
  there fails a gate until the fingerprint is updated, and if the change could alter a run's
  outcome, `ActionLog.RULES_VERSION` must be bumped — which invalidates existing replays. So a UI
  fix that requires touching game rules is expensive; flag it rather than assuming it is free.
- **`resources/theme/dango.tres` is generated**, from `tools/gen_theme.gd`. Never spec a hand-edit
  of it. Spec the generator instead.
- **The save file is the player's real one.** Anything exercising progression needs `SaveGuard`.
- **`--headless` cannot take a screenshot** (dummy renderer, null texture — the run hangs and
  looks like a broken capture harness). QA captures run windowed.
- **A GDScript parse error hangs a headless run** instead of failing it.
- **Some data cannot be captured on this machine.** The dev save owns every unlock, so "unaffordable
  price button" has no state to screenshot. If a finding depends on a state the capture cannot
  show, say so — that is not a gap in the design, it is information the implementer needs.

Added 20 Sep 2026, learned the hard way:

- **Godot `Label` has no letter-spacing.** It now works through `DangoTheme.display_label(…,
  tracking_em)`, which converts your em value to `FontVariation.spacing_glyph` — an **integer
  number of pixels**. So tracking below half a pixel rounds to zero: `.02em` at 17px, `.01em` at
  18px and `.03em` at 12px currently render with no spacing at all. Those are not implementation
  misses; the engine cannot express them. Do not re-report them.
- **A `ColorRect` cannot round its corners**, so a 6px rule with `border-radius:3px` renders
  square. Sub-pixel at that height, but real.
- **A Godot `Button` has no line-height control.** Baloo 2 carries a ~1.61em line box, so a
  button whose mockup height is 61px renders nearer 76px unless it is given an explicit height.
  Where a button's height matters, state it as a fixed number.
- **Party Axies and all monsters/bosses do NOT come from the mockups.** The party renders through
  a 3D gene rig (`AxieCharacter3D`), monsters use the existing Chimera sprite set. This is an
  explicit owner decision. Match the mockup's layout boxes — the 186px enemy column, the 180px
  party column — and never ask for the mockup's flat `back-<class>.png` art to be used instead.
- **Every asset the mockups name already exists in this repo** under a different folder name, and
  `MockupAssets.gd` translates it. You never need to ask for art to be produced or renamed.

---

## 7. What a delivery that works looks like

A pass that can be implemented without a round trip contains:

1. **One normative change list.** Each item: an ID, the screen, the specific element, what is
   wrong (`OBSERVED` / `INFERRED`), and what it should become — in the relationship language of §1.
2. **The capture each item came from, with its data state.**
3. **A target image or redline per screen**, at any size — with the note that positions are
   relative, so the image is the intent, not a pixel ruler.
4. **An explicit priority order**, and an honest statement of which items are visible to a player
   and which are internal. *This matters more than it sounds:* the last pass's §1 was entirely
   foundation work, so a full implementation round produced **zero visible change** — which read,
   reasonably, as "nothing improved". If a section will not look different when it lands, say so
   in that section, so it can be scheduled against expectations rather than against hope.
5. **Anything you could not determine**, named. An unknown that is flagged costs one question; an
   unknown that is guessed costs a round trip.

---

## 8. A copy-paste template for one finding

```
ID        C4
Screen    Combat
Element   Enemy intent badge → target line ("-> Buba")
Evidence  2026-09-20_real-flow-varied-enemies.png, captured turn 1, all units full HP
Observed  The target text renders at ~10px directly on the painted background, cream on
          light-green foliage. It is unreadable at 100% zoom.
Inferred  It is drawn as a sibling of the badge rather than a child, so it inherits no plate.
Should be Inside the intent badge, on the badge's own fill, at 14px, inked via
          DangoTheme.ink_on(badge_fill). Use "→", not "->".
Applies to Every enemy intent badge. There is no party equivalent.
Visible?  Yes — a player reads this every turn.
```

Five of those beat five pages of prose, and none of them needs a decision from the implementer.

---

## 9. The short version

1. Numbers, quoted from the mockup markup. 1920×1080 is the canvas, exactly.
2. Label every finding `OBSERVED` or `INFERRED`, and state the capture's data state.
3. Specs over code. Code you ship is untested until someone runs it — say so.
4. One normative list. No contradictions between "why" and "do".
5. Name the full set a rule applies to.
6. Say which items a player will actually see, and which will look like nothing happened.

---

## 10. This round specifically — a review of a build, not a fresh design

Written 20 Sep 2026, for the review the project owner has asked you to run.

**What happened since you last saw this.** All thirteen screens were rebuilt against the four v2
mockups by six implementation passes in one day. `FIX-PASS-01/02/03` and `handoff-spec-v2.html`
have been demoted to history — the mockups are now the only authority, and the test file that
used to encode the prose laws (`t_ui_laws.gd`) has had four of its eight laws deleted or
rewritten because they contradicted the design. The owner has looked at the result and reports
"a lot of small UI/UX errors", which is the honest expected outcome: nobody implementing this
could run the engine, so not one pixel was verified before he saw it.

**Where the evidence is.** `production/qa/evidence/*.png`, regenerated from the QA capture
scripts. The implementer can open those PNGs directly, so **anchor every finding to a capture
filename plus where in the frame it is.** A crop or an arrow is worth more than a paragraph.

**Captures are at 1920×1080 exactly.** If something looks clipped or off-centre, that is a real
defect now — there is no window-size excuse left.

### Do not spend effort reporting these — they are known and already scheduled

| Known gap | Status |
| --- | --- |
| Work Sans body copy renders at weight 500; the mockups say 600 | `DangoTheme.prose_label()` exists; the call-site sweep is not done |
| Several colours were approximated before exact tokens existed (`#B4600C`, `#2E7D2B`, `#5A3310`, `#98A2B1`, `#7C8695`, `#DCE2EC`, `#A6B0BF`) | Tokens now exist; the swap is not done |
| Combat damage numbers render 15–26px against the mockup's 58/54 | Will be flattened to the mockup sizes |
| Codex panel stops 72px short of the mockup's `bottom:48` | The footer rule that caused it is gone; not yet undone |
| Tracking below half a pixel renders as zero | Engine limit, see §6 |
| Team Select's "THIS COMP LEANS" strip, Vault's "USE IN TEAM", Codex's authoring chips, Reward's SKIP, Shop's MP cost, Treasure's SMASH | Not built — each needs a game rule that does not exist yet, not a UI fix |

Re-reporting one of these is harmless; reporting thirty of them buries the findings that matter.

### What the implementer most needs from you

1. **A ranked list.** "A lot of small errors" is not actionable at scale. Which ten, in order,
   most damage the read of the screen? Put the enemy nameplates and anything a player looks at
   every turn above a chip's 2px padding.
2. **For each finding: the capture, the element, what it does now, what the mockup says, and the
   mockup's own number.** The template in §8 is still the right shape.
3. **A separate list of things that are wrong but are NOT in the mockups** — places where the
   build does something the design never specified, so the mockup cannot arbitrate. Those need a
   decision from the owner, and mixing them into the main list stalls the whole batch.
4. **Say which findings are one edit and which are a rebuild.** A dozen one-line fixes can land
   in a single pass; one rebuild cannot.

### What NOT to send

No `.gd` files. The last handoff shipped `t_ui_laws.gd` as "drop in as-is", and it encoded rules
taken from the prose passes rather than the mockups — so for weeks the project's own gate was
enforcing the opposite of the design, and every implementer trusted it because it was green.
Send the specification; the code is the implementer's problem and his to get wrong.

No new normative document either. There is exactly one authority — the four mockups — and every
previous pass that declared itself "the highest document" is why this file has a §4.
