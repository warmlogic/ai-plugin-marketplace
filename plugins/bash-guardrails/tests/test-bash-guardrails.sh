#!/usr/bin/env bash
# Test suite for bash-guardrails.sh hook
# Run: bash plugins/bash-guardrails/tests/test-bash-guardrails.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK="$SCRIPT_DIR/../scripts/bash-guardrails.sh"
pass=0
fail=0

run_test() {
  local expect="$1" label="$2" cmd="$3"
  result=$(printf '{"tool_input":{"command":"%s"}}' "$cmd" | bash "$HOOK" 2>&1)
  exit_code=$?

  if [ "$expect" = "pass" ] && [ $exit_code -ne 2 ]; then
    pass=$((pass+1))
  elif [ "$expect" = "block" ] && [ $exit_code -eq 2 ]; then
    pass=$((pass+1))
  elif [ "$expect" = "hint" ]; then
    if echo "$result" | grep -q "HINT"; then
      pass=$((pass+1))
    else
      echo "  FAIL: $label (expected HINT, got none)"
      fail=$((fail+1))
      return
    fi
  elif [ "$expect" = "no-hint" ]; then
    if echo "$result" | grep -q "HINT"; then
      echo "  FAIL: $label (unexpected HINT)"
      fail=$((fail+1))
      return
    else
      pass=$((pass+1))
    fi
  else
    echo "  FAIL: $label (expected $expect, got exit $exit_code)"
    echo "        $result"
    fail=$((fail+1))
    return
  fi
  echo "  ok: $label"
}

# Helper for commands with embedded double quotes or multiline content
_test_json() {
  local expect="$1" label="$2" cmd="$3"
  result=$(jq -n --arg c "$cmd" '{"tool_input":{"command":$c}}' | bash "$HOOK" 2>&1)
  exit_code=$?
  if [ "$expect" = "pass" ] && [ $exit_code -ne 2 ]; then
    pass=$((pass+1)); echo "  ok: $label"
  elif [ "$expect" = "block" ] && [ $exit_code -eq 2 ]; then
    pass=$((pass+1)); echo "  ok: $label"
  else
    echo "  FAIL: $label (expected $expect, got exit $exit_code)"
    echo "        $result"
    fail=$((fail+1))
  fi
}

# Helper for testing permissionDecision output
_test_allow() {
  local label="$1" cmd="$2" expect_allow="$3"
  result=$(jq -n --arg c "$cmd" '{"tool_input":{"command":$c}}' | bash "$HOOK" 2>/dev/null)
  if [ "$expect_allow" = true ]; then
    if echo "$result" | grep -q '"permissionDecision"'; then
      pass=$((pass+1)); echo "  ok: $label"
    else
      echo "  FAIL: $label (expected allow decision, got none)"; echo "        $result"; fail=$((fail+1))
    fi
  else
    if echo "$result" | grep -q '"permissionDecision"'; then
      echo "  FAIL: $label (unexpected allow decision)"; fail=$((fail+1))
    else
      pass=$((pass+1)); echo "  ok: $label"
    fi
  fi
}

run_test_allowlist() {
  local label="$1" cmd="$2" expect_allow="$3"
  result=$(printf '{"tool_input":{"command":"%s"}}' "$cmd" | bash "$HOOK" 2>/dev/null)
  if [ "$expect_allow" = true ]; then
    if echo "$result" | grep -q '"permissionDecision"'; then
      pass=$((pass+1)); echo "  ok: $label"
    else
      echo "  FAIL: $label (expected allow decision, got none)"; echo "        $result"; fail=$((fail+1))
    fi
  else
    if echo "$result" | grep -q '"permissionDecision"'; then
      echo "  FAIL: $label (unexpected allow decision)"; fail=$((fail+1))
    else
      pass=$((pass+1)); echo "  ok: $label"
    fi
  fi
}

echo "bash-guardrails.sh test suite"
echo "========================="

echo ""
echo "--- Safe single commands ---"
run_test pass "simple git command" "git log --oneline"
run_test pass "git with flags" "git diff --stat HEAD~3"
run_test pass "mkdir" "mkdir -p /tmp/test"
run_test pass "echo" "echo hello world"

