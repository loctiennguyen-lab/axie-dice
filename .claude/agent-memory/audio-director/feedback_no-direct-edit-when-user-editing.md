---
name: no-direct-edit-when-user-editing
description: Deliver full code in the chat response instead of using Write/Edit when the user is concurrently hand-editing src/client.html
metadata:
  type: feedback
---

When the user says they are editing `src/client.html` in parallel, do NOT use
Write/Edit tools on that file (or any file they're actively touching) even if
asked to "design and write complete code." Instead, return the complete,
ready-to-paste code in the final chat message and tell them exactly where to
insert it (function name / line anchor).

**Why:** the user runs a single-file HTML build (`src/client.html`, ~2.4MB) and
edits it by hand alongside agent sessions. A concurrent Write/Edit from an
agent can race with their manual edits and silently lose work — there is no
merge step, just whichever write lands last.

**How to apply:** before touching `src/client.html` (or any file explicitly
flagged as "I'm editing this now"), confirm whether the user wants the change
applied by the agent or just handed over as text. Default to handing over text
when in doubt for this specific file. This is a per-request constraint, not a
permanent ban — re-check each session since the user may finish their manual
edit pass and want direct edits again next time.
