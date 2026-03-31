# bash-guardrails Canary Audit

Run the bash-guardrails canary audit to detect whether Claude Code's native permission system now handles patterns that the hook currently blocks. Use this when the user mentions "bash-guardrails canary", "canary audit for bash-guardrails", "test if bash-guardrails restrictions can be loosened", or "pre-release validation for bash-guardrails".

## When to use

- After upgrading Claude Code
- Before releasing a new version of bash-guardrails
- When considering loosening bash-guardrails hook restrictions

## How to run

### Quick check (no API cost)

Check if the CC version has changed since the last audit:

```bash
bash plugins/bash-guardrails/tests/test-canary.sh --diff
```

### View latest baseline (no API cost)

```bash
bash plugins/bash-guardrails/tests/test-canary.sh --report
```

### Full audit (costs ~$0.05-0.15)

Run all sentinel commands through a fresh `claude -p --bare` session (no hooks, no plugins) to observe CC's native behavior:

```bash
bash plugins/bash-guardrails/tests/test-canary.sh --yes
```

The `--yes` flag skips the interactive confirmation prompt. Without it, the script will ask for confirmation before spending API credits.

The script will:

1. Test each sentinel command from `tests/canary-commands.json`
2. Save results to `tests/canary-baselines/<version>.json`
3. Report which hook restrictions might be removable

## Interpreting results

- **PASS**: CC did not block the command. The hook is the sole protection for this pattern — do NOT remove the hook check.
- **CC**: CC blocked this pattern natively. The hook restriction is redundant and is a candidate for removal.
- **HOOK**: The globally-installed hook intercepted the command before CC could weigh in. This result is **inconclusive** — we don't know what CC would do. Re-run with `ANTHROPIC_API_KEY` set (enables `--bare` mode, skips hooks) for a clean test.
- **SKIP**: Policy-only restriction (e.g., `git commit --amend`). Not a candidate for removal regardless of CC behavior.
- **UNCLEAR**: Could not determine CC behavior. Run the specific command manually to verify.

## Pre-release checklist

When preparing a bash-guardrails release:

1. Run `bash plugins/bash-guardrails/tests/test-bash-guardrails.sh` (unit tests)
2. Run `bash plugins/bash-guardrails/tests/test-canary.sh --diff` (version drift check)
3. If drift detected, run `bash plugins/bash-guardrails/tests/test-canary.sh --yes` (full audit)
4. Review candidates for removal
5. If removing a restriction, update the hook script AND the unit tests

## Adding new sentinel commands

Edit `tests/canary-commands.json` to add entries:

```json
{
  "id": "descriptive-name",
  "check": 5,
  "category": "cc_workaround",
  "cmd": "the command to test",
  "hook_verdict": "block",
  "rationale": "Why this restriction exists and when it could be removed"
}
```

Categories:

- `cc_workaround` — exists because of CC heuristic limitations. Candidate for removal.
- `policy` — intentional guardrail. Never removed by canary results.
- `baseline` — control commands that should always pass. Validates test harness.