echo ""
echo "--- Commands with comments/whitespace pass through unmodified ---"
_test_json pass "comment-only line" '# this is a comment'
_test_json pass "inline trailing comment" "echo hello # trailing comment"
_test_json pass "leading whitespace" "  git status"
_test_json pass "trailing whitespace" "git status  "
_test_json pass "apostrophe in comment" "# don't do this"

echo ""
echo "--- git -C (allowed) ---"
run_test pass "git -C log" "git -C /some/path log --oneline"
run_test pass "git -C status" "git -C /some/path status"

echo ""
echo "--- Compound commands (allowed) ---"
run_test pass "cd && ls" "cd /tmp && ls -la"
run_test pass "cd && git pull" "cd /tmp && git pull origin main"
run_test pass "echo && echo" "echo hello && echo world"
run_test pass "rm && mkdir" "rm -rf /tmp/foo && mkdir /tmp/bar"
run_test pass "git pull && push" "git pull && git push"
run_test pass "npm || npm ci" "npm install || npm ci"
run_test pass "cmd || true" "some-cmd 2>/dev/null || true"

echo ""
echo "--- git commit --amend (allowed) ---"
run_test pass "git amend" "git commit --amend -m fix"
run_test pass "git amend no-edit" "git commit --amend --no-edit"

echo ""
echo "--- Shell control structures (allowed) ---"
run_test pass "for loop" 'for f in *.txt; do echo \$f; done'
run_test pass "while loop" 'while true; do sleep 1; done'
run_test pass "if/then/fi" 'if [ -f x ]; then cat x; fi'
run_test pass "case/esac" 'case \$x in a) echo a;; b) echo b;; esac'

echo ""
echo "--- Heredoc body (allowed) ---"
_test_json pass "heredoc with backticks in body" "$(printf 'gh pr create --body-file /dev/stdin <<'"'"'BODY'"'"'\nThis has `backticks` and `code`\nBODY')"
_test_json pass "heredoc with && in body" "$(printf 'cat > /tmp/notes.md <<'"'"'EOF'"'"'\ncd && cmd and foo && bar\nEOF')"
_test_json pass "heredoc with || in body" "$(printf 'cmd --body-file /dev/stdin <<'"'"'END'"'"'\nnpm install || npm ci\nEND')"

echo ""
echo "--- Backtick hint (check 6) ---"
_test_json pass "backtick passes (not blocked)" 'echo `date`'
run_test no-hint "dollar-paren no warn" 'echo \$(date)'

echo ""
echo "--- Zsh-only syntax (blocked, check 7) ---"
run_test block "zsh =() blocked" 'diff =(echo a) =(echo b)'

echo ""
echo "--- Pipe hints (check 10) ---"
run_test hint "cat pipe warns" "cat file.txt | wc -l"
run_test hint "grep pipe warns" "grep foo bar.txt | head"
run_test hint "find pipe warns" "find . -name x | xargs rm"
run_test no-hint "jq pipe no warn" "npm list --json | jq .deps"
run_test no-hint "sort pipe no warn" "git log --oneline | sort"
run_test no-hint "cmd | wc no warn" "docker ps | wc -l"

echo ""
echo "--- Here-string <<< with quoted literal (check 11) ---"
_test_allow '<<< double-quoted string' 'EDITOR="tee" bd edit engram-mif.20 --notes <<< "some note text"' true
_test_allow '<<< single-quoted string' "cmd <<< 'hello world'" true
_test_allow '<<< unquoted variable not approved' 'cmd <<< $SOME_VAR' false

echo ""
echo "--- Allowlist auto-approve (check 12) ---"
run_test_allowlist "git log is allowlisted" "git log --oneline" true
run_test_allowlist "npm install is allowlisted" "npm install express" true
run_test_allowlist "echo is allowlisted" "echo hello" true
run_test_allowlist "unknown cmd not allowlisted" "some-unknown-command --flag" false

echo ""
echo "========================="
if [ "$fail" -eq 0 ]; then
  echo "ALL PASSED: $pass tests"
else
  echo "RESULTS: $pass passed, $fail FAILED"
  exit 1
fi
