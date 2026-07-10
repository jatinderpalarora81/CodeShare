# shareworks-defect-hunter

GitHub Copilot plugin that automates the flow **Splunk logs → defect identification → root cause in the Shareworks Java monolith → drafted fix**, with a structural human-approval gate before any PR.

Modeled on patterns from [github/awesome-copilot](https://github.com/github/awesome-copilot) (`new-relic-incident-response`, `aws-incident-triage`, `debug`, `pagerduty-incident-responder`, `tdd-*`, `doublecheck`, `acquire-codebase-knowledge`, `incident-postmortem`, `tool-guardian`/`session-logger`).

## The pipeline

| Stage | Agent | Input → Output |
|---|---|---|
| 1. Triage | `sw-splunk-triage` | error/window/Jira ID → **Defect Dossier** (deduped signature, sanitized trace, impact, trend, reproducing SPL) |
| 2. Root cause | `sw-root-cause` | Defect Dossier → **RCA Report** (evidence chain: log → code line → causing commit, confidence level) |
| 3. Fix | `sw-fix-engineer` | RCA Report → failing test + minimal fix + self-review → **human approval gate** → draft PR |

## What's in the box

```
agents/         sw-splunk-triage, sw-root-cause, sw-fix-engineer (.agent.md)
skills/         sw-spl-playbook        SPL library + index/field conventions  ← CUSTOMIZE
                sw-stacktrace-to-code  trace→repo mapping rules               ← CUSTOMIZE
                sw-defect-dossier      triage output contract + template
                sw-rca-report          RCA output contract + template
instructions/   shareworks-java        fix coding standards (money/time/tests) ← CUSTOMIZE
                shareworks-review      self-review gate before human approval
hooks/          audit-logger           JSONL audit trail + Splunk write-guard
mcp/            splunk-mcp.json        Splunk MCP server config (2 options)
```

## Setup

1. **Splunk MCP server** — pick one in `mcp/splunk-mcp.json`:
   - Option A: [official Splunk MCP Server](https://splunkbase.splunk.com/app/7931) (Splunk Cloud / Enterprise 9.4+)
   - Option B: [splunk/splunk-mcp-server2](https://github.com/splunk/splunk-mcp-server2) self-hosted, with SPL guardrails + output sanitization (recommended if logs may contain PII)

   Create a **read-only** service account scoped to the Shareworks indexes (see `$security_requirements` in the file). Copy the `servers` block into `.vscode/mcp.json` (VS Code) and/or repo Settings → Copilot → Coding agent → MCP configuration.

2. **Customize the placeholders** — search the repo for `<<CUSTOMIZE` and fill in:
   - `skills/sw-spl-playbook/SKILL.md` — index names, sourcetypes, correlation-ID field, deploy markers, known-noise list (highest-leverage file in the plugin)
   - `skills/sw-stacktrace-to-code/SKILL.md` — application package roots, package→module map
   - `instructions/shareworks-java.instructions.md` — money/date utility classes, test framework, MDC key

3. **Generate the codebase map (Phase 0)** — run the awesome-copilot skill [`acquire-codebase-knowledge`](https://github.com/github/awesome-copilot/tree/main/skills/acquire-codebase-knowledge) on the monolith to produce `docs/codebase/`. The RCA agent uses it to navigate instead of blind-grepping. Refresh periodically.

4. **Install the plugin** into the monolith repo (copy folders, or once published to a marketplace: `copilot plugin install shareworks-defect-hunter@<marketplace>`). Make the hook executable: `chmod +x hooks/audit-logger/audit-log.sh`.

## Usage (Phase 1 — on-demand)

```
@sw-splunk-triage what's spiking in prod since last night's release?
@sw-root-cause take dossier SW-TRIAGE-20260710-01
@sw-fix-engineer implement the fix from that RCA
  → review diff + test evidence → "approved" → draft PR
```

## Guardrails baked in

- Splunk access is read-only twice over: token capabilities AND the `audit-logger` hook blocks modifying SPL (`|delete`, `|collect`, `|outputlookup`, POSTs)
- PII redaction rules in every agent + sanitization at the MCP layer (Option B)
- Human approval is a workflow stage, not a prompt suggestion — `sw-fix-engineer` stops at Phase 5
- Time-boxed searches (24h default / 7d cap, result caps) bound cost
- JSONL audit trail of every session and tool call (metadata only) for change-control evidence

## Later phases

- **Scheduled scan**: GitHub Actions cron runs `sw-splunk-triage` headless via Copilot CLI; new P1/P2 dossiers become GitHub/Jira issues
- **Alert-driven**: Splunk saved-search alert → webhook → `repository_dispatch` → issue assigned to the Copilot coding agent, which runs stages 2–3 and opens a draft PR (human still merges)
