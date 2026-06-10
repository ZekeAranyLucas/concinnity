---
name: fix-issues
description: Use when applying approved fixes from the issues directory — for example "fix the approved issues", "apply the accepted fixes", "do the fixes we agreed on". Step 4 of the dot-issues workflow; groups approved issues by file and dispatches fix agents serially with verification.
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
- There are approved (`[/]`) issues in the issues directory that need fixing
- User wants automated help resolving review feedback

## Prerequisites

- Issues directory resolved (see "Resolve the Issues Directory" below) containing review files with `[/]` (approved) state
- Source files accessible for editing

## Resolve the Issues Directory

Fix reads from any existing location and writes state updates back to the originating file. Full algorithm in `save-issues/SKILL.md`.

`${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_PROJECT_DIR}` are substituted by the runtime before this skill is rendered.

```bash
mapfile -t ISSUES_READ_DIRS < <(bash "${CLAUDE_PLUGIN_ROOT}/scripts/resolve-issues-dir.sh" --root "${CLAUDE_PROJECT_DIR}" --read)
if [ "${#ISSUES_READ_DIRS[@]}" -eq 0 ]; then
  echo "No issues directory found. Use a review skill to create one."
  exit 0
fi
```

---

## Workflow

### Step 1: Scan for Approved Issues

First, find all approved issues across every readable directory:

```bash
# Find all [/] issues
for dir in "${ISSUES_READ_DIRS[@]}"; do
  grep -rn "^### \[/\]" "$dir"/*.md
done
```

Parse each match to extract:
- Review file path (which `.md` file under which directory)
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

After each File Fix Agent completes, verify the fixes and update the originating `.md` file in place (do not move it to a different directory):

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
3. Use `/dot-issues:show-issues` to see remaining open issues
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
│ → Update issue file states  │               │
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

- **No approved issues:** "No approved issues found. Use `/dot-issues:show-issues` to review and approve issues first."
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
