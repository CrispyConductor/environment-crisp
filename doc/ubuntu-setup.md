# Ubuntu setup

Supported releases: 24.04, 24.10, 25.04, 25.10.

## New machine

1. Install the base system, update it, and confirm drivers are working.
2. Install git and clone this repo.
3. Run the installer for the release you are on:

   ```sh
   ./install.sh -p default ubuntu2510-regolith regolith34
   ```

   That pulls in the console, desktop and Regolith package sets along with the
   dotfiles. For a headless machine use `./install.sh -p server` instead.

   Packages, apt repositories, tmux plugins, fzf and neovim plugins are all
   handled by the installer. Nothing below needs doing by hand unless noted.

4. Replace the Firefox snap with the apt build - the snap cannot talk to the
   keepassxc browser plugin:

   ```sh
   ./install.sh firefox-apt
   ```

5. Open Nextcloud, log in with the credentials from the password manager, and
   enable syncing for at least the keepass database.
6. Open keepassxc and open the database from Nextcloud.
7. Install the keepassxc browser plugin, enable browser integration in
   keepassxc's settings, then connect the extension.
8. Switch this repo's remote to ssh:

   ```sh
   git remote set-url origin git@github.com:CrispyConductor/environment-crisp.git
   ```

9. Reboot and log into the Regolith session.

## Optional extras

These are automated but not installed by default - add them individually, or
via the `dev` profile:

```sh
./install.sh fnm devtools ai-tools rust    # node, LSPs, aider + llm, rust
./install.sh -p dev ubuntu2604-base
```

`fnm` also installs the current Node.js LTS, `rust` also installs
rust-analyzer, and re-running any of these later keeps them current.
`devtools` installs the language servers `init.lua` wires up (pyright,
typescript-language-server, the vue language server) via whatever npm it
finds - list it after `fnm` so npm exists by the time it runs. `ai-tools`
installs aider and llm and depends on `claude-code`, so naming it pulls that
in too - the neovim side of these AI plugins is disabled by default, though,
see the AI plugin table in the README. Put API keys in
`~/.config/fish/conf.d/90-local.fish`:

```fish
set -gx ANTHROPIC_API_KEY 'sk-ant-...'
```

See [doc/modules.md](modules.md) for what each module does. Everything below
this is *not* automated - building neovim or tmux from source needs a git ref
or version pinned by hand and takes minutes to rebuild, which does not suit a
module meant to be safe and quick to re-run.

### Newer neovim than the distro ships

```sh
sudo apt install ninja-build gettext libtool libtool-bin autoconf automake \
    cmake g++ pkg-config unzip curl doxygen build-essential libnsl-dev
make CMAKE_BUILD_TYPE=Release CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=$HOME/.local"
make install
```

### Newer tmux than the distro ships

```sh
sudo apt install libevent-dev libncurses-dev bison
sh autogen.sh                       # only when building from git
./configure --prefix="$HOME/.local"
make && make install
```
