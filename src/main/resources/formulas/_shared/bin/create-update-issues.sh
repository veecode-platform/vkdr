#!/usr/bin/env bash
#
# create-update-issues.sh - Create GitHub issues for available formula updates
#
# Usage: ./create-update-issues.sh
#
# Requires: gh (GitHub CLI), jq
# Environment: GH_TOKEN must be set for authentication
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Get updates JSON
updates=$("$SCRIPT_DIR/check-updates.sh" --json)

# Ensure dependency-update label exists
gh label create "dependency-update" --color "0366d6" --description "Automated dependency update" 2>/dev/null || true

# Count updates
update_count=$(echo "$updates" | jq '[.[] | select(.status == "update-available")] | length')

if [ "$update_count" -eq 0 ]; then
  echo "No updates available. All formulas are up-to-date."
  exit 0
fi

echo "Found $update_count formula(s) with updates available."

# Process each formula with updates available
echo "$updates" | jq -c '.[] | select(.status == "update-available")' | while read -r item; do
  formula=$(echo "$item" | jq -r '.formula')
  type=$(echo "$item" | jq -r '.type')
  current=$(echo "$item" | jq -r '.current')
  latest=$(echo "$item" | jq -r '.latest')

  echo "Processing $formula: $current -> $latest"

  # Check if issue already exists (search by title)
  existing=$(gh issue list --search "update: $formula to $latest in:title" --state open --json number --jq 'length' 2>/dev/null || echo "0")
  if [ "$existing" -gt 0 ]; then
    echo "  Issue already exists, skipping..."
    continue
  fi

  # Build issue body
  body="## Dependency Update Available

A new version is available for the **$formula** formula.

### Update Details

\`\`\`yaml
formula: $formula
type: $type
current_version: \"$current\"
target_version: \"$latest\"
update_yaml: src/main/resources/formulas/$formula/_meta/update.yaml
spec_file: src/main/resources/formulas/$formula/_meta/spec.md
test_command: make test-formula formula=$formula
\`\`\`

### Instructions

1. Read the formula spec: \`src/main/resources/formulas/$formula/_meta/spec.md\`
2. Follow the \"Updating\" section for this formula type: \`$type\`
3. Update version to: \`$latest\`
4. Run tests: \`make test-formula formula=$formula\`
5. Commit with message: \`update: $formula to $latest\`

### Links

- [Formula update.yaml](https://github.com/veecode-platform/vkdr/blob/main/src/main/resources/formulas/$formula/_meta/update.yaml)
- [Formula spec.md](https://github.com/veecode-platform/vkdr/blob/main/src/main/resources/formulas/$formula/_meta/spec.md)"

  # Create issue
  gh issue create \
    --title "update: $formula to $latest" \
    --label "dependency-update" \
    --body "$body"

  echo "  Created issue for $formula update"
done

echo "Done."
