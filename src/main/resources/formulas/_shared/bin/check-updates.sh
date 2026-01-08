#!/usr/bin/env bash
#
# check-updates.sh - Check all formulas for available updates
#
# Usage: ./check-updates.sh [--json]
#
# Reads _meta/update.yaml from each formula and checks for newer versions.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FORMULAS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

JSON_OUTPUT=false
if [[ "${1:-}" == "--json" ]]; then
  JSON_OUTPUT=true
fi

# Check for required tools
check_requirements() {
  local missing=()
  command -v yq &>/dev/null || missing+=("yq")
  command -v helm &>/dev/null || missing+=("helm")
  command -v curl &>/dev/null || missing+=("curl")
  command -v jq &>/dev/null || missing+=("jq")

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Error: Missing required tools: ${missing[*]}" >&2
    exit 1
  fi
}

# Get latest helm chart version from OCI registry or HTTP repo
get_helm_latest() {
  local repo="$1"
  local chart="$2"

  # For OCI registries, use helm show chart
  if [[ "$repo" == oci://* ]]; then
    helm show chart "$repo" 2>/dev/null | grep '^version:' | awk '{print $2}'
  else
    # For HTTP repos, add temp repo and search
    local temp_repo="temp-check-$$"
    # Extract just the chart name (remove any org/ prefix)
    local chart_name="${chart##*/}"
    helm repo add "$temp_repo" "$repo" &>/dev/null || true
    helm repo update "$temp_repo" &>/dev/null || true
    local version
    version=$(helm search repo "$temp_repo/$chart_name" --output json 2>/dev/null | jq -r '.[0].version // ""')
    helm repo remove "$temp_repo" &>/dev/null || true
    echo "$version"
  fi
}

# Get latest GitHub release version
get_github_release_latest() {
  local repo="$1"
  curl -s "https://api.github.com/repos/$repo/releases/latest" 2>/dev/null | \
    jq -r '.tag_name // empty' | sed 's/^v//'
}

# Get latest GitHub tag (for projects that use tags instead of releases)
get_github_tag_latest() {
  local repo="$1"
  # Filter out nightly/snapshot tags, get only semver-like tags
  curl -s "https://api.github.com/repos/$repo/tags?per_page=50" 2>/dev/null | \
    jq -r '.[].name' | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$' | sed 's/^v//' | head -1
}

# Compare versions (returns 0 if update available, 1 if up-to-date)
version_gt() {
  local current="$1"
  local latest="$2"

  # Remove 'v' prefix if present
  current="${current#v}"
  latest="${latest#v}"

  if [[ "$current" == "$latest" ]]; then
    return 1
  fi

  # Use sort -V for version comparison
  local highest
  highest=$(printf '%s\n%s' "$current" "$latest" | sort -V | tail -1)
  [[ "$highest" == "$latest" && "$current" != "$latest" ]]
}

# Process a single formula
check_formula() {
  local formula_dir="$1"
  local formula_name
  formula_name=$(basename "$formula_dir")

  local update_file="$formula_dir/_meta/update.yaml"
  if [[ ! -f "$update_file" ]]; then
    return
  fi

  local update_type
  update_type=$(yq -r '.type // ""' "$update_file")

  case "$update_type" in
    helm-pinned)
      local repo chart current_version latest_version
      repo=$(yq -r '.helm.repo // ""' "$update_file")
      chart=$(yq -r '.helm.chart // ""' "$update_file")
      current_version=$(yq -r '.helm.version // ""' "$update_file")

      if [[ -z "$repo" || -z "$current_version" ]]; then
        return
      fi

      latest_version=$(get_helm_latest "$repo" "$chart")

      if [[ -n "$latest_version" ]]; then
        print_result "$formula_name" "helm-pinned" "$current_version" "$latest_version"
      fi
      ;;

    helm-latest)
      # Always uses latest, just report status
      if ! $JSON_OUTPUT; then
        echo -e "${BLUE}$formula_name${NC}: helm-latest (auto-updates)"
      fi
      ;;

    helm-frozen)
      # Intentionally not updated
      if ! $JSON_OUTPUT; then
        echo -e "${YELLOW}$formula_name${NC}: helm-frozen (not updating)"
      fi
      ;;

    operator)
      local github_repo current_version latest_version
      github_repo=$(yq -r '.operator.github // ""' "$update_file")
      current_version=$(yq -r '.operator.version // ""' "$update_file")

      if [[ -z "$github_repo" || -z "$current_version" ]]; then
        return
      fi

      # Try releases first, then tags
      latest_version=$(get_github_release_latest "$github_repo")
      if [[ -z "$latest_version" ]]; then
        latest_version=$(get_github_tag_latest "$github_repo")
      fi

      if [[ -n "$latest_version" ]]; then
        print_result "$formula_name" "operator" "$current_version" "$latest_version"
      fi
      ;;
  esac
}

# Track results for JSON output
declare -a JSON_RESULTS=()
UPDATES_AVAILABLE=0

print_result() {
  local name="$1"
  local type="$2"
  local current="$3"
  local latest="$4"

  if $JSON_OUTPUT; then
    local status="up-to-date"
    if version_gt "$current" "$latest"; then
      status="update-available"
      UPDATES_AVAILABLE=$((UPDATES_AVAILABLE + 1))
    fi
    JSON_RESULTS+=("{\"formula\":\"$name\",\"type\":\"$type\",\"current\":\"$current\",\"latest\":\"$latest\",\"status\":\"$status\"}")
  else
    if version_gt "$current" "$latest"; then
      echo -e "${RED}$name${NC}: $current → ${GREEN}$latest${NC} (update available)"
      UPDATES_AVAILABLE=$((UPDATES_AVAILABLE + 1))
    else
      echo -e "${GREEN}$name${NC}: $current (up-to-date)"
    fi
  fi
}

main() {
  check_requirements

  if ! $JSON_OUTPUT; then
    echo "Checking formula updates..."
    echo ""
  fi

  # Find all formulas with update.yaml
  for formula_dir in "$FORMULAS_DIR"/*/; do
    # Skip _shared and hidden directories
    local dir_name
    dir_name=$(basename "$formula_dir")
    if [[ "$dir_name" == _* ]] || [[ "$dir_name" == .* ]]; then
      continue
    fi

    check_formula "$formula_dir"
  done

  if $JSON_OUTPUT; then
    # Output JSON array
    echo "["
    local first=true
    for result in "${JSON_RESULTS[@]}"; do
      if $first; then
        first=false
      else
        echo ","
      fi
      echo "  $result"
    done
    echo "]"
  else
    echo ""
    if [[ $UPDATES_AVAILABLE -gt 0 ]]; then
      echo -e "${YELLOW}$UPDATES_AVAILABLE update(s) available${NC}"
    else
      echo -e "${GREEN}All formulas are up-to-date${NC}"
    fi
  fi

  exit 0
}

main "$@"
