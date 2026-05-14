---
name: deep-review
description: Use when reviewing critical code, specs, designs, or plans where missed issues are costly and thoroughness matters more than speed — for example "do a thorough review", "audit this PR", "be rigorous about this change". Zodiac-powered multi-agent review with adversarial debate over both issues and solutions; finds more than fast-review but takes longer.
---

# Zodiac Team Deep Review

## Overview

**Multi-agent review with adversarial debate and solution proposals.** Agents independently review, debate findings, then — once the issue list is hardened — propose solutions in overlapping groups and debate those too. The supervisor merges only debate-hardened findings AND debate-hardened solutions.

Two debate cycles:
1. **Issue debate** (Phases 1-3) — find and harden problems
2. **Solution debate** (Phases 4-6) — propose and harden fixes

Key differences from zodiac-team:fast-review:
- **No issue limit** — find everything within your lens
- **Anti-satisfaction-bias** — after each finding, re-read the entire function for independent concerns
- **Issue debate** — agents challenge each other's findings before merge
- **Solution debate** — agents propose fixes, then challenge each other's solutions
- **Six phases** — Review → Issue Debate → Issue Finals → Solution Proposals → Solution Debate → Solution Finals

## When to Use

Use when:
- Reviewing critical code changes where missed issues are costly
- You want adversarial verification of review findings
- Thoroughness matters more than speed
- Reviewing complex multi-file changes

Don't use for:
- Quick reviews (use zodiac-team:fast-review instead)
- Small diffs under 50 lines (overkill)
- Environments without Agent tool support

**Arguments:**
- `/zodiac-team:deep-review` — auto-detect type, all 12 signs
- `/zodiac-team:deep-review --type code` — force review type (code, spec, design, plan)
- `/zodiac-team:deep-review --team virgo,scorpio,aries` — use only specified signs (smaller, faster)

## Step 0: Detect Review Type

Same as zodiac-team:fast-review. Check for `--type` override first; otherwise detect from signals.

| Priority | Signal | Review Type |
|----------|--------|------------|
| 1 | `--type code\|spec\|design\|plan` flag | Use specified type |
| 2 | git diff output present, or reviewing a PR/changeset | **Code review** |
| 3 | Markdown with "Requirements", "Success Criteria", or "Scope" headings | **Spec review** |
| 4 | Markdown with "Architecture", "Components", or "Data Flow" headings | **Design review** |
| 5 | Markdown with "Tasks", "Steps", or "Implementation Plan" headings | **Plan review** |
| 6 | None of the above | **General review** |

## Step 1: Compose Team

**Default: all 12 signs.** The debate format benefits from maximum coverage — more perspectives produce richer debate. Callers can narrow with `--team` for smaller reviews.

### Team Selection

1. If `--team` is specified (e.g., `--team virgo,scorpio,aries`), use only those personas.
2. Otherwise, use **all 12 signs**: Aries, Taurus, Gemini, Cancer, Leo, Virgo, Libra, Scorpio, Sagittarius, Capricorn, Aquarius, Pisces.

When using a subset via `--team`, validate element/modality balance (at least 3/4 elements, 2/3 modalities). Note gaps in output. The full 12-sign default has perfect balance by definition.

## Persona Lens Reference

Same table as zodiac-team:fast-review. Each persona's allowed/forbidden concerns are derived from their zodiac skill file at dispatch time.

