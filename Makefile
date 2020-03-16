# Configuration
# -------------

APP_NAME = `grep 'app:' mix.exs | sed -e 's/\[//g' -e 's/ //g' -e 's/app://' -e 's/[:,]//g'`
APP_VERSION = `grep '@version ' mix.exs | cut -d '"' -f2`
GIT_REVISION = `git rev-parse HEAD`

# Introspection targets
# ---------------------

.PHONY: help
help: header targets

.PHONY: header
header:
	@echo "\033[34mEnvironment\033[0m"
	@echo "\033[34m---------------------------------------------------------------\033[0m"
	@printf "\033[33m%-23s\033[0m" "APP_NAME"
	@printf "\033[35m%s\033[0m" $(APP_NAME)
	@echo ""
	@printf "\033[33m%-23s\033[0m" "APP_VERSION"
	@printf "\033[35m%s\033[0m" $(APP_VERSION)
	@echo ""
	@printf "\033[33m%-23s\033[0m" "GIT_REVISION"
	@printf "\033[35m%s\033[0m" $(GIT_REVISION)
	@echo "\n"

.PHONY: targets
targets:
	@echo "\033[34mTargets\033[0m"
	@echo "\033[34m---------------------------------------------------------------\033[0m"
	@perl -nle'print $& if m{^[a-zA-Z_-]+:.*?## .*$$}' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

# Development targets
# -------------------

.PHONY: dependencies
dependencies: ## Install dependencies
	mix deps.get --force

# CI targets
# ----------

.PHONY: lint
lint: lint-compile lint-format lint-credo ## Run lint tools on the code

.PHONY: lint-compile
lint-compile:
	mix compile --warnings-as-errors --force

.PHONY: lint-format
lint-format:
	mix format --dry-run --check-formatted

.PHONY: lint-credo
lint-credo:
	mix credo --strict

.PHONY: test
test: ## Run the test suite
	mix test

.PHONY: format
format: ## Run formatting tools on the code
	mix format
