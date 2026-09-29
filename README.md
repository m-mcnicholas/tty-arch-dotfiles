# TTY Arch workspace

For an already installed x86_64 Arch Linux system with networking and a regular sudo-capable user. Disk setup and operating-system installation are outside this workspace installer.

Clone and run from the checkout as your regular user:

```sh
git clone https://github.com/m-mcnicholas/tty-arch-dotfiles.git ~/tty-arch-dotfiles
cd ~/tty-arch-dotfiles
./bootstrap.sh
```

The keyboard menu starts with the core workspace and terminal Joplin selected. It installs Bash configuration, Gruvbox, tmux, Neovim, Git, ranger, lazygit, search tools, NetworkManager, OpenSSH, and standard home folders, including `~/Projects`. The SSH server stays disabled. Media, mail, X11, Steam, and all editor language packs start unchecked. Space toggles a feature; Enter reviews the final summary; Back returns to the choices; Cancel exits before applying selected features. If `dialog` is missing, bootstrap first asks whether to install it with a full system upgrade so it can show the menu. A full `pacman -Syu` system upgrade is part of package installation. Setup never removes packages when a feature is unchecked.

After setup, run `tty-setup` from any interactive shell to add or repair features. `./bootstrap.sh` uses the current checkout, and ordinary reruns never pull Git changes. For a remote first run, `bash <(curl -fsSL https://raw.githubusercontent.com/m-mcnicholas/tty-arch-dotfiles/main/bootstrap.sh)` clones the checkout first. Set `DOTFILES_DIR` to change that destination. `~/.local/bin` is on the interactive Bash path.

Inspect or automate selection with:

```sh
tty-setup --plan
tty-setup --features joplin,lang-rust --yes
tty-setup --features music,video --yes --gpu none
./bootstrap.sh --with-x --gpu auto
./bootstrap.sh --steam --yes
```

`--no-x`, `--with-x`, `--steam`, `--gpu auto|mesa|nvidia|none`, and `--yes` are accepted by bootstrap and `tty-setup`. Steam adds X11 automatically and enables `[multilib]`. Auto graphics detection runs after `pciutils` is installed; `none` leaves drivers unchanged. NVIDIA auto selection assumes supported hardware and the stock Arch kernel, so choose manually on other systems. `--plan` does not check Arch prerequisites or change the machine.

Core is always included, including when `--features` names only optional features. The available IDs are:

| Feature | ID | What it adds |
| --- | --- | --- |
| Terminal notes | `joplin` | Joplin CLI; selected by default |
| YouTube Music | `music` | `ytm` and its download support |
| Console video | `video` | `tty-video`, mpv, and yt-dlp |
| Mail | `mail` | aerc, GPG, and pass |
| Desktop | `x11` | X11, i3, and Firefox |
| Games | `steam` | Steam and X11; enables `[multilib]` |
| Remote login | `ssh-server` | enables and starts `sshd` |
| Neovim languages | `lang-js`, `lang-web`, `lang-json`, `lang-python`, `lang-bash`, `lang-lua`, `lang-markdown`, `lang-rust` | only the selected parsers, servers, and formatters |

The Rust pack uses `rust-analyzer` and `rustfmt`; it keeps an existing Rust toolchain. Installed feature state and language selections live in `~/.local/state/tty-setup` and `~/.config/tty-setup`, outside the repository. Reruns compare recorded state with installed tools and can repair missing pieces. If a step fails, setup prints its name and stops; rerun the same selection after fixing it.

For package-free linking, use `./install.sh --plan` or `./install.sh --apply`. Without `--features`, it links every available configuration for standalone use. Add `--features core,mail` to link a subset. Existing targets move to timestamped `.backup-*` paths; correct symlinks are left alone.

To undo the configuration, run `./uninstall.sh --plan` to review the changes, then `./uninstall.sh --apply`. Use `--features core,mail` to remove only those features. The script removes symlinks that point to this checkout, restores the latest matching `.backup-*` file when present, and clears the selected setup state and language markers. It leaves links or files that you have replaced yourself untouched. Packages, services, personal data, theme choice, the checkout, and generated home folders remain; setup does not record their previous state, so remove those manually if desired.

Joplin follows its [official terminal installation method](https://joplinapp.org/help/apps/terminal/): npm installs into the user's `~/.joplin-bin`, with a link in `~/.local/bin`. Notes and sync credentials remain local. Run `joplin` and configure synchronization there. For music, run `ytm setup` after selecting `music`. For mail, initialize `gpg` and `pass`, then copy `examples/aerc-accounts.conf.example` to `~/.config/aerc/accounts.conf`, set mode 600, and edit the account addresses. The setup output repeats only instructions for selected accounts.

A local TTY login applies the selected palette and starts or attaches to tmux `main`. Theme commands run as your regular user; sudo's PATH is irrelevant. `tty-theme --list` works over SSH. `tty-theme nord` previews a palette on a local console, `tty-theme --set nord` saves it for future local TTY and X sessions, and `tty-theme --reset` restores console defaults. Saving over SSH takes effect at the next local login. `tty-theme --set gruvbox` restores the default. The prompt always shows user and current directory, with host added on SSH, Git branch, and a red prompt mark after errors.

The first run creates XDG Downloads, Documents, Pictures, Music, Videos, Desktop, Templates, and Public directories plus `~/Projects`. Existing `user-dirs.dirs` custom paths are respected, and files are never moved. `startx` launches i3 after selecting `x11`; `ssh-server` alone enables `sshd`. Console video needs a compatible DRM device and local seat; use `tty-video-check` before playback.

If `tty-theme` says permission denied, update the checkout and rerun `tty-setup --features core --yes` so its executable symlink is repaired. If the command is missing, run `~/.local/bin/tty-theme --list` or start a new interactive Bash shell. If `pacman` is missing, repair the Arch installation first; setup cannot install the package manager itself. If a package or Neovim plugin download fails, check network access and rerun the same command. The installer uses full package transactions, so it does not refresh package databases alone.

## Validation and Arch checks

Local checks passed: Bash syntax, `tests/smoke.sh`, `tests/mock-install.sh`, `tests/nvim-languages.sh`, and `git diff --check`. ShellCheck was unavailable in the development environment. Before release, run `shellcheck bootstrap.sh install.sh bin/tty-setup bin/tty-theme home.bashrc home.bash_profile` on a machine that has it installed.

An Arch VM check is still required: execute a default setup and confirm Joplin launches, OpenSSH is installed, `sshd` is disabled, the Gruvbox palette appears before tmux, and Neovim starts without a language pack. Add a language pack later and check its server, parser, and formatter; repeat for Rust. Test optional media, mail, X11, Steam, and SSH service separately. Graphics and direct DRM playback need checks on the target hardware.

Each item in `feedback.md` maps to these checks: default theme and theme command permissions to the palette and executable checks; missing Joplin and OpenSSH to the default setup check; menu and later additions to the plan and rerun tests; standard folders to the XDG directory test; prompt contents to the shell test; and pacman availability to the prerequisite check.
