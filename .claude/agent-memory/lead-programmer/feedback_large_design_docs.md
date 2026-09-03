---
name: feedback-large-design-docs
description: For 1000+ line design docs, write code first and grep for facts on demand instead of reading the doc linearly
metadata:
  type: feedback
---

When implementing from a very large design doc (e.g. `design/gdd/part-skill-identity.md`,
~3400 lines), do NOT read it linearly before writing code. Make an edit every turn and
`grep -n` for the single fact the next line depends on. If a verified generator/tool already
implements the derivation chain, read *that* instead of the prose.

**Why:** I burned 21 turns reading and left `src/` untouched; the coordinator stopped me and
said the generator agent had hit the identical failure and only recovered by switching to
write-first. The doc cannot be held in one context, and a passing tool
(`node tools/gen_faces.mjs --check --strict`) is guaranteed to match the spec while the prose
is not.

**How to apply:** kicks in for any task where the spec exceeds roughly 1000 lines, or where a
tool/test already encodes the spec. Order work so every step leaves the tree testable, and
prefer one working core function over five half-finished edits.

Related: [[project-axiedice-verification-baselines]]
