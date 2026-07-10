# Defect Dossier — SW-TRIAGE-YYYYMMDD-nn

| Field | Value |
|---|---|
| **Severity** | P1 / P2 / P3 — justification |
| **Signature** | `ExceptionClass @ com.solium.module.Clazz.method` |
| **Normalized message** | `...` with `<ID>`, `<TS>`, `<UUID>` placeholders |
| **Status vs. baseline** | NEW / SPIKING (n× 7-day baseline) / steady-elevated |
| **First seen** | 2026-07-09 22:14 UTC (± nearest deploy marker) |
| **Last seen** | 2026-07-10 06:02 UTC |
| **Event count (window)** | 1,284 events / last 24h |
| **Distinct requests** | 312 correlation IDs |
| **Distinct sessions** | 97 |
| **Affected endpoints / jobs** | `POST /exercise/confirm`, `NightlyVestingJob` |
| **Invocation type** | interactive / batch / queue-consumer |
| **Suspected release window** | deploy v2026.07.1 @ 2026-07-09 21:50 UTC |

## Representative stack trace (sanitized)

```
<full trace including all Caused-by chains>
```

## Reproducing SPL

```spl
<final queries, verbatim>
```

## Notes & caveats

- <clustering decisions, log gaps, sampling caveats>

## Triage recommendation

- <investigate now / today / backlog> → hand to `sw-root-cause`
