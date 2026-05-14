---
name: prioritize
description: Prioritize review feedback using the Concinnity framework - Correct > Cognition > Conformant > Compatible
---

# Prioritize Issues by Concinnity

## Overview

**Concinnity** is a prioritization framework for organizing feedback into a clear hierarchy. It ensures reviewers address what matters most first, rather than mixing critical issues with style suggestions.

The four principles, in strict priority order:

| Priority | Principle | Definition |
|----------|-----------|------------|
| **P1** | **Correct** | Does the code work? Does it satisfy requirements? |
| **P2** | **Cognition** | Can humans understand it? Is the intent clear? |
| **P3** | **Conformant** | Does it follow project/team conventions? |
| **P4** | **Compatible** | Does it follow language/ecosystem standards? |

## When to Use

Use when:
- You have a list of issues from a review (code, spec, test, design)
- You need to organize feedback into actionable priorities
- You want to clearly communicate what's blocking vs nice-to-have
- Merging feedback from multiple reviewers or review agents

## The Four Principles

### P1: Correct (Blocking)

**Definition:** The code must work. It must satisfy its requirements and behave correctly.

**This is always the highest priority.** A beautifully written, idiomatic piece of code that doesn't work is worthless.

**Examples by domain:**

| Domain | P1 Correct Issues |
|--------|-------------------|
| Code Review | Bugs, contract violations, race conditions, unsafe assumptions, missing error handling |
| Spec Review | Missing requirements, infeasible constraints, contradictions, will lead to wrong implementation |
| Test Review | Tests that don't actually test anything, flaky tests, test pollution, weak assertions |
| Design Review | Fundamental feasibility problems, missing critical requirements |

### P2: Cognition (Should Fix)

**Definition:** Humans must be able to understand the code. Clear intent enables maintenance.

**This is second priority.** Code that works but nobody can understand becomes unmaintainable.

**Examples by domain:**

| Domain | P2 Cognition Issues |
|--------|---------------------|
| Code Review | Confusing logic, poor naming, unreadable code, missing context comments |
| Spec Review | Ambiguous terms, vague criteria, confusing structure, implementers will misunderstand |
| Test Review | Unclear test names, missing test documentation, confusing test setup |
| Design Review | Unclear scope, ambiguous success criteria, confusing terminology |

### P3: Conformant (Consider)

**Definition:** Code should follow project and team conventions. Consistency within a codebase aids understanding.

**This is third priority.** Deviation from team patterns creates cognitive load, but doesn't break functionality.

**Examples by domain:**

| Domain | P3 Conformant Issues |
|--------|----------------------|
| Code Review | Inconsistent with codebase patterns, deviates from project conventions |
| Spec Review | Inconsistent with how similar specs are written, deviates from team templates |
| Test Review | Test structure differs from team patterns, naming conventions not followed |
| Design Review | Format differs from team's design doc standards |

### P4: Compatible (Consider)

**Definition:** Code should follow language and ecosystem conventions. This aids understanding for anyone familiar with the technology.

**This is lowest priority.** Industry standards matter, but team conventions take precedence.

**Examples by domain:**

| Domain | P4 Compatible Issues |
|--------|----------------------|
| Code Review | Non-idiomatic for language/framework, ignores ecosystem standards |
| Spec Review | Deviates from industry standard spec formats (RFC style, etc.) |
| Test Review | Test patterns unfamiliar to developers from other teams |
| Design Review | Doesn't follow industry design doc conventions |

## Prioritization Algorithm

### Step 1: Deduplicate

If the same issue appears multiple times (from different reviewers or agents), keep only one instance in the highest applicable priority category.

### Step 2: Rank by Principle

For each issue, determine which Concinnity principle it violates:

1. Does it affect **correctness**? → P1
2. Does it affect **understandability**? → P2
3. Does it violate **project conventions**? → P3
4. Does it violate **language/ecosystem conventions**? → P4

**Important:** An issue's priority is determined by the principle it violates, not by who found it or how it was discovered.

### Step 3: Categorize into Buckets

Group issues into three actionable buckets:

| Bucket | Priorities | Meaning |
|--------|------------|---------|
| **Blocking** | P1 | Must fix before proceeding |
| **Should Fix** | P2 | Hard to understand = hard to maintain |
| **Consider** | P3, P4 | Consistency improvements |

## Output Format

Present prioritized feedback in this structure:

```markdown
## Blocking (P1 Correct)
1. [Issue description - why it's a correctness problem]
2. [Another correctness issue]

## Should Fix (P2 Cognition)
1. [Issue description - why it harms understanding]
2. [Another cognition issue]

## Consider (P3/P4 Conformant/Compatible)
1. [Issue description - which convention it violates]
2. [Another convention issue]
```

**Guidelines:**
- Each bucket may be empty if no issues at that priority
- Within a bucket, order issues by impact (most impactful first)
- Be specific about why each issue belongs in its bucket
- Do not include issues that aren't actionable

## Examples

### Code Review Example

**Raw issues:**
- Function returns wrong type
- Variable named `x` instead of `userId`
- Missing null check causes crash
- Uses `for` loop instead of `map()` (team convention)
- Inconsistent indentation

**Prioritized:**

```markdown
## Blocking (P1 Correct)
1. Missing null check in `processUser()` causes crash when user not found
2. Function `getConfig()` returns Promise but caller expects sync value

## Should Fix (P2 Cognition)
1. Variable `x` on line 45 should be named `userId` for clarity

## Consider (P3/P4 Conformant/Compatible)
1. Team convention: use `map()` instead of `for` loops for transformations
2. Inconsistent indentation (tabs vs spaces) on lines 12-15
```

### Spec Review Example

**Raw issues:**
- Success criteria says "fast" without defining threshold
- Missing section on error handling
- Uses "user" and "customer" interchangeably
- Different heading style than team template

**Prioritized:**

```markdown
## Blocking (P1 Correct)
1. Missing error handling requirements - implementers won't know how to handle failures

## Should Fix (P2 Cognition)
1. Success criteria "fast response time" needs quantified threshold (e.g., < 200ms)
2. Inconsistent terminology: "user" and "customer" used interchangeably

## Consider (P3/P4 Conformant/Compatible)
1. Heading style differs from team spec template (use ## not ###)
```

## Integration with Other Skills

This skill provides the prioritization logic used by:
- `five-agent-code-review` - Step 2 Supervisor Merge
- `five-agent-spec-review` - Step 2 Supervisor Merge
- `tola-review-tests` - Organizing test feedback

When using those skills, the Concinnity prioritization is applied automatically during the merge phase.

## Key Insight

> "A beautifully written, idiomatic piece of code that doesn't work is worthless."

The Concinnity framework encodes this wisdom: **correctness always comes first**. Style debates are only relevant once the code actually works and can be understood.
