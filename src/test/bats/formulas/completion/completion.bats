#!/usr/bin/env bats
# completion.bats - Tests for: vkdr completion bash/zsh/install/uninstall/status
#
# No cluster required.
#
# SAFETY: every test points VKDR_COMPLETIONS_DIR and --rc-file into $BATS_TEST_TMPDIR, so the
# developer's real ~/.bashrc and ~/.zshrc are never touched. --rc-file is always passed
# explicitly, which also forces the rc-file code path instead of the no-rc shortcut (that
# shortcut would write outside the sandbox, into a directory the real shell searches).
#
# PREREQUISITES:
#   - VKDR tools installed (vkdr init) for the 'explain' path only; generation needs nothing.

load '../../helpers/common'

setup() {
  load_vkdr
  export VKDR_COMPLETIONS_DIR="$BATS_TEST_TMPDIR/completions"
  export FAKE_RC="$BATS_TEST_TMPDIR/fake-rc"
  printf '# sentinel-before\nexport FOO=1\n' > "$FAKE_RC"
  cp "$FAKE_RC" "$FAKE_RC.orig"
  SCRIPT="$BATS_TEST_TMPDIR/vkdr.bash"
}

# Capture the pure script with a plain redirect, never `run` - bats' `run` folds stderr into
# $output, and dev mode shells out to mvn which can emit WARNING: lines.
gen_script() {
  vkdr completion bash > "$SCRIPT" 2>/dev/null
}

