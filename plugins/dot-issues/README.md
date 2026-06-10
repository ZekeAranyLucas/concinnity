# dot-issues

File-based issue tracking under a per-repo issues directory.

A lightweight workflow for capturing review findings, triaging them interactively, and driving automated fixes — all backed by markdown files in your repo.

## Install

```
/plugin marketplace add ZekeAranyLucas/concinnity
/plugin install dot-issues@concinnity
```

Then run `/reload-plugins`.

## Issues directory resolution

All skills resolve their working directory through `scripts/resolve-issues-dir.sh`. The skills invoke it via `${CLAUDE_PLUGIN_ROOT}/scripts/resolve-issues-dir.sh` and pass `--root "${CLAUDE_PROJECT_DIR}"`; the runtime substitutes both variables (also accepted as `${COPILOT_PLUGIN_ROOT}`/`${PLUGIN_ROOT}` and `${COPILOT_PROJECT_DIR}`) before the skill is rendered. The script returns absolute paths and works even when the user invoked the agent from a subdirectory.

Order of preference:

1. `$DOT_ISSUES` — explicit override (absolute path, or relative to the project root)
2. `<root>/.local/issues/` — preferred default if `.local/` is in `.gitignore`
3. `<root>/.issues/` — original layout if `.issues/` is in `.gitignore`
4. None matched → the skill prompts you to pick `.local/` or `.issues/`, adds it to `.gitignore`, and re-runs

Read operations (`show-issues`, `triage-issues`, `fix-issues`) scan **every** existing candidate (`.local/issues/` and `.issues/`) so legacy data stays visible after a project migrates. Updates are written back to the originating file.

## Skills

| Skill | Description |
|-------|-------------|
| `save-issues` | Persists an issue list to the issues directory |
| `show-issues` | Displays open issues from the issues directory |
| `triage-issues` | Interactively triages issues (accept / reject / skip) |
| `fix-issues` | Drives automated fixing of accepted issues, grouped by file |

## Pairs well with

[`zodiac-team`](https://github.com/ZekeAranyLucas/concinnity/tree/main/plugins/zodiac-team) review skills produce findings that `dot-issues` can triage and auto-fix. Either plugin works standalone — installing both unlocks the full review-to-fix loop.
