# Dreaming State — the spine

This file is the spine for the dreaming loop. It tracks what's been analyzed
and prevents re-analysis. Read it first, write it last.

## Format

```yaml
last_analysis: YYYY-MM-DD
analyzed_entries:
  - repo: path/to/progress.md
    entries_analyzed: N
    failures_found: N
    proposals_made: N
```

## Current state

```yaml
last_analysis: 2026-08-18
analyzed_entries:
  - repo: docs-freshness/progress.md
    entries_analyzed: 3
    failures_found: 2
    proposals_made: 1
```

## History

- 2026-08-18 status=OK failures=3 proposals=1 (proposed rule for: forgot to run tests before claiming success)
