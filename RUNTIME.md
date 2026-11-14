# Runtime contract

Every plugin here runs its tools one way, so it works the same from a Claude Code session, a hook, launchd, CI or a sandboxed agent.

1. **Prerequisites.** The tools the plugin calls: `git`, `gh` and `uv` where it uses them, plus any other tool it names. Setup checks each one with `command -v` and, when one is missing, names the command that installs it. Nobody installs Python: uv supplies it. A setup script that itself runs through uv cannot check or install uv: uv is installed first, and the shell command that starts setup (a skill's command, a CLI wrapper) checks `command -v uv` and names its install (`brew install uv`, or without Homebrew `curl -LsSf https://astral.sh/uv/install.sh | sh`).
2. **Python.** Every Python entry point starts with `#!/usr/bin/env -S uv run --quiet --script` (`--quiet` keeps uv's own messages out of output a caller parses) and carries inline script metadata, `requires-python = ">=3.12"` and its dependencies (standard library preferred). An explicit `UV_PYTHON` overrides `requires-python`, so set it to 3.12+ or leave it unset: under `--quiet` an older value runs with no warning. A `.python-version` naming an older version is ignored. It is executable and is run by its path, never as `python3 <file>`, `python3 -` or `python3 -c`: a snippet becomes a small script. A module that is only imported needs no shebang. The rule covers the plugin's runtime: scripts, hooks, skills' commands and CI. A test harness may run its suite through `uv run` or `uvx`, with its test tools pinned to exact versions so a new release cannot turn the suite red, but it starts the plugin's own scripts the way users do.

   ```python
   #!/usr/bin/env -S uv run --quiet --script
   # /// script
   # requires-python = ">=3.12"
   # dependencies = []
   # ///
   ```

3. **One path.** No interpreter version check, no fallback to another runner, and no import moved inside a function so an old Python can load the module.
4. **Missing tools fail loudly.** A command stops and names what is missing and the command that installs it. A hook that must never block the session may skip its work, but it tells the user once, at session start, what it skips and how to install the missing tool. In Claude Code that is a SessionStart hook's JSON `systemMessage`: a hook's plain stderr at exit 0 is not shown to the user.
5. **A guard enforces it.** Each repo that runs Python has one check, a test or an audit check, that fails on any bare `python3` or `python` invocation (in shell files and in the shell blocks of skill and agent markdown), on an entry point without the uv shebang or its metadata, and on an interpreter version check. It reads the metadata block with a TOML parser (Python's `tomllib`), not a regex.

uv uses a Python 3.12+ it finds and downloads one only when it finds none, so it may need the network once. A sandboxed caller points `UV_CACHE_DIR` at a writable directory under `$TMPDIR` and runs uv once outside the sandbox first, so the sandbox only reads an installed Python. uv adds start-up time to every process it starts, so time a hot path (a hook that runs on every tool call) before and after converting it.

A hook's script runs as uv's child. When a command hook hits its timeout, Claude Code ends it by signaling the hook's whole process group, TERM and then KILL about a second later, so the script does not outlive it (observed behavior; the hooks docs don't state it). A script that calls `setsid` or `setpgid`, or daemonizes a grandchild, would escape the group, so hooks stay in the hook's process group and never start a new one.
