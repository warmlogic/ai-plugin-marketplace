#!/usr/bin/env bash
# Test suite for mdlint.sh and mdlint-check.sh
# Run from repo root: bash plugins/mdlint/tests/test-mdlint.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK="$SCRIPT_DIR/../scripts/mdlint.sh"
PLUGIN_ROOT="$SCRIPT_DIR/.."

pass=0
fail=0

# BSD mktemp (macOS) requires X's at the end — create without extension then rename.
mktemp_md() {
  local t
  t=$(mktemp /tmp/test-mdlint-XXXXXX)
  mv "$t" "${t}.md"
  echo "${t}.md"
}

# Pipe a PostToolUse JSON payload into the hook.
run_hook() {
  local file_path="$1"
  printf '{"tool_input":{"file_path":"%s"}}' "$file_path" | \
    CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK" >/dev/null 2>&1
}

# Run hook with a minimal PATH that excludes /opt/homebrew/bin (simulates CC hook env).
run_hook_minimal_path() {
  local file_path="$1"
  printf '{"tool_input":{"file_path":"%s"}}' "$file_path" | \
    env -i HOME="$HOME" TMPDIR="${TMPDIR:-/tmp}" \
    PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
    CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK" >/dev/null 2>&1
}

ok() { pass=$((pass+1)); echo "  ok: $1"; }
fail_test() { fail=$((fail+1)); echo "  FAIL: $1"; }

expect_exit() {
  local label="$1" expected="$2" file="$3"
  run_hook "$file"
  local actual=$?
  if [ "$actual" -eq "$expected" ]; then ok "$label"; else fail_test "$label (expected exit $expected, got $actual)"; fi
}

echo "mdlint.sh test suite"
echo "===================="

# --- Skip conditions ---
echo ""
echo "--- Early-exit / skip ---"

tmp_txt=$(mktemp /tmp/test-mdlint-XXXXXX)
printf 'not markdown\n' > "$tmp_txt"
expect_exit "non-.md file exits 0" 0 "$tmp_txt"

expect_exit "nonexistent .md exits 0" 0 "/tmp/test-mdlint-does-not-exist-12345.md"

tmp_md=$(mktemp_md)
printf '# Hello\n\nClean file.\n' > "$tmp_md"
expect_exit "clean .md exits 0" 0 "$tmp_md"

# --- PATH regression ---
echo ""
echo "--- PATH regression (minimal hook environment) ---"

# Verify the hook runs without error when /opt/homebrew/bin is not on PATH.
# Before the fix: jq (also in /opt/homebrew/bin) was called before PATH injection,
# so the script crashed and silently no-op'd via the hook's || true guard.
tmp_md_path=$(mktemp_md)
printf '# Title\n\nSome content.\n' > "$tmp_md_path"
run_hook_minimal_path "$tmp_md_path"
if [ $? -eq 0 ]; then
  ok "hook exits 0 on minimal PATH"
else
  fail_test "hook errored on minimal PATH — PATH injection may have regressed"
fi

# Verify prettier actually ran: a table without spaces should be reformatted.
# prettier normalizes |Name|Value| → | Name | Value |
tmp_md_prettier=$(mktemp_md)
printf '|Name|Value|\n|---|---|\n|Ada|42|\n' > "$tmp_md_prettier"
before=$(cat "$tmp_md_prettier")
run_hook_minimal_path "$tmp_md_prettier"
after=$(cat "$tmp_md_prettier")
if [ "$before" != "$after" ]; then
  ok "prettier ran and modified file on minimal PATH (PATH injection confirmed effective)"
else
  fail_test "prettier did not modify file on minimal PATH — binaries may not be found"
fi

# --- Lint error reporting ---
echo ""
echo "--- Lint error reporting ---"

# MD040 (fenced-code-language) is enabled in config and not auto-fixable → exit 2.
tmp_md_lint=$(mktemp_md)
printf '# Title\n\n```\nsome code\n```\n' > "$tmp_md_lint"
printf '{"tool_input":{"file_path":"%s"}}' "$tmp_md_lint" | \
  CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK" >/dev/null 2>&1
exit_code=$?
if [ "$exit_code" -eq 2 ]; then
  ok "unfixable MD040 error exits 2"
else
  fail_test "unfixable MD040 error: expected exit 2, got $exit_code"
fi

# Verify stderr contains the error hint.
stderr_out=$(printf '{"tool_input":{"file_path":"%s"}}' "$tmp_md_lint" | \
  CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" bash "$HOOK" 2>&1 >/dev/null || true)
if echo "$stderr_out" | grep -q "MARKDOWN LINT"; then
  ok "exit 2 path emits MARKDOWN LINT to stderr"
else
  fail_test "exit 2 path missing MARKDOWN LINT in stderr"
fi

# --- Summary ---
echo ""
echo "Results: $pass passed, $fail failed"
[ "$fail" -eq 0 ] && exit 0 || exit 1
