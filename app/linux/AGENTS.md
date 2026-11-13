<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-11-13 | Updated: 2026-11-13 -->

# linux

## Purpose
Linux desktop runner used **only** as headless harness for CI desktop integration tests (P1-T09) and DebugDrive (`make drive-up`, P3-T04). Never released.

## Subdirectories
| Directory | Purpose |
|-----------|---------|
| `runner/` | GTK runner (`main.cc`, `my_application.*`) |
| `flutter/` | Generated plugin registrant + CMake glue |

## For AI Agents

### Working In This Directory
- Generated scaffolding; do not add product features or platform-specific behavior here.
- Do not remove: CI and DebugDrive depend on it.

### Testing Requirements
- Exercised by `make it` (CI: `desktop-it.yml`, Linux + xvfb) and `make drive-up` once that lands.

<!-- MANUAL: Any manually added notes below this line are preserved on regeneration -->
