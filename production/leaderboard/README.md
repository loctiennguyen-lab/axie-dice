# Leaderboard — how a score gets here

Nothing in this folder is trusted. `LEADERBOARD.md` is generated from what the referee
computed by replaying each run, and the referee never reads a score from a submission,
because a submission does not contain one.

## The pieces

| Path | What it is |
|---|---|
| `records/` | Submitted run records. Each is the JSON the game writes from **Result → SAVE RUN RECORD**: seed, team, mode, ascension, and the ordered list of decisions. No score. |
| `golden/` | Real runs whose score was written down on the machine that played them, with an `.expected.json` beside each. These are the **cross-platform determinism check**, not samples. |
| `verdicts/` | Output. Wiped and rebuilt every verification; not committed. |
| `LEADERBOARD.md` | Output. Rebuilt by CI from the verdicts. |

## Submitting a run

1. Finish a **Ranked** run. On the result screen press **SAVE RUN RECORD** — it writes a JSON
   file and shows you the path.
2. Add that file to `production/leaderboard/records/` and open a pull request.
3. `.github/workflows/verify-runs.yml` replays it and reports the score it computed. A record
   that does not verify turns the check red, **with the reason** — a typo'd file, a run played
   on older rules, and a tampered log each say something different.

Locally, the same thing, same script:

```bash
tools/verify_runs.sh                       # golden + every record
tools/verify_runs.sh path/to/record.json   # just one
```

## What this is not

It is not a live submit endpoint. A game client cannot push to this repository without
carrying a credential, and a credential shipped inside a game is a credential everybody has.
This covers a closed beta and proves the whole pipeline end to end; a public ranked board
still needs a small always-on endpoint in front of it one day
(`docs/architecture/adr-0004-headless-godot-is-the-referee.md`).

## Why the golden records matter more than they look

The game is recorded on one machine and replayed on another — a Mac on someone's desk, a
Linux x86 runner in CI. If the same run scores differently on the two, then an honest player
is called a cheat by a referee running elsewhere, and no amount of anti-cheat can fix that,
because the anti-cheat *is* the thing disagreeing. `verify_runs.sh` checks the golden records
first and refuses to score a single submission while one of them disagrees.
