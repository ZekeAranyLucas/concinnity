# dot-issues

File-based issue tracking in `.issues/`.

A lightweight workflow for capturing review findings, triaging them interactively, and driving automated fixes — all backed by markdown files in your repo.

## Install

```
/plugin marketplace add ZekeAranyLucas/concinnity
/plugin install dot-issues@concinnity
```

Then run `/reload-plugins`.

## Skills

| Skill | Description |
|-------|-------------|
| `save-issues` | Persists an issue list to the `.issues/` store |
| `show-issues` | Displays open issues from `.issues/` |
| `triage-issues` | Interactively triages issues (accept / reject / skip) |
| `fix-issues` | Drives automated fixing of accepted issues, grouped by file |

## Pairs well with

[`zodiac-team`](https://github.com/ZekeAranyLucas/concinnity/tree/main/plugins/zodiac-team) review skills produce findings that `dot-issues` can triage and auto-fix. Either plugin works standalone — installing both unlocks the full review-to-fix loop.
