---
name: sw-defect-dossier
description: 'Output contract for Splunk triage of Shareworks defects. Use when emitting a triaged defect: fill the Defect Dossier template completely, with sanitized log excerpts and reproducible SPL. Every dossier is the hand-off artifact to root-cause analysis.'
---

# Defect Dossier

The standard hand-off artifact from Splunk triage to root-cause analysis. One dossier per deduplicated error signature. Every field is filled or explicitly `unknown` — no silent omissions. All log content sanitized: no participant names, emails, SSN/SIN, account numbers, or monetary amounts.

Use the template at `templates/defect-dossier.md`.

## Field rules

- **Dossier ID**: `SW-TRIAGE-<YYYYMMDD>-<nn>`, sequential per run.
- **Signature**: normalized form — exception class + topmost application frame; message with IDs/timestamps/UUIDs replaced by `<ID>`, `<TS>`, `<UUID>`.
- **Severity**: P1/P2/P3 per the SPL Playbook §5, with a one-line justification.
- **Stack trace**: ONE representative, complete (including all `Caused by:` chains), sanitized. Not a fragment.
- **Impact numbers**: counts only (events, distinct requests, distinct sessions, endpoints/jobs). Never identities.
- **Trend**: `NEW` / `SPIKING (n× baseline)` / `steady-elevated`, with the baseline window used.
- **First seen**: timestamp with timezone; note the nearest deploy marker if one exists.
- **Reproducing SPL**: the final query/queries that produce the dossier's numbers, verbatim, so anyone can re-run them.
- **Confidence caveats**: anything that could make this dossier misleading (sampling, log gaps, multi-signature clustering).
