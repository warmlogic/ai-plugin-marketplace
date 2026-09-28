# AI Plugin Marketplace

This repository is a public Claude Code plugin marketplace for AI coding tool plugins.

## Repository structure

```text
.claude-plugin/marketplace.json   # Marketplace catalog (lists all plugins and their GitHub sources)
README.md                          # Plugin names, repo links, install commands
CONTRIBUTING.md                    # How to add a plugin
```

Each plugin lives in its own GitHub repo (e.g. `warmlogic/claude-bash-guardrails`). The marketplace only holds the catalog.

## Key conventions

- Plugin names are kebab-case (`bash-guardrails`, not `BashGuardrails`)
- Every plugin must have a `.claude-plugin/plugin.json` manifest in its own repo
- Every plugin must be registered in `.claude-plugin/marketplace.json` with a GitHub `source`
- **Unversioned.** No plugin here — and no catalog entry — carries a `version` field. Claude Code
  resolves the installed copy from the git commit SHA of the plugin's source (an install lands in
  `~/.claude/plugins/cache/<marketplace>/<plugin>/<sha12>/`), so every merge to a plugin repo's
  `main` is a release, with no bump and no separate publish step. Users pick it up through
  marketplace auto-update (off by default for a third-party marketplace like this one; toggled
  under `/plugin` → **Marketplaces**) or on demand with `claude plugin update <plugin>@ai-plugin-marketplace`
  — `/plugin marketplace update` alone refreshes the catalog, not installed plugins. `claude plugin validate .` warns "No version specified" when validating a
  plugin's own repo (its `plugin.json` has no `version`) — that warning is expected and accepted
  there; this catalog repo has no `plugin.json` of its own and validates with zero warnings.
- **Descriptions: `plugin.json` is the source.** A catalog entry's `description` must equal that plugin's own
  `.claude-plugin/plugin.json` `description`, verbatim — it's the copy contributors keep in sync
  when either changes. Don't repeat a plugin's description anywhere else (e.g. the README table);
  link to the plugin's repo instead.
- Validate changes with `claude plugin validate .` from the repo root (catches missing
  registrations, malformed manifests, etc.)

## Plugin development workflow

Work on plugins in their own repos. To test locally, run `claude --plugin-dir .` from the plugin repo root.

Plugin-specific workflows (e.g. a plugin's own audit or test tooling) live in that plugin's own
repo, in its `AGENTS.md`.
