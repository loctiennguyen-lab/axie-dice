# ADR-0001: Leaderboard Backend Infrastructure

## Status
Accepted (2026-09-01, phiên tiếp theo — product owner yêu cầu implement trực tiếp)

**Vendor cụ thể đã chọn** (Decision section để ngỏ "exact vendor is an implementation detail"): **Vercel Functions + Upstash Redis** (REST API, không dùng SDK — chỉ `fetch()` thuần, khớp tinh thần "không bundler/dependency" của dự án). Sorted-set (`ZADD`/`ZRANGE`) là cấu trúc dữ liệu tự nhiên cho leaderboard, không cần schema SQL. Xem `api/submit-run.js`, `api/leaderboard.js`, `api/_engine.js`.

**MVP scope đã ship — hẹp hơn spec đầy đủ trong `leaderboard-system.md`, ghi rõ để không ai tưởng nhầm đã xong 100%:**
- **1 board/(mode, ascension)** — KHÔNG có tách Standard/Collector. Lý do: tách bảng cần biết chắc 1 run có dùng "quyền chọn-trước NFT" hợp lệ hay không, nhưng progression/Vault hiện chưa sync lên server nên không xác minh được — xem giải pháp "Ranked Run" bên dưới.
- **Không có Daily seed view riêng** — chỉ All-time top-100.
- **"Ranked Run"** (mới, không có trong `leaderboard-system.md` gốc) — cơ chế thay thế tạm cho việc chưa sync progression: khi bật, `newGame()` bị ép `bonusReroll=0, metaHpBonus=0, startRelics=[]` bất kể Unlocks/Pass đã mua gì, và Vault (Import Axie) bị chặn khỏi team — cả server lẫn client đều áp dụng đúng luật này nên không cần server biết META của người chơi. Đây chính là tinh thần "Standard board, ai cũng như nhau" của thiết kế gốc, chỉ khác là MỌI run (không chỉ Standard) đều chơi ở mức baseline thay vì tách riêng 2 bảng.
- Anti-cheat replay (phần khó/quan trọng nhất) đã implement ĐẦY ĐỦ đúng thiết kế: server replay qua chính `src/engine.js`, không bao giờ tin score client gửi. Đã test bằng 1 run thật (139 action) chơi tự động rồi replay qua đúng `api/submit-run.js` — điểm khớp 100%.

**Việc còn lại để vận hành thật** (ngoài phạm vi 1 phiên code): user cần tự tạo Upstash Redis database (upstash.com, free tier đủ dùng cho beta) và set 2 env var `UPSTASH_REDIS_REST_URL`/`UPSTASH_REDIS_REST_TOKEN` trong Vercel Project Settings — không có 2 biến này, `/api/submit-run` vẫn tính điểm đúng nhưng trả về `stored:false` (đã tự verify hành vi graceful-degrade này).

## Date
2026-09-01

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Custom — Vanilla JavaScript/HTML5, no game engine (see `.claude/docs/technical-preferences.md`) |
| **Domain** | Core / Networking (server-side, does not touch client rendering or gameplay code paths) |
| **Knowledge Risk** | LOW — this is a backend infrastructure choice, not a client-engine API dependency. No `docs/engine-reference/` applies (project predates the Godot/Unity/Unreal template assumption). |
| **References Consulted** | `design/gdd/leaderboard-system.md`, `docs/axiedice-source/ORIGINAL_PROJECT_CLAUDE.md` §2-3 (build architecture, engine/UI boundary), `tools/sim.js` (proof that `src/engine.js` already runs headless in Node) |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Confirm chosen serverless platform's Node.js runtime version can execute `src/engine.js` unmodified (it currently targets browser-compatible ES6+, should run as-is in any modern Node runtime — verify no browser-only globals leak into `engine.js`, which the existing engine/DOM boundary rule already forbids) |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None (first ADR in this project) |
| **Enables** | Implementation of `design/gdd/leaderboard-system.md`; any future ADR touching score submission, session auth, or rate-limiting |
| **Blocks** | Any story implementing leaderboard submission/display — cannot start until this ADR is Accepted |
| **Ordering Note** | This ADR only decides *where the backend runs and how scores are verified*. It does NOT decide database schema, auth provider, or rate-limiting specifics — those are implementation details for the stories that follow, constrained by the interface this ADR fixes. |

## Context

### Problem Statement

