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
