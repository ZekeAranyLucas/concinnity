---
name: dot-issues-fix
description: Fix approved issues by grouping them by file and dispatching fix agents serially with verification
---

# Fix Approved Issues

## Overview

Automatically fix issues that have been approved (`[/]` state) by:
1. Grouping issues by source file
2. Creating tasks to track progress
3. Dispatching a Fix Agent subagent for each file (serially)
4. Verifying each fix before marking as resolved

## When to Use

Use when:
- User says "fix issues", "fix approved issues", "dot issues fix"
- There are approved (`[/]`) issues in `.issues/` that need fixing
- User wants automated help resolving review feedback

## Prerequisites

- Issues in `.issues/` folder with `[/]` (approved) state
- Source files accessible for editing

---

## Workflow

### Step 1: Scan for Approved Issues

First, find all approved issues across all review files:

```bash
# Find all [/] issues
grep -rn "^### \[/\]" .issues/*.md
```

Parse each match to extract:
- Review file path (which `.issues/` file)
- Issue number and ID (e.g., `tola-review-tests#3`)
- Category
- Description
- **Source file** and line numbers
- Code snippet
- Suggestion

### Step 2: Group Issues by Source File

Group all approved issues by their **source file path**. This ensures:
- All fixes to a single file happen together
- No concurrent edit conflicts
- Related issues are fixed in context

**Example grouping:**
```
src/test/UserAuthTest.kt:
  - tola-review-tests#1: Test Isolation (lines 5-12)
  - tola-review-tests#4: Weak Assertion (line 25)
  - tola-review-tests#7: Style - double-bang (line 8)

src/test/SessionManagerTest.kt:
  - tola-review-tests#2: Weak Assertion (line 15)
  - tola-review-tests#3: Import Wildcard (line 3)

src/main/AuthService.kt:
  - code-review#5: Missing null check (line 42)
```

### Step 3: Create Tasks for Tracking

Use **TaskCreate** to create a task for each source file:

```
TaskCreate:
  subject: "Fix 3 issues in UserAuthTest.kt"
  description: "Apply fixes for issues #1, #4, #7"
  activeForm: "Fixing UserAuthTest.kt"

TaskCreate:
  subject: "Fix 2 issues in SessionManagerTest.kt"
  description: "Apply fixes for issues #2, #3"
  activeForm: "Fixing SessionManagerTest.kt"

TaskCreate:
  subject: "Fix 1 issue in AuthService.kt"
  description: "Apply fix for issue #5"
  activeForm: "Fixing AuthService.kt"
```

### Step 4: Execute Fix Agents by File (Serial)

For each source file, dispatch a **File Fix Agent** subagent.

**IMPORTANT:** Run file agents SERIALLY, not in parallel. This prevents conflicts if files have dependencies.

**Before each file:**
```
TaskUpdate: status = "in_progress"
```

**File Fix Agent Prompt:**
```
You are the File Fix Agent. Fix all approved issues in this file:

**File:** {source_file_path}

**Issues to fix:**

{For each issue in this file:}
## Issue {id}: {category} - {description}
**Lines:** {start}-{end}
**Current code:**
```{lang}
{code snippet}
```
**Problem:** {explanation}
**Suggestion:** {fix}

---

## Instructions

1. Read the source file
2. Apply ALL fixes for this file
3. Ensure fixes don't conflict with each other
4. Preserve code that isn't part of an issue

## Fix Guidelines by Category

- **Refactor**: Move shared state to local variables, extract methods
- **Assertion**: Replace weak assertions with specific expected values
- **Import**: Replace wildcards with explicit imports
- **Style**: Apply style fixes (double-bang → requireNotNull, etc.)
- **Delete**: Remove identified dead/duplicate code

## Output

After applying fixes, report status for each issue:
- FIXED: Successfully applied
- SKIPPED: Could not apply (explain why)
- CONFLICT: Fix conflicts with another issue
```

**After each file agent completes:**
```
TaskUpdate: status = "completed"
```

### Step 5: Verify and Update Issue States

