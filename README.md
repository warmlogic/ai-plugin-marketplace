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

| Plugin            | Repo                                                                                    | Install                                                 |
| ----------------- | --------------------------------------------------------------------------------------- | ------------------------------------------------------- |
| `bash-guardrails` | [warmlogic/claude-bash-guardrails](https://github.com/warmlogic/claude-bash-guardrails) | `/plugin install bash-guardrails@ai-plugin-marketplace` |
| `mdlint`          | [warmlogic/claude-mdlint](https://github.com/warmlogic/claude-mdlint)                   | `/plugin install mdlint@ai-plugin-marketplace`          |

See each plugin's own repo for what it does — the description lives there, in its
`.claude-plugin/plugin.json`, and on the **Discover** tab of `/plugin`.

## Using with Claude Code

Claude Code has native marketplace support. See
[Discover and install plugins](https://code.claude.com/docs/en/discover-plugins) for full
documentation.

### Add the marketplace

```text
/plugin marketplace add warmlogic/ai-plugin-marketplace
```

This registers the marketplace locally. You only need to do this once. Auto-update is off by
default for third-party marketplaces like this one; turn it on under `/plugin` → **Marketplaces**
→ **Enable auto-update** to receive plugin updates automatically.

### Install a plugin

```text
/plugin install <plugin-name>@ai-plugin-marketplace
```

Plugins are copied to a local cache at `~/.claude/plugins/cache`. The **Installed** tab in
`/plugin` (or `claude plugin list` in your shell) shows installed plugins.

### Update plugins

With auto-update off, update a plugin on demand from your shell:

```text
claude plugin update <plugin-name>@ai-plugin-marketplace
```

or open it on the **Installed** tab in `/plugin` and select **Update now**. `/plugin marketplace
update` refreshes the catalog only; it doesn't update installed plugins.

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
