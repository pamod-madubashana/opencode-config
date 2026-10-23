# Completion Discipline

- Never end a turn while any todo is still `pending` or `in_progress`. Continue executing the next pending item immediately.
- Do not stop to "show remaining tasks" or present a task list as a stopping point. Remaining work may only appear as a progress note inside an ongoing run.
- Only produce a final summary when every todo is `completed` (or explicitly `cancelled` with a reason). If blocked, state the blocker and the single next action needed.
- When the user says "don't stop until complete" (or equivalent), treat it as a hard constraint: keep working through all pending todos in the same run; do not yield between items.
- After a specialist returns, synthesize and immediately proceed to the next pending todo. Do not wait for the user to say "continue".
