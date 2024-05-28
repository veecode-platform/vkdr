# Define the version
VERSION=$(shell mvn help:evaluate -Dexpression=project.version -q -DforceStdout)
RELEASE_VERSION=$(shell echo $(VERSION) | sed 's/-SNAPSHOT//')
NEXT_VERSION=$(shell echo $(RELEASE_VERSION) | awk -F. -v OFS=. '{$(NF)++; print $0"-SNAPSHOT"}')

# Targets
.PHONY: release bump

# Default target
release: set-release-version git-tag bump-version

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
	mvn versions:set -DnewVersion=$(NEXT_VERSION)
	mvn versions:commit
	git commit -am "Bump version to $(NEXT_VERSION)"
	git push origin main

# Rollback changes made by versions:set in case of error
rollback:
	mvn versions:revert
