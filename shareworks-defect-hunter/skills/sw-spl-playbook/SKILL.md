---
name: sw-spl-playbook
description: 'Curated SPL query library and Splunk conventions for the Shareworks platform. Use whenever searching Shareworks logs in Splunk: error sweeps, signature normalization, baseline/trend comparison, impact scans, and known-noise exclusions. This is the single source of truth for index names, sourcetypes, and field conventions — never invent them.'
---

# Shareworks SPL Playbook

The single source of truth for querying Shareworks logs in Splunk. Agents must use the values defined here and never invent index, sourcetype, or field names. Values marked `<<CUSTOMIZE>>` must be filled in by the Shareworks team before first use — treat unfilled placeholders as a hard stop and ask the engineer.

## 1. Environment reference (CUSTOMIZE ME)

| Item | Value |
|---|---|
| Production app index | `<<CUSTOMIZE: e.g. sw_prod_app>>` |
| Batch/scheduler index | `<<CUSTOMIZE: e.g. sw_prod_batch>>` |
| Web/access index | `<<CUSTOMIZE: e.g. sw_prod_web>>` |
| Application sourcetype(s) | `<<CUSTOMIZE: e.g. log4j, sw:app:json>>` |
| Correlation ID field | `<<CUSTOMIZE: e.g. correlationId>>` |
| Session field | `<<CUSTOMIZE: e.g. sessionId>>` |
| Environment/host field | `<<CUSTOMIZE: e.g. env, host>>` |
| Deploy marker (index or event) | `<<CUSTOMIZE: e.g. index=deploys sourcetype=deploy:event>>` |
| Client/company field (if logged) | `<<CUSTOMIZE>>` |

Aliases used below: `$APP_IDX`, `$BATCH_IDX`, `$ST`, `$CID`.

## 2. Guardrails

- Always bound time: `earliest=-24h latest=now` (default). Hard cap: 7 days.
- Always cap output: `| head 1000` on raw-event queries.
- Never `| delete`, `| collect`, `| outputlookup`, saved-search writes, or any modifying command.
- Sanitize before quoting: strip emails, SSN/SIN-like patterns, account numbers, participant names, monetary amounts.

## 3. Core queries

### 3.1 Error sweep with signature normalization

```spl
index=$APP_IDX sourcetype=$ST earliest=-24h latest=now
  (log_level=ERROR OR log_level=FATAL OR "Exception" OR "ERROR")
| rex field=_raw "(?<exception_class>[A-Za-z0-9_$.]+(?:Exception|Error))"
| rex field=_raw "(?<top_frame>at\s+(?:com\.solium|com\.shareworks|<<CUSTOMIZE: app package roots>>)[^\r\n(]+)"
| eval norm_msg = _raw
| rex mode=sed field=norm_msg "s/\d{4}-\d{2}-\d{2}[T ][\d:.,+Z-]+/<TS>/g"
| rex mode=sed field=norm_msg "s/\b\d{6,}\b/<ID>/g"
| rex mode=sed field=norm_msg "s/\b[0-9a-f]{8}-[0-9a-f-]{27,}\b/<UUID>/g"
| eval signature = coalesce(exception_class,"(no-class)") . " @ " . coalesce(top_frame,"(no-frame)")
| stats count, dc($CID) as distinct_requests, earliest(_time) as first_seen,
        latest(_time) as last_seen, values(source) as sources by signature
| convert ctime(first_seen) ctime(last_seen)
| sort - count
| head 50
```

### 3.2 New-vs-baseline detection

```spl
index=$APP_IDX sourcetype=$ST earliest=-8d latest=now
  (log_level=ERROR OR log_level=FATAL)
| rex field=_raw "(?<exception_class>[A-Za-z0-9_$.]+(?:Exception|Error))"
| eval window=if(_time >= relative_time(now(), "-24h"), "current", "baseline")
| stats count(eval(window="current")) as current_24h,
        count(eval(window="baseline")) as baseline_7d by exception_class
| eval baseline_hourly = baseline_7d / 168, current_hourly = current_24h / 24
| eval status = case(baseline_7d=0 AND current_24h>0, "NEW",
                     current_hourly > 3*baseline_hourly, "SPIKING",
                     true(), "steady")
| where status!="steady"
| sort - current_24h
```

### 3.3 Impact scan for one signature

```spl
index=$APP_IDX sourcetype=$ST earliest=-24h latest=now "<EXCEPTION_CLASS>"
| stats dc($CID) as distinct_requests,
        dc($SESSION) as distinct_sessions,
        values(uri_path) as endpoints,
        count as events,
        earliest(_time) as first_seen
| convert ctime(first_seen)
```

### 3.4 Timeline around first-seen (release correlation)

```spl
index=$APP_IDX sourcetype=$ST earliest=<FIRST_SEEN-4h> latest=<FIRST_SEEN+1h> "<EXCEPTION_CLASS>"
| timechart span=5m count
```

Cross-check against deploy markers: `<<CUSTOMIZE: deploy marker query>>`.

### 3.5 Full stack trace retrieval (for the dossier)

```spl
index=$APP_IDX sourcetype=$ST earliest=-24h "<EXCEPTION_CLASS>" "<TOP_FRAME_CLASS>"
| head 3
| table _time, $CID, _raw
```

Take ONE representative trace; sanitize before quoting.

### 3.6 Batch job failures

```spl
index=$BATCH_IDX earliest=-24h (status=FAILED OR "job failed" OR log_level=ERROR)
| stats count, latest(_time) as last_seen, values(job_name) as jobs by exception_class
| convert ctime(last_seen)
```

## 4. Known-noise exclusion list (CUSTOMIZE ME)

Signatures to discard during triage (append `NOT` clauses to sweeps). Review quarterly — noise lists rot.

| Signature pattern | Reason | Added |
|---|---|---|
| `<<CUSTOMIZE: e.g. ClientAbortException @ ...>>` | user closed browser mid-response | — |
| `<<CUSTOMIZE: e.g. expected retry on lock timeout in job X>>` | auto-retried, alerts separately | — |

## 5. Severity classification reference

- **P1**: NEW or SPIKING and touches money-moving flows (exercise, sale, tax withholding, transfers) OR blocks login/vesting broadly
- **P2**: elevated in a core flow, limited blast radius or workaround exists
- **P3**: threshold-crossing background noise, cosmetic, retry-resolved
