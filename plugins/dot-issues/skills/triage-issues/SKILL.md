---
name: triage-issues
description: Use when going through review findings one at a time to accept, reject, or skip — for example "let's triage these issues", "review them with me one by one", "decide what to fix". Step 3 of the dot-issues workflow, after issues are saved but before fixing.
---

# Triage Issues Interactively

## Overview

Walk through each open issue (`[ ]` state) one at a time, presenting details and fix options, then recording the user's decision (accept, reject, or skip) before moving to the next issue.

## When to Use

Use when:
- User says "triage issues", "review issues one by one", "dot issues triage"
- User wants to make accept/reject decisions on review feedback
- Starting triage of a new review's findings
- User wants to understand each issue before deciding

## Prerequisites

- Issues in `.issues/` folder with `[ ]` (open) state
- Source files accessible for reading

---

## Workflow

### Step 1: Scan for Open Issues

Find all open issues across all review files:

```bash
# Find all [ ] issues (open, not yet triaged)
grep -rn "^### \[ \]" .issues/*.md 2>/dev/null
```

If no open issues found:
> No open issues to triage. All issues have been reviewed.
> Use `/dot-issues:show-issues` to see the full status.

Parse each match to extract:
- Review file path
- Issue number
- Category
- Brief description

### Step 2: Sort by Concinnity Priority (Subagent)

Launch a **Prioritizer Agent** to sort issues using the Concinnity framework.

**Prioritizer Agent Prompt:**
```
You are the Issue Prioritizer. Given a list of open issues, categorize each into exactly one Concinnity priority level:

## Concinnity Framework (strict priority order)

| Priority | Principle | Definition |
|----------|-----------|------------|
| **P1** | **Correct** | Does the code work? Bugs, race conditions, test pollution, weak assertions, missing error handling |
| **P2** | **Cognition** | Can humans understand it? Confusing logic, poor naming, unclear test names, missing context |
| **P3** | **Conformant** | Follows project conventions? Team patterns, project style, local standards |
| **P4** | **Compatible** | Follows language/ecosystem standards? Idiomatic code, industry conventions |

## Your Task

For each issue:
1. Read the issue description and category
2. Determine which Concinnity principle it violates
3. Assign the appropriate priority

## Input

{list of open issues with their descriptions}

## Output

Return as JSON, sorted by priority:
{
  "P1": [
    {"id": "tola-review-tests#2", "title": "Weak Assertion", "reason": "Test doesn't catch bugs"}
  ],
  "P2": [
    {"id": "tola-review-tests#1", "title": "Test Isolation", "reason": "Confusing shared state"}
  ],
  "P3": [
    {"id": "tola-review-tests#3", "title": "Import Wildcard", "reason": "Team convention"}
  ],
  "P4": []
}
```

**Use the agent result** to build the triage queue in priority order: P1 first, then P2, P3, P4. This ensures the most critical issues are triaged first.

### Step 3: Present Queue Summary

Before starting, show what will be triaged (sorted by Concinnity priority):

```markdown
# Issue Triage

**Open issues to review:** {count}
**Sorted by:** Concinnity priority (Correct > Cognition > Conformant > Compatible)

| # | Priority | Review | Issue | Category |
|---|----------|--------|-------|----------|
| 1 | P1 Correct | tola-review-tests | #2 Weak Assertion | Test doesn't catch bugs |
| 2 | P1 Correct | code-review-auth | #4 Missing Validation | Null pointer crash |
| 3 | P2 Cognition | tola-review-tests | #1 Test Isolation | Confusing shared state |
| 4 | P3 Conformant | tola-review-tests | #3 Import Wildcard | Team convention |

Starting triage. For each issue I'll show:
- The problematic code
- Why it's flagged
- Options for fixing

You can respond: **accept**, **reject**, or **skip**

---
```

### Step 4: Triage Each Issue

For each open issue (in Concinnity priority order), follow this flow:

#### 4a. Read and Present the Issue

Read the full issue from the `.issues/` file and the referenced source file.

Present to the user:

```markdown
## Issue 1 of {total}: [{priority}] {Category} - {Brief description}

**Priority:** {P1 Correct | P2 Cognition | P3 Conformant | P4 Compatible}
**From:** {review-file}
**File:** [{path}:{lines}]({path}#L{start}-L{end})

### Current Code

```{language}
// The problematic code from source file
```

### Problem

{Explanation from the issue of what's wrong}

### Fix Options

**Option A: {Primary fix}**
```{language}
// Suggested fix code
```

**Option B: {Alternative approach}** (if applicable)
```{language}
// Alternative fix
```

**Option C: No change needed** - Reject if this is acceptable as-is

---

**Your decision:**
- **accept** - Approve this issue for fixing (marks as `[/]`)
- **reject** - Won't fix, close the issue (marks as `[-]`)
- **skip** - Leave open, decide later (stays as `[ ]`)
```

#### 4b. Wait for User Decision

Use AskUserQuestion to get the user's decision:

```
Question: What would you like to do with this issue?

Options:
- Accept (will fix)
- Reject (won't fix)
- Skip (decide later)
```

#### 4c. Record the Decision

