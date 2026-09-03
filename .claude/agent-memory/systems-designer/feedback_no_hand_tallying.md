---
name: no-hand-tallying
description: Never hand-derive counts or RP totals in this project; ask for a measurement instead, and validate the check itself before trusting a green result
metadata:
  type: feedback
---

Do not hand-tally totals (RP sums, relic counts, band membership, "which relics share a token")
and present them as evidence. Ask for the measurement and let a tool adjudicate.

**Why:** hand-derived counts in this project have been wrong every time they were checked.
`gen_faces.mjs` adjudicated the face tables after hand-counting failed repeatedly; a distinct-face
figure was hand-counted as 201 and measured as 190. `tools/t_relic.mjs` plays that role for relic
balance.

**How to apply:**
- **If I have no Bash tool, ask the coordinator to run commands** — they will run anything and
  report exact output. Write a throwaway script in the scratchpad and ask for it. Do not fall back
  to reasoning over the file by eye; that is when the errors happen.
- Copy authoritative numbers from the source audit rather than recomputing them, and say which tool
  is the arbiter.
- Reserve my own arithmetic for structural reasoning (why a change is needed), not for totals.

**The checks themselves are the top failure mode here — seven incidents, all "a check that could
not see what it claimed to check".** This became `relic-system.md` AC-25. Before trusting a green:

1. **Measure shipped reality, not the model that produced the check.** Run over real `RELICS` /
   `HEROES` / `FACE_POOL`, never a generated ideal domain. A synthetic 6-slot × 8-type die invented
   `horn ∧ shield`, which does not exist, and hid a whole dead-draw pair.
2. **Prove the check can fail** — mutate a known-good input and confirm it goes red. A check that
   has never failed is indistinguishable from one that tests nothing.
3. **Compare the SET of failing units, not the count.** A mutation landing inside an already-failing
   unit leaves the count unchanged, so a count-based gate reports "cannot fail" while it is actually
   catching the mutation. This bit my own verifier.
4. **Type-check any cell read by column index.** An off-by-one column returned a rarity (`1`) where
   an RP (`43.00`) was expected — valid-looking, silently wrong, no alarm.
5. **Hold out a column and validate against it.** Fitting `V_out` to `RP sau` and then reproducing
   the untouched `RP trước` column 8/8 is what separates "model recovered" from "numbers fitted".

Related: [[project-relic-system-inv1]].
