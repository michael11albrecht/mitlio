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

## Cost savers

| Saver | Where | Tune with (repo variable) |
|---|---|---|
| Docs-only PRs (`docs/**`, `reports/**`, `*.md`, no critical path) are not reviewed; `agent-review` is set to success with "skipped: docs-only" | `agent-review` | none |
| After an approved review, a push with at most N changed lines (and no critical path) is not re-reviewed; the previous success is carried over | `agent-review` | `REVIEW_SKIP_LINES` (default 15) |
| Diff of at most N lines and no critical path: small model and 8 turns. Otherwise the full model and 12 turns | `agent-review` | `REVIEW_SMALL_LINES` (default 80), `REVIEWER_MODEL_SMALL` (default `claude-haiku-5-5`) |
| `REVIEWER_MODEL` set: always that model (disables the diff-size rule) | `agent-review` | `REVIEWER_MODEL` |
| Daily implementer cap and turn cap | `agent-implement` | `AGENT_DAILY_LIMIT` (default 3), `IMPLEMENTER_MAX_TURNS` (default 30) |
| Cost per run (`total_cost_usd`, turns) in the job summary | all three | none |

Critical paths for the diff-size and re-review rules: `.github/`, `supabase/`, `packages/domain/`, `tool/`, `.claude/`,
`CLAUDE.md`, `CODEOWNERS`, `analysis_options.yaml`, `lefthook.yml`. They always get the full model.

The Console workspace spend limit (Setup, step 2) is the only hard cap and is set in the Console, not in this repo.