The project is currently a fully static, serverless artifact: `build.py` concatenates `src/*.js` into one self-contained HTML file, deployed as a static asset (Vercel/Netlify/S3 — see `docs/axiedice-source/ORIGINAL_PROJECT_CLAUDE.md` §2). The product owner has requested a leaderboard (`design/gdd/leaderboard-system.md`) so players can compete — this is the **first feature in the project's history that requires a backend**, since comparing scores across players and preventing trivial client-side score forgery both require server-side state and computation the static-HTML architecture cannot provide.

The leaderboard design already fixes the anti-cheat approach: the server must **replay the player's action log through the actual `src/engine.js`** (the same deterministic, seeded, pure-function engine already proven to run headless in Node via `tools/sim.js`) and only accept the score the replay itself produces — never trust a client-submitted score. This constrains the backend choice: whatever runs the leaderboard backend **must be able to execute real Node.js code**, not just evaluate declarative security rules. That single constraint rules out pure "backend-as-a-service with client-side rules" products (e.g. Firestore/Realtime DB used only via their client SDK and security-rule language) as the *sole* backend — some layer capable of running `engine.js` verbatim in Node is mandatory.

### Constraints

- Must not require the client build to add a bundler, framework, or `node_modules` dependency (`ORIGINAL_PROJECT_CLAUDE.md` §2 — "Không có bundler" is a load-bearing project constraint, unrelated to this decision, but the backend choice must not force client-side changes that violate it).
- Must run `src/engine.js` unmodified (or with minimal, clearly-flagged adaptation) in a server Node.js context — this is the entire basis of the anti-cheat design in `leaderboard-system.md`.
- Must support per-(mode, ascension, Standard/Collector) leaderboard segmentation (44 sub-boards per `leaderboard-system.md`) without requiring a heavyweight ops setup — the project has no existing DevOps/infra team, per its scale (indie/solo-adjacent, static-site deploy history).
- Cost must stay near-zero at low traffic — this is a new, unproven feature; committing to paid infrastructure before validating player interest is premature spend.

### Requirements

- Accept a submitted run (seed, team, mode, ascension, action log) from the client.
- Re-simulate that run server-side using `src/engine.js`, exactly as `tools/sim.js` already does headless.
- Reject (do not record) any submission whose replay fails or produces a different outcome than implied by a normal, rule-following game session.
- Store and serve top-N results per (mode, ascension, Standard/Collector) bucket, plus Daily and All-time views (`leaderboard-system.md`).
- Version-pin the engine used for replay to the engine build active when the run's seed was generated, so a later balance patch (e.g. `docs/balance-log.md` 2026-09-01) does not retroactively invalidate or misscore old submissions.

## Decision

Use a **serverless function platform** (e.g. Cloudflare Workers, Vercel Functions, or equivalent — exact vendor is an implementation detail for the first leaderboard story, not fixed by this ADR) paired with a **lightweight managed database** (e.g. Supabase Postgres, or an equivalent hosted SQL/KV store) for score storage.

This satisfies every constraint above: serverless functions run real Node.js/JS, so `src/engine.js` can be `require`'d or bundled into the function exactly as `tools/sim.js` already proves is possible; both serverless functions and the managed-DB tier have generous free/near-zero tiers appropriate for an unproven, low-initial-traffic feature; neither requires standing up or maintaining a server process, matching the project's zero-ops history; and the client remains a static single HTML file that simply makes authenticated `fetch()` calls to the function endpoints — no bundler, no client framework change.

### Architecture Diagram

