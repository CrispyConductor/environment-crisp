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

Node, via fnm, is automated but not installed by default:

```sh
./install.sh fnm
```

That installs fnm itself and the current Node.js LTS, and re-running it later
keeps the LTS current. Everything below this is *not* automated, because it is
either machine-specific or changes too often to pin.

### openssh server

```sh
sudo apt install openssh-server
```

### Language servers

```sh
npm install -g pyright                                  # Python
npm install -g typescript typescript-language-server    # JS/TS
npm install -g @vue/language-server @vue/typescript-plugin
```

`@vue/language-server` and `@vue/typescript-plugin` must be the same version.
`init.lua` looks for the plugin under `~/.local/lib/node_modules`, so keep npm's
global prefix at `~/.local`:

```sh
npm set prefix $HOME/.local
```

```sh
rustup component add rust-analyzer                      # Rust
```

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

### AI CLIs

The neovim side of these is disabled by default - see the AI plugin table in
the README.

```sh
sudo apt install pipx
pipx install aider-install && aider-install
pipx install llm && llm keys set openai
```

Put API keys in `~/.config/fish/conf.d/90-local.fish`:

```fish
set -gx ANTHROPIC_API_KEY 'sk-ant-...'
```

### fisher (fish package manager)

```sh
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish \
    | source && fisher install jorgebucaran/fisher
```
