---
name: sw-stacktrace-to-code
description: 'Map a Java stack trace from Shareworks production logs to files and lines in the monolith repository. Use during root-cause analysis to find the topmost application frame, skip framework/generated frames, and translate packages to repo modules.'
---

# Stack Trace → Code Mapping (Shareworks Monolith)

Rules for converting a sanitized production stack trace into repo locations worth reading. Fill every `<<CUSTOMIZE>>` before first use.

## 1. Application package roots (CUSTOMIZE ME)

Frames matching these prefixes are *application frames* — everything else is framework/library:

```
<<CUSTOMIZE: e.g.
com.solium.
com.shareworks.
>>
```

## 2. Frame-skipping rules

Walk the trace top-down; the first frame matching an application package root is the **primary frame** (your entry wound). While walking:

- SKIP framework frames: `java.*`, `javax.*`, `jakarta.*`, `sun.*`, `org.springframework.*`, `org.hibernate.*`, `org.apache.*`, `com.fasterxml.*`, servlet containers
- SKIP generated/proxy frames: `$Proxy`, `$$EnhancerBy`, `$$FastClass`, `GeneratedMethodAccessor`, lambda frames (`lambda$`) — but note the enclosing class
- SKIP infrastructure app frames listed here (logging wrappers, generic interceptors): `<<CUSTOMIZE: e.g. com.solium.common.logging.*>>`
- For `Caused by:` chains — the DEEPEST `Caused by` is usually the true origin; map its primary frame first, then the outer ones for the call context

## 3. Package → module/path mapping (CUSTOMIZE ME)

| Package prefix | Repo path | Domain |
|---|---|---|
| `<<e.g. com.solium.vesting>>` | `<<e.g. src/main/java/com/solium/vesting>>` | Vesting engine |
| `<<e.g. com.solium.exercise>>` | `<<...>>` | Exercise & release |
| `<<e.g. com.solium.tax>>` | `<<...>>` | Tax withholding |
| `<<e.g. com.solium.reporting>>` | `<<...>>` | Reporting |
| `<<e.g. com.solium.batch>>` | `<<...>>` | Batch jobs / schedulers |

Fallback: derive path from the package (`com.x.y.Clazz` → `**/src/main/java/com/x/y/Clazz.java`) and verify with code search — the monolith may have multiple source roots.

## 4. Line-number caveats

- Line numbers are from the **deployed** build. Before trusting `Clazz.java:412`, confirm the file at the deployed version/tag (`git show <deploy-tag>:<path>`), not just `main`.
- `Unknown Source` / `Native Method`: fall back to method name + code search.
- If line and method don't match on the deploy tag, the artifact may be stale/hotfixed — flag this; it is itself a finding.

## 5. Entry-point identification

After locating the primary frame, walk DOWN the trace (earlier frames) to classify how the code was invoked:

- HTTP request → controller/servlet frame → note the endpoint
- Scheduled/batch → scheduler or job frame → note the job name
- Queue/event consumer → listener frame → note the queue/topic

The dossier's affected-endpoint list must be consistent with this classification; a mismatch means you mapped the wrong frame.

## 6. Output format

```
PRIMARY FRAME : com.solium.vesting.VestingCalculator.calculateTranche (VestingCalculator.java:412)
REPO PATH     : src/main/java/com/solium/vesting/VestingCalculator.java  [verified @ deploy tag v2026.06.2]
INVOKED VIA   : batch — NightlyVestingJob
CAUSED-BY ROOT: java.lang.NullPointerException (deepest cause)
CALL CONTEXT  : NightlyVestingJob.run → GrantService.processVesting → VestingCalculator.calculateTranche
```
