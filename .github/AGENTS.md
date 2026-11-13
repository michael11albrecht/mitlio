<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-11-13 | Updated: 2026-11-13 -->

# .github

## Purpose
GitHub config: CI, automerge, risk labeling, code owners, issue/PR templates.

## Key Files
| File | Description |
|------|-------------|
| `CODEOWNERS` | Owner review for `critical` paths — **protected** |
| `pull_request_template.md` | Task ID, changes, checklist (make check, tests first, deps, goldens, UX, drive output), risk |
| `ISSUE_TEMPLATE/agent_task.yml` | One-PR agent task: Task ID, Context, Do, Accept, Out of scope; label `agent-ready` |

## Subdirectories
| Directory | Purpose |
|-----------|---------|
| `workflows/` | `ci.yml`, `automerge.yml`, `risk-label.yml` — **protected** |
| `ISSUE_TEMPLATE/` | Issue forms |

## For AI Agents

### Working In This Directory
- Do not edit `workflows/**` or `CODEOWNERS` unless the issue explicitly asks (critical, owner review).
- Always fill the PR template; link issue and task ID.
- Risk label comes from `tool/risk_label.sh`.

<!-- MANUAL: Any manually added notes below this line are preserved on regeneration -->
