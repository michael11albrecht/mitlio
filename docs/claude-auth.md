# Claude auth for the CI agents

The three agent workflows (`agent-plan`, `agent-implement`, `agent-review`) can authenticate to Claude two ways.
The repo variable `CLAUDE_AUTH` picks one. No code change or PR is needed to switch.

| `CLAUDE_AUTH` | Credential (secret) | Billing |
|---|---|---|
| unset or `oauth` (default) | `CLAUDE_CODE_OAUTH_TOKEN` (`claude setup-token`) | subscription limits / its monthly credit pool |
| `api` | `ANTHROPIC_API_KEY` | per token, on the Console workspace the key belongs to |

Each workflow blanks the credential it is not using, so the action never sees both, and a `Check Claude credentials`
step fails with a plain message if the selected secret is missing or `CLAUDE_AUTH` has an invalid value.

## Switch

```sh
gh variable set CLAUDE_AUTH --body api      # API key
gh variable delete CLAUDE_AUTH              # back to the subscription token (needs CLAUDE_CODE_OAUTH_TOKEN set again)
```

The next run picks it up; the `Check Claude credentials` step logs which mode is active.

## Setup for API mode

1. Console: create a dedicated workspace (e.g. `mitlio-ci`) and an API key in it.
2. Set a monthly spend limit on that workspace. Keep auto-reload off.
3. `gh secret set ANTHROPIC_API_KEY`
4. `CLAUDE_CODE_OAUTH_TOKEN` was deleted on purpose (2026-11-17) so the subscription cannot be used by accident. To go back: `claude setup-token`, then `gh secret set CLAUDE_CODE_OAUTH_TOKEN` and `gh variable delete CLAUDE_AUTH`.

## Cost notes

Model IDs are the same in both modes (`PLANNER_MODEL`, `IMPLEMENTER_MODEL`, `REVIEWER_MODEL`).
The reviewer is the high-volume job (about 190 runs in the first 3 days at about $0.08 each at API prices).
Check the workspace usage page after switching; the action log also prints `total_cost_usd` per run.
