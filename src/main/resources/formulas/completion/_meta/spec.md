# completion Formula Specification

Unusual formula: **only `explain` is a shell script.** Everything else lives in Java.

## Purpose

Generates and installs shell TAB-completion (bash, zsh) for the whole vkdr command tree.

## Key Files

| File | Purpose |
| --- | --- |
| `explain/formula.sh` | Renders `_meta/docs.md` with glow — the only shell code here |
| `_meta/docs.md` | User documentation |
| `cmd/completion/CompletionsSupport.java` | All generation, detection and rc-file logic |
| `cmd/completion/Vkdr*Command.java` | picocli command classes |

## Why the logic is in Java, not a formula

1. The script content comes from the picocli `CommandSpec`, which only exists in Java.
2. `ShellExecutor.executeCommand` gates every command except `init`/`upgrade` behind
   `validateInitialization`, and that gate prints its "not initialized" banner to **stdout** —
   which a user piping into `source` would ingest.
3. `~/.vkdr/formulas/` does not exist until `vkdr init` runs (`ScriptsExtractor` unpacks it), so
   a formula-backed implementation could not work on a fresh machine — exactly when a user most
   wants completion set up.

Because the completions commands never call `ShellExecutor`, the init gate is never reached and
`ALLOWED_WITHOUT_INIT` needs no change. `explain` is the exception: it needs glow from
`~/.vkdr/bin`, so it legitimately requires `vkdr init`.

## Generation

`CompletionsSupport.generate()` calls `picocli.AutoComplete.bash(root.name(), root.commandLine())`,
reaching the root via `spec.root()` — necessary because `VkdrRunner` builds the root `CommandLine`
inline and stores it nowhere.

`stripZshGlobalSideEffects()` then removes two lines picocli emits in its zsh branch:

| Removed | Why |
| --- | --- |
| `setopt COMPLETE_ALIASES` | Permanently changes completion for every alias in the user's zsh |
| `alias compopt=complete` | Global alias the user never asked for; picocli's call sites already guard with `type compopt` |

The `compinit`/`bashcompinit` bootstrap is deliberately **kept** — it is what makes one script
serve both shells. A bats test asserts both removed strings are absent and that `bashcompinit`
is still present, so a picocli upgrade that changes the template fails loudly.

## Compatibility surfaces

- **Sentinel strings** `# >>> vkdr completion >>>` / `# <<< vkdr completion <<<` are a
  compatibility surface. Changing them orphans every previously installed block; if they ever
  change again, `upsertBlock`/`removeBlock` must also recognise the outgoing pair.
  This already happened once: **v2.0.25 shipped the command as `completions`** and wrote the
  plural markers. `LEGACY_BEGIN`/`LEGACY_END` in `CompletionSupport` keep those recognised, so
  upgrading replaces the old block in place rather than appending a second one, and `uninstall`
  still removes it. Two bats tests cover both directions. The plural markers can be dropped once
  v2.0.25 is old enough to ignore.
- **The command name is singular**, matching kubectl, helm, k3d, gh and kind. There is
  deliberately **no `completions` alias**: picocli renders aliases as real entries, so an alias
  appears as a duplicate in both `--help` and the generated completion script. A bats test
  asserts the plural spelling is rejected.
- The **storage directory stays plural** (`~/.vkdr/completions/`), because it holds scripts for
  several shells and renaming it would orphan the `_vkdr` loaders that v2.0.25 wrote into
  `$fpath` directories. Docker uses the same split (`docker completion`, `~/.docker/completions`).
- **bash 3.2**: the generated script must parse under `/bin/bash` on macOS. picocli's template
  uses only `printf -v` and `local IFS=$'\n'`, both fine on 3.2. Tested.
- `Files.readAllLines` normalises CRLF to LF, so an rc file with CRLF endings is rewritten with
  LF. Acceptable — only macOS and Linux are supported.

## Behaviour notes

- `writeScript()` compares content and no-ops when identical, which is what makes it safe to
  call from `vkdr init` on every run.
- `upsertBlock()` replaces an existing block **in place** rather than delete-and-append, so the
  user's chosen position relative to nvm/oh-my-zsh survives.
- Passing `--rc-file` explicitly forces the rc-file method and skips the no-rc shortcut.
- `VKDR_COMPLETIONS_DIR` overrides `~/.vkdr/completions`; the bats tests rely on it for isolation.
- Malformed sentinels (unbalanced or out of order) raise `IllegalStateException` rather than
  guessing, surfacing as exit code `COMPLETIONS_INSTALL`.

## Testing

`make test-completion` — no cluster required.
