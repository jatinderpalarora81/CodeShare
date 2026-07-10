---
description: 'Coding standards for defect fixes in the Shareworks Java monolith. Applied to all Java source and test changes.'
applyTo: '**/*.java'
---

# Shareworks Java Fix Standards

These rules apply to every change made by agents (and humans) fixing defects in the monolith. Fill `<<CUSTOMIZE>>` items to match your actual conventions.

## Scope discipline

- Minimal diff: fix the defect and nothing else. No opportunistic refactoring, reformatting, import reordering, or dependency changes in a defect-fix PR.
- Match the surrounding code's style, even where it differs from modern preference. Consistency beats fashion inside a monolith.
- New code follows the module's existing patterns for DI, transactions, and error handling — check `docs/codebase/CONVENTIONS.md` first.

## Money & time correctness (stock plan platform)

- Monetary values: `BigDecimal` only — never `double`/`float`. Always specify scale and `RoundingMode` explicitly; use the platform's money utility if one exists: `<<CUSTOMIZE: e.g. com.solium.common.money.Money>>`.
- Share quantities: respect fractional-share rules of the module; do not assume integers.
- Dates: vesting/exercise/tax dates are business dates — use the platform's date utilities and participant/plan timezone rules: `<<CUSTOMIZE: date utility class>>`. Never `new Date()` / system-default timezone in domain logic.
- DST, leap years, and month-end arithmetic are recurring defect sources — when touching date math, add tests for Feb 29, DST transitions, and month-end.

## Defensive patterns

- Do not "fix" an NPE with a bare null check unless the RCA established that null is a *legal* state. Otherwise fix the contract violation at its source.
- No blanket `try/catch (Exception e)` that swallows or merely logs. Preserve the failure semantics the callers rely on.
- Batch jobs must remain idempotent and re-runnable: a fix must not introduce state that breaks re-execution after partial failure.
- Preserve transactional boundaries; do not move DB writes across transaction lines to make a test pass.

## Logging

- Log at the point of failure with the correlation ID field: `<<CUSTOMIZE: MDC key>>`.
- NEVER log PII: no participant names, emails, SSN/SIN, account numbers, grant quantities, or monetary amounts. Log internal IDs only.
- No `System.out.println`, no `printStackTrace()`.

## Testing

- Framework: `<<CUSTOMIZE: e.g. JUnit 5 + Mockito + AssertJ>>`. Follow existing test-class naming: `<<CUSTOMIZE: e.g. ClazzTest>>`.
- Every defect fix ships with a test that fails without the fix and passes with it.
- Test data is synthetic — never copied from production logs or databases.
- Assert behavior, not implementation: prefer asserting outputs/state over verifying internal call sequences.

## Compatibility

- Persisted data formats, API response shapes, and report layouts are contracts — do not change them in a defect fix without flagging it as a breaking follow-up.
- Feature flags: if the defective code is behind a flag, state the flag and test both states.
