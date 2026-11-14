# mitlio — single command surface for humans, CI and agents.
# Definition of done for every change: `make check` is green.
# See docs/IMPLEMENTATION_PLAN.md §5.1.

SHELL := /bin/bash
.DEFAULT_GOAL := help

FLUTTER ?= $(shell command -v flutter 2>/dev/null || echo $(HOME)/sdk/flutter/bin/flutter)
DART    ?= $(shell command -v dart 2>/dev/null || echo $(HOME)/sdk/flutter/bin/dart)

DOMAIN := packages/domain
DRIVE  := packages/drive_client
DOMAIN_WEB := packages/domain_web
TOOLING := packages/tooling
WEB    := web
APP    := app

define not_yet
	@echo "make $@: not yet available ($(1))"
endef

.PHONY: help
help: ## List targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-16s %s\n", $$1, $$2}'

.PHONY: bootstrap
bootstrap: ## Install deps and git hooks
	$(FLUTTER) --version
	$(FLUTTER) pub get
	@command -v lefthook >/dev/null && lefthook install || echo "lefthook not installed — git hooks skipped (see CLAUDE.md)"

.PHONY: gen
gen: ## Run code generation
	cd $(APP) && $(FLUTTER) gen-l10n
	cd app && $(DART) run build_runner build --delete-conflicting-outputs

.PHONY: db-schema
db-schema: ## Dump Drift schema to app/drift_schemas + regenerate migration test helpers
	cd app && $(DART) run drift_dev schema dump lib/db/app_database.dart drift_schemas/
	cd app && $(DART) run drift_dev schema generate drift_schemas/ test/db/generated/
	perl -pi -e 's/unused_import$$/unused_import,strict_raw_type/' app/test/db/generated/schema_v1.dart
	$(DART) format app/test/db/generated

.PHONY: fmt
fmt: ## Format all Dart code
	$(DART) format .

.PHONY: fmt-check
fmt-check: ## Fail if formatting is needed
	$(DART) format --output=none --set-exit-if-changed .

.PHONY: lint
lint: ## Static analysis (infos are fatal)
	$(FLUTTER) analyze --fatal-infos

.PHONY: test-domain
test-domain: ## Domain unit tests (fast TDD loop)
	cd $(DOMAIN) && $(DART) test

.PHONY: domain-web
domain-web: ## Compile domain_web to JS (build/domain_web) + size budget
	tool/build_domain_web.sh

.PHONY: domain-web-test
domain-web-test: domain-web ## domain_web VM tests + Node parity test on the compiled JS
	cd $(DOMAIN_WEB) && $(DART) test
	node --test $(DOMAIN_WEB)/test_js/parity.test.mjs

.PHONY: web-install
web-install: ## Install web/ dependencies (npm ci)
	cd $(WEB) && npm ci

$(WEB)/node_modules/.package-lock.json: $(WEB)/package-lock.json
	cd $(WEB) && npm ci

.PHONY: web-build
web-build: $(WEB)/node_modules/.package-lock.json ## Build the Astro static site (web/dist)
	cd $(WEB) && ASTRO_TELEMETRY_DISABLED=1 npm run build

.PHONY: web-check
web-check: ## astro check + static build (skipped when npm is missing)
	@if command -v npm >/dev/null; then \
	  $(MAKE) $(WEB)/node_modules/.package-lock.json && \
	  (cd $(WEB) && ASTRO_TELEMETRY_DISABLED=1 npm run check && npm run build); \
	else echo "npm not installed — web-check skipped"; fi

.PHONY: test-drive
test-drive: ## Drive client tests
	cd $(DRIVE) && $(DART) test

.PHONY: test-tooling
test-tooling: ## Tests for repo tooling (gates)
	cd $(TOOLING) && $(DART) test
	tool/risk_label_test.sh
	tool/agent_metrics_test.sh

.PHONY: agent-metrics
agent-metrics: ## Regenerate docs/agent-metrics.md from merged PRs (needs gh + jq)
	tool/agent_metrics.sh --write

