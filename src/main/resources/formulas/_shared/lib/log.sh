#!/usr/bin/env bash

# Plain variables and printf '\033' only: associative arrays (declare -A) and the
# '\e' escape need bash 4+, and macOS still ships bash 3.2 as /bin/bash.
C_RED=$(printf '\033[31m')
C_GREEN=$(printf '\033[32m')
C_YELLOW=$(printf '\033[33m')
C_BLUE=$(printf '\033[34m')
C_CYAN=$(printf '\033[36m')
C_BOLD=$(printf '\033[1m')
C_BOLDRED=$(printf '\033[01;31m')
C_BOLDGREEN=$(printf '\033[01;32m')
C_BOLDYELLOW=$(printf '\033[01;33m')
C_BOLDBLUE=$(printf '\033[01;34m')
C_BOLDCYAN=$(printf '\033[01;36m')
NC=$(printf '\033[0m')

readonly C_RED C_GREEN C_YELLOW C_BLUE C_CYAN C_BOLD
readonly C_BOLDRED C_BOLDGREEN C_BOLDYELLOW C_BOLDBLUE C_BOLDCYAN NC

log() {
  local TOTERM=${1:-}
  local MESSAGE=${2:-}
  echo -e "${MESSAGE:-}" | (
    if [[ ${TOTERM} == true ]] ; then
      tee -a >&2
      #tee -a
    fi
  )
}

# Check if non-error logs should be muted
shouldLog() {
  # If VKDR_SILENT is set to "true", only show errors
  if [ "${VKDR_SILENT:-false}" = "true" ]; then
    return 1  # Don't log (except errors)
  fi
  return 0  # Log normally
}

bold() { shouldLog && log "true" "${C_BOLD}$*${NC}"; return 0; }
info() { shouldLog && log "true" "${C_GREEN}$*${NC}"; return 0; }
infoYellow() { shouldLog && log "true" "${C_YELLOW}$*${NC}"; return 0; }
boldInfo() { shouldLog && log "true" "${C_BOLDGREEN}$*${NC}"; return 0; }
notice() { shouldLog && log "true" "${C_BLUE}$*${NC}"; return 0; }
boldNotice() { shouldLog && log "true" "${C_BOLDBLUE}$*${NC}"; return 0; }
error() { log "true" "${C_RED}$*${NC}"; return 0; }
boldError() { log "true" "${C_BOLDRED}$*${NC}"; return 0; }
trace() { log "${LOG_TRACE:-}" "${C_CYAN}$*${NC}"; return 0; }
boldTrace() { log "${LOG_TRACE:-}" "${C_BOLDCYAN}$*${NC}"; return 0; }
warn() { shouldLog && log "${LOG_DEBUG:-}" "${C_YELLOW}$*${NC}"; return 0; }
boldWarn() { shouldLog && log "${LOG_DEBUG:-}" "${C_BOLDYELLOW}$*${NC}"; return 0; }
debug() { shouldLog && log "${LOG_DEBUG:-}" "${C_RED}[DEBUG]${NC} $*"; return 0; }
