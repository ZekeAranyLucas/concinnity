# Concinnity

Claude Code plugins for multi-agent review and issue-tracking workflows.

## Install the marketplace

```
/plugin marketplace add ZekeAranyLucas/concinnity
```

## Plugins

| Plugin | Description |
|--------|-------------|
| [`zodiac-team`](plugins/zodiac-team/) | Multi-agent code review with 12 zodiac developer personas, adversarial debate, and Concinnity prioritization |
| [`dot-issues`](plugins/dot-issues/) | File-based issue tracking in `.issues/` — save, show, triage, and fix review findings |

Install either independently:

```
/plugin install zodiac-team@concinnity
/plugin install dot-issues@concinnity
```

`zodiac-team` review skills can persist their findings via `dot-issues:save-issues`. They work standalone, but installing both unlocks the full review-to-fix loop.

Then run `/reload-plugins` to activate without restarting.
