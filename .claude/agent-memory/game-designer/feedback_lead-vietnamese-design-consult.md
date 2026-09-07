---
name: feedback-lead-vietnamese-design-consult
description: This project is worked through a "lead" persona who relays design questions from an end designer/user, communicates in Vietnamese, and enforces a strict discuss-only phase before any file writes.
metadata:
  type: feedback
---

The requester in this project identifies as "the lead" (project coordinator),
not the end designer directly — they relay a summarized design problem
(already having read the code themselves) and explicitly gate the interaction:
"ĐÂY LÀ GIAI ĐOẠN THẢO LUẬN THIẾT KẾ THUẦN TUÝ. KHÔNG được Write/Edit bất kỳ
file nào." (pure design-discussion phase, no Write/Edit tool use at all) —
the output is meant to be carried back to a human user for further discussion,
not written to `design/gdd/` yet.

**Why**: The collaboration protocol in this project already requires
Question → Options → Decision → Draft → Approval, but this lead adds an extra
gate on top: sometimes the ask is *only* the Question/Options phase, with
Draft/Approval deliberately deferred to a separate later session.

**How to apply**: When a message is phrased as a discussion/consult request
(not "write the GDD" or "draft section X"), do not create or edit files even
if the request contains rich structural detail (line numbers, code excerpts,
a clear proposed design) — treat all of that as grounding context for a
text-only analysis. Requests are in Vietnamese; respond in Vietnamese, in the
explicit Question → Options → (recommendation) → Open-questions structure
requested, and verify code claims in the request against the actual repo
before accepting them (see [[class-passive-already-universal]] for a case
where the summarized premise turned out to be stale).
