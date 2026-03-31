#!/usr/bin/env bash
set -euo pipefail

# --- --help: print check summary from #@check tags in this script ---
if [ "${1:-}" = "--help" ]; then
  echo "bash-guardrails — PreToolUse hook for Claude Code's Bash tool"
  echo ""
  echo "Checks:"
  grep '^#@check' "$0" | sed 's/^#@check /  /'
  echo ""
  echo "Usage: Runs automatically as a PreToolUse hook. No arguments needed."
  echo "       Pass --help to print this summary."
  exit 0
fi

cmd=$(jq -r '.tool_input.command // ""')

# --- Helpers ---

# Emit a PreToolUse allow decision and exit.
emit_allow() {
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "allow",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

#@check  4  hint    Multiline commands → hint to split (unless control structure or heredoc)
# --- 4. Detect multiline, control structures, and heredocs ---
non_empty_lines=$(echo "$cmd" | grep -c '\S' || true)
is_control_structure=false
echo "$cmd" | head -1 | grep -Eq '^\s*(if|for|while|until|case)\b' && is_control_structure=true
has_heredoc=false
echo "$cmd" | grep -q '<<' && has_heredoc=true

if [ "$non_empty_lines" -gt 1 ] && [ "$is_control_structure" = false ] && [ "$has_heredoc" = false ]; then
  echo "HINT: Multiline command — prefer separate Bash tool calls." >&2
fi

# Extract command portion only (before heredoc body) for syntax checks.
# Heredoc bodies are stdin data — backticks, &&, $'...' there are literal text.
cmd_for_syntax="$cmd"
if [ "$has_heredoc" = true ]; then
  heredoc_line=$(echo "$cmd" | grep -n '<<' | head -1 | cut -d: -f1)
  cmd_for_syntax=$(echo "$cmd" | head -n "$heredoc_line")
fi

#@check  6  hint    Backtick substitution → hint (prefer $() for clarity)
# --- 6. Hint on backtick substitution ---
# Strip single-quoted strings so patterns inside quotes aren't false positives.
no_sq=$(echo "$cmd_for_syntax" | sed -e "s/'[^']*'//g")
if echo "$no_sq" | grep -q '`'; then
  echo 'HINT: Consider using $() instead of backticks for clarity.' >&2
fi

#@check  7  block   Zsh-only syntax =() → block
# --- 7. Block Zsh-only syntax ---
# Use cmd_for_syntax (skips heredoc bodies) and strip quoted strings to avoid
# false positives when =() appears inside argument text (e.g., gh pr create --body "...=()...").
no_quotes=$(echo "$cmd_for_syntax" | sed -e "s/'[^']*'//g" -e 's/"[^"]*"//g')
if echo "$no_quotes" | grep -Eq '=\(' ; then
  echo 'BLOCKED: =() is Zsh-only. Use bash-compatible syntax (<(), mktemp, or arr=( ) with space).' >&2
  exit 2
fi

#@check 10  hint    Pipes from cat/grep/find/ls → hint to use Read/Grep/Glob tools
# --- 10. Warn on pipe usage (only when dedicated tools exist) ---
pipe_source=$(echo "$cmd" | grep -oE '^\s*(cat|head|tail|grep|rg|find|ls)\s' | head -1 | tr -d '[:space:]' || true)
if [ -n "$pipe_source" ]; then
  echo "HINT: Consider using Read/Grep/Glob tools instead of piping from $pipe_source." >&2
fi

#@check 11  allow   Here-strings (<<<) with quoted literals → allow (no file read)
# --- 11. Auto-approve here-strings (<<<) with quoted string literals ---
# Claude Code sees "<" in "<<<" and warns about reading sensitive files,
# but <<< "string" just feeds a literal to stdin — no file involved.
if echo "$cmd" | grep -q '<<<'; then
  herestring_val=$(echo "$cmd" | sed -n 's/.*<<<[[:space:]]*//p')
  echo "$herestring_val" | grep -Eq '^["'"'"']' && \
    emit_allow "Here-string (<<<) with quoted literal is safe — no file read"
fi

#@check 12  allow   Commands matching permissions.allow → allow (checks settings.json + settings.local.json)
# --- 12. Auto-approve commands already in permissions.allow ---
# Claude Code sometimes re-prompts for already-trusted commands (e.g., quoted
# characters). If the command matches an allow rule, suppress the prompt.
# This runs AFTER all blocking checks, so dangerous patterns are still caught.
allowlisted=false
settings_candidates=("$HOME/.claude/settings.json" "$HOME/.claude/settings.local.json")
if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
  settings_candidates+=("$CLAUDE_PROJECT_DIR/.claude/settings.json" "$CLAUDE_PROJECT_DIR/.claude/settings.local.json")
fi
for settings_file in "${settings_candidates[@]}"; do
  [ -f "$settings_file" ] || continue
  while IFS= read -r rule; do
    [ -z "$rule" ] && continue
    pattern=$(printf '%s' "$rule" | sed -e 's/[.+?^${}()|[\]\\]/\\&/g' -e 's/\*/.*/g')
    if echo "$cmd" | grep -Eq "^${pattern}$"; then
      allowlisted=true
      break 2
    fi
  done < <(jq -r '.permissions.allow[]? // empty | select(startswith("Bash(")) | sub("^Bash\\("; "") | sub("\\)$"; "")' "$settings_file" 2>/dev/null)
done

# --- 13. Emit result ---
if [ "$allowlisted" = true ]; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "allow",
      permissionDecisionReason: "Command matches existing permissions.allow rule"
    }
  }'
fi

exit 0
