# AI Plugin Marketplace

Public [plugin marketplace](https://code.claude.com/docs/en/plugin-marketplaces) for AI coding
tools. Safety, quality, and productivity plugins for Claude Code and compatible tools.

## What is this?

A Git repository containing a catalog of [plugins](https://code.claude.com/docs/en/plugins) that
extend AI coding tools with useful functionality. Plugins can include:

- **Skills**: Context that Claude automatically loads when relevant
- **Agents**: Specialized sub-agents for specific tasks
- **Commands**: Slash commands for repeatable workflows
- **Hooks**: Automated actions triggered by tool use (e.g., lint on file save)
- **MCP servers**: Integrations with external tools and services

Anyone can submit a plugin via PR. See [CONTRIBUTING.md](CONTRIBUTING.md).

## Available plugins

| Plugin            | Description                                                                                                                                                        |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `bash-guardrails` | Auto-approve hook for Claude Code's Bash tool — reduces unnecessary permission prompts for read-only pipelines, find -exec, here-strings, shell loops/conditionals, and allowlisted commands |
| `mdlint`          | Auto-format and lint markdown files written by Claude Code — prettier + markdownlint on every Write/Edit                                                           |

## Using with Claude Code

Claude Code has native marketplace support. See
[Discover and install plugins](https://code.claude.com/docs/en/discover-plugins) for full
documentation.

### Add the marketplace

```text
/plugin marketplace add warmlogic/ai-plugin-marketplace
```

This registers the marketplace locally. You only need to do this once; Claude Code will
auto-update the marketplace catalog on startup.

### Install a plugin

```text
/plugin install <plugin-name>@ai-plugin-marketplace
```

Plugins are copied to a local cache at `~/.claude/plugins/cache`. Run `/plugin list` to see
installed plugins.

### Update plugins

```text
/plugin marketplace update
```

## Auto-install for repos

Repository maintainers can add this to their repo's `.claude/settings.json` so that users are
automatically prompted to install the marketplace when they trust the project folder:

```json
{
  "extraKnownMarketplaces": {
    "ai-plugin-marketplace": {
      "source": {
        "source": "github",
        "repo": "warmlogic/ai-plugin-marketplace"
      }
    }
  }
}
```

To also enable specific plugins by default:

```json
{
  "enabledPlugins": {
    "<plugin-name>@ai-plugin-marketplace": true
  }
}
```

See [Plugin settings](https://code.claude.com/docs/en/settings#plugin-settings) for full
configuration options.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to create and submit a plugin.

## License

[MIT](LICENSE)
