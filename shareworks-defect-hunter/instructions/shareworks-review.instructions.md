---
description: 'Self-review gate for agent-generated fixes on the Shareworks monolith. The fix engineer agent must pass every item before presenting a diff for human approval.'
applyTo: '**'
---

# Shareworks Fix Review Gate

A diff may be presented for human approval only when every item below passes. Items that do not apply must be marked N/A with a reason — never silently skipped.

## Correctness

- [ ] The fix addresses the root cause named in the RCA Report, not a symptom upstream/downstream of it
- [ ] The failure mechanism can no longer occur for ANY path in the Defect Dossier (interactive, batch, queue)
- [ ] A test reproduces the defect (red) and passes with the fix (green); suite and build are green
- [ ] Edge cases enumerated and covered where relevant: null, zero, negative, max, DST boundary, leap day, month-end, multi-currency, terminated participant, cancelled/expired grant

## Safety

- [ ] No behavior change for currently-correct inputs (state the reasoning)
- [ ] Money math uses BigDecimal with explicit scale/rounding; no float/double introduced
- [ ] Transactional boundaries and batch idempotency unchanged
- [ ] If bad data was persisted by the bug: "Data remediation" section present in the hand-off (no migration scripts unless requested)

## Security & compliance

- [ ] No PII in code, tests, fixtures, comments, commit messages, or PR text
- [ ] If the diff touches authn/authz, input parsing, SQL, serialization, or logging: security review checklist run and findings noted
- [ ] No new dependencies; no dependency version changes

## Hygiene

- [ ] Diff is minimal — no refactors, reformatting, or unrelated cleanups (adjacent issues listed as Follow-ups instead)
- [ ] Matches module conventions (`shareworks-java.instructions.md`, `docs/codebase/CONVENTIONS.md`)
- [ ] Rollback plan stated (normally: single revert commit)
- [ ] PR body will contain: summary, RCA reference, test evidence, risk notes — and no raw log data
