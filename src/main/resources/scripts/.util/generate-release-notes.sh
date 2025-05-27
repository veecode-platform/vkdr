#!/bin/bash

# Script to generate release notes from git commits
set -e

VERSION=$1
if [ -z "$VERSION" ]; then
  echo "Error: Version parameter is required"
  echo "Usage: $0 <version>"
  exit 1
fi

# Source the log utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/log.sh"

startInfos "Generating release notes for v$VERSION"

# Get the latest tag
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

# Generate release notes from git commits
if [ -z "$LATEST_TAG" ]; then
  info "No previous tags found. Generating release notes from all commits."
  COMMITS=$(git log --pretty=format:"* %s (%h)" --no-merges)
else
  info "Generating release notes since $LATEST_TAG"
  COMMITS=$(git log ${LATEST_TAG}..HEAD --pretty=format:"* %s (%h)" --no-merges)
fi

# Create CHANGELOG.md if it doesn't exist
if [ ! -f CHANGELOG.md ]; then
  info "Creating new CHANGELOG.md file"
  echo "# Changelog" > CHANGELOG.md
  echo "" >> CHANGELOG.md
fi

# Prepare release notes
RELEASE_DATE=$(date +"%Y-%m-%d")
RELEASE_NOTES="## v$VERSION ($RELEASE_DATE)\n\n$COMMITS\n\n"

# Insert new release notes at the top of the file (after the header)
awk -v notes="$RELEASE_NOTES" 'NR==2{print notes}1' CHANGELOG.md > CHANGELOG.md.tmp
mv CHANGELOG.md.tmp CHANGELOG.md

success "Release notes for v$VERSION have been generated and added to CHANGELOG.md"
