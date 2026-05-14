---
name: save-issues
description: Save review issues to the .issues/ folder with task-based format for tracking accept/reject workflow
---

# Save Issues to .issues/

## Overview

Save structured review feedback to the `.issues/` folder in the repository root. Each review session creates a dated file with issues formatted as tasks that can be accepted or rejected.

## When to Use

Use when:
- Completing a code review and need to save findings
- Completing a test review (tola-review-tests)
- Completing a spec review (five-agent-spec-review)
- Any review that produces actionable issues

## Folder Structure

```
project-root/
├── .issues/                          # All review files go here
│   ├── 2026-01-30__tola-review-tests.md
│   ├── 2026-01-30__code-review-auth-module.md
│   └── 2026-01-28__spec-review-api-design.md
├── .gitignore                        # Should include .issues/
└── ...
```

## Setup: Add to .gitignore

Before first use, ensure `.issues/` is gitignored:

```bash
# Check if .gitignore exists and has .issues/
grep -q "^\.issues" .gitignore 2>/dev/null || echo ".issues/" >> .gitignore
```

Or manually add to `.gitignore`:
```
# Review issues (local working documents)
.issues/
```

## File Naming Convention

```
{YYYY-MM-DD}__{review-type}.md
```

Examples:
- `2026-01-30__tola-review-tests.md`
- `2026-01-30__code-review-feature-login.md`
- `2026-01-30__spec-review-api-v2.md`

If multiple reviews of the same type on the same day:
- `2026-01-30__tola-review-tests.md`
- `2026-01-30__tola-review-tests-2.md`

## Issue Format

Each issue is a task with checkbox for accept/reject workflow:

```markdown
### [ ] Issue {N}: {Category} - {Brief description}

**File:** [{relative/path/to/File.ext}:{startLine}-{endLine}]({relative/path/to/File.ext})

**Code:**
```{language}
// The problematic code snippet
```

**Problem:** {Explanation of what's wrong}

**Suggestion:** {How to fix it}

---
```

### Checkbox States

- `[ ]` - **Open**: Not yet reviewed
- `[/]` - **Approved**: Acknowledged as valid, will fix
- `[x]` - **Fixed**: Issue has been resolved
- `[-]` - **Rejected**: Won't fix (with optional reason)

**Workflow:**
```
[ ] Open → [/] Approved → [x] Fixed
         ↘ [-] Rejected
```

When changing state, add a note:
```markdown
### [/] Issue 1: Test Isolation - Shared mutable state
...
*Approved 2026-01-30 - Will fix in next commit*

### [x] Issue 2: Weak Assertion - Only checks existence
...
*Fixed 2026-01-30 - commit abc123*

### [-] Issue 3: Naming - Consider renaming variable
...
*Rejected - Matches team convention*
```

## Full File Template

```markdown
# {Review Type}: {Subject}

**Reviewed:** {YYYY-MM-DD}
**Reviewer:** Claude ({skill-name} skill)
**Files:** {count} files reviewed

---

### [ ] Issue 1: {Category} - {Brief description}

**File:** [{path}:{lines}]({path})

**Code:**
```{lang}
// snippet
```

**Problem:** {explanation}

**Suggestion:** {fix}

---

### [ ] Issue 2: {Category} - {Brief description}

...

---

## Summary

**Issues found:** {count}
**By priority:**
- Must Fix: {count}
- Should Fix: {count}
- Consider: {count}

### Recommendations

| Priority | Issue | Recommendation |
|----------|-------|----------------|
| Must Fix | #1 {title} | {why} |
| Should Fix | #2 {title} | {why} |
| Consider | #3 {title} | {why} |

### Next Steps

1. Review issues above and mark `[x]` to accept or `[-]` to reject
2. For accepted issues, apply the suggested fixes
3. Re-run tests/checks to verify fixes
4. Use `/dot-issues:show-issues` to see remaining open issues
```

## Integration with Review Skills

Review skills should call this pattern at the end of their workflow:

```markdown
## Output

After completing the review, save issues using the save-issues format:

1. Create `.issues/` folder if it doesn't exist
2. Create file: `.issues/{YYYY-MM-DD}__{review-type}.md`
3. Write issues using the task-based format above
4. Tell user: "Review saved to `.issues/{filename}`. Use `/dot-issues:show-issues` to track progress."
```

## Example: After tola-review-tests

```markdown
# Test Review: UserAuthTest.kt, SessionManagerTest.kt

**Reviewed:** 2026-01-30
**Reviewer:** Claude (tola-review-tests skill)
**Files:** 2 files reviewed

---

### [ ] Issue 1: Test Isolation - Shared mutable state

**File:** [src/test/kotlin/com/example/UserAuthTest.kt:5-12](src/test/kotlin/com/example/UserAuthTest.kt)

**Code:**
```kotlin
class UserAuthTest {
    private val authManager = AuthManager()  // Shared across tests

    @Test fun login_success() { authManager.login("user", "pass") }
    @Test fun logout_clearsSession() { /* authManager still logged in! */ }
}
```

**Problem:** The `authManager` instance is shared across tests. State from `login_success` carries over to `logout_clearsSession`.

**Suggestion:** Create a fresh `AuthManager()` instance inside each test method.

---

### [/] Issue 2: Weak Assertion - Only checks existence

**File:** [src/test/kotlin/com/example/SessionManagerTest.kt:25](src/test/kotlin/com/example/SessionManagerTest.kt)

**Code:**
```kotlin
assertNotNull(session.token)
```

**Problem:** Only verifies token exists, not that it's the correct token.

**Suggestion:** Assert the expected token value: `assertEquals("expected-token-123", session.token)`

*Approved 2026-01-30 - Will fix in next commit*

---

## Summary

**Issues found:** 2
**By priority:**
- Must Fix: 1
- Should Fix: 1
- Consider: 0

### Recommendations

| Priority | Issue | Recommendation |
|----------|-------|----------------|
| Must Fix | #1 Test isolation | Prevents flaky test failures |
| Should Fix | #2 Weak assertion | Test won't catch token bugs |

### Next Steps

1. Review issues above and mark `[x]` to accept or `[-]` to reject
2. For accepted issues, apply the suggested fixes
3. Re-run tests to verify fixes
4. Use `/dot-issues:show-issues` to see remaining open issues
```

## Commands

After saving issues, inform the user:

```
Review saved to .issues/2026-01-30__tola-review-tests.md

Next steps:
- Open the file and mark issues [x] accepted or [-] rejected
- Use /dot-issues:show-issues to see all open issues across reviews
```
