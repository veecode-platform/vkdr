#!/usr/bin/env bash

declare -Agr C=(
  [red]=$(echo -e '\033[31m')
  [green]=$(echo -e '\033[32m')
  [yellow]=$(echo -e '\033[33m')
  [blue]=$(echo -e '\033[34m')
  [cyan]=$(echo -e '\033[36m')
  [bold]=$(echo -e '\033[1m')
  [boldred]=$(echo -e '\033[01;31m')
  [boldgreen]=$(echo -e '\033[01;32m')
  [boldyellow]=$(echo -e '\033[01;33m')
  [boldblue]=$(echo -e '\033[01;34m')
  [boldcyan]=$(echo -e '\033[01;36m')
)

NC=$(echo -e "\e[0m")
readonly NC

export C

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

bold() { shouldLog && log "true" "${C[bold]}$*${NC}"; return 0; }
info() { shouldLog && log "true" "${C[green]}$*${NC}"; return 0; }
infoYellow() { shouldLog && log "true" "${C[yellow]}$*${NC}"; return 0; }
boldInfo() { shouldLog && log "true" "${C[boldgreen]}$*${NC}"; return 0; }
notice() { shouldLog && log "true" "${C[blue]}$*${NC}"; return 0; }
boldNotice() { shouldLog && log "true" "${C[boldblue]}$*${NC}"; return 0; }
error() { log "true" "${C[red]}$*${NC}"; return 0; }
boldError() { log "true" "${C[boldred]}$*${NC}"; return 0; }
trace() { log "${LOG_TRACE:-}" "${C[cyan]}$*${NC}"; return 0; }
boldTrace() { log "${LOG_TRACE:-}" "${C[boldcyan]}$*${NC}"; return 0; }
warn() { shouldLog && log "${LOG_DEBUG:-}" "${C[yellow]}$*${NC}"; return 0; }
boldWarn() { shouldLog && log "${LOG_DEBUG:-}" "${C[boldyellow]}$*${NC}"; return 0; }
debug() { shouldLog && log "${LOG_DEBUG:-}" "${C[red]}${C[red]}[DEBUG]${NC} $*${NC}"; return 0; }
