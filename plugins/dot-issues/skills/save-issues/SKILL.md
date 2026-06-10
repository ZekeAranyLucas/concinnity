---
name: save-issues
description: Use after a review produces findings to persist them to .issues/ with checkbox-tracked accept/reject states. Step 1 of the dot-issues workflow (save → show → triage → fix); typically invoked by review skills rather than directly.
---

# Save Issues to the issues directory

## Overview

Save structured review feedback to the repo's issues directory (resolved at runtime — see "Resolve the Issues Directory" below). Each review session creates a dated file with issues formatted as tasks that can be accepted or rejected.

## When to Use

Use when:
- Completing a code review and need to save findings
- Completing a test review (tola-review-tests)
- Completing a spec review (five-agent-spec-review)
- Any review that produces actionable issues

## Resolve the Issues Directory

All dot-issues skills resolve their working directory through a shared script
shipped with this plugin:

```
${CLAUDE_PLUGIN_ROOT}/scripts/resolve-issues-dir.sh
```

`${CLAUDE_PLUGIN_ROOT}` (alias `${COPILOT_PLUGIN_ROOT}` / `${PLUGIN_ROOT}`) is
substituted by the runtime before the LLM reads this skill, so the path is
already absolute when bash sees it.

**Resolution order (write mode):**

1. `$DOT_ISSUES` — explicit user override (absolute or repo-relative path); skips the gitignore check
2. `.local/issues/` — if `.gitignore` contains a line that ignores `.local` (preferred default; one folder for all local working files)
3. `.issues/` — if `.gitignore` contains a line that ignores `.issues` (original layout)
4. Nothing matches → the script exits with code `2` and the skill must **prompt the user** to choose `.local/` or `.issues/`, add it to `.gitignore`, then re-run

**Read mode (`--read`)** returns every candidate directory that physically exists (in resolution order), so reviews written under the old layout remain visible after a project migrates.

### Invoking the script

Both `${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_PROJECT_DIR}` are substituted by the runtime before the LLM reads this skill, so the paths below are already absolute when bash sees them. Passing `--root` explicitly is preferred over relying on the script's `git rev-parse` / cwd fallback — it works even when the user invoked the agent from a subdirectory.

```bash
SCRIPT="${CLAUDE_PLUGIN_ROOT}/scripts/resolve-issues-dir.sh"
ROOT="${CLAUDE_PROJECT_DIR}"

# Write mode — absolute path on stdout, exit 2 if unresolved
ISSUES_DIR="$(bash "$SCRIPT" --root "$ROOT")" || {
  # Prompt the user to add .local/ or .issues/ to .gitignore, then retry.
  exit 2
}

# Read mode — newline-separated list of existing absolute dirs, exit 3 if none exist
mapfile -t ISSUES_READ_DIRS < <(bash "$SCRIPT" --root "$ROOT" --read)
```

### Prompt-on-fallback flow

When `resolve-issues-dir.sh` exits with code 2 (nothing resolved), ask the user — do not silently pick a default:

> No issues directory is configured. Where should review files go?
> 1. `.local/issues/` — recommended (one folder for all local working files; will add `.local/` to `.gitignore`)
> 2. `.issues/` — original layout (will add `.issues/` to `.gitignore`)
> 3. Set `$DOT_ISSUES` yourself and re-run

Apply the chosen change to `.gitignore`, then re-run the resolver.

## Folder Structure

After resolution, files live under `$ISSUES_DIR`:

```
project-root/
├── .local/issues/                    # OR .issues/ — resolved per project
│   ├── 2026-01-30__tola-review-tests.md
│   ├── 2026-01-30__code-review-auth-module.md
│   └── 2026-01-28__spec-review-api-design.md
├── .gitignore                        # Must ignore .local/ (or .issues/)
└── ...
```

## File Naming Convention

Files are written to `$ISSUES_DIR/{YYYY-MM-DD}__{review-type}.md`.

Examples (assuming `$ISSUES_DIR = .local/issues`):
- `.local/issues/2026-01-30__tola-review-tests.md`
- `.local/issues/2026-01-30__code-review-feature-login.md`
- `.local/issues/2026-01-30__spec-review-api-v2.md`

If multiple reviews of the same type on the same day:
- `.local/issues/2026-01-30__tola-review-tests.md`
- `.local/issues/2026-01-30__tola-review-tests-2.md`

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

1. Resolve `$ISSUES_DIR` via `resolve-issues-dir.sh` (prompt user on exit 2)
2. Create `$ISSUES_DIR/` if it doesn't exist
3. Create file: `$ISSUES_DIR/{YYYY-MM-DD}__{review-type}.md`
4. Write issues using the task-based format above
5. Tell user: "Review saved to `$ISSUES_DIR/{filename}`. Use `/dot-issues:show-issues` to track progress."
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

After saving issues, inform the user (substitute the resolved `$ISSUES_DIR`):

```
Review saved to .local/issues/2026-01-30__tola-review-tests.md

Next steps:
- Open the file and mark issues [x] accepted or [-] rejected
- Use /dot-issues:show-issues to see all open issues across reviews
```
