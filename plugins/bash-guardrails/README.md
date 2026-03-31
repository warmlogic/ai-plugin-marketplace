# bash-guardrails

Lightweight guardrails for Claude Code's Bash tool. A PreToolUse hook that normalizes commands, hints at better alternatives, and auto-approves known-safe operations to reduce permission prompts.

## What it does

Run `bash scripts/bash-guardrails.sh --help` for the current check list:

```text
bash-guardrails — PreToolUse hook for Claude Code's Bash tool

Checks:
   4  hint    Multiline commands → hint to split (unless control structure or heredoc)
   6  hint    Backtick substitution → hint (prefer $() for clarity)
   7  block   Zsh-only syntax =() → block
  10  hint    Pipes from cat/grep/find/ls → hint to use Read/Grep/Glob tools
  11  allow   Here-strings (<<<) with quoted literals → allow (no file read)
  12  allow   Commands matching permissions.allow → allow (checks settings.json + settings.local.json)
```

## Installation

Enable the plugin in your Claude Code settings:

```json
{
  "enabledPlugins": {
    "bash-guardrails@ai-plugin-marketplace": true
  }
}
```

## Testing

Unit tests:

```bash
bash plugins/bash-guardrails/tests/test-bash-guardrails.sh
```

### Canary audit

Detects whether Claude Code's native permission system now handles patterns that the hook blocks — helping you identify restrictions that can be safely loosened after CC upgrades.

```bash
# Check for CC version drift (no API cost)
bash plugins/bash-guardrails/tests/test-canary.sh --diff

# View latest baseline (no API cost)
bash plugins/bash-guardrails/tests/test-canary.sh --report

# Full audit (~$0.02 with ANTHROPIC_API_KEY or CLAUDE_CODE_OAUTH_TOKEN)
bash plugins/bash-guardrails/tests/test-canary.sh
```

Or just ask Claude: "run the canary audit for bash-guardrails."

## Dependencies

- `jq` (for JSON parsing — typically pre-installed with Claude Code)
- `bash` 4.0+ (for `<<<` here-strings and `${var:offset:length}` substring syntax)