After each File Fix Agent completes, verify the fixes and update the `.issues/` file:

**VERIFIED → Mark as Fixed:**
```markdown
### [x] Issue 1: Test Isolation - Shared mutable state

...

*Fixed 2026-01-31 - Moved selector to local variable in each test*
```

**PARTIAL → Keep Approved with Note:**
```markdown
### [/] Issue 2: Weak Assertion - Only checks existence

...

*Partially fixed 2026-01-31 - Needs manual review*
```

**FAILED → Keep Approved with Note:**
```markdown
### [/] Issue 5: Test Isolation - Manager instance shared

...

*Fix attempted 2026-01-31 - Automated fix failed, needs manual intervention*
```

---

## Output

After all files are processed, report:

```markdown
# Fix Summary

**Files processed:** 3
**Issues processed:** 6
**Fixed:** 5
**Skipped:** 1

## By File

| File | Issues | Fixed | Skipped |
|------|--------|-------|---------|
| UserAuthTest.kt | 3 | 3 | 0 |
| SessionManagerTest.kt | 2 | 1 | 1 |
| AuthService.kt | 1 | 1 | 0 |

## Details

### Fixed
- [x] tola#1: Test Isolation in UserAuthTest.kt
- [x] tola#4: Weak Assertion in UserAuthTest.kt
- [x] tola#7: Style in UserAuthTest.kt
- [x] tola#2: Weak Assertion in SessionManagerTest.kt
- [x] code#5: Null check in AuthService.kt

### Skipped
- [/] tola#3: Import Wildcard in SessionManagerTest.kt - conflicts with test framework

## Next Steps

1. Run tests to verify fixes: `./gradlew test`
2. Review skipped issues manually
3. Use `/dot-issues-show` to see remaining open issues
```

---

## Execution Flow Diagram

```
Start
  │
  ▼
┌─────────────────────────────┐
│ Scan for [/] approved issues │
└─────────────────────────────┘
  │
  ▼
┌─────────────────────────────┐
│ Group issues by source file │
└─────────────────────────────┘
  │
  ▼
┌─────────────────────────────┐
│ TaskCreate for each file    │
│ → Track progress visibly    │
└─────────────────────────────┘
  │
  ▼
┌─────────────────────────────┐
│ For each source file        │◄──────────────┐
│ (SERIAL execution)          │               │
└─────────────────────────────┘               │
  │                                           │
  ▼                                           │
┌─────────────────────────────┐               │
│ TaskUpdate: in_progress     │               │
└─────────────────────────────┘               │
  │                                           │
  ▼                                           │
┌─────────────────────────────┐               │
│ File Fix Agent (subagent)   │               │
│ → Fix ALL issues in file    │               │
└─────────────────────────────┘               │
  │                                           │
  ▼                                           │
┌─────────────────────────────┐               │
│ Verify fixes                │               │
│ → Update .issues/ states    │               │
└─────────────────────────────┘               │
  │                                           │
  ▼                                           │
┌─────────────────────────────┐               │
│ TaskUpdate: completed       │               │
└─────────────────────────────┘               │
  │                                           │
  ├── More files? ────────────────────────────┘
  │
  ▼
┌─────────────────────────────┐
│ Generate summary report     │
└─────────────────────────────┘
  │
  ▼
 Done
```

---

## Error Handling

- **No approved issues:** "No approved issues found. Use `/dot-issues-show` to review and approve issues first."
- **File not found:** Skip issue, mark as FAILED with "Source file not found"
- **Parse error:** Skip issue, mark as FAILED with "Could not parse issue format"
- **Compile error after fix:** Revert change, mark as BROKEN
- **All fixes failed:** Report summary and suggest manual review

---

## Quick Commands

| User says | Action |
|-----------|--------|
| "fix issues" | Run full workflow on all approved issues |
| "fix UserAuthTest.kt" | Only fix issues in that specific file |
| "fix tola issues" | Only fix issues from tola-review-tests |
| "dry run fix" | Show what would be fixed without applying |
