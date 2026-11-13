<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-11-13 | Updated: 2026-11-13 -->

# packages

## Purpose
Pure Dart workspace packages (listed in root `pubspec.yaml` `workspace:`). No Flutter dependency in any of them.

## Subdirectories
| Directory | Purpose |
|-----------|---------|
| `domain/` | `mitlio_domain`: business logic (see `domain/AGENTS.md`) |
| `drive_client/` | `mitlio_drive`: DebugDrive CLI client (see `drive_client/AGENTS.md`) |
| `tooling/` | `mitlio_tooling`: repo gates, coverage gate (see `tooling/AGENTS.md`) |

## For AI Agents

### Working In This Directory
- New package: add to root `pubspec.yaml` workspace, use `resolution: workspace`, `publish_to: none`, SDK `^3.14.0`.
- New dependency needs one-line rationale in PR body.

### Testing Requirements
- Each package: `cd packages/<pkg> && dart test`.

<!-- MANUAL: Any manually added notes below this line are preserved on regeneration -->