# Drive the generated completion function the way bash would.
# Usage: complete_with <shell> <word0> [word1 ...]   - last arg is the partial word
complete_with() {
  local sh="$1"; shift
  local driver="$BATS_TEST_TMPDIR/drive.sh"
  cat > "$driver" <<'DRIVER'
#!/usr/bin/env bash
source "$1"; shift
COMP_WORDS=("$@")
COMP_CWORD=$(( $# - 1 ))
COMP_LINE="${COMP_WORDS[*]}"
COMP_POINT=${#COMP_LINE}
_complete_vkdr
printf '%s\n' "${COMPREPLY[@]}"
DRIVER
  "$sh" "$driver" "$SCRIPT" "$@" 2>/dev/null
}

# ============================================================================
# Generation
# ============================================================================

@test "completion bash: succeeds and emits the entry point" {
  run vkdr completion bash
  assert_success
  assert_output --partial "_complete_vkdr"
  assert_output --partial "complete -F _complete_vkdr"
}

@test "completion bash: first line is the shebang (stdout is not polluted)" {
  gen_script
  run head -1 "$SCRIPT"
  assert_output "#!/usr/bin/env bash"
}

@test "completion bash: includes top-level command groups" {
  gen_script
  run cat "$SCRIPT"
  assert_output --partial "infra"
  assert_output --partial "whoami"
  assert_output --partial "mirror"
  assert_output --partial "completion"
}

@test "completion bash: includes nested 3-level commands" {
  gen_script
  run grep -c "^function _picocli_vkdr_infra_start()" "$SCRIPT"
  assert_output "1"
}

@test "completion bash: includes leaf options and the inherited --silent" {
  gen_script
  run cat "$SCRIPT"
  assert_output --partial "--gateway-class"
  assert_output --partial "--silent"
}

@test "completion bash: includes enum option values" {
  gen_script
  run cat "$SCRIPT"
  assert_output --partial "dbless"
}

@test "completion zsh: keeps picocli's bashcompinit bootstrap" {
  run vkdr completion zsh
  assert_success
  assert_output --partial "bashcompinit"
}

@test "completion: zsh global side effects are stripped" {
  gen_script
  run grep -c 'COMPLETE_ALIASES' "$SCRIPT"
  assert_output "0"
  run grep -c 'alias compopt=complete' "$SCRIPT"
  assert_output "0"
}

@test "completion: bash and zsh emit identical scripts" {
  vkdr completion bash > "$BATS_TEST_TMPDIR/a" 2>/dev/null
  vkdr completion zsh  > "$BATS_TEST_TMPDIR/b" 2>/dev/null
  run diff "$BATS_TEST_TMPDIR/a" "$BATS_TEST_TMPDIR/b"
  assert_success
}

@test "completion: the plural spelling is NOT accepted" {
  # kubectl, helm, k3d, gh and kind all use the singular; there is deliberately no alias,
  # because an alias shows up as a duplicate entry in both --help and TAB completion.
  run vkdr completions bash
  assert_failure
}

# ============================================================================
# Shell compatibility
# ============================================================================

@test "completion bash: script parses under bash 5" {
  gen_script
  run bash -n "$SCRIPT"
  assert_success
}

@test "completion bash: script parses under bash 3.2 (macOS /bin/bash)" {
  [ -x /bin/bash ] || skip "/bin/bash not available"
  gen_script
  run /bin/bash -n "$SCRIPT"
  assert_success
}

# ============================================================================
# Functional completion
# ============================================================================

@test "completion: top level offers command groups" {
  gen_script
  run complete_with bash vkdr ""
  assert_success
  assert_line "infra"
  assert_line "postgres"
  assert_line "completion"
}

@test "completion: a group offers its subcommands" {
  gen_script
  run complete_with bash vkdr mirror ""
  assert_line "add"
  assert_line "remove"
  assert_line "list"
}

@test "completion: a 3-level path offers leaf subcommands" {
  gen_script
  run complete_with bash vkdr postgres ""
  assert_line "createdb"
  assert_line "dropdb"
  assert_line "listdbs"
}

@test "completion: a dash offers flags" {
  gen_script
  run complete_with bash vkdr kong install "-"
  assert_line "--domain"
}

@test "completion: prefix filtering works" {
  gen_script
  run complete_with bash vkdr "mir"
  assert_line "mirror"
  refute_line "infra"
}

@test "completion: works under bash 3.2 at runtime, not just at parse time" {
  [ -x /bin/bash ] || skip "/bin/bash not available"
  gen_script
  run complete_with /bin/bash vkdr postgres ""
  assert_line "createdb"
}

# ============================================================================
# Install
# ============================================================================

@test "install: writes the script and wires the rc file" {
  run vkdr completion install --shell bash --rc-file "$FAKE_RC" -y
  assert_success
  [ -f "$VKDR_COMPLETIONS_DIR/vkdr.bash" ]
  run grep -c '>>> vkdr completion >>>' "$FAKE_RC"
  assert_output "1"
}

@test "install: preserves pre-existing rc content" {
  vkdr completion install --shell bash --rc-file "$FAKE_RC" -y >/dev/null 2>&1
  run cat "$FAKE_RC"
  assert_output --partial "sentinel-before"
  assert_output --partial "FOO=1"
}

@test "install: the modified rc file is still valid shell" {
  vkdr completion install --shell bash --rc-file "$FAKE_RC" -y >/dev/null 2>&1
  run /bin/bash -n "$FAKE_RC"
  assert_success
}

@test "install: is idempotent - second run is byte-for-byte identical" {
  vkdr completion install --shell bash --rc-file "$FAKE_RC" -y >/dev/null 2>&1
  cp "$FAKE_RC" "$BATS_TEST_TMPDIR/snap1"
  vkdr completion install --shell bash --rc-file "$FAKE_RC" -y >/dev/null 2>&1
  run diff "$BATS_TEST_TMPDIR/snap1" "$FAKE_RC"
  assert_success
  run grep -c '>>> vkdr completion >>>' "$FAKE_RC"
  assert_output "1"
}

@test "install: second run reports it is already installed" {
  vkdr completion install --shell bash --rc-file "$FAKE_RC" -y >/dev/null 2>&1
  run vkdr completion install --shell bash --rc-file "$FAKE_RC" -y
  assert_success
  assert_output --partial "already installed"
}

@test "install: replaces a stale block in place instead of appending" {
  {
    printf '# >>> vkdr completion >>>\n'
    printf 'source /some/old/path/vkdr.bash\n'
    printf '# <<< vkdr completion <<<\n'
    printf '# after-block\n'
  } >> "$FAKE_RC"
  vkdr completion install --shell bash --rc-file "$FAKE_RC" -y >/dev/null 2>&1
  run grep -c '>>> vkdr completion >>>' "$FAKE_RC"
  assert_output "1"
  run cat "$FAKE_RC"
  refute_output --partial "/some/old/path/vkdr.bash"
  assert_output --partial "after-block"
}

@test "install: migrates a v2.0.25 'completions' block instead of orphaning it" {
  # v2.0.25 shipped the plural markers. Upgrading must replace that block, not leave it
  # behind and append a second one.
  {
    printf '# >>> vkdr completions >>>\n'
    printf 'source /some/old/path/vkdr.bash\n'
    printf '# <<< vkdr completions <<<\n'
  } >> "$FAKE_RC"
  vkdr completion install --shell bash --rc-file "$FAKE_RC" -y >/dev/null 2>&1
  run grep -c 'vkdr completions' "$FAKE_RC"
  assert_output "0"
  run grep -c '>>> vkdr completion >>>' "$FAKE_RC"
  assert_output "1"
}

@test "uninstall: removes a legacy v2.0.25 'completions' block" {
  {
    printf '# >>> vkdr completions >>>\n'
    printf 'source /some/old/path/vkdr.bash\n'
    printf '# <<< vkdr completions <<<\n'
  } >> "$FAKE_RC"
  vkdr completion uninstall --shell bash --rc-file "$FAKE_RC" >/dev/null 2>&1
  run grep -c 'vkdr completion' "$FAKE_RC"
  assert_output "0"
  run cat "$FAKE_RC"
  assert_output --partial "sentinel-before"
}

@test "install: creates the rc file when it does not exist" {
  rm -f "$FAKE_RC"
  run vkdr completion install --shell bash --rc-file "$FAKE_RC" -y
  assert_success
  [ -f "$FAKE_RC" ]
}

@test "install: handles an rc file with no trailing newline" {
  printf 'export FOO=1' > "$FAKE_RC"
  vkdr completion install --shell bash --rc-file "$FAKE_RC" -y >/dev/null 2>&1
  run /bin/bash -n "$FAKE_RC"
  assert_success
  run grep -c 'FOO=1' "$FAKE_RC"
  assert_output "1"
}

@test "install: --dry-run changes nothing" {
  run vkdr completion install --shell bash --rc-file "$FAKE_RC" --dry-run
  assert_success
  run diff "$FAKE_RC.orig" "$FAKE_RC"
  assert_success
}

@test "install: --no-rc writes the script but leaves the rc alone" {
  run vkdr completion install --shell bash --rc-file "$FAKE_RC" --no-rc -y
  assert_success
  [ -f "$VKDR_COMPLETIONS_DIR/vkdr.bash" ]
  run diff "$FAKE_RC.orig" "$FAKE_RC"
  assert_success
}

@test "install: backs up the rc file before the first change" {
  vkdr completion install --shell bash --rc-file "$FAKE_RC" -y >/dev/null 2>&1
  [ -f "$FAKE_RC.vkdr-bak" ]
  run diff "$FAKE_RC.orig" "$FAKE_RC.vkdr-bak"
  assert_success
}

@test "install: refuses to guess when the sentinels are unbalanced" {
  printf '# >>> vkdr completion >>>\n' >> "$FAKE_RC"
  run vkdr completion install --shell bash --rc-file "$FAKE_RC" -y
  assert_failure
  assert_output --partial "Unbalanced"
}

# ============================================================================
# Uninstall
# ============================================================================

@test "uninstall: restores the rc file byte-for-byte" {
  vkdr completion install --shell bash --rc-file "$FAKE_RC" -y >/dev/null 2>&1
  run vkdr completion uninstall --shell bash --rc-file "$FAKE_RC"
  assert_success
  run diff "$FAKE_RC.orig" "$FAKE_RC"
  assert_success
}

@test "uninstall: is idempotent" {
  vkdr completion install --shell bash --rc-file "$FAKE_RC" -y >/dev/null 2>&1
  vkdr completion uninstall --shell bash --rc-file "$FAKE_RC" >/dev/null 2>&1
  run vkdr completion uninstall --shell bash --rc-file "$FAKE_RC"
  assert_success
}

@test "uninstall: succeeds when nothing was ever installed" {
  run vkdr completion uninstall --shell bash --rc-file "$FAKE_RC"
  assert_success
  assert_output --partial "not installed"
}

@test "uninstall: --purge removes the generated script" {
  vkdr completion install --shell bash --rc-file "$FAKE_RC" -y >/dev/null 2>&1
  [ -f "$VKDR_COMPLETIONS_DIR/vkdr.bash" ]
  vkdr completion uninstall --shell bash --rc-file "$FAKE_RC" --purge >/dev/null 2>&1
  [ ! -f "$VKDR_COMPLETIONS_DIR/vkdr.bash" ]
}

# ============================================================================
# Status
# ============================================================================

@test "status: exits 1 before install and 0 after" {
  run vkdr completion status --shell bash --rc-file "$FAKE_RC"
  assert_failure
  vkdr completion install --shell bash --rc-file "$FAKE_RC" -y >/dev/null 2>&1
  run vkdr completion status --shell bash --rc-file "$FAKE_RC"
  assert_success
}
