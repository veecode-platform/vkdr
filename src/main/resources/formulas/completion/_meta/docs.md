# vkdr completion

Shell TAB-completion for vkdr, supporting **bash** and **zsh**.

Once installed, pressing TAB completes command groups, subcommands and option flags across the whole vkdr command tree. The completion data is generated from the CLI itself, so it always matches the version of vkdr you have installed.

```bash
vkdr <TAB>                     # infra  kong  postgres  vault ...
vkdr postgres <TAB>            # createdb  dropdb  install  listdbs ...
vkdr kong install -<TAB>       # --domain  --mode  --log-level ...
vkdr kong install --mode <TAB> # dbless  standard  hybrid
```

Completion is entirely static: pressing TAB never starts vkdr, never contacts the cluster, and works whether or not a cluster is running. Flags appear once you type `-`, which matches how kubectl, helm and k3d behave.

## vkdr completion install

Writes the completion script and wires it into your shell. This is the command most people want.

```bash
vkdr completion install
```

### Flags

| Flag | Description | Default |
| --- | --- | --- |
| `--shell` | Shell to configure: `bash` or `zsh` | detected from `$SHELL` |
| `--rc-file` | rc file to modify. Naming one forces the rc-file method | auto |
| `--dir` | Install into this directory instead of auto-detecting one | auto |
| `--no-rc` | Only write the script, never touch an rc file | `false` |
| `--dry-run` | Report what would change, write nothing | `false` |
| `-y`, `--yes` | Do not prompt before modifying an rc file | `false` |

### How it chooses where to install

The completion script is always written to `~/.vkdr/completions/vkdr.bash`. What happens next depends on your shell.

If your shell already searches a directory vkdr can write to, a small loader is placed there and **no rc file is modified at all**. For zsh that is a directory on `$fpath` such as `$ZSH_CUSTOM/completions`, `$ZSH/completions`, or Homebrew's `site-functions`. For bash it is the bash-completion v2 directory `~/.local/share/bash-completion/completions`. This is the best outcome, because your shell then loads completions lazily and startup cost is zero.

Only when neither is available does vkdr append a guarded block to your rc file:

```bash
# >>> vkdr completion >>>
# Managed by 'vkdr completion install'. Do not edit inside this block.
[ -f "$HOME/.vkdr/completions/vkdr.bash" ] && . "$HOME/.vkdr/completions/vkdr.bash"
# <<< vkdr completion <<<
```

Re-running `install` never appends a second block: an existing block is replaced in place, so its position in your rc file is preserved. The rc file is backed up to `<rc>.vkdr-bak` before the first change and written atomically, so an interrupted run cannot truncate it.

## vkdr completion uninstall

Removes exactly the guarded block and any loader files that `install` created, leaving the rest of your rc file untouched.

```bash
vkdr completion uninstall
vkdr completion uninstall --all      # clean up every known rc file
vkdr completion uninstall --purge    # also delete ~/.vkdr/completions/vkdr.bash
```

## vkdr completion status

Reports where completions are installed and whether the script is still current. Exits `0` when wired up and `1` when not.

```bash
vkdr completion status
```

## vkdr completion bash / zsh

Print the completion script to stdout. Both emit the same script: it detects zsh at runtime and enables `bashcompinit` itself.

```bash
source <(vkdr completion bash)
```

Use this for a quick trial in the current shell, or to place the script somewhere yourself. Do **not** put `eval "$(vkdr completion bash)"` in an rc file, because that runs vkdr on every shell start. `vkdr completion install` writes a file and sources that instead, which is faster and keeps working even if vkdr is later removed.

## Staying up to date

The script reflects the command tree at the moment it was generated, so a new vkdr release can add commands it does not know about. `vkdr init`, which you must run after every upgrade anyway, regenerates an already-installed script automatically. It never installs completions on its own and never edits an rc file.

Run `vkdr completion status` if you want to check.

## Troubleshooting

| Symptom | Cause and fix |
| --- | --- |
| `compdef: command not found` in zsh | The script was sourced before `compinit`. Move the vkdr block to the end of `~/.zshrc`, after oh-my-zsh is loaded. |
| Nothing completes after install | Open a new shell, or `source` your rc file. |
| Works in Terminal but not in a new bash shell on macOS | macOS runs bash as a *login* shell, which reads `~/.bash_profile` rather than `~/.bashrc`. Re-run with `--rc-file ~/.bash_profile`. |
| Completions are missing a new command | Run `vkdr init` to regenerate, then open a new shell. |
| TAB shows files instead of flags | Flags appear after you type `-`. This matches kubectl, helm and k3d. |

## Important notes

- Values for `--label`-style key=value options are not completed, only the flag name is.
- vkdr never uses `sudo` for completions. Everything stays under `$HOME`.
- The generated script is compatible with bash 3.2, the version macOS ships as `/bin/bash`.
