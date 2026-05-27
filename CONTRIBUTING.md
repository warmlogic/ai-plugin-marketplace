# Contributing a Plugin

Anyone can add a plugin to this marketplace via PR.

## Quick Start

1. Create a public GitHub repo for your plugin
2. Add a `.claude-plugin/plugin.json` manifest at the repo root
3. Add your skills, agents, commands, hooks, or MCP servers
4. Submit a PR to this repo registering your plugin in `.claude-plugin/marketplace.json`

## Plugin Structure

Each plugin lives in its own GitHub repo. The repo root is the plugin root:

```text
your-plugin-repo/
├── .claude-plugin/
│   └── plugin.json         # Required: name, description, version
├── skills/                  # Model-invoked context (Claude loads automatically)
│   └── your-skill/
│       └── SKILL.md
├── commands/                # User-invoked slash commands
│   └── your-command.md
├── agents/                  # Subagent definitions
│   └── your-agent.md
├── hooks/                   # Event handlers
│   └── hooks.json
└── .mcp.json                # MCP servers (cross-tool compatible)
```

## Plugin Manifest (`plugin.json`)

```json
{
  "name": "your-plugin-name",
  "description": "What the plugin does",
  "version": "1.0.0",
  "author": {
    "name": "Your Name"
  }
}
```

## Registering in the Marketplace

Add an entry to the `plugins` array in `.claude-plugin/marketplace.json` via PR:

```json
{
  "name": "your-plugin-name",
  "source": {
    "source": "github",
    "repo": "your-github-user/your-plugin-repo",
    "ref": "main"
  },
  "description": "What the plugin does",
  "author": {
    "name": "Your Name"
  },
  "homepage": "https://github.com/your-github-user/your-plugin-repo",
  "repository": "https://github.com/your-github-user/your-plugin-repo",
  "license": "MIT",
  "category": "development",
  "keywords": ["relevant", "tags"],
  "tags": ["relevant", "tags"]
}
```

Do not set `version` in the marketplace entry — the plugin system reads version from `plugin.json` in your repo. Setting it in both places causes silent conflicts (plugin.json always wins).

## Naming

- Use kebab-case: `my-lint-rules`, not `MyLintRules`
- Be descriptive: `credit-model-reviewer`, not `cmr`
- Prefix with `claude-` to signal the ecosystem (e.g. `your-github-user/claude-my-plugin`)

## Testing Locally

From your plugin repo root:

```bash
claude --plugin-dir .
```

Then use `/reload-plugins` after making changes.

## Validation

From this marketplace repo root:

```bash
claude plugin validate .
```

## Updating a Plugin

To release a new version of your plugin:

1. Bump `version` in your plugin repo's `.claude-plugin/plugin.json`
2. Push to GitHub (no marketplace PR needed — the marketplace always pulls from `ref: "main"`)

The marketplace entry does not need updating for version changes. Users get the new version on their next `plugin marketplace update`.

## Hook conventions

- PostToolUse/PreToolUse hooks that run the same command for multiple tools must use a **single entry with a pipe-separated matcher** (e.g. `"Edit|Write|MultiEdit"`) rather than multiple separate entries with the same command — Claude Code may deduplicate identical commands, causing none to fire

## What Makes a Good Plugin?

- **Skills**: Domain knowledge that Claude should automatically know
- **Agents**: Specialized reviewers or assistants
- **Commands**: Repeatable workflows (e.g., `/your-plugin:deploy-checklist`)
- **MCP servers**: Integrations with external tools (these also work in Cursor/Copilot)
- **Hooks**: Automated checks on tool use (e.g., lint on file save)