| Persona | Archetype | Allowed Concerns (Review Lens) |
|---------|-----------|-------------------------------|
| **Aries** | The Launcher | Unnecessary complexity, over-engineering, scope creep, shipping blockers |
| **Taurus** | The Reliability Engineer | Error handling, failure modes, operational concerns, rollback plans, migration safety |
| **Gemini** | The Polyglot | Cross-system consistency, API contract alignment, integration issues, mixed patterns |
| **Cancer** | The Team Anchor | Developer experience, code approachability, documentation gaps, maintainability |
| **Leo** | The Tech Lead | Craftsmanship quality, API cleanliness, consistent patterns, code pride |
| **Virgo** | The Code Analyst | Correctness, contract violations, off-by-one errors, naming precision, test coverage gaps |
| **Libra** | The API Designer | Interface balance, API ergonomics, contract fairness, boundary clarity |
| **Scorpio** | The Debugger | Hidden bugs, race conditions, state corruption, security vulnerabilities, root cause issues |
| **Sagittarius** | The Explorer | Better patterns or tools, missed approaches, emerging best practices, assumption challenges |
| **Capricorn** | The Program Architect | Structural fit with long-term architecture, dependency management, sequencing, standards compliance |
| **Aquarius** | The Systems Architect | Architectural coherence, conceptual model fit, system-level patterns, radical alternatives |
| **Pisces** | The UX Empath | User impact, error message quality, workflow intuitiveness, accessibility, developer experience |

**Forbidden concerns** for each persona = the other team members' allowed concerns.

## Step 2: Create Agent Dispatch Plan (Issue Phases)

Create agents for the issue-finding debate (Phases 1-3). Each persona gets three agents. With the default 12-sign team, this is 36 agents.

For a team of N personas [A, B, ..., N]:

```
Phase 1 (parallel):    Review-A, Review-B, ..., Review-N
                            ↓          ↓              ↓
Phase 2 (parallel):    Debate-A, Debate-B, ..., Debate-N
  (each blocked by ALL Phase 1 agents)
                            ↓          ↓              ↓
Phase 3 (parallel):    Finals-A, Finals-B, ..., Finals-N
  (each blocked by ALL Phase 2 agents)
```

Create all 3×N agents first, then set dependencies, then dispatch all Phase 1 agents.

**Solution phase agents (Phases 4-6) are created AFTER the supervisor merge in Step 6**, because the issue assignments determine which agents get which agents.

## Step 3: Dispatch — Phase 1 (Independent Review)

Launch all team members concurrently using the Agent tool in a SINGLE message.

### Phase 1 Agent Prompt Template

~~~
REVIEW MODE: {Review Type} Review (Debate Format — Phase 1: Independent Review)

TARGET:
{diff content, file content, or spec content — inline if <500 lines, else provide file paths}

YOUR REVIEW LENS:

ALLOWED CONCERNS — focus ONLY on these:
{Allowed concerns from Persona Lens Reference}

FORBIDDEN CONCERNS — do NOT comment on these (other team members own these):
{For each other team member: "- {Their allowed concerns} ({Their sign})"}

RULES:
- Find ALL issues within your lens. There is NO limit on the number of issues.
- Each issue must fall within your ALLOWED CONCERNS.
- Do NOT comment on anything in FORBIDDEN CONCERNS.
- Classify each using Concinnity: P1 Correct, P2 Cognition, P3 Conformant, P4 Compatible.

ANTI-SATISFACTION BIAS:
Finding one issue in a function does NOT complete your review of that function.
After each finding, re-read the ENTIRE function for independent concerns:
threading, resource management, naming, responsibility, performance.
Satisfaction bias — the tendency to stop reviewing after finding one bug —
is the #1 cause of missed findings.

OUTPUT FORMAT — numbered findings for debate:

