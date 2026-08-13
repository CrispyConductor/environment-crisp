# environment-crisp

Personal dotfiles and system setup, organised as installable modules.

## Install

```sh
git clone https://github.com/CrispyConductor/environment-crisp.git
cd environment-crisp
./install.sh                        # default profile: base + fish
```

Or pick what you want:

```sh
./install.sh --list                 # available modules and profiles
./install.sh base fish zsh
./install.sh -p workstation         # full desktop
./install.sh -p default ubuntu2510-regolith regolith34
```

The installer symlinks `~/.userenv` to the checkout, so the repo can live
anywhere as long as you do not move it afterwards.

Needs bash 4+ (every Linux distro; on macOS, `brew install bash` first).

### Options

| Option | Effect |
|---|---|
| `-p, --profile NAME` | install the module set in `profiles/NAME` |
| `-e, --existing POLICY` | `ask` (default), `overwrite`, or `keep` |
| `-n, --dry-run` | report what would change, change nothing |
| `--home DIR` | install into `DIR` instead of `$HOME` (for testing) |
| `--no-packages` | skip package installation |
| `--no-hooks` | skip module setup hooks |
| `--packages-only` | install only packages and apt repos — no dotfiles, hooks, anchor or state |
| `--skip-unavailable` | install the packages that exist, report the rest instead of stopping |
| `--uninstall` | remove the named modules' files |
| `-l, --list` | list modules and profiles |
| `--list-packages` | print the resolved package list and exit |

Anything the installer replaces is backed up to
`~/.dotfiles-backup/<timestamp>/` as a real copy.

Re-running is safe and does nothing when everything is already current.

## Upgrading from the pre-module layout

If a machine still has the old layout installed, **run this before pulling**:

```sh
curl -fsSLO https://raw.githubusercontent.com/CrispyConductor/environment-crisp/master/unlink-dotfiles.sh
bash unlink-dotfiles.sh --dry-run     # see what it will do
bash unlink-dotfiles.sh
```

It replaces every symlink pointing into the checkout with a real copy of the
file, so nothing breaks between the pull and the re-install, and the new
installer sees ordinary files it can back up rather than dangling links. It
leaves `~/.userenv` alone, since the configs still reach through it at runtime.

Then:

```sh
cd environment-crisp && git pull
./install.sh -p default
```

You should only need this once. From here on the installer records what it
installs, so files that move between modules are cleaned up automatically.

Two leftovers are harmless and can be deleted at your leisure:

- `~/.config/fish/fish_variables` — no longer managed here. The colours it held
  are now `set -g` in `conf.d/30-colors.fish`, and globals take precedence over
  universals, so the stale file has no effect.
- `~/.dotfiles_backup/` — the old backup directory. Its contents are symlinks
  into the repo rather than copies, so nothing in it is recoverable anyway.
  `unlink-dotfiles.sh --clean-old-backups` removes it.

## Layout

```
install.sh              install modules
unlink-dotfiles.sh      one-time migration off the old layout
lib/                    installer internals
modules/                the modules themselves
profiles/               named module sets
bin/                    commands, symlinked into ~/.local/bin
libexec/                helpers invoked by configs, not meant for $PATH
  clipboard/            tmux <-> nvim <-> GUI <-> ssh clipboard sync
  tmux/                 tmux keybinding helpers
doc/                    documentation and the tmux cheat sheet
```

See [doc/modules.md](doc/modules.md) for the module format, and
[doc/ubuntu-setup.md](doc/ubuntu-setup.md) /
[doc/macos-setup.md](doc/macos-setup.md) for setting up a new machine.

## Adding a new Ubuntu release

The per-release modules exist because the apt repositories move and packages
occasionally get renamed. To work out what a new release needs, probe it before
writing the module:

```sh
# What would we try to install?
./install.sh --list-packages ubuntu2510-regolith

# Try it on the new release. Packages that no longer resolve are reported
# rather than failing the whole apt transaction.
./install.sh --packages-only --skip-unavailable ubuntu2510-regolith
```

`--packages-only` touches nothing else — no dotfiles, no hooks, no `~/.userenv`
anchor, no install state — so it is safe to run repeatedly on a machine you are
still figuring out.

Whatever it reports as unavailable is what the release renamed or dropped. Then
copy the nearest existing release's modules:

```sh
cp -r modules/ubuntu2510-base     modules/ubuntu2604-base
cp -r modules/ubuntu2510-gui      modules/ubuntu2604-gui
cp -r modules/ubuntu2510-regolith modules/ubuntu2604-regolith
```

and edit the `meta` `requires=` lines, the repo suite/URL in
`repos/regolith.repo`, and add a `packages.subst` entry for each rename:

```
# <name in the shared list> = <name to use on this release>
regolith-session-flashback = regolith-session-sway
```

Only put genuinely new packages in the release module's own `packages` file;
anything shared belongs in `ubuntu-common-*` so every release gets it.

## Per-machine settings

Local values and overrides go in files the installer creates once and never
touches again:

| Shell | File |
|---|---|
| fish | `~/.config/fish/conf.d/90-local.fish` |
| bash + zsh | `~/.shellrc-local` |
| bash only | `~/.bashrc-local` |
| ssh | `~/.ssh/config.local` |

API keys belong in these. For fish:

```fish
set -gx ANTHROPIC_API_KEY 'sk-ant-...'
```

`conf.d/90-local.fish` sorts last and `config.fish` is deliberately empty, so
anything set there wins over the repo defaults.

## Two GitHub identities

`~/.ssh/config` defines two hosts, both pinned with `IdentitiesOnly yes` so the
right key is used even with both loaded in the agent:

| Host | Key |
|---|---|
| `github.com` | `id_ed25519_main` |
| `github-infotrust` | `id_ed25519_infotrust_github` |

To clone with the alternate key, use the alias in the URL:

```sh
git clone git@github-infotrust:org/repo.git
```

`git_clone_infotrust` does that rewriting for you, and accepts any URL form:

```sh
git_clone_infotrust org/repo
git_clone_infotrust https://github.com/org/repo.git
```

`git_setup_infotrust <url>` repoints an existing clone's origin the same way.

Because selection lives in the remote URL rather than a per-clone
`core.sshCommand`, it survives `git remote set-url` and is visible in
`git remote -v`.

`IdentityFile` points at a `.pub` deliberately: that is how ssh selects a
specific agent-held key when the private key is not on disk, which is what lets
this repo ship key selection without shipping any secrets.

## Neovim AI plugins

`init.lua` has a feature table near the top:

```lua
local aiPlugins = {
	copilot = true,
	codeium = false,
	aider   = false,
	avante  = false,
	chatgpt = false,
}
```

Only Copilot is installed. The others keep their full configuration and
keybindings in the file; flipping a flag to `true` and re-running
`nvim --headless "+Lazy! sync" +qa` is all it takes to turn one back on.
Enabling `avante` also needs a working `make`, and `aider` expects the aider
CLI on `$PATH`.
