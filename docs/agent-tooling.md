# Agent tooling: which model for what

## Budget context (2026-11)

- GitHub Copilot (Student plan) is credit-metered: 200 credits (~$2) per month, then paid per token. Do not use Copilot chat/agent/CLI for this repo. Inline completions only. Keep the Copilot spending limit at $0.
- Actions minutes are free (public repo). Nothing to optimise there.
- CI agents (`agent-plan`, `agent-implement`, `agent-review`, `agent-fix-ci`) run Claude. `agent-fix-ci` and the nightly mutation issues never spend by default: the first needs `AGENT_FIX_CI=true`, the second only files `agent-ready` issues (the owner adds `agent-implement`). Keep repo variable `CLAUDE_AUTH` unset or `oauth` (subscription token), not `api` (per-token billing).

## Claude Code

Primary tool for all implementation, per `CLAUDE.md` (Sonnet implements, Opus plans).

## Gemini CLI (optional second opinion)

Use only for manual, non-blocking second opinions on a diff or a design. Never for implementation, never in CI, never in a flow that waits on it: it is slow (seconds to 2+ minutes) and the free tier returns 503 "high demand" under load (CLI retries 10x, up to ~15 min).

- Installed via Homebrew: `gemini` (0.68.0), `rg`. Make sure `/opt/homebrew/bin` is on PATH.
- Config: `~/.gemini/settings.json` (auth `gemini-api-key`, default model `gemini-3.8-flash`). API key is in the macOS keychain, not in the repo. Never commit or echo it.
- "Sign in with Google" free tier is discontinued; `gemini-2.5-flash` is gone for new users. Do not suggest either.

Review the current branch:

```
git diff main...HEAD | gemini -p "Review this diff for bugs and violations of CLAUDE.md rules. Be terse."
```

Rules for agents:
- Wrap in a hard timeout (`perl -e 'alarm 120; exec @ARGV' gemini -p "..."`); if it times out or returns 503, skip it and continue. Do not retry in a loop.
- From inside the Claude Code sandbox, `gemini` may hang (keychain access). If it does, ask the user to run it in a terminal and paste the output.
- Treat output as a suggestion. `make check` stays the only definition of done.

## Not available

- Codex: not installed, needs a paid ChatGPT plan or API key.
- `omc` CLI (for `/ask`, `/ccg`): not installed. Use `gemini -p` directly.