```
┌─────────────────────┐        POST /submit-run          ┌──────────────────────────┐
│  Client (static      │  {seed, teamKeys, mode,          │  Serverless Function       │
│  build/index.html,   │──asc, nftPreselect[], actions[]}─▶│  (replay + verify)         │
│  unchanged)          │                                   │                            │
│                      │◀───────── {accepted, score} ──────│  1. require src/engine.js  │
└─────────────────────┘                                    │  2. newGame(seed,...)      │
         │                                                  │  3. replay actions[] via   │
         │  GET /leaderboard?mode=&asc=&board=&period=     │     same calls tools/sim.js│
         ▼                                                  │     already uses           │
┌─────────────────────┐                                    │  4. compute Score from     │
│  Serverless Function  │◀──── query top-N ─────────────────│     replay result only     │
│  (read leaderboard)  │                                    │  5. write to DB if valid   │
└─────────────────────┘                                    └──────────────┬─────────────┘
         │                                                                 │
         ▼                                                                 ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  Managed DB (scores table, per mode/asc/board/period; engine_version column) │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Key Interfaces

- **`POST /submit-run`** — body: `{seed: number, teamKeys: string[], mode: 'short'|'full', ascension: 0-10, nftPreselect: string[], actions: Action[], engineVersion: string}`. Response: `{accepted: boolean, score?: number, reason?: string}`. The function computes `score` itself from the replay — a client-submitted score field, if present, is ignored (per `leaderboard-system.md` Acceptance Criteria).
- **`GET /leaderboard`** — query params `mode`, `ascension`, `board` (`standard`|`collector`), `period` (`daily`|`alltime`). Returns top-N rows: `{rank, displayName, score, mode, ascension, board, submittedAt}`.
- **Engine versioning**: each deployed build of `src/engine.js` is tagged with a version string (e.g. a short git SHA or semver bumped alongside `docs/balance-log.md` entries). The function replays using the version pinned at the time the seed was issued, and the `scores` table records `engine_version` per row — satisfying the "Edge Cases" requirement in `leaderboard-system.md` about balance patches not retroactively invalidating old submissions. Exact versioning mechanism (git SHA vs. manual semver file) is left to the implementing story.

## Alternatives Considered

### Alternative 1: Self-hosted Node server (Express/Fastify + SQLite or Postgres, on a VPS)
- **Description**: Stand up and operate a small always-on Node.js server process, own the database, own the deploy pipeline.
- **Pros**: Full control over runtime, no vendor lock-in, no per-invocation cold-start latency, simplest mental model for a team already comfortable with the existing `python3 build.py` / `tools/serve.py` local-dev pattern.
- **Cons**: Requires ongoing ops (uptime, patching, scaling, backups) the project has never needed before; introduces a fixed cost floor even at zero traffic; a solo/small team taking on server ops is a meaningfully bigger commitment than the "backend nhẹ" (lightweight backend) the product owner explicitly asked for.
- **Rejection Reason**: Violates the "lightweight" framing of the accepted decision and adds ops burden disproportionate to an unvalidated, early-stage feature. Revisit if/when leaderboard traffic and the broader product (e.g. the NFT/backend-dependent features already flagged as Phase 2+ in `docs/review-2026-08-31.md`) justify dedicated infrastructure.

### Alternative 2: Pure BaaS via client SDK + security rules only (e.g. Firestore/Realtime DB, no Cloud Functions)
- **Description**: Client writes scores directly to a managed database, gated only by declarative security rules (no server-side code execution).
- **Pros**: Fastest possible time-to-ship, zero backend code to write or maintain, generous free tiers.
- **Cons**: Cannot execute `src/engine.js` to replay-verify a run — security rules are a declarative constraint language, not a general-purpose runtime. This directly breaks the anti-cheat design that `leaderboard-system.md` treats as the entire point of the system ("Score gian lận không bao giờ xuất hiện trên bảng" — a fabricated score would need to be rejected by *running the actual game logic*, not by a rule like "score < some cap").
- **Rejection Reason**: Structurally incompatible with the accepted anti-cheat approach. Could be reconsidered only if the leaderboard's integrity bar were lowered to "trust client scores" — the product owner has not indicated that tradeoff is acceptable, and it would undermine the "minh bạch triệt để" pillar this system is explicitly built to extend (`leaderboard-system.md` Player Fantasy).

## Consequences

### Positive
- Anti-cheat is provably correct rather than heuristic: the same `engine.js`/`tools/sim.js` pattern already validated in this codebase extends directly to server-side replay, with no new game-logic code to write or keep in sync.
- Near-zero cost and near-zero ops burden at launch, appropriate for an unproven feature.
- Client remains a static single-file build — the project's core architectural identity (`ORIGINAL_PROJECT_CLAUDE.md` §2) is untouched; only new, additive `fetch()` calls are introduced.
- Segmented, versioned leaderboard design (44 sub-boards, engine-version-pinned replay) is fully supportable by a managed SQL/KV store without custom infrastructure.

### Negative
- Introduces the project's first external vendor dependency (serverless platform + managed DB) — a meaningful precedent, since every prior system in this project has been self-contained.
- Cold-start latency on serverless functions may make `/submit-run` feel slower than a warm dedicated server, especially at low traffic where functions scale to zero between calls — acceptable for a post-run, non-blocking submission but worth monitoring.
- `src/engine.js` now has two consumers with different failure tolerances: the client (`build.py` output, must never crash mid-combat) and the server (replay function, must reject cleanly on any malformed/adversarial input) — the engine/DOM boundary rule already protects the first; a new discipline (defensive replay-input validation) must be added for the second, and is not yet specified (left to the implementing story).

### Risks
- **Vendor lock-in to the chosen serverless platform's specific API shape.** *Mitigation*: keep the replay function's core logic (import engine.js, replay actions, compute score) as a plain, platform-agnostic module; only the thin request/response adapter should be platform-specific, so migrating vendors later is a small adapter rewrite, not a logic rewrite.
- **`src/engine.js` may contain assumptions that only hold in a browser context** (untested — the engine/DOM boundary rule claims purity, but this has only been exercised via `tools/sim.js`'s specific harness, not a production serverless runtime). *Mitigation*: the first implementing story must smoke-test `engine.js` execution inside the actual chosen serverless runtime (not just local Node) before any player-facing submission path ships.
- **Balance patches changing `engine.js` mid-flight could desync client and server score expectations if engine versioning (Key Interfaces) is implemented incorrectly.** *Mitigation*: explicit acceptance criterion in `leaderboard-system.md` already requires version-pinned replay; the implementing story must include a test that replays a pre-patch action log against the pre-patch engine version and confirms the score matches what was originally computed, even after `docs/balance-log.md` records a later patch.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|---------------------------|
| `design/gdd/leaderboard-system.md` | "Nộp điểm & xác thực" — server re-runs `engine.js` from action log, never trusts client-submitted score | Decision section fixes a serverless-function backend specifically because it can execute `engine.js` in Node, unlike a rules-only BaaS (see Alternative 2, rejected) |
| `design/gdd/leaderboard-system.md` | 44 sub-boards (mode × ascension × Standard/Collector), Daily + All-time views | Key Interfaces' `GET /leaderboard` query shape and the managed-DB schema support this segmentation without custom infra |
| `design/gdd/leaderboard-system.md` Edge Cases | "Replay không khớp do version engine.js đổi giữa lúc chơi và lúc server xử lý" | Key Interfaces specifies `engineVersion` field and per-row `engine_version` storage; Risks section requires the implementing story to test this explicitly |
| `.claude/docs/technical-preferences.md` | "Không có bundler... một file HTML tự chứa" (client architecture constraint) | Decision explicitly requires the client to remain unchanged except for additive `fetch()` calls — no bundler or framework introduced |

## Performance Implications
- **CPU**: Each `/submit-run` call re-executes a full game simulation (comparable cost to one `tools/sim.js` iteration) — bounded by the existing per-run turn cap (`s.turn>45` convention used in `tools/sim.js`), so worst-case function execution time is bounded and predictable.
- **Memory**: Minimal — `engine.js` state is a small deep-cloneable object (already proven via the existing undo/snapshot system, `pushUndo`/`SNAP` in `src/engine.js`); no large asset loading needed server-side (art/audio assets stay client-only).
- **Load Time**: Not applicable to the static client build; `/leaderboard` reads are simple indexed queries against a small per-bucket row count (top-N), expected to be fast on any managed SQL/KV store.
- **Network**: New outbound calls from a previously fully-offline-capable client. Must be designed as non-blocking / best-effort (a failed submission should not disrupt local gameplay) — matches Edge Cases in `leaderboard-system.md` ("Client mất kết nối giữa chừng khi đang nộp điểm").

## Migration Plan
No existing code migrates — this is wholly additive. The client's existing local save/resume (`localStorage`, per `AUDIT_AND_SPEC_v1.md` §A2.12/E1) is unaffected; leaderboard submission is a new, optional, best-effort network call appended after a run ends, not a replacement for any existing system.

## Validation Criteria
- A submitted run with a forged/inflated score field is rejected or corrected to the replay-computed value (never records the forged number) — direct test of the anti-cheat property this ADR exists to enable.
- A submitted run replayed through a different `engine_version` than the one active at submission time is rejected or clearly flagged, per the versioning requirement.
- `tools/sim.js`-equivalent replay logic, when run inside the actual chosen serverless runtime (not just local `node`), produces identical results to local `node tools/sim.js` for the same seed/actions — validates the "Risks" concern about browser-context assumptions leaking into `engine.js`.
- Cost at low traffic (first weeks post-launch) stays within the platform's free/near-zero tier — validates the "lightweight backend" framing this ADR was built around.

## Related Decisions
- `design/gdd/leaderboard-system.md` — the gameplay/design spec this ADR makes implementable.
- `docs/axiedice-source/design/AUDIT_AND_SPEC_v1.md` §G8 — the NFT hybrid pre-select decision that motivates the Standard/Collector board split this ADR's schema must support.
- `docs/balance-log.md` — precedent for how `TUNE` constants change over time; motivates the engine-versioning requirement here.