Based on user response, update the issue in the `.issues/` file:

**If Accept:**
```markdown
### [/] Issue 1: Test Isolation - Shared mutable state

...existing content...

*Approved {YYYY-MM-DD} - {optional user note or "Will fix"}*
```

**If Reject:**
```markdown
### [-] Issue 1: Test Isolation - Shared mutable state

...existing content...

*Rejected {YYYY-MM-DD} - {user's reason if provided, or "Won't fix"}*
```

**If Skip:**
- Leave the issue unchanged (`[ ]` state)
- Add a note if user provided context:
```markdown
### [ ] Issue 1: Test Isolation - Shared mutable state

...existing content...

*Skipped {YYYY-MM-DD} - {user's note if any}*
```

#### 4d. Confirm and Continue

After recording:

```markdown
Recorded: **{decision}** for Issue #{n}

{count} issues remaining. Continuing to next issue...

---
```

### Step 5: Triage Summary

After all issues are processed (or user stops early):

```markdown
# Triage Complete

**Issues reviewed:** {count}
**Accepted (will fix):** {count}
**Rejected (won't fix):** {count}
**Skipped (still open):** {count}

## Decisions Made

| Priority | Issue | Decision | Note |
|----------|-------|----------|------|
| P1 | tola#2 Weak Assertion | Accepted | Test doesn't catch bugs |
| P2 | tola#1 Test Isolation | Accepted | Will fix in next commit |
| P3 | tola#3 Import Wildcard | Skipped | Need to check team style |

## Next Steps

{If accepted issues exist:}
- Run `/dot-issues:fix-issues` to automatically fix accepted issues
- Or fix manually and mark as `[x]` when done

{If skipped issues exist:}
- Run `/dot-issues:triage-issues` again to review skipped issues
- Or use `/dot-issues:show-issues` to see all issue states
```

---

## Interactive Commands During Triage

The user can say these at any point:

| Command | Action |
|---------|--------|
| "accept" / "yes" / "approve" | Mark issue as approved `[/]` |
| "reject" / "no" / "won't fix" | Mark issue as rejected `[-]` |
| "skip" / "later" / "next" | Leave open, move to next |
| "accept all" | Accept all remaining issues |
| "reject all" | Reject all remaining issues |
| "stop" / "done" / "quit" | End triage, show summary |
| "show code" | Re-display the source code |
| "explain more" | Provide more context about the issue |

---

## Presenting Fix Options

When presenting fix options, tailor to the issue category:

### Refactor Issues
- Show before/after of structural change
- Explain impact on test isolation or code organization

### Assertion Issues
- Show the weak assertion and stronger alternative
- Explain what bugs the stronger assertion would catch

### Style Issues
- Show the style violation and corrected form
- Reference team conventions if known

### Import Issues
- List the specific imports that would replace wildcards
- Show the cleaned up import block

### Logic Issues
- Explain the logical flaw
- Show corrected logic with edge cases considered

---

## Edge Cases

### Large Number of Issues

If more than 10 open issues:

```markdown
Found {count} open issues to triage.

Would you like to:
1. **Triage all** - Review each issue in priority order (default)
2. **Triage P1 only** - Only review Correct (blocking) issues
3. **Triage by review** - Focus on one review file at a time
4. **Triage by category** - Review all Refactor issues, then Assertion, etc.
5. **Quick mode** - Show brief summaries, faster decisions
```

### User Wants to Stop Early

If user says "stop", "done", or "quit":

```markdown
Stopping triage early.

**Progress:** {reviewed} of {total} issues triaged
**Accepted:** {count}
**Rejected:** {count}
**Skipped:** {count}
**Not yet reviewed:** {remaining}

Run `/dot-issues:triage-issues` again to continue from where you left off.
```

### Source File Not Found

If the referenced source file doesn't exist:

```markdown
## Issue {n}: {description}

**Warning:** Source file not found: {path}

The file may have been moved, renamed, or deleted since the review.

**Options:**
- **reject** - Close this issue (file no longer exists)
- **skip** - Leave open in case file is restored
- **locate** - Help me find where this code moved to
```

### Issue Already Has Notes

If issue has previous skip/triage notes, show them:

```markdown
## Issue {n}: {description}

**Previous notes:**
- *Skipped 2026-01-28 - Need to discuss with team*
- *Skipped 2026-01-29 - Still waiting on decision*

{rest of issue presentation}
```

---

## Integration

**Uses:**
- `zodiac-team:prioritize` - For sorting issues by priority

**Works with issues created by:**
- `tola-review-tests`
- `five-agent-code-review`
- `five-agent-spec-review`
- `ado-pr-review`
- Any skill using the `save-issues` format

**After triage, use:**
- `/dot-issues:fix-issues` to automatically fix accepted issues
- `/dot-issues:show-issues` to see updated status

---

## Quick Reference

```
/dot-issues:triage-issues          # Start interactive triage (sorted by Concinnity priority)
/dot-issues:triage-issues tola     # Only triage issues from tola-review-tests
/dot-issues:triage-issues --p1     # Only triage P1 Correct (blocking) issues
/dot-issues:triage-issues --quick  # Quick mode (brief summaries)
```
