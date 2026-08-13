# macOS setup

## System

1. Set passwords:

   ```sh
   passwd
   security set-keychain-password
   ```

2. System Settings → Sharing: enable Remote Login for all users, with disk
   access.
3. System Settings → Sharing: set the computer name.
4. Reboot.

## Applications

Installed from their own `.dmg` files rather than Homebrew:

- **Chrome**
- **Synergy** — from symless.com. Grant accessibility permissions when
  prompted, then enter the license key and configure.
- **NextCloud** — from nextcloud.com. Log in and sync the keepass database.
- **KeePassXC** — from keepassxc.org. Leave it closed until the dotfiles are
  installed, since the installer copies `keepassxc.ini` into place.

## Homebrew and dotfiles

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install bash
git clone https://github.com/CrispyConductor/environment-crisp.git
cd environment-crisp
./install.sh -p macos
```

`brew install bash` comes first because `install.sh` needs bash 4 or newer and
macOS still ships 3.2. The script checks and tells you if it is too old.

The `macos` module installs the Homebrew formulae; `base` and `fish` install the
dotfiles, tmux plugins, fzf and neovim plugins.

If macOS refuses to let `chsh` set fish as the login shell, make sure the shell
does not end up as bash:

```sh
chsh -s /bin/zsh
```

## After the dotfiles

1. Restart keepassxc, enable browser integration in its settings, install the
   Chrome keepassxc plugin, then click the extensions icon and connect.
2. Install language servers:

   ```sh
   npm install -g pyright typescript typescript-language-server
   ```

   The `macos` module already points npm's global prefix at `~/.local`, which is
   where `init.lua` looks for the Vue TypeScript plugin.

3. Reboot.
