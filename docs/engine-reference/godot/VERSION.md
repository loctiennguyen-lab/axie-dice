# Godot Engine — Version Reference

| Field | Value |
|-------|-------|
| **Engine Version** | Godot 4.7.2 |
| **Release Date** | ~Mid 2026 (4.7 line) |
| **Project Pinned** | 2026-09-17 (corrected from stale 4.6 pin — actual editor installed at `/Users/loc.tien.nguyen/Desktop/Godot.app` is 4.7.2, confirmed via `Info.plist CFBundleShortVersionString`) |
| **Last Docs Verified** | 2026-09-17 |
| **LLM Knowledge Cutoff** | May 2025 |

## Knowledge Gap Warning

The LLM's training data likely covers Godot up to ~4.3. Versions 4.4 through 4.7
introduced changes the model does NOT know about. Always cross-reference this
directory before suggesting Godot API calls.

**Verified 2026-09-17 (for the Axie Dice Godot port, `godot-port` branch)**: checked
4.6→4.7 migration notes specifically for the subsystems this port's architecture
depends on — autoload/singleton pattern, `Tween`, `ParallaxBackground`/`ParallaxLayer`,
`Control` focus system, `Resource` loading/caching, `AnimationPlayer`, `RefCounted`,
GDScript signals. **No breaking changes found** for any of these in 4.7. Only two
unrelated changes: `RichTextLabel.add_image()` param rename
(`width_in_percent`/`height_in_percent` → `width_unit`), and `Control.accessibility_live`
moving from `DisplayServer.AccessibilityLiveMode` to
`AccessibilityServer.AccessibilityLiveMode` — neither used by this project (2D-only,
no RichTextLabel image embedding planned, no accessibility API usage yet).

## Post-Cutoff Version Timeline

| Version | Release | Risk Level | Key Theme |
|---------|---------|------------|-----------|
| 4.4 | ~Mid 2025 | MEDIUM | Jolt physics option, FileAccess return types, shader texture type changes |
| 4.5 | ~Late 2025 | HIGH | Accessibility (AccessKit), variadic args, @abstract, shader baker, SMAA |
| 4.6 | Jan 2026 | HIGH | Jolt default, glow rework, D3D12 default on Windows, IK restored |
| 4.7 | ~Mid 2026 | LOW (for this project) | RichTextLabel `add_image` param rename, accessibility API namespace move — no impact on 2D turn-based combat/UI architecture used here |

## Verified Sources

- Official docs: https://docs.godotengine.org/en/stable/
- 4.6→4.7 migration: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html
- 4.5→4.6 migration: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.6.html
- 4.4→4.5 migration: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.5.html
- Changelog: https://github.com/godotengine/godot/blob/master/CHANGELOG.md
- Release notes: https://godotengine.org/releases/4.6/
