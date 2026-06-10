#!/usr/bin/env bash
# resolve-issues-dir.sh — Resolve the issues directory for dot-issues skills.
#
# Project root resolution (in order):
#   1. --root <path> flag
#   2. $CLAUDE_PROJECT_DIR env var (substituted by Claude Code / Copilot)
#   3. $COPILOT_PROJECT_DIR env var (alias)
#   4. `git rev-parse --show-toplevel` if git is available
#   5. current working directory
# The script cds into the resolved root before reading .gitignore, then emits
# absolute paths so callers can use the result regardless of their own cwd.
#
# Resolution order (write mode, the default):
#   1. $DOT_ISSUES env var — used as-is; trust the user. May be absolute or
#      relative to the resolved project root.
#   2. <root>/.local/issues  — if .gitignore contains a line that ignores .local
#   3. <root>/.issues        — if .gitignore contains a line that ignores .issues
#   4. (none)                — exit code 2; caller must prompt the user to pick
#                              a location, add it to .gitignore, then re-run.
#
# Read mode (--read):
#   Print every candidate directory that physically exists, one per line,
#   in resolution order. Includes both .local/issues/ and .issues/ if both
#   are present, so legacy reviews are not lost after a repo migrates from
#   one layout to the other. Exits 0 if at least one directory exists;
#   exits 3 (with no stdout) if none exist.
#
# Output: absolute paths (no trailing slash) on stdout — a single line in
# write mode, one per line in read mode. Errors go to stderr.
#
# Exit codes:
#   0  — success (path printed)
#   2  — write mode: no location could be resolved
#   3  — read mode: no candidate directories exist
#   64 — usage error (unknown flag)
#   65 — project root does not exist or is not a directory

set -u

mode="write"
root=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --read) mode="read"; shift ;;
    --write) mode="write"; shift ;;
    --root) root="${2:-}"; shift 2 ;;
    --root=*) root="${1#--root=}"; shift ;;
    -h|--help)
      sed -n '2,36p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      printf 'resolve-issues-dir.sh: unknown argument: %s\n' "$1" >&2
      exit 64
      ;;
  esac
done

# Resolve the project root: flag > CLAUDE_PROJECT_DIR > COPILOT_PROJECT_DIR
# > git toplevel > cwd. Empty values fall through.
if [ -z "$root" ]; then root="${CLAUDE_PROJECT_DIR:-}"; fi
if [ -z "$root" ]; then root="${COPILOT_PROJECT_DIR:-}"; fi
if [ -z "$root" ]; then
  root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
fi
if [ -z "$root" ]; then root="$PWD"; fi

if [ ! -d "$root" ]; then
  printf 'resolve-issues-dir.sh: project root does not exist: %s\n' "$root" >&2
  exit 65
fi
cd "$root" || exit 65
# Use the resolved absolute path for all output.
root="$PWD"

# Return 0 if .gitignore exists and ignores the given top-level name.
# Accepts patterns like:   .local   .local/   /.local   /.local/
# Skips comments and blank lines. Negations (!.local) are not honored.
gitignore_contains() {
  name="$1"
  [ -f .gitignore ] || return 1
  # Strip CR (for CRLF files), comments, leading/trailing whitespace.
  awk -v target="$name" '
    {
      sub(/\r$/, "")
      sub(/#.*/, "")
      gsub(/^[ \t]+|[ \t]+$/, "")
      if ($0 == "") next
      line = $0
      sub(/^\//, "", line)
      sub(/\/$/, "", line)
      if (line == target) { found = 1; exit }
    }
    END { exit (found ? 0 : 1) }
  ' .gitignore
}

# Resolve the primary (write) destination. Echoes ABSOLUTE path on stdout, or
# returns 1 if nothing resolves. $DOT_ISSUES may be absolute or relative; if
# relative, it is interpreted relative to the resolved project root.
resolve_primary() {
  if [ -n "${DOT_ISSUES:-}" ]; then
    local dst="${DOT_ISSUES%/}"
    case "$dst" in
      /*) printf '%s\n' "$dst" ;;
      *)  printf '%s/%s\n' "$root" "$dst" ;;
    esac
    return 0
  fi
  if gitignore_contains ".local"; then
    printf '%s/.local/issues\n' "$root"
    return 0
  fi
  if gitignore_contains ".issues"; then
    printf '%s/.issues\n' "$root"
    return 0
  fi
  return 1
}

if [ "$mode" = "write" ]; then
  if primary="$(resolve_primary)"; then
    printf '%s\n' "$primary"
    exit 0
  fi
  cat >&2 <<EOF
resolve-issues-dir.sh: no issues directory could be resolved.
Project root: $root

Set one of the following and re-run:
  - export DOT_ISSUES=path/to/dir     (explicit override)
  - add ".local/" to .gitignore       (then this script returns <root>/.local/issues)
  - add ".issues/" to .gitignore      (then this script returns <root>/.issues)
EOF
  exit 2
fi

# Read mode: list every candidate that physically exists, in resolution order,
# deduped. Always checks $DOT_ISSUES, <root>/.local/issues, and <root>/.issues —
# independent of what .gitignore says — so legacy data is never hidden from
# readers. Emits absolute paths.
emitted=""
emit_if_exists() {
  dir="$1"
  [ -n "$dir" ] || return 0
  dir="${dir%/}"
  # Resolve relative paths against the project root.
  case "$dir" in
    /*) ;;
    *)  dir="$root/$dir" ;;
  esac
  [ -d "$dir" ] || return 0
  case ":$emitted:" in
    *":$dir:"*) return 0 ;;
  esac
  emitted="$emitted:$dir"
  printf '%s\n' "$dir"
}

emit_if_exists "${DOT_ISSUES:-}"
emit_if_exists "$root/.local/issues"
emit_if_exists "$root/.issues"

if [ -z "$emitted" ]; then
  exit 3
fi
exit 0