.PHONY: test-app
test-app: ## App unit + widget tests
	cd $(APP) && $(FLUTTER) test

.PHONY: test
test: test-domain test-drive test-tooling test-app ## All unit + widget tests

.PHONY: cov
cov: ## Tests with coverage + per-path gates (ARGS='--baseline f --write-summary f')
	tool/coverage.sh $(ARGS)

.PHONY: mutate
mutate: ## Mutation tests on domain (CHANGED=1 for changed files only)
	tool/mutate.sh $(if $(CHANGED),--changed,)

.PHONY: deps-policy
deps-policy: ## Fail on ad/tracking/review-prompt SDKs in lockfiles (tool/deps_policy.yaml)
	cd $(TOOLING) && $(DART) run bin/deps_policy.dart --root ../.. --policy ../../tool/deps_policy.yaml

.PHONY: arch
arch: ## Architecture rules
	cd $(APP) && $(FLUTTER) test test/architecture

.PHONY: goldens goldens-update
goldens: ## Verify golden tests (platform-independent CI goldens, ADR 0022)
	cd $(APP) && $(FLUTTER) test --tags golden
goldens-update: ## Update goldens (never in CI)
	@test -z "$$CI" || { echo "make goldens-update must not run in CI"; exit 1; }
	cd $(APP) && $(FLUTTER) test --tags golden --update-goldens

.PHONY: it
it: ## Desktop integration tests (Linux + xvfb only, runs in CI)
ifeq ($(shell uname -s),Linux)
	cd $(APP) && xvfb-run -a $(FLUTTER) test integration_test -d linux
else
	@echo "make it: linux only, runs in CI (desktop-it workflow)"
endif

.PHONY: db-up db-test db-reset
db-up db-test db-reset: ## Local Supabase
	$(call not_yet,Supabase arrives in P6)

DRIVE_DEVICE ?= linux
DRIVE_WAIT   ?= 300
ifeq ($(shell uname -s),Linux)
DRIVE_XVFB := xvfb-run -a
endif

.PHONY: drive-up drive-down drive
drive-up: ## Run debug app in the background for DebugDrive (DRIVE_DEVICE=linux, xvfb on Linux)
	@mkdir -p .drive && rm -f .drive/uri
	@cd $(APP) && nohup $(DRIVE_XVFB) $(FLUTTER) run -d $(DRIVE_DEVICE) --vmservice-out-file=$(CURDIR)/.drive/uri \
		--dart-define=BUILD_SHA=$$(git rev-parse --short HEAD 2>/dev/null || echo dev) \
		>$(CURDIR)/.drive/run.log 2>&1 </dev/null & echo $$! >$(CURDIR)/.drive/pid
	@for i in $$(seq 1 $(DRIVE_WAIT)); do \
		[ -s .drive/uri ] && { echo "drive-up: app ready ($$(cat .drive/uri))"; exit 0; }; \
		kill -0 $$(cat .drive/pid) 2>/dev/null || break; sleep 1; \
	done; echo "drive-up: app did not start, see .drive/run.log"; tail -n 30 .drive/run.log; exit 1
drive-down: ## Stop the app started by drive-up
	@[ -f .drive/pid ] && { pkill -P $$(cat .drive/pid) 2>/dev/null; kill $$(cat .drive/pid) 2>/dev/null; } || true
	@rm -f .drive/pid .drive/uri
drive: ## Call ext.mitlio.* on the running app (CMD='ping' or CMD='seed {"scenario":"x"}')
	@test -n "$(CMD)" || { echo "usage: make drive CMD='ping' (see docs/drive-protocol.md)"; exit 64; }
	@tool/drive.sh $(CMD)

.PHONY: secrets
secrets: ## Scan for committed secrets
	@command -v gitleaks >/dev/null && gitleaks git --no-banner --redact . || echo "gitleaks not installed — skipped"

.PHONY: check-fast
check-fast: fmt-check lint test-domain ## Quick gate (agent Stop hook)

.PHONY: check
check: fmt-check lint arch deps-policy test-tooling cov domain-web-test web-check goldens secrets ## Definition of done (cov runs all tests)
