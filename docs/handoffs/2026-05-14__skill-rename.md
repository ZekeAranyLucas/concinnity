# Handoff: Skill Rename to v2.0.0 (mid-flight)

**Date:** 2026-05-14
**Status:** In progress — uncommitted changes on `main`
**Workdir:** `/Users/zaranylucas/src/personal/concinnity`

Load this file at the start of a fresh Claude Code session to pick up where the prior session left off. It is intentionally self-contained.

---

## What this repo is

`ZekeAranyLucas/concinnity` — a Claude Code plugin marketplace bundling two plugins:

- **`zodiac-team`** — multi-agent code/spec/design/plan review with 12 zodiac developer personas, adversarial debate, and Concinnity prioritization. Currently at **v1.2.0**.
- **`dot-issues`** — file-based issue tracking under `.issues/` (save, show, triage, fix). Currently at **v1.0.0**.

Marketplace name (inside `.claude-plugin/marketplace.json`): `concinnity`.

Install (for reference):
```
/plugin marketplace add ZekeAranyLucas/concinnity
/plugin install zodiac-team@concinnity
/plugin install dot-issues@concinnity
/reload-plugins
```

## Identity setup (already wired up)

The user has two GitHub identities; this repo uses the personal one.

- **Personal:** `zeke@aranylucas.com` / GitHub account `ZekeAranyLucas`
- **Work:** `zaranylucas@microsoft.com` / GitHub account `zaranylucas_microsoft` (the `userEmail` context exposes this, but it's wrong for this repo)

`~/.gitconfig` has an `includeIf "gitdir:~/src/personal/"` block that pulls in `~/.gitconfig-personal`, which overrides `user.email` to the personal address. So any repo under `~/src/personal/` automatically commits with the personal identity — no per-repo config needed. **Do not add per-repo `user.email` overrides on top of this.**

`gh` CLI has both accounts authenticated; switch with `gh auth switch --user ZekeAranyLucas` or `--user zaranylucas_microsoft`. No automatic per-owner routing.

## What we just shipped (v1.2.0, committed and pushed)

Opportunistic dot-issues integration. `zodiac-team` review/debate skills no longer assume dot-issues is installed. Closing recommendations branch on availability of `dot-issues:*` skills in the current session. README wording updated; `.gitignore` added covering `.issues/` and `.DS_Store`.

Commit: `746e93d` on `main`.

## What's mid-flight (the v2.0.0 rename)

**Decision:** Drop the redundant plugin-name prefix from skill names. The Claude Code skill namespace already provides the prefix (`zodiac-team:zodiac-team-debate` becomes `zodiac-team:deep-review`). Also rename `zodiac-team-debate` → `deep-review` because "debate" describes the mechanism, not the outcome.

**Renames:**

| Plugin | Old skill name | New skill name |
|---|---|---|
| zodiac-team | zodiac-team-review | review |
| zodiac-team | zodiac-team-debate | deep-review |
| zodiac-team | zodiac-team-compose | compose |
| zodiac-team | prioritize-issues-by-concinnity | prioritize |
| dot-issues | dot-issues-save | save |
| dot-issues | dot-issues-show | show |
| dot-issues | dot-issues-triage | triage |
| dot-issues | dot-issues-fix | fix |

**Version bumps (pending):** both plugins → 2.0.0 (breaking).

## Current uncommitted state

`git status` shows 8 renamed SKILL.md files (directories already moved via `git mv`, frontmatter `name:` already updated via sed). Cross-references inside SKILL.md bodies, READMEs, and version manifests are NOT yet updated. **The repo is on `main` with these uncommitted changes** — fine to continue from here. If you'd rather reset and redo, see "Resetting state" at the bottom.

## Pending work (checklist)

### 1. Update cross-skill slash-command references inside SKILL.md bodies

The skill names changed, so internal references like `/dot-issues-fix` must become `/dot-issues:fix`, and `/zodiac-team-debate` must become `/zodiac-team:deep-review`. Approx. 30 references across 8 files.

Pattern of changes per file:

- `/dot-issues-save` → `/dot-issues:save`
- `/dot-issues-show` → `/dot-issues:show`
- `/dot-issues-triage` → `/dot-issues:triage`
- `/dot-issues-fix` → `/dot-issues:fix`
- `/zodiac-team-review` → `/zodiac-team:review`
- `/zodiac-team-debate` → `/zodiac-team:deep-review`

Also prose references — the bodies mention skill names without the slash prefix in several places (e.g., "Same as zodiac-team-review" → "Same as the review skill"; "Use zodiac-team-review if speed matters" → "Use the review skill if speed matters"). The `deep-review` SKILL.md has the most of these — about 8 occurrences of `zodiac-team-review` and `zodiac-team-debate` in prose.

Files (post-rename paths):
- `plugins/zodiac-team/skills/review/SKILL.md`
- `plugins/zodiac-team/skills/deep-review/SKILL.md` (largest; ~20 refs)
- `plugins/zodiac-team/skills/compose/SKILL.md`
- `plugins/zodiac-team/skills/prioritize/SKILL.md`
- `plugins/dot-issues/skills/save/SKILL.md`
- `plugins/dot-issues/skills/show/SKILL.md`
- `plugins/dot-issues/skills/triage/SKILL.md`
- `plugins/dot-issues/skills/fix/SKILL.md`

The filename pattern in `.issues/{YYYY-MM-DD}__zodiac-debate-{subject}.md` (inside `deep-review` SKILL.md) should become `.issues/{YYYY-MM-DD}__zodiac-deep-review-{subject}.md` (or just `zodiac-review-` for the quick version, both renamed accordingly).

`dot-issues-save format` (referenced as a format identifier in prose) should become "save format" or "dot-issues save format" — pick one and be consistent.

### 2. Update READMEs

- `/Users/zaranylucas/src/personal/concinnity/README.md` — line 25 references `dot-issues-save` in prose
- `/Users/zaranylucas/src/personal/concinnity/plugins/zodiac-team/README.md` — lines 22-25 skill table uses old names; lines 16 references `/dot-issues-triage` and `/dot-issues-fix`
- `/Users/zaranylucas/src/personal/concinnity/plugins/dot-issues/README.md` — lines 20-23 skill table uses old names

### 3. Bump versions to 2.0.0

- `/Users/zaranylucas/src/personal/concinnity/plugins/zodiac-team/.claude-plugin/plugin.json`: `1.2.0` → `2.0.0`
- `/Users/zaranylucas/src/personal/concinnity/plugins/dot-issues/.claude-plugin/plugin.json`: `1.0.0` → `2.0.0`
- `/Users/zaranylucas/src/personal/concinnity/.claude-plugin/marketplace.json`: update both versions in the plugins array

### 4. Commit + push to concinnity main

Single commit. Git should already detect directory renames (it does — verified before handoff).

Suggested commit message:
```
feat!: rename skills to drop redundant plugin-name prefix; v2.0.0

Skills are namespaced by plugin (`zodiac-team:review`), so the previous
naming (`zodiac-team:zodiac-team-review`) was redundant. Also rename
zodiac-team-debate → deep-review since "debate" describes the mechanism,
not the outcome.

BREAKING: skill IDs change. Anyone installing fresh just gets the new
names; assume no migration needed (per user direction).

- zodiac-team:review (was zodiac-team-review)
- zodiac-team:deep-review (was zodiac-team-debate)
- zodiac-team:compose (was zodiac-team-compose)
- zodiac-team:prioritize (was prioritize-issues-by-concinnity)
- dot-issues:save (was dot-issues-save)
- dot-issues:show (was dot-issues-show)
- dot-issues:triage (was dot-issues-triage)
- dot-issues:fix (was dot-issues-fix)

Both plugins bumped to 2.0.0.
```

### 5. Update OddGarden CLAUDE.md (related repo)

Path: `/Users/zaranylucas/src/OddGarden/CLAUDE.md` (working tree change pending from the prior session).

The file currently references `zodiac-team:zodiac-team-debate` and `dot-issues:dot-issues-{save,triage,fix}`. Update to:
- `zodiac-team:deep-review`
- `dot-issues:save`, `dot-issues:triage`, `dot-issues:fix`

Skill prerequisites table is around line 220. The earlier session also added a row for `oddgarden-review-loop` listing its dot-issues dependencies — keep that, just update the names.

OddGarden's project-local skills under `.claude/skills/oddgarden-*` reference bare names like `dot-issues-save`. After the rename, those bare names won't resolve. They should be updated to the new names too (`dot-issues:save`, `zodiac-team:deep-review`, etc.). Files to grep:
```
~/src/OddGarden/.claude/skills/oddgarden-review-loop/SKILL.md
~/src/OddGarden/.claude/skills/oddgarden-design-review/SKILL.md
~/src/OddGarden/.claude/skills/oddgarden-plan-review/SKILL.md
~/src/OddGarden/.claude/skills/oddgarden-code-review/SKILL.md
~/src/OddGarden/.claude/skills/chive/SKILL.md
```

Commit OddGarden changes separately (it's a different repo, and pushing requires its own work-account auth).

## Decisions and rationale (for context)

**Why opportunistic, not hard-dependency, on dot-issues:** The user chose "soft dependency, documented" during the original refactor. `zodiac-team` can produce useful review output standalone; `dot-issues` is a workflow layer on top.

**Why drop the prefix:** `zodiac-team:zodiac-team-debate` is two namespaces stacked. Inside the plugin namespace the prefix is redundant. Same logic for `dot-issues:dot-issues-save`.

**Why "deep-review" over "audit", "thorough", etc.:** Pairs cleanly with `review` to tell a story — fast version, thorough version. User confirmed "these names make sense to me."

**Why 2.0.0:** Skill IDs are part of the public contract. Renaming them is breaking. User confirmed "everyone is fresh" so no migration shims needed, but version still bumps.

**Why we did NOT do description-optimization evals via skill-creator:** User chose "Phase A only — rename and ship." Evals deferred. If you want to do them, see `Skill: skill-creator:skill-creator` and follow its "Description Optimization" section per renamed skill.

## Optional follow-up (not blocking 2.0.0)

- **Heading-format drift between zodiac-team and dot-issues**: `zodiac-team-debate` writes files with `Blocking Issues / Should Fix / Consider` sections; `dot-issues-save` template documents `Must Fix / Should Fix / Consider`. The drift is real but pre-existing — fix in a future PR.
- **Description optimization via skill-creator**: validate that the new short names trigger correctly against realistic user queries. See the skill-creator instructions for `run_loop.py`.

## Resetting state (only if you want to redo from scratch)

If you'd rather discard the in-flight rename and redo:
```bash
cd /Users/zaranylucas/src/personal/concinnity
git restore --staged .
git restore .
```
This drops the `git mv` and frontmatter changes, returning to v1.2.0 clean state.

## How to resume

1. `cd /Users/zaranylucas/src/personal/concinnity`
2. Confirm `git status` matches the "Current uncommitted state" section above
3. Work through the "Pending work" checklist in order
4. Verify `git config user.email` shows `zeke@aranylucas.com` before committing
5. After push, switch to OddGarden and apply the related-repo updates