### Finding {N}: {Brief title}
- **Priority:** {P1 Correct | P2 Cognition | P3 Conformant | P4 Compatible}
- **File:** {path:line}
- **Code:** {relevant snippet}
- **Problem:** {what's wrong and why it matters}
- **Suggestion:** {how to fix it}

{If domain rules match, append DOMAIN RULES section — see Domain Rules below}
~~~

**CRITICAL:**
- All Phase 1 agents MUST be dispatched in a SINGLE message (parallel)
- Do NOT simulate — each persona is a separate subagent
- Collect all Phase 1 results before proceeding

## Step 4: Dispatch — Phase 2 (Debate)

After ALL Phase 1 agents complete, launch Phase 2 agents. All four debate agents dispatch in a SINGLE message.

### Phase 2 Agent Prompt Template

~~~
DEBATE PHASE: You are reviewing other personas' findings and defending your own.

YOUR PHASE 1 FINDINGS:
{This persona's Phase 1 output}

OTHER REVIEWERS' FINDINGS:
{For each other persona:}
--- {Sign} ({Archetype}) ---
{Their Phase 1 output}
---

INSTRUCTIONS:
1. Read ALL other reviewers' findings carefully.
2. For each finding from another reviewer, verify it by reading the actual code.
   Use the Read tool to check file:line references.
3. For each finding, decide: CONFIRM, CHALLENGE, or WITHDRAW (for your own).
   - CONFIRM: The finding is valid. State why.
   - CHALLENGE: The finding is wrong or overstated. State why with evidence.
   - WITHDRAW: One of YOUR findings that you now believe is wrong. State why.
4. Do at least 2 rounds of analysis:
   - Round 1: React to every other reviewer's findings.
   - Round 2: Re-examine your own findings in light of what others found.
     Did anyone's finding reveal something you missed? Add new findings if so.

OUTPUT FORMAT:

## Confirmations
{For each confirmed finding from others:}
- **{Sign}'s Finding {N}:** CONFIRMED — {brief reason}

## Challenges
{For each challenged finding:}
- **{Sign}'s Finding {N}:** CHALLENGED — {evidence and reasoning}

## Withdrawals
{For any of your own findings you're withdrawing:}
- **My Finding {N}:** WITHDRAWN — {why it was wrong}

## New Findings (discovered during debate)
{Any new issues found while verifying others' code references:}
### Finding {N}: {Brief title}
{same format as Phase 1}
~~~

## Step 5: Dispatch — Phase 3 (Finals)

After ALL Phase 2 agents complete, launch Phase 3. All four finals agents dispatch in a SINGLE message.

### Phase 3 Agent Prompt Template

~~~
You are {Sign} — {Archetype}. {Element} + {Modality}.

FINALS PHASE: Submit your post-debate findings list.

YOUR PHASE 1 FINDINGS:
{This persona's Phase 1 output}

DEBATE RESULTS FROM ALL REVIEWERS:
{All Phase 2 outputs from all personas}

INSTRUCTIONS:
Produce your FINAL findings list. This list MUST reflect what changed during debate:
- KEEP findings that were confirmed or unchallenged.
- REMOVE findings you withdrew or that were successfully challenged.
- ADD new findings you discovered during debate.
- UPGRADE/DOWNGRADE priority if debate revealed the issue is more/less severe.

For each finding, note its debate status: [unchallenged], [confirmed by {Sign}],
[survived challenge from {Sign}], or [new — found during debate].

OUTPUT FORMAT — same as Phase 1 but with debate status:

### Finding {N}: {Brief title} [{debate status}]
- **Priority:** {P1 | P2 | P3 | P4}
- **File:** {path:line}
- **Code:** {relevant snippet}
- **Problem:** {what's wrong}
- **Suggestion:** {how to fix}
~~~

## Step 6: Supervisor Merge — Hardened Issue List

Collect all Phase 3 finals and apply Concinnity framework. This produces the **hardened issue list** that feeds into solution proposals.

### 6a. Deduplicate

If two personas surfaced the same issue, keep the stronger framing. Credit the persona who articulated it best. Note if multiple personas confirmed it — cross-confirmation increases confidence.

### 6b. Weight by Debate Outcome

| Debate Status | Weight |
|---------------|--------|
| Confirmed by 2+ personas | High confidence — list first within priority tier |
| Confirmed by 1 persona | Normal confidence |
| Unchallenged | Normal confidence |
| Survived challenge | High confidence — the challenge tested it |
| New (found during debate) | Normal confidence — mark as debate-discovered |

### 6c. Prioritize Using Concinnity

| Priority | Principle | Examples |
|----------|-----------|---------|
| **P1** | **Correct** | Bugs, contract violations, race conditions, security vulnerabilities |
| **P2** | **Cognition** | Confusing logic, ambiguous terms, poor naming, unreadable code |
| **P3** | **Conformant** | Inconsistent patterns, deviates from project conventions |
| **P4** | **Compatible** | Non-idiomatic for language/framework, ignores ecosystem standards |

### 6d. Bucket into Three Groups

- **Blocking Issues** — P1 (Correct). Must fix before merge/approval.
- **Should Fix** — P2 (Cognition). Hard to understand = hard to maintain.
- **Consider** — P3/P4 (Conformant/Compatible). Consistency and standards.

### 6e. Number the Hardened Issues

Assign each issue a stable ID (H1, H2, ..., HN) for reference in solution phases.

---

## Step 7: Assign Issues to Solution Groups

Divide the hardened issues among the N available agents. **Each issue MUST be assigned to at least 2 agents** so that competing solutions emerge.

### Assignment Strategy

1. **Match by persona lens.** Assign each issue to the persona whose allowed concerns best match the issue's domain, plus at least one persona from a different element for contrasting perspective.
2. **Spread the load.** No single agent should get more than ceil(2 × issues / N) assignments. Distribute evenly.
3. **Ensure overlap.** Every issue gets 2-3 agents. For P1 issues, prefer 3 agents.

### Assignment Table Format

Produce an assignment table before dispatching:

```
H1: "Race condition in connection pool" → Scorpio, Taurus, Virgo
H2: "Confusing error message" → Pisces, Cancer
H3: "Non-idiomatic use of streams" → Leo, Sagittarius
...
```

### Create Solution Agent Dispatch Plan

Create agents for Phases 4-6. Unlike the issue phases (where every agent participates in every phase), solution phases are scoped per assignment group.

```
Phase 4 (parallel):    Solve-{Sign} for each agent (one agent per persona, containing all their assigned issues)
                            ↓
Phase 5 (parallel):    SolDebate-{Issue} for each issue (one agent per issue, assigned to that issue's group)
  (each blocked by ALL Phase 4 agents for that issue's assigned personas)
                            ↓
Phase 6 (parallel):    SolFinals-{Issue} for each issue (one agent per issue)
  (each blocked by ALL Phase 5 agents for that issue)
```

## Step 8: Dispatch — Phase 4 (Solution Proposals)

Launch one agent per persona who has assignments. All dispatch in a SINGLE message.

### Phase 4 Agent Prompt Template

~~~
SOLUTION PHASE: Propose fixes for your assigned issues.

REVIEW TARGET (for context):
{original diff/file content or file paths}

YOUR ASSIGNED ISSUES:
{For each issue assigned to this persona:}
### {Issue ID}: {Brief title}
- **Priority:** {P1 | P2 | P3 | P4}
- **Debate status:** {status from issue debate}
- **File:** {path:line}
- **Code:** {relevant snippet}
- **Problem:** {what's wrong}

INSTRUCTIONS:
1. For EACH assigned issue, read the actual code at the referenced file:line using the Read tool.
2. Understand the surrounding context — read the full function/class, not just the flagged line.
3. Propose a concrete solution. Include:
   - The exact code change (before → after)
   - Why this approach over alternatives
   - Any risks or tradeoffs of the fix
   - Whether the fix could affect other issues in the hardened list
4. If you believe an issue is actually unfixable or would be better addressed differently
   than a code change (e.g., requires architectural rework), say so and explain why.

APPROACH THROUGH YOUR LENS:
{Sign}'s strengths shape HOW you propose fixes:
{Allowed concerns — these inform your solution style, not what issues you address}

OUTPUT FORMAT — one solution per assigned issue:

### Solution for {Issue ID}: {Brief title}
- **Approach:** {1-2 sentence summary}
- **Before:**
```{lang}
{current code}
```
- **After:**
```{lang}
{proposed fix}
```
- **Rationale:** {why this approach}
- **Risks:** {tradeoffs, potential regressions, or "None identified"}
- **Cross-impact:** {other hardened issues affected, or "None"}
~~~

## Step 9: Dispatch — Phase 5 (Solution Debate)

After ALL Phase 4 agents complete, launch solution debate. Dispatch one agent per **issue** (not per persona). Each issue's assigned agents debate within a single agent prompt that presents all competing solutions.

### Phase 5 Agent Prompt Template

For each issue, pick the persona from its group whose lens best matches the issue domain as the debate lead. That agent evaluates ALL proposed solutions.

~~~
SOLUTION DEBATE: Evaluate competing solutions for {Issue ID}.

ISSUE:
### {Issue ID}: {Brief title}
- **Priority:** {P1 | P2 | P3 | P4}
- **File:** {path:line}
- **Problem:** {what's wrong}

PROPOSED SOLUTIONS:
{For each agent who proposed a solution for this issue:}
--- {Sign} ({Archetype}) ---
{Their Phase 4 solution for this issue}
---

INSTRUCTIONS:
1. Read the actual code at the referenced file:line. Verify each proposed solution
   would actually compile/work in context.
2. For each solution, evaluate:
   - **Correctness:** Does it actually fix the problem?
   - **Completeness:** Does it handle edge cases?
   - **Risk:** Could it introduce new issues?
   - **Simplicity:** Is it the simplest fix that works?
3. Do at least 2 rounds of analysis:
   - Round 1: Evaluate each solution independently.
   - Round 2: Compare solutions against each other. Can the best parts be combined?
4. Produce a RECOMMENDED solution — it may be one of the proposals as-is, a modified
   version, or a synthesis of multiple proposals.

OUTPUT FORMAT:

## {Issue ID}: Solution Evaluation

### Evaluation of {Sign}'s Solution
- **Correctness:** {PASS | FAIL — reason}
- **Completeness:** {PASS | PARTIAL | FAIL — reason}
- **Risk:** {LOW | MEDIUM | HIGH — reason}
- **Simplicity:** {rating and notes}

{Repeat for each proposed solution}

### Recommended Solution
- **Based on:** {Sign}'s solution (as-is | modified | synthesis of Sign1 + Sign2)
- **Confidence:** {HIGH | MEDIUM | LOW}
- **Before:**
```{lang}
{current code}
```
- **After:**
```{lang}
{recommended fix}
```
- **Rationale:** {why this is the best solution}
- **Dissent:** {any unresolved concerns from other approaches}
~~~

## Step 10: Dispatch — Phase 6 (Solution Finals)

After ALL Phase 5 agents complete, launch finals. One agent per issue — same lead as Phase 5.

### Phase 6 Agent Prompt Template

~~~
You are {Sign} — {Archetype}. {Element} + {Modality}.

SOLUTION FINALS: Produce the definitive solution for {Issue ID}.

ISSUE:
### {Issue ID}: {Brief title}
- **Priority:** {P1 | P2 | P3 | P4}
- **File:** {path:line}

ALL PROPOSED SOLUTIONS (Phase 4):
{All Phase 4 solutions for this issue}

DEBATE EVALUATION (Phase 5):
{Phase 5 output for this issue}

INSTRUCTIONS:
Produce the FINAL recommended solution. This MUST reflect the debate evaluation:
- If the debate recommended a solution, adopt it unless you have strong evidence against.
- If debate confidence was LOW, note this — the user should review carefully.
- Include the complete before/after code change.
- Assign a solution confidence level.

OUTPUT FORMAT:

### Final Solution for {Issue ID}: {Brief title}
- **Confidence:** {HIGH | MEDIUM | LOW}
- **Before:**
```{lang}
{current code}
```
- **After:**
```{lang}
{final fix}
```
- **Rationale:** {why this solution won}
- **Dissent:** {unresolved concerns, or "None — consensus reached"}
~~~

## Step 11: Final Merge and Categorize

Combine the hardened issue list (Step 6) with the final solutions (Step 10). Categorize into three action groups.

### Action Groups

**Group 1 — Auto-apply (HIGH confidence, any priority):**
All issues where the solution debate produced HIGH confidence consensus. These are safe to apply without further review. Order by priority (P1 first).

**Group 2 — Triage needed (P1/P2 priority, MEDIUM or LOW confidence):**
High-priority problems where the best fix is uncertain. These need interactive human review because the issue is important but the solution has unresolved debate. Include dissent summary for each.

**Group 3 — Remaining (P3/P4 priority, MEDIUM or LOW confidence):**
Lower-priority items with uncertain fixes. Safe to defer or address opportunistically.

### Within Each Group

Sort by priority (P1 → P2 → P3 → P4), then by confidence (HIGH → MEDIUM → LOW).

## Step 12: Save Review

Save to `.issues/{YYYY-MM-DD}__zodiac-deep-review-{subject}.md`.

### Output Template

````markdown
# Zodiac Team Deep Review: {subject}

**Reviewed:** {YYYY-MM-DD}
**Reviewer:** Claude (zodiac-team:deep-review)
**Review type:** {Code|Spec|Design|Plan|General} review ({auto-detected|user-specified})
**Process:** 6-phase debate (issue review → issue debate → issue finals → solution proposals → solution debate → solution finals)

---

## Team Composition

- **Team:** {Sign1} ({Archetype1}), {Sign2} ({Archetype2}), ...
- **Element coverage:** {elements} ({gaps if any})
- **Modality coverage:** {modalities} ({gaps if any})
{If coverage gaps:}
- **Coverage note:** {underrepresented perspectives}

## Debate Summary

### Issue Debate
- **Phase 1 findings:** {total across all personas}
- **Challenges raised:** {count}
- **Findings withdrawn:** {count}
- **New findings from debate:** {count}
- **Hardened issues:** {count}

### Solution Debate
- **Solutions proposed:** {total across all agents}
- **Solutions evaluated:** {count}
- **High confidence solutions:** {count}
- **Medium confidence solutions:** {count}
- **Low confidence solutions (needs manual review):** {count}

---

## Blocking Issues (P1 — Correct)

### [ ] {Issue ID}: {Brief description}

- **Found by:** {Sign} ({Archetype})
- **Debate status:** {confirmed by Sign2, Sign3 | unchallenged | survived challenge from Sign2 | new}
- **File:** [{path}:{lines}]({path})
- **Problem:** {explanation}
- **Solution confidence:** {HIGH | MEDIUM | LOW}
- **Proposed by:** {Sign} ({Archetype}) {| synthesis of Sign1 + Sign2}
- **Before:**
```{lang}
{current code}
```
- **After:**
```{lang}
{recommended fix}
```
- **Rationale:** {why this solution}
- **Dissent:** {unresolved concerns, or "none"}

---

## Should Fix (P2 — Cognition)

### [ ] {Issue ID}: {Brief description}

{same format}

---

## Consider (P3-P4 — Conformant/Compatible)

### [ ] {Issue ID}: {Brief description}

{same format}

---

## Summary

**Issues found:** {count}
**By priority:**
- Blocking Issues: {count}
- Should Fix: {count}
- Consider: {count}

**Solution confidence:**
- High: {count}
- Medium: {count}
- Low (review carefully): {count}

---

## Recommended Actions

### Auto-apply: HIGH confidence solutions ({count} issues)

These solutions survived adversarial debate with consensus. Safe to apply without further review:

{List of issue IDs with brief titles, all HIGH confidence regardless of priority}

> Run `/dot-issues:fix-issues` to apply these automatically.

### Triage needed: P1/P2 issues with MEDIUM or LOW confidence ({count} issues)

These are high-priority problems where the best fix is uncertain. Review each manually:

{List of issue IDs with brief titles, confidence level, and dissent summary}

> Run `/dot-issues:triage-issues` to interactively review these.

### Remaining: LOW priority with MEDIUM/LOW confidence ({count} issues)

Lower-priority items that may not be worth the review effort right now:

{List of issue IDs with brief titles}

> Address opportunistically, or defer.

### Next Steps

1. Apply high-confidence fixes: `/dot-issues:fix-issues` (filters to accepted HIGH confidence)
2. Triage uncertain critical fixes: `/dot-issues:triage-issues` (focuses on P1/P2 MEDIUM/LOW)
3. Use `/dot-issues:show-issues` to see remaining open issues
````

Tell user: "Debate review saved to `.issues/{filename}`."

After saving, present the recommended actions summary in chat (not just in the file). Check whether the `dot-issues` plugin is installed in the current session (look for skills in the `dot-issues:*` namespace in your available skills list):

**If `dot-issues:*` skills are available:**
1. State how many issues can be auto-applied (HIGH confidence) and offer to run `/dot-issues:fix-issues`
2. State how many P1/P2 issues need triage (MEDIUM/LOW confidence) and offer to run `/dot-issues:triage-issues`
3. State how many remaining issues can be deferred (mention `/dot-issues:show-issues` for tracking)

**If `dot-issues` is NOT installed:**
1. State how many issues are HIGH/MEDIUM/LOW confidence in chat (same counts, no slash-command offers)
2. Close with: "Findings saved to `.issues/{filename}`. To get triage and auto-fix workflows, install the companion plugin: `/plugin install dot-issues@concinnity`."
The file's inline `> Run /dot-issues:X-issues` callouts remain useful as documentation if the user installs dot-issues later.

**Do NOT include in output:**
- Raw Phase 1-6 agent outputs
- Commentary on the debate process mechanics
- Explanations of dispatch order or agent assignments

## Domain Rules

Identical to zodiac-team:fast-review. Domain rules are conditional context injected into **ALL team members' Phase 1 prompts** when the review target matches certain patterns.

**Before dispatching Phase 1, check each domain rule's "Applies when" criteria. If matched, append to EVERY persona's Phase 1 prompt.**

### Domain Rule: Android PII Logging

**Applies when:** Code uses `Log.{v,d,i,w,e}(` or `Log.{v,d,i,w,e}PiiFree(`

**Context:**

This codebase uses a custom Log class with two variant families:
- `Log.d(tag, msg)` — debug log, Android logcat only, debug builds only
- `Log.dPiiFree(tag, msg)` — PII-safe log, goes to BOTH logcat AND LogManager (customer feedback)

All levels (v, d, i, w, e) have PiiFree counterparts. PiiFree also supports structured logging: `dPiiFree(tag, msg, extraTags, properties)`.

**CRITICAL: PiiFree logs may be collected and sent to Microsoft support. They MUST NOT contain PII.**

PII includes: file paths, URLs, file names, user IDs, emails, tokens, credentials, unsanitized exception messages.

**What to flag:**
1. **(P1 Blocking)** PiiFree call that logs PII
2. **(P1 Blocking)** PiiFree call logging unsanitized exception.message
3. **(P2 Should Fix)** Using Log.d() where Log.dPiiFree() would be appropriate
4. **(Consider)** Opportunity to add structured logging (extraTags/properties)

### Domain Rule: Android MockRampValues for Test Isolation

**Applies when:** Test code uses `mockkObject(RampSettings` or `mockkStatic(RampSettings`

**Context:**

This codebase has two ways to mock feature flags:
- `MockRampValues` (correct) — lightweight `RampConnection` implementation, `AutoCloseable`
- `mockkObject(RampSettings.XXX)` (incorrect) — MockK static mocking of legacy class

**CRITICAL: Tests MUST use `MockRampValues` instead of `mockkObject`/`mockkStatic` on `RampSettings`.**

**What to flag:**
1. **(P2 Should Fix)** `mockkObject(RampSettings.XXX)` — use `MockRampValues.of(setting, value).use { }` instead
2. **(P2 Should Fix)** `mockkStatic(RampSettings::class)` — same fix
3. **(P2 Should Fix)** MockRampValues created but not closed (missing `.use {}` or `.close()`)

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Limiting findings to 5 per persona | No limit. Find everything within your lens. |
| Stopping after first finding in a function | Re-read entire function for independent concerns after each finding. |
| Skipping debate phase for "efficiency" | Debate is the point. It catches false positives and missed issues. |
| Dispatching phases sequentially one agent at a time | Each phase dispatches ALL agents in a SINGLE message |
| Simulating debate in your own head | Each phase requires actual Agent tool subagent dispatch |
| Letting debate degrade into agreement | Agents must VERIFY by reading code, not just accept findings |
| Merging without weighting debate outcomes | Cross-confirmed and challenge-surviving findings rank higher |
| Using only 4 signs when no `--team` override | Default is all 12. The debate format thrives on maximum coverage. |
| Assigning each issue to only 1 agent for solutions | Each issue needs 2-3 agents so competing solutions emerge |
| Skipping solution debate ("the fix is obvious") | Obvious fixes often miss edge cases. Debate them anyway. |
| Proposing solutions without reading surrounding code | Agents must Read the full function/class, not just the flagged line |
| Combining issue debate and solution debate into one | They are separate cycles. Harden the issue list FIRST, then solve. |

## Rationalizations to Ignore

| Excuse | Reality |
|--------|---------|
| "The review phase found enough, skip debate" | Debate catches false positives and reveals missed issues. Always run it. |
| "I can simulate the debate myself" | No. Each persona is a separate subagent in each phase. |
| "Six phases is too slow" | Use zodiac-team:fast-review if speed matters. This skill prioritizes thoroughness. |
| "The findings are already good, debate won't help" | Debate eliminates ~20% of false positives in practice. |
| "I'll just do 1 round of debate" | Minimum 2 rounds. Round 2 catches what round 1 missed. |
| "12 agents is too many, I'll use 4" | Default is 12 for a reason. Use `--team` to narrow if needed. |
| "The fix is obvious, skip solution debate" | The first solution is rarely the best. Competing proposals surface tradeoffs. |
| "One agent per issue is enough for solutions" | Multiple agents produce competing solutions. That's how you find the best one. |
| "I'll propose solutions during the issue debate" | No. Solutions come AFTER the issue list is hardened. Mixing them conflates two questions. |

## Core Pattern Summary

```
Review Target → Detect Type → Compose Team (default: all 12 signs) → Create Issue Agent Dispatch Plan

═══ ISSUE DEBATE CYCLE ═══

Phase 1: Independent Review (all N personas in parallel)
  Review-Aries, Review-Taurus, ..., Review-Pisces
       ↓ (all Phase 1 complete)
Phase 2: Issue Debate (all N personas in parallel)
  Debate-Aries, Debate-Taurus, ..., Debate-Pisces
  (each reads ALL Phase 1 outputs, verifies code, challenges/confirms)
       ↓ (all Phase 2 complete)
Phase 3: Issue Finals (all N personas in parallel)
  Finals-Aries, Finals-Taurus, ..., Finals-Pisces
  (each submits revised list reflecting debate outcomes)
       ↓ (all Phase 3 complete)
Supervisor Merge → Hardened Issue List (H1, H2, ..., HM)
       ↓
Assign Issues to Solution Groups (2-3 agents per issue)

═══ SOLUTION DEBATE CYCLE ═══

Phase 4: Solution Proposals (agents solve their assigned issues in parallel)
  Solve-Aries, Solve-Taurus, ..., (only agents with assignments)
       ↓ (all Phase 4 complete)
Phase 5: Solution Debate (one debate per issue, in parallel)
  SolDebate-H1, SolDebate-H2, ..., SolDebate-HM
  (debate lead evaluates competing solutions, 2+ rounds)
       ↓ (all Phase 5 complete)
Phase 6: Solution Finals (one final per issue, in parallel)
  SolFinals-H1, SolFinals-H2, ..., SolFinals-HM
  (definitive solution per issue, with confidence level)
       ↓ (all Phase 6 complete)
Final Merge (order by priority, then confidence) → Save to .issues/
```
