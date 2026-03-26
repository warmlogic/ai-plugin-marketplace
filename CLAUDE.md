# AI Plugin Marketplace

This repository is a public Claude Code plugin marketplace for AI coding tool plugins.

## Repository structure

```text
.claude-plugin/marketplace.json   # Marketplace catalog (lists all plugins and their sources)
plugins/<name>/                   # Each plugin in its own directory
  .claude-plugin/plugin.json      # Plugin manifest (name, description, version)
  skills/<skill-name>/SKILL.md    # Skills (auto-discovered)
  commands/<command>.md            # Slash commands
  agents/<agent>.md               # Sub-agent definitions
  hooks/hooks.json                # Event-driven hooks
  .mcp.json                       # MCP server configs
```

## Key conventions

- Plugin names are kebab-case
- Every plugin must have a `.claude-plugin/plugin.json` manifest
- Every plugin must be registered in `.claude-plugin/marketplace.json`
- When bumping a plugin version in `plugin.json`, always update the matching `version` field in `.claude-plugin/marketplace.json` too
- When adding, removing, or updating a plugin's description, keep the "Available plugins" table in `README.md` in sync with `.claude-plugin/marketplace.json`
- Validate changes with `claude plugin validate .` from the repo root (catches version mismatches, missing registrations, etc.)
- PostToolUse/PreToolUse hooks that run the same command for multiple tools must use a single entry with a pipe-separated matcher (e.g., `"Edit|Write|MultiEdit"`) rather than multiple entries with the same command — Claude Code may deduplicate identical commands, causing none to fire
