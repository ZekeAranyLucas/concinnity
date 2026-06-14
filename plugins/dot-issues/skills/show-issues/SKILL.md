---
name: show-issues
description: Use when checking what review issues are still open across past reviews, starting a work session, or asking "what's left to do?", "any open issues?", "where did we leave off?". Scans the issues directory (`.local/issues/`, `.issues/`, or `$DOT_ISSUES`) across all reviews and summarizes by state.
---

# Show Issues from the issues directory

## Overview

Scan the repo's issues directory for all review files, parse issue states, and present a summary of open issues. Offer to help resolve individual issues.

## When to Use

Use when:
- User wants to see outstanding issues from past reviews
- User says "show issues", "what issues are open", "dot issues show"
- Starting a work session and need to see what needs attention
- Checking progress on review feedback

## Resolve the Issues Directory

This skill is read-mostly. Use the resolver script (shipped with this plugin)
in `--read` mode so legacy `.issues/` data is still visible after a project
migrates to `.local/issues/`.

`${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_PROJECT_DIR}` are substituted by the runtime before this skill is rendered, so the paths below are already absolute when bash sees them.

```bash
mapfile -t ISSUES_READ_DIRS < <(bash "${CLAUDE_PLUGIN_ROOT}/scripts/resolve-issues-dir.sh" --root "${CLAUDE_PROJECT_DIR}" --read)
if [ "${#ISSUES_READ_DIRS[@]}" -eq 0 ]; then
  echo "No issues directory found. Run a review skill to create one."
  exit 0
fi
```

When updating issue state (approve / fix / reject), write back to the **same file** that was read (not the resolved write location), so legacy data stays in place.

## Workflow

### Step 1: Scan the issues directory

```bash
# Find all issue files across every readable location
for dir in "${ISSUES_READ_DIRS[@]}"; do
  ls -la "$dir"/*.md 2>/dev/null
done
```

If `ISSUES_READ_DIRS` is empty, tell the user:
> No issues directory found. Run a review skill (like `/tola-review-tests`) to create issues.

### Step 2: Parse Each File

For each `.md` file across `ISSUES_READ_DIRS`:

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
**Files scanned:** {count} review files across {ISSUES_READ_DIRS joined with ", "}

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
No issues directory found (checked $DOT_ISSUES, .local/issues/, .issues/).

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

You can archive old review files in place:
  for dir in "${ISSUES_READ_DIRS[@]}"; do
    mkdir -p "$dir/archive"
    mv "$dir"/2026-01-*.md "$dir/archive/" 2>/dev/null
  done
```

### Empty Issues Folder
```
The issues directory exists but contains no review files.

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

Suggest archiving when reviews are fully resolved. Archive in place — keep each file in the directory it was read from so legacy `.issues/` data doesn't get silently relocated to `.local/issues/`:

```bash
for dir in "${ISSUES_READ_DIRS[@]}"; do
  mkdir -p "$dir/archive"
  mv "$dir"/2026-01-15__*.md "$dir/archive/" 2>/dev/null
done
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
