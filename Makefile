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
	$(call not_yet,build_runner arrives with freezed/drift/riverpod in P2/P3)

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

.PHONY: test-drive
test-drive: ## Drive client tests
	cd $(DRIVE) && $(DART) test

.PHONY: test-tooling
test-tooling: ## Tests for repo tooling (gates)
	cd $(TOOLING) && $(DART) test
	tool/risk_label_test.sh

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

.PHONY: drive-up drive
drive-up: ## Run debug app on desktop for DebugDrive
	$(call not_yet,DebugDrive is P3-T04)
drive: ## Call ext.mitlio.* on the running app (CMD='ping')
	$(call not_yet,DebugDrive is P3-T04)

.PHONY: secrets
secrets: ## Scan for committed secrets
	@command -v gitleaks >/dev/null && gitleaks git --no-banner --redact . || echo "gitleaks not installed — skipped"

.PHONY: check-fast
check-fast: fmt-check lint test-domain ## Quick gate (agent Stop hook)

.PHONY: check
check: fmt-check lint arch test-tooling cov domain-web-test goldens secrets ## Definition of done (cov runs all tests)
