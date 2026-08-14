# Module format

A module is an independently installable unit of configuration: its dotfiles,
its packages, and its setup steps. `install.sh` installs one or more of them.

`install.sh` needs **bash 4 or newer** (it uses associative arrays for
dependency resolution). That is every Linux distro; on macOS it means
`brew install bash`, since the system bash is still 3.2.

```
modules/<name>/
├── meta                # description, dependencies, platform, package manager
├── link/               # $HOME-mirrored tree, symlinked into place
├── copy/               # $HOME-mirrored tree, copied into place
├── template/           # $HOME-mirrored tree, copied only if absent
├── merge/              # $HOME-mirrored tree, line-merged into the destination
├── packages            # package names, one per line
├── packages.subst      # per-release package renames
├── repos/*.repo        # apt repository definitions
└── install.sh          # optional setup hook, run after files are placed
```

Every part is optional. A module with only a `packages` file is perfectly
valid, and so is one with only a `link/` tree.

## The four file trees

All four mirror `$HOME`, so a file at

```
modules/base/link/.config/nvim/init.lua
```

is installed to `~/.config/nvim/init.lua`. Adding a dotfile means putting the
file in the right place - there is no list to update.

### `link/`

Symlinked, **one link per file** rather than one link per directory. That
matters: when `~/.config/nvim` was a single directory symlink, everything
neovim wrote into it - `lazy-lock.json` in particular - landed inside the repo
and needed a `.gitignore` entry to hide it. Linking `init.lua` on its own lets
the application write to a real local directory.

The same applies to `~/.config/fish/functions/`, where fish itself may write.

Note the installer never `chmod`s a symlinked destination, since that would
change the mode of the file inside the repo.

### `copy/`

A real copy, replacing whatever is there subject to `--existing`. Use it for:

- **Files the owning application rewrites.** `keepassxc.ini` is the reason this
  tree exists — keepassxc saves settings on exit, and a symlink meant a
  permanently dirty work tree.
- **Files that need permissions git cannot store.** git records only the
  executable bit, so a symlinked file carries whatever the clone's umask
  produced. `copy/` runs `apply_perms`, which is how everything under `.ssh/`
  ends up 600 regardless of umask.

The tradeoff is that editing a `copy/` file in the repo needs a re-install to
take effect, where a `link/` file is live immediately.

### `template/`

Copied **only if the destination does not exist**, and never touched again.
This is how per-machine files get seeded:

| Template | Purpose |
|---|---|
| `.config/fish/conf.d/90-local.fish` | fish overrides and secrets |
| `.shellrc-local` | bash + zsh overrides |
| `.bashrc-local` | bash-only overrides |
| `.ssh/config.local` | extra ssh hosts |

### `merge/`

The source's lines are added to the destination if they are not already there,
leaving anything else in the file alone. Blank lines and `#` comments are
skipped. Re-running adds nothing, so it is idempotent.

`~/.ssh/authorized_keys` is the case this was built for. It is special-cased:
comparison is on the key material (type + base64) rather than the whole line,
so a key whose trailing comment differs is still recognised as already present.
Every other file compares whole lines.

## `meta`

Sourced as shell, so it is plain `key=value`:

```sh
description="fish shell: conf.d snippets, prompt, functions, completions"
requires="base"          # space-separated module names, resolved recursively
platform="any"           # any | linux | macos
pkgmgr=""                # apt | brew, only needed if the module has packages
```

Dependencies are installed first. A cycle is an error. Installing a module
whose `platform` does not match the running system is an error rather than a
silent skip.

`requires` is deliberately **not** followed by `--uninstall`: removing `fish`
must not drag `base` out with it, since other modules still need it.

## Packages

`packages` is one name per line; `#` comments and blank lines are ignored.

Packages are gathered across every module in the run and installed in a single
transaction, after all `repos/` definitions have been applied. That ordering is
what lets a shared module list `signal-desktop` while the per-release module
supplies the repository it comes from.

Before installing, each name is checked against `apt-cache policy`. `apt-get
install` fails the entire transaction on one unknown name, which tells you
nothing useful when a distro release has renamed something — so the installer
splits the list first and names the packages with no installation candidate.
By default that stops the run; `--skip-unavailable` installs the rest instead,
which together with `--packages-only` is how a new release gets surveyed before
its module is written.

### `packages.subst`

Rewrites a name inherited from another module:

```
# <name in the shared list> = <name to use here>
regolith-session-flashback = regolith-session-sway
```

This is how per-release package renames are handled without duplicating the
shared list. The shared list always carries the current name; only the affected
release module needs an entry.

### `repos/*.repo`

Plain `key=value`. Two shapes are supported - a hand-written one-line entry:

```
key_url=https://updates.signal.org/desktop/apt/keys.asc
keyring=/usr/share/keyrings/signal-desktop-keyring.gpg
list_path=/etc/apt/sources.list.d/signal-xenial.list
entry=deb [arch=amd64 signed-by={keyring}] https://updates.signal.org/desktop/apt xenial main
```

or a deb822 `.sources` file downloaded from upstream:

```
key_url=https://updates.signal.org/desktop/apt/keys.asc
keyring=/usr/share/keyrings/signal-desktop-keyring.gpg
sources_url=https://updates.signal.org/static/desktop/apt/signal-desktop.sources
sources_path=/etc/apt/sources.list.d/signal-desktop.sources
```

`{keyring}` in `entry` is replaced with the `keyring` value. Keyrings are
written with a plain redirect rather than `tee -a`; appending is what made the
old scripts grow the Signal keyring without bound on every re-run.

