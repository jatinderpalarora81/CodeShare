#!/bin/bash
# Audit Logger + Splunk write-guard hook for the shareworks-defect-hunter plugin.
#
# 1. Appends a JSONL audit record for every agent session and tool invocation
#    (who/when/what) — supports change-control / SOX evidence requirements.
# 2. When GUARD_SPLUNK_READONLY=true, BLOCKS any Splunk tool call whose input
#    contains modifying SPL commands (| delete, | collect, | outputlookup, etc.).
#
# Env:
#   AUDIT_EVENT            - session_start | tool_use | session_end
#   AUDIT_LOG_DIR          - default .github/logs/copilot/audit
#   GUARD_SPLUNK_READONLY  - "true" to enable the write-guard on tool_use
#   SKIP_AUDIT             - "true" to disable entirely (do not use in prod repos)

set -euo pipefail

[[ "${SKIP_AUDIT:-}" == "true" ]] && exit 0

EVENT="${AUDIT_EVENT:-unknown}"
LOG_DIR="${AUDIT_LOG_DIR:-.github/logs/copilot/audit}"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/audit-$(date -u +%Y%m%d).jsonl"
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
ACTOR="${GITHUB_ACTOR:-${USER:-unknown}}"

INPUT=""
TOOL_NAME=""
TOOL_INPUT=""
if [[ "$EVENT" == "tool_use" ]]; then
  INPUT=$(cat || true)
  if command -v jq &>/dev/null; then
    TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.toolName // empty' 2>/dev/null || echo "")
    TOOL_INPUT=$(printf '%s' "$INPUT" | jq -r '.toolInput // empty | tostring' 2>/dev/null || echo "")
  fi
  [[ -z "$TOOL_NAME" ]] && TOOL_NAME=$(printf '%s' "$INPUT" | grep -oE '"toolName"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:.*"\([^"]*\)"$/\1/' || echo "unknown")
fi

# --- Write-guard: block modifying SPL against Splunk tools -------------------
if [[ "$EVENT" == "tool_use" && "${GUARD_SPLUNK_READONLY:-}" == "true" ]]; then
  if printf '%s' "$TOOL_NAME" | grep -qiE 'splunk'; then
    if printf '%s' "$TOOL_INPUT" | grep -qiE '\|\s*(delete|collect|outputlookup|outputcsv|sendemail)|saved/searches.*(POST|create)|"method"\s*:\s*"(POST|PUT|DELETE)"'; then
      printf '{"ts":"%s","event":"BLOCKED_splunk_write","actor":"%s","tool":"%s"}\n' \
        "$TS" "$ACTOR" "$TOOL_NAME" >> "$LOG_FILE"
      echo "BLOCKED: modifying Splunk operation detected. This plugin is read-only against Splunk." >&2
      exit 1
    fi
  fi
fi

# --- Audit record (metadata only — never log tool payloads, they may hold log data)
printf '{"ts":"%s","event":"%s","actor":"%s","tool":"%s"}\n' \
  "$TS" "$EVENT" "$ACTOR" "${TOOL_NAME:-n/a}" >> "$LOG_FILE"

exit 0
