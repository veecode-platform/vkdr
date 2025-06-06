# Define the version
VERSION=$(shell mvn help:evaluate -Dexpression=project.version -q -DforceStdout)
RELEASE_VERSION=$(shell echo $(VERSION) | sed 's/-SNAPSHOT//')
#NEXT_VERSION=$(shell echo $(RELEASE_VERSION) | awk -F. -v OFS=. '{$(NF)++; print $0"-SNAPSHOT"}')
NEXT_VERSION=$(shell echo $(RELEASE_VERSION) | awk -F. '{print $$1"."$$2"."$$3+1"-SNAPSHOT"}')

# Targets
.PHONY: release bump generate-release-notes command

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
