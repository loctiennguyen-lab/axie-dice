---
name: dangotheme-button-state-spec
description: Decided hover/pressed/disabled spec for DangoTheme primary_button_style()/secondary_button_style() — formulas, not hex, plus a general hover-vs-pressed design rule reusable for future button families
metadata:
  type: project
---

Decided 2026-09-19, in response to a measured gap: no button in the Godot port
(`godot/`) had any hover/pressed visual feedback — `DangoTheme.gd`'s
`primary_button_style()`/`secondary_button_style()` had no state variants, and
every call site (`MainMenu.gd`, `CombatView.gd`, `ResultView.gd`, etc., ~10
files) forced `normal == hover == pressed` to the same StyleBoxFlat. Full
numeric spec was reported to the invoking orchestrator (not written to a file
by me — `ui-programmer` implements). See [[reference_dangotheme-border-semantics]]
for the related "border color channel is reserved for panel state-alerts, not
button hover" boundary this spec respects.

**General rule (reusable for any future button family, not just these two):**
hover only changes color (lighten/brighten fill+border), never geometry.
Pressed changes color in the OPPOSITE direction (darken) AND geometry
(border_width +1, content_margin_top +1.0/content_margin_bottom -1.0 — net
zero so minimum-size and outer Control rect are unaffected) AND drops any
shadow. Disabled never inherits `warning` treatment and never uses the
hover/pressed color direction — it flattens via reduced alpha/saturation only.
This asymmetry (hover = color-only, pressed = color + shape) is what makes
hover and pressed unmistakable from each other, not just from normal.

**Primary family formulas** (`PRIMARY.lightened(0.15)` hover /
`PRIMARY.darkened(0.12)` pressed — asymmetric on purpose, darkening a
saturated hue reads "muddy" faster than lightening reads "washed out" at the
same %). Disabled: `Color(PRIMARY.darkened(0.3).r,.g,.b, 0.45)`, ignores
`warning` param entirely (border fixed at width 2, no shadow).

**Secondary family formulas**: hover keeps `BG_PANEL_SOFT`'s alpha (0.55) but
lightens rgb (`.lightened(0.08)`) + brightens border (`PRIMARY.lightened(0.2)`)
— "translucent glow". Pressed jumps alpha to 0.85 with unchanged rgb (opaque,
not lightened) + darkened border (`PRIMARY.darkened(0.15)`) + border_width 3 —
"solid, sunken". These are opposite alpha/lightness directions from each
other, which is the key legibility trick for an outline-style button where
bg fill is mostly transparent so color alone is a weak signal.

**Found but NOT bundled into the spec without separate sign-off**: no call
site anywhere sets `font_color`/`font_hover_color`/`font_pressed_color` on a
*primary* button — text falls back to Godot's default light font color, which
is ~2.2:1 contrast on `PRIMARY` (#FF9345), failing AA even for large bold
text. Dark text (`DangoTheme.BG`) would give ~9.5:1. Flagged as a related but
separate scope item since it changes the existing "normal" look, which the
hover/pressed/disabled ask didn't cover — don't silently fix contrast bugs
while asked only for missing states; surface them.

**Godot API note for implementers**: Button has 4 *separate* font color theme
keys (`font_color`, `font_hover_color`, `font_pressed_color`,
`font_disabled_color`) — not one key reused. Easy to miss since StyleBox
override keys (`normal`/`hover`/`pressed`/`disabled`) look parallel but font
color keys have the `font_` prefix pattern instead.
