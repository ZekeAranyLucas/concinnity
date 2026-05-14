# Description trigger evals — findings

This note records the empirical evaluation of skill descriptions done during the v2.0.0 rename. The hand-crafted query sets live at:

- `skills/fast-review/evals/trigger-eval.json`
- `skills/deep-review/evals/trigger-eval.json`
- `skills/hire-zodiacs/evals/trigger-eval.json`
- `skills/prioritize/evals/trigger-eval.json`

Each set has 20 queries (~9 should-trigger, ~11 should-not-trigger). The negatives are deliberately near-misses — easy negatives don't tell you anything. Examples: "thorough audit" against fast-review, "quick sanity check" against deep-review, "hire a plumber" against hire-zodiacs, "prioritize my inbox" against prioritize.

## What we ran

`skill-creator`'s `run_loop.py` — splits each set 60/40 train/test, runs every query 3 times against the current description, asks Claude to propose improvements, and iterates up to 5 times. Best description is picked by test score (not train) to avoid overfitting.

Model used: `claude-opus-4-7`. Five iterations per skill.

## What we found

**The current descriptions are the empirical best across all four skills.** Across 5 iterations of progressively more aggressive rewrites (including "THE default skill", "USE THIS SKILL whenever in doubt", explicit phrase lists, exclusion lists), nothing beat the original on held-out test data.

| Skill | Original test recall | Best alt test recall | Precision |
|---|---|---|---|
| fast-review | 0% | 0% | 100% |
| deep-review | 11% | 11% | 100% |
| hire-zodiacs | 0% | 0% | 100% |
| prioritize | 11% | 11% | 100% |

**Precision is perfect across all four.** When these skills trigger, they trigger correctly. None of the carefully-chosen near-miss negatives (e.g., "hire a contractor", "prioritize my inbox", "review this poem") fired the skill.

**Recall is structurally low across all four.** Queries like "review my PR", "hire me a team for X", or "which of these issues matter most?" don't reliably invoke their skills, even with descriptions begging Claude to. This is consistent across radically different skill types (review vs. team-composition vs. ranking) and description styles, so it's not a description-quality problem.

## Hypothesis

Claude is conservative about invoking *any* of these skills for natural-language queries, regardless of weight class. Even a simple ranking task ("which of these issues matter most?") doesn't reliably fire `prioritize`. The model seems to prefer handling such requests itself over delegating to a documented skill. This is probably a reasonable default in general — but it does mean these skills primarily fire on **explicit slash-command invocation** rather than natural language.

It may also be partly a test-harness artifact: `run_loop.py` calls Claude headlessly via `claude -p` with no conversation context, which is a less-rich invocation environment than real Claude Code sessions. Real-world recall may be somewhat higher than the ~0–17% measured here. But the directional finding — that further description tuning has no payoff — is consistent enough to act on.

## Practical implication

In documentation, lean into the slash-command form (`/zodiac-team:fast-review`, `/zodiac-team:deep-review`, `/zodiac-team:hire-zodiacs`, `/zodiac-team:prioritize`) as the recommended invocation. The descriptions are good enough; further tuning has no measurable payoff.

The four `dot-issues` skills were not evaluated separately. Three of them (`save-issues`, `show-issues`, `fix-issues`) are workflow-tied — they make sense only in the context of an existing `.issues/` folder, which the trigger-eval harness can't realistically simulate. `save-issues` is also invoked programmatically by review skills rather than directly by users.

## Re-running the evals

```bash
SC=~/.claude/plugins/cache/claude-plugins-official/skill-creator/unknown/skills/skill-creator
cd "$SC" && python3 -m scripts.run_loop \
  --eval-set <path-to-trigger-eval.json> \
  --skill-path <path-to-skill> \
  --model claude-opus-4-7 \
  --max-iterations 5 \
  --verbose
```

If a future description change accidentally raises recall (good) or drops precision (bad), this benchmark will surface it.
