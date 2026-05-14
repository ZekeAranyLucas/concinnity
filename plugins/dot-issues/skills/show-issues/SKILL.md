---
name: show-issues
description: Scan the .issues/ folder, summarize open issues across all reviews, and offer to help resolve them
---

# Show Issues from .issues/

## Overview

Scan the `.issues/` folder for all review files, parse issue states, and present a summary of open issues. Offer to help resolve individual issues.

## When to Use

Use when:
- User wants to see outstanding issues from past reviews
- User says "show issues", "what issues are open", "dot issues show"
- Starting a work session and need to see what needs attention
- Checking progress on review feedback

## Workflow

### Step 1: Scan .issues/ Folder

```bash
# Find all issue files
ls -la .issues/*.md 2>/dev/null || echo "No .issues/ folder found"
```

If no `.issues/` folder exists, tell the user:
> No `.issues/` folder found. Run a review skill (like `/tola-review-tests`) to create issues.

### Step 2: Parse Each File

For each `.md` file in `.issues/`:

1. Extract metadata (review date, type, files reviewed)
2. Count issues by state:
   - `[ ]` = **Open** (not yet reviewed)
   - `[/]` = **Approved** (acknowledged, will fix)
   - `[x]` = **Fixed** (resolved)
   - `[-]` = **Rejected** (won't fix)
3. Extract open and approved issue summaries

**Parsing pattern for issues:**
```
### [ ] Issue {N}: {Category} - {Brief description}
### [/] Issue {N}: {Category} - {Brief description}
### [x] Issue {N}: {Category} - {Brief description}
### [-] Issue {N}: {Category} - {Brief description}
```

**State categories:**
- **Actionable** = Open + Approved (needs attention)
- **Closed** = Fixed + Rejected (no action needed)

### Step 3: Present Summary

```markdown
# Issues Summary

**Last updated:** {current date}
**Files scanned:** {count} review files in .issues/

## Overview

| Review | Date | Open | Approved | Fixed | Rejected |
|--------|------|------|----------|-------|----------|
| tola-review-tests | 2026-01-30 | 2 | 1 | 1 | 1 |
| code-review-auth | 2026-01-28 | 0 | 0 | 3 | 1 |
| spec-review-api | 2026-01-25 | 1 | 0 | 5 | 1 |
| **Total** | | **3** | **1** | **9** | **3** |

## Actionable Issues (Open + Approved)

### From tola-review-tests (2026-01-30)

- [ ] **#1 Test Isolation** - Shared mutable state in UserAuthTest.kt
- [/] **#2 Weak Assertion** - Only checks existence *(approved, will fix)*
- [ ] **#5 Smoke Test** - No assertions in LoggerTest.kt

### From spec-review-api (2026-01-25)

- [ ] **#4 Missing Requirement** - Error handling not specified

---

**Actionable: 4** (3 open, 1 approved)

Would you like me to help resolve any of these? Reply with the issue number or review name.
```

### Step 4: Offer Resolution Help

When user selects an issue:

1. Read the full issue from the file
2. Read the referenced source file
3. Propose a fix
4. If user accepts, apply the fix
5. Update the issue state:
   - `[ ]` → `[/]` when user approves but hasn't fixed yet
   - `[/]` → `[x]` when fix is applied
   - `[ ]` → `[x]` when fix is applied directly
   - `[ ]` → `[-]` when user rejects

**Resolution flow:**
```markdown
## Resolving: Issue #1 from tola-review-tests

**Issue:** Test Isolation - Shared mutable state in UserAuthTest.kt

**Current code:**
```kotlin
class UserAuthTest {
    private val authManager = AuthManager()  // Shared
}
```

**Proposed fix:**
```kotlin
class UserAuthTest {
    @Test fun login_success() {
        val authManager = AuthManager()  // Fresh instance
        // ...
    }
}
```

Apply this fix? (yes/no)
```

After applying:
```markdown
Fixed! Updated UserAuthTest.kt and marked issue as resolved.

Remaining open issues: 3
```

## Edge Cases

### No Issues Folder
```
No .issues/ folder found.

To create issues, run a review skill:
- /tola-review-tests - Review test code
- /five-agent-code-review - Review code changes
- /five-agent-spec-review - Review specs/designs
```

### All Issues Closed
```
# Issues Summary

All issues are resolved!

**Files scanned:** 3 review files
**Total issues:** 12 (all closed)

You can archive old review files:
  mv .issues/2026-01-*.md .issues/archive/
```

### Empty Issues Folder
```
The .issues/ folder exists but contains no review files.

Run a review skill to create issues.
```

## File Operations

### Update Issue State

**Approve an issue (will fix later):**
```markdown
### [/] Issue 1: Test Isolation - Shared mutable state
...
*Approved 2026-01-30 - Will fix in next commit*
```

**Mark as fixed:**
```markdown
### [x] Issue 1: Test Isolation - Shared mutable state
...
*Fixed 2026-01-30 - Created fresh instances in each test (commit abc123)*
```

**Reject an issue:**
```markdown
### [-] Issue 3: Naming - Consider renaming variable
...
*Rejected 2026-01-30 - Matches existing team convention*
```

### Archive Old Reviews

Suggest archiving when reviews are fully resolved:

```bash
mkdir -p .issues/archive
mv .issues/2026-01-15__*.md .issues/archive/
```

## Integration

This skill works with issues created by:
- `tola-review-tests`
- `five-agent-code-review`
- `five-agent-spec-review`
- `ado-pr-review`
- Any skill using the `save-issues` format

## Quick Commands

| User says | Action |
|-----------|--------|
| "show issues" | Run full scan and summary |
| "open issues" | Show only open + approved issues |
| "approve #3" | Mark issue #3 as approved (will fix) |
| "resolve #3" | Help fix issue #3 from most recent review |
| "resolve tola #1" | Help fix issue #1 from tola review |
| "reject #3" | Mark issue #3 as rejected (won't fix) |
| "archive old" | Move fully-resolved reviews to archive |
