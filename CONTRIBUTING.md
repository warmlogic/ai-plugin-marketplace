# Contributing a Plugin

Anyone can add a plugin to this marketplace via PR.

## Quick Start

1. Create a `plugins/your-plugin-name/` directory
2. Add a `.claude-plugin/plugin.json` manifest
3. Add your skills, agents, commands, hooks, or MCP servers
4. Register your plugin in `.claude-plugin/marketplace.json`
5. Open a PR

## Plugin Structure

```text
plugins/your-plugin-name/
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

Add an entry to the `plugins` array in `.claude-plugin/marketplace.json`:

```json
{
  "name": "your-plugin-name",
  "source": "./plugins/your-plugin-name",
  "description": "What the plugin does",
  "version": "1.0.0",
  "category": "development",
  "tags": ["relevant", "tags"]
}
```

## Naming

- Use kebab-case: `my-lint-rules`, not `MyLintRules`
- Be descriptive: `credit-model-reviewer`, not `cmr`

## Testing Locally

```bash
claude --plugin-dir ./plugins/your-plugin-name
```

Then use `/reload-plugins` after making changes.

## Validation

From the repo root:

```bash
claude plugin validate .
```

## What Makes a Good Plugin?

- **Skills**: Domain knowledge that Claude should automatically know
- **Agents**: Specialized reviewers or assistants
- **Commands**: Repeatable workflows (e.g., `/your-plugin:deploy-checklist`)
- **MCP servers**: Integrations with external tools (these also work in Cursor/Copilot)
- **Hooks**: Automated checks on tool use (e.g., lint on file save)