## `install.sh`

Optional. Runs after the module's files are in place, and after packages are
installed, so it can rely on both.

It is **sourced**, not executed, which gives it the helpers from `lib/`:

| Available | Meaning |
|---|---|
| `$TARGET_HOME` | where we are installing (not necessarily `$HOME`) |
| `$REPO_DIR` | this repo's absolute path |
| `$DRY_RUN` | `1` when nothing should actually change |
| `$SUDO` | `sudo`, or empty when already root |
| `run <cmd...>` | execute, or report under `--dry-run` |
| `info` / `step` / `good` / `warn` / `verbose` | output |
| `have_cmd <name>` | is a command available |
| `ensure_line <file> <line>` | append a line unless already present |
| `state_record <module> <kind> <rel> <src>` | register a file for cleanup/uninstall |
| `install_deb_url <name> <url> <pkg>` | install a `.deb`, skipping if present |
| `apt_pkg_installed <pkg>` | query dpkg |

Hooks must be safe to re-run, and must use `$TARGET_HOME` rather than `$HOME`
so that installing into a test home stays contained. Anything that only makes
sense on a real install - `chsh`, enabling a systemd user unit - should check
`[ "$TARGET_HOME" = "$HOME" ]` first.

Three things to be careful about, since hooks are sourced into the installer's
own shell:

- **Do not call `exit`.** It would terminate the whole install. `return` ends
  just the hook.
- **Prefix temporaries with `_`.** The installer is mid-loop over `m`, and also
  uses `src`, `dest`, `rel`, `f` and `name`. A bare assignment to any of those
  corrupts the run.
- **Never touch a shared daemon without isolating it.** The base hook installs
  tmux plugins, which needs a running tmux server; it starts a private one with
  `tmux -L userenv-install` and kills that, so a live session on the default
  socket is untouched. A bare `tmux kill-server` would take down whatever the
  user is sitting in.

## Install state

Every destination is recorded in
`~/.local/state/userenv/installed.tsv` as `module<TAB>kind<TAB>path<TAB>source`.

This gives `--uninstall`, but the more important effect is that when a module
stops providing a file - it moved to another module, got renamed, or was
dropped - the stale destination is removed on the next install.

That is what makes future reorganizations of this repo self-healing, and it is
why `unlink-dotfiles.sh` should only ever be needed once: the installer that
came before this one kept no record of what it had done.

Only symlinks pointing into this repo are ever removed automatically. A real
file is reported and left alone, because it might hold content that matters.

Two rules keep this from deleting live files:

- Pruning runs **after** all hooks, and asks whether *any* module in the run
  still provides a path — not just the one that used to. Otherwise moving a
  file between modules would have the old owner delete what the new owner just
  installed, and hook-registered files (everything under `~/.local/bin`) would
  be deleted and re-created on every run.
- `--no-hooks` skips pruning entirely and records state additively. With hooks
  skipped the run never learns about the files they own, so pruning against
  that picture would delete them. Skipping setup steps must not uninstall
  anything.

## Adding a module

1. `mkdir -p modules/<name>`
2. Write `meta` with at least a `description`.
3. Drop files into `link/`, `copy/`, `template/` or `merge/`, mirroring `$HOME`.
4. Add `packages` / `repos/` if it installs software.
5. Add `install.sh` if it needs setup steps beyond placing files.
6. `./install.sh --dry-run --home /tmp/testhome <name>` to check placement.

## Current modules

### Dotfiles

| Module | Contents |
|---|---|
| `base` | neovim, tmux, git, ssh, bash, clipboard sync, `bin/` on `$PATH` |
| `fish` | fish `conf.d` snippets, prompt, functions, completions, fisher |
| `zsh` | zshrc, crispy theme, oh-my-zsh |
| `regolith34` | Regolith 3.4 Xresources |
| `claude-code` | Claude Code CLI (native installer) and linked `~/.claude/settings.json` |

### Packages

`ubuntu-common-base`, `ubuntu-common-gui` and `ubuntu-common-regolith` hold the
version-independent package lists and are pulled in as dependencies. They are
not meant to be installed directly - on their own they would reference
repositories that only the per-release modules define.

The per-release modules carry nothing but their repository definitions (and, for
25.10, one `packages.subst` entry):

| Module | Adds |
|---|---|
| `ubuntu<ver>-base` | console packages |
| `ubuntu<ver>-gui` | desktop packages, Signal repo, Discord, GUI clipboard service |
| `ubuntu<ver>-regolith` | Regolith packages and repo |

`<ver>` is one of `2404`, `2410`, `2504`, `2510`.

| Module | Contents |
|---|---|
| `macos` | Homebrew formulae |
| `firefox-apt` | replaces the Firefox snap with the PPA build |
| `fnm` | installs fnm, the current Node.js LTS and points npm's global prefix at `~/.local` (Linux; macOS uses the homebrew formula instead) |
| `devtools` | language servers via npm: pyright, tsserver, vue - needs npm from `fnm` or `macos` already on `$PATH` |
| `ai-tools` | installs aider and llm via pipx; depends on `claude-code` |
| `rust` | installs rust via rustup, plus the rust-analyzer component |

## Profiles

`profiles/<name>` is a list of module names, same comment rules as `packages`.

```
./install.sh -p workstation
```

A profile and explicit modules can be combined, which is usually easier than
editing a profile for a one-off:

```
./install.sh -p default ubuntu2504-regolith regolith34
```
