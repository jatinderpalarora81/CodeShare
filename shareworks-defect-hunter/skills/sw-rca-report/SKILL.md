---
name: sw-rca-report
description: 'Output contract for root-cause analysis of Shareworks defects. Use when concluding an RCA: fill the blameless RCA Report template with an evidence chain (log event → code line → causing change), an honest confidence level, alternatives ruled out, and a fix direction for the fix engineer.'
---

# RCA Report

The standard hand-off artifact from root-cause analysis to fix engineering (and, later, to the post-incident record). Blameless by construction: systems and processes fail, not people — write "the code did not handle X", never "developer Y missed X".

Use the template at `templates/rca-report.md`.

## Field rules

- **Root cause statement**: ONE sentence in the exact mechanism form: "When `<input/state>`, `<code at file:line>` does `<wrong thing>`, producing `<the logged failure>`."
- **Evidence chain**: minimum three links — (1) log evidence from the dossier, (2) code evidence with file:line verified at the deployed tag, (3) change evidence (commit/PR + why its diff touches the failing path) or an explicit statement that no code change is implicated (then: data/config/scale evidence).
- **Confidence**: High / Medium / Low with the specific reason. High requires the mechanism to explain every dossier fact, including which paths are NOT affected.
- **Alternatives ruled out**: at least two, each with the evidence that killed it.
- **Blast radius**: what flows/participants/companies are affected; whether bad data was persisted (this drives the fix engineer's data-remediation section).
- **Fix direction**: one paragraph — the shape of the minimal fix at the root cause, plus regression-risk notes. Not a diff.
- **No PII** anywhere.
