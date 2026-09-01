---
name: feedback-orchestrator-collaboration-mode
description: When invoked by an orchestrator/parent agent as a background task (not a live human user chat), the "ask before writing files" protocol is explicitly waived by the caller — write directly.
metadata:
  type: feedback
---

When the calling prompt is from an orchestrator agent (not a live human user turn) and explicitly
states the collaboration/approval protocol is waived for this task ("đây là task nền tự động, cứ
viết thẳng, tôi sẽ review sau" — 2026-09-01, `docs/art/visual-redesign-2026-09-01.md`), write the
target file directly without pausing for a "May I write this to [path]?" confirmation.

**Why:** the standard collaboration protocol (Question -> Options -> Decision -> Draft ->
Approval, ask before Write/Edit) assumes a live back-and-forth with the actual product owner in
the loop each step. A subagent invocation from an orchestrator is itself already the delegated
go-ahead for the scoped task — waiting for a second approval inside the subagent turn just stalls
the pipeline with no one available to answer.

**How to apply:** still show full reasoning/options in the response (the "Explain" half of the
protocol always applies), and still flag anything the caller should route back to the human owner
for real sign-off (e.g. this spec's "pending creative-director / product-owner sign-off" status
line, and the base64-font-vs-system-font fork left as an explicit open call for
`ui-programmer`/`technical-artist`). Only the *file-write pause* is skipped, and only when the
calling message itself says so — do not assume this applies to a direct human user request.
