# AI Plugin Marketplace

This repository is a public Claude Code plugin marketplace for AI coding tool plugins.

## Repository structure

```text
.claude-plugin/marketplace.json   # Marketplace catalog (lists all plugins and their GitHub sources)
README.md                          # Plugin table — keep in sync with marketplace.json
CONTRIBUTING.md                    # How to add a plugin
```

Each plugin lives in its own GitHub repo (e.g. `warmlogic/claude-bash-guardrails`). The marketplace only holds the catalog.

## Key conventions

- Plugin names are kebab-case (`bash-guardrails`, not `BashGuardrails`)
- Every plugin must have a `.claude-plugin/plugin.json` manifest in its own repo
- Every plugin must be registered in `.claude-plugin/marketplace.json` with a GitHub `source`
- Plugin versions are managed in the plugin's own `plugin.json` — do NOT set `version` in marketplace entries (plugin.json always wins; setting both causes silent conflicts)
- **Versioning policy (semver):** every merge to `main` is a release — bump the version in the PR branch before merging
  - **Patch** (`0.4.x`): bug fixes, doc-only changes, minor wording tweaks
  - **Minor** (`0.x.0`): new skills, agents, commands, hooks, or features
  - **Major** (`x.0.0`): breaking changes (renamed skills, removed commands, changed hook contracts)
- When adding, removing, or updating a plugin's description, keep the "Available plugins" table in `README.md` in sync with `.claude-plugin/marketplace.json`
- Validate changes with `claude plugin validate .` from the repo root (catches version mismatches, missing registrations, etc.)

## Plugin development workflow

Work on plugins in their own repos. To test locally, run `claude --plugin-dir .` from the plugin repo root.

### Canary audits

Some plugins include a canary audit (`tests/test-canary.sh`) that detects whether Claude Code's native behavior has changed in ways that affect the plugin's value. When modifying a plugin that has a canary audit:

1. **Before starting work:** Ask the user if they want to run the canary audit first (`test-canary.sh --yes`). This reveals whether CC already handles the pattern natively, which may change the approach (e.g., no fix needed, or the fix belongs upstream in CC rather than in the hook).
2. **After adding or modifying auto-approve checks:** Add corresponding sentinel commands to `canary-commands.json` so future audits can detect when CC catches up. Then ask the user if they want to run a full audit to baseline the new sentinels.
3. **Quick check (no API cost):** `test-canary.sh --diff` compares the current CC version to the latest baseline and flags version drift without spending API credits.
