# RCA Report — <Dossier ID> / <Jira ID>

**Defect:** <one-line summary>
**Analyst:** sw-root-cause agent, <date>
**Confidence:** High / Medium / Low — <reason>

## Root cause

When `<input/state>`, `<Clazz.method @ path/File.java:line>` does `<wrong thing>`, producing `<logged exception/failure>`.

## Evidence chain

1. **Log** — <signature, volume, first-seen, affected vs. unaffected paths> (Dossier <ID>)
2. **Code** — `<file:line verified at deploy tag vX>`: <what the code does and why it fails on this input>
3. **Change** — <commit/PR, merged date, deployed date>: <why this diff touches the failing path>
   *(or: no code change implicated — data/config/scale evidence: <...>)*

## Why this explains all the facts

- Message pattern: <...>
- Volume & trend: <...>
- Affected paths: <...>
- **Unaffected paths:** <why the mechanism spares them>

## Alternatives ruled out

| Hypothesis | Killed by |
|---|---|
| <alt 1> | <evidence> |
| <alt 2> | <evidence> |

## Blast radius

- Flows affected: <...>
- Scale: <counts from dossier>
- Persisted bad data: yes/no — <what, since when>

## Fix direction (for sw-fix-engineer)

<one paragraph: minimal fix shape at the root cause; regression risks; test that should be written first; data-remediation implications>

## Open questions

- <anything that blocks High confidence>
