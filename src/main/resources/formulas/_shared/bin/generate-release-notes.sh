#!/usr/bin/env bash

# Script to generate release notes from git commits
set -e

VERSION=$1
if [ -z "$VERSION" ]; then
  echo "Error: Version parameter is required"
  echo "Usage: $0 <version>"
  exit 1
fi

# Source the log utilities
source "$(dirname "$0")/log.sh"

info "Generating release notes for v$VERSION"

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

last_line=$(printf "%s\n" "$COMMITS" | tail -n 1)

# Check if it starts with "* Bump version " and remove line if it does
if [[ $last_line == \*\ Bump\ version\ * ]]; then
  # Remove last line
  COMMITS=$(printf "%s\n" "$COMMITS" | sed '$d')
fi

# Create CHANGELOG.md if it doesn't exist
if [ ! -f CHANGELOG.md ]; then
  info "Creating new CHANGELOG.md file"
  echo "# VKDR Changelog" > CHANGELOG.md
  echo "" >> CHANGELOG.md
fi

# Prepare release notes
RELEASE_DATE=$(date +"%Y-%m-%d")
#RELEASE_NOTES=$"## v$VERSION ($RELEASE_DATE)\n$COMMITS\n"
#RELEASE_NOTES=$'## v'"$VERSION"' ('"$RELEASE_DATE"')\n'"$COMMITS"'\n'
RELEASE_NOTES=$(printf "\n## v%s (%s)\n%s\n" "$VERSION" "$RELEASE_DATE" "$COMMITS")
echo "NOTES: $RELEASE_NOTES"

# Insert new release notes at the top of the file (after the header)
sed '2r /dev/stdin' CHANGELOG.md <<< "$RELEASE_NOTES" > CHANGELOG.md.tmp
mv CHANGELOG.md.tmp CHANGELOG.md

info "Release notes for v$VERSION have been generated and added to CHANGELOG.md"
