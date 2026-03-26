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

| Plugin            | Description                                                                                                                           |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `bash-guardrails` | Safety guardrails for Claude Code's Bash tool — blocks compound commands, enforces safe patterns, auto-approves known-safe operations |
| `mdlint`          | Auto-format and lint markdown files written by Claude Code — prettier + markdownlint on every Write/Edit, with a Stop hook safety net |

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

## Using with other AI tools

The marketplace format is Claude Code-native. Other AI coding tools cannot install from it
directly. However, there is meaningful cross-compatibility through
[MCP (Model Context Protocol)](https://modelcontextprotocol.io/):

| Component       | Claude Code | Cursor  | Copilot | Android Studio | Others  |
| --------------- | :---------: | :-----: | :-----: | :------------: | :-----: |
| Skills          |     Yes     |    -    |    -    |       -        |    -    |
| Agents          |     Yes     |    -    |    -    |       -        |    -    |
| Commands        |     Yes     |    -    |    -    |       -        |    -    |
| Hooks           |     Yes     |    -    |    -    |       -        |    -    |
| **MCP servers** |   **Yes**   | **Yes** | **Yes** |    **Yes**     | Growing |

**MCP servers are the universal layer.** Any plugin that includes an MCP server (`.mcp.json`)
can be used by any tool that supports MCP. Users of those tools would clone this repo and
manually configure the MCP server in their tool's settings rather than using the marketplace
install flow.

MCP configuration locations by tool:

- **Cursor**: `.cursor/mcp.json` in any project.
  See [Cursor MCP docs](https://docs.cursor.com/context/model-context-protocol).
- **Android Studio (Gemini)**: MCP support via the Gemini plugin.
  See [Android Studio MCP docs](https://developer.android.com/studio/preview/gemini/mcp).
- **GitHub Copilot**: `.vscode/mcp.json` or VS Code settings.
  See [Copilot MCP docs](https://docs.github.com/en/copilot/customizing-copilot/extending-copilot-in-vs-code/using-mcp-servers-in-vs-code).

**Skills and agents** are Claude Code-specific Markdown files. They can't be used directly by
other tools, but the content is plain Markdown that could be adapted into Cursor rules
(`.cursor/rules/`) or Copilot instructions (`.github/copilot-instructions.md`) manually.

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
