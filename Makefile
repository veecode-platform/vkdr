# Define the version
VERSION=$(shell mvn help:evaluate -Dexpression=project.version -q -DforceStdout)
RELEASE_VERSION=$(shell echo $(VERSION) | sed 's/-SNAPSHOT//')
#NEXT_VERSION=$(shell echo $(RELEASE_VERSION) | awk -F. -v OFS=. '{$(NF)++; print $0"-SNAPSHOT"}')
NEXT_VERSION=$(shell echo $(RELEASE_VERSION) | awk -F. '{print $$1"."$$2"."$$3+1"-SNAPSHOT"}')

# BATS testing configuration (pinned versions)
BATS_CORE_VERSION    := 1.11.1
BATS_SUPPORT_VERSION := 0.3.0
BATS_ASSERT_VERSION  := 2.1.0
BATS_DETIK_VERSION   := 1.3.2
BATS_LIBS_DIR        := .bats-libs
BATS_BIN             := $(BATS_LIBS_DIR)/bats-core/bin/bats

# Targets
.PHONY: release bump generate-release-notes command \
        setup-bats check-cluster test test-whoami test-kong test-formula test-binary test-verbose test-debug clean-bats

# Default target
release: set-release-version generate-release-notes git-tag bump-version

# Set the release version (remove -SNAPSHOT)
set-release-version:
	mvn versions:set -DnewVersion=$(RELEASE_VERSION)
	mvn versions:commit

# Create a git tag for the release
git-tag:
	git commit -am "Release version $(RELEASE_VERSION)"
	git tag -a v$(RELEASE_VERSION) -m "v$(RELEASE_VERSION)"
	git push origin v$(RELEASE_VERSION)
	git push origin main

# Bump to the next snapshot version
bump-version:
	#echo "Next version: $(NEXT_VERSION)"
	mvn versions:set -DnewVersion=$(NEXT_VERSION)
	mvn versions:commit
	git commit -am "Bump version to $(NEXT_VERSION)"
	git push origin main

# Generate release notes
generate-release-notes:
	./src/main/resources/scripts/.util/generate-release-notes.sh $(RELEASE_VERSION)
	git add CHANGELOG.md

# Rollback changes made by versions:set in case of error
rollback:
	mvn versions:revert

# Create a new vkdr command structure
# Usage: make command task=<command> subtask=<subcommand>
command:
	@if [ -z "$(task)" ] || [ -z "$(subtask)" ]; then \
		echo "Error: Both task and subtask must be specified"; \
		echo "Usage: make command task=<command> subtask=<subcommand>"; \
		exit 1; \
	fi
	./src/main/resources/scripts/.util/create-command.sh "$(task)" "$(subtask)"

# ============================================================================
# BATS Testing
# ============================================================================

# Check if VKDR cluster is running (prerequisite for formula tests)
check-cluster:
	@if ! ~/.vkdr/bin/k3d cluster list 2>/dev/null | grep -q "vkdr-local"; then \
		echo ""; \
		echo "ERROR: VKDR cluster 'vkdr-local' not found."; \
		echo ""; \
		echo "Formula tests require a running VKDR k3d cluster."; \
		echo "Please run: vkdr infra up"; \
		echo ""; \
		exit 1; \
	fi
	@echo "VKDR cluster 'vkdr-local' is available."

# Download and setup BATS testing framework
setup-bats: $(BATS_BIN)

$(BATS_BIN):
	@echo "Setting up BATS testing framework..."
	@mkdir -p $(BATS_LIBS_DIR)
	@echo "Downloading bats-core v$(BATS_CORE_VERSION)..."
	@curl -sL https://github.com/bats-core/bats-core/archive/refs/tags/v$(BATS_CORE_VERSION).tar.gz | \
		tar -xz -C $(BATS_LIBS_DIR) && mv $(BATS_LIBS_DIR)/bats-core-$(BATS_CORE_VERSION) $(BATS_LIBS_DIR)/bats-core
	@echo "Downloading bats-support v$(BATS_SUPPORT_VERSION)..."
	@curl -sL https://github.com/bats-core/bats-support/archive/refs/tags/v$(BATS_SUPPORT_VERSION).tar.gz | \
		tar -xz -C $(BATS_LIBS_DIR) && mv $(BATS_LIBS_DIR)/bats-support-$(BATS_SUPPORT_VERSION) $(BATS_LIBS_DIR)/bats-support
	@echo "Downloading bats-assert v$(BATS_ASSERT_VERSION)..."
	@curl -sL https://github.com/bats-core/bats-assert/archive/refs/tags/v$(BATS_ASSERT_VERSION).tar.gz | \
		tar -xz -C $(BATS_LIBS_DIR) && mv $(BATS_LIBS_DIR)/bats-assert-$(BATS_ASSERT_VERSION) $(BATS_LIBS_DIR)/bats-assert
	@echo "Downloading bats-detik v$(BATS_DETIK_VERSION)..."
	@curl -sL https://github.com/bats-core/bats-detik/archive/refs/tags/v$(BATS_DETIK_VERSION).tar.gz | \
		tar -xz -C $(BATS_LIBS_DIR) && mv $(BATS_LIBS_DIR)/bats-detik-$(BATS_DETIK_VERSION) $(BATS_LIBS_DIR)/bats-detik
	@echo "BATS setup complete."

# Remove BATS libraries
clean-bats:
	@rm -rf $(BATS_LIBS_DIR)
	@echo "BATS libraries removed."

# Run all formula tests (dev mode - tests current source code)
# Use VKDR_TEST_MODE=binary to test compiled native binary instead
test: setup-bats check-cluster
	@echo "Running tests in $(or $(VKDR_TEST_MODE),dev) mode..."
	@$(BATS_BIN) --tap src/test/bats/formulas/

# Run tests for a specific formula
# Usage: make test-formula formula=whoami
test-formula: setup-bats check-cluster
	@if [ -z "$(formula)" ]; then \
		echo "Error: formula must be specified"; \
		echo "Usage: make test-formula formula=<name>"; \
		exit 1; \
	fi
	@echo "Running $(formula) tests in $(or $(VKDR_TEST_MODE),dev) mode..."
	@$(BATS_BIN) --tap src/test/bats/formulas/$(formula)/

# Shortcut for whoami tests
test-whoami: setup-bats check-cluster
	@echo "Running whoami tests in $(or $(VKDR_TEST_MODE),dev) mode..."
	@$(BATS_BIN) --tap src/test/bats/formulas/whoami/

# Shortcut for kong tests
test-kong: setup-bats check-cluster
	@echo "Running kong tests in $(or $(VKDR_TEST_MODE),dev) mode..."
	@$(BATS_BIN) --tap src/test/bats/formulas/kong/

# Test using compiled native binary (release testing)
test-binary: setup-bats check-cluster
	@if [ ! -x "target/vkdr" ]; then \
		echo "ERROR: Native binary not found. Run: ./mvnw native:compile -Pnative"; \
		exit 1; \
	fi
	@echo "Running tests in binary mode (compiled native binary)..."
	@VKDR_TEST_MODE=binary $(BATS_BIN) --tap src/test/bats/formulas/

# Run tests with verbose output (for debugging)
test-verbose: setup-bats check-cluster
	@$(BATS_BIN) --verbose-run --show-output-of-passing-tests src/test/bats/formulas/

# Run tests keeping resources on failure (for debugging)
test-debug: setup-bats check-cluster
	@VKDR_SKIP_TEARDOWN=true $(BATS_BIN) --verbose-run src/test/bats/formulas/
