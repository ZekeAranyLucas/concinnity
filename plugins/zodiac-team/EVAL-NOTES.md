# Description trigger evals — findings

This note records the empirical evaluation of the `fast-review` and `deep-review` skill descriptions, done during the v2.0.0 rename. The hand-crafted query sets live at:

- `skills/fast-review/evals/trigger-eval.json`
- `skills/deep-review/evals/trigger-eval.json`

Each set has 20 queries (~9 should-trigger, ~11 should-not-trigger). The negatives are deliberately near-misses (e.g., "thorough audit" for fast-review, "quick sanity check" for deep-review) — the easy ones don't tell you anything.

## What we ran

`skill-creator`'s `run_loop.py` — splits each set 60/40 train/test, runs every query 3 times against the current description, asks Claude to propose improvements, and iterates up to 5 times. Best description is picked by test score (not train) to avoid overfitting.

Model used: `claude-opus-4-7`. Five iterations per skill.

## What we found

**The current descriptions are the empirical best.** Across all 5 iterations of progressively more aggressive rewrites (including "THE default skill for any review request", "USE THIS SKILL whenever in doubt", explicit phrase lists, etc.), nothing beat the original on held-out test data.

|  | Original (current) | Best of 5 alternatives |
|---|---|---|
| fast-review test score | 4/7 | 4/7 |
| deep-review test score | 4/7 | 4/7 |
| Precision (both) | 100% | 100% |
| Recall (both) | ~0–11% | ~0–11% |

**Precision is perfect** — when these skills trigger, they trigger correctly. There are no false positives. The negatives in the eval set all pass.

**Recall is structurally low** — queries like "review my PR" or "look at this diff" don't reliably invoke the skill, even with descriptions begging Claude to use them. This is consistent across radically different description styles, which suggests it's not a description-quality problem.

## Hypothesis

Claude is conservative about invoking skills it perceives as "heavyweight" (multi-agent, parallel dispatch) for casually-phrased queries. It would rather handle a "look at my code" request itself than spin up a persona team. This is probably the right default in general — but it does mean these skills primarily fire on **explicit slash-command invocation** rather than natural language.

## Practical implication

In documentation, lean into the slash-command form (`/zodiac-team:fast-review`, `/zodiac-team:deep-review`) as the recommended invocation. The descriptions are good enough; further tuning has no measurable payoff.

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
