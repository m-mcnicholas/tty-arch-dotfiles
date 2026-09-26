# TTY-first Arch workspace

For a fresh x86_64 Arch installation with Bash on local virtual consoles. A login starts (or attaches to) the `main` tmux session. Neovim, ranger, lazygit, music, and mail run there. X starts only when you run `startx` from the login shell.

## 1. Prepare the system

Complete the normal [Arch installation](https://wiki.archlinux.org/title/Installation_guide), create a regular user with sudo access, boot into a local TTY, and make sure the network works. Install the official repository packages listed in the manifests:

```bash
git clone https://github.com/m-mcnicholas/tty-arch-dotfiles.git ~/tty-arch-dotfiles
cd ~/tty-arch-dotfiles
mapfile -t tty_packages < <(grep -Ev '^(#|$)' packages/tty.txt)
sudo pacman -Syu --needed "${tty_packages[@]}"
mapfile -t x_packages < <(grep -Ev '^(#|$)' packages/x11.txt)
sudo pacman -S --needed "${x_packages[@]}"
sudo systemctl enable --now NetworkManager
```

The Neovim manifest includes language servers for JavaScript/TypeScript, HTML, CSS, JSON, Python, Bash, Lua, and Markdown, plus their formatters. Identify the graphics device with `lspci -k` before testing direct DRM or X. For Intel or AMD graphics, install Mesa with `sudo pacman -S --needed mesa`; for a supported NVIDIA card and the stock Arch kernel, use `sudo pacman -S --needed nvidia-open nvidia-utils`. Other NVIDIA cards or kernels need their matching driver package. Keep the actual GPU choice and any console keymap local to the machine.

## 2. Link the dotfiles

```bash
./install.sh --plan
./install.sh --apply
./install.sh --plan
```

`--plan` makes no changes. `--apply` creates absolute symlinks and moves existing targets to timestamped `.backup-*` paths first. Repeating `--apply` leaves correct links alone. It never installs packages or changes system files. Review your existing `.bash_profile`, `.bashrc`, `.gitconfig`, and `.xinitrc` backups if you had custom settings. Put your personal Git name and email in `~/.config/git/local.conf`, which the linked Git config includes. First run `mkdir -p ~/.config/git`, then create that file with:

```ini
[user]
    name = Your Name
    email = you@example.com
```

## 3. Install the pipx applications

```bash
pipx install ytm-player
pipx inject ytm-player 'yt-dlp[default]'
pipx install 'yt-dlp[default]'
```

`ytm-player` uses its own pipx environment, so the injection supplies its yt-dlp EJS solver there. The separate `yt-dlp` command is used by `mpv` and `tty-video`. Arch's `deno` package is the JavaScript runtime. The [yt-dlp EJS guide](https://github.com/yt-dlp/yt-dlp/wiki/EJS) calls for a supported runtime and matching solver scripts; the PyPI `default` group supplies the latter. Upgrade both pipx environments together when YouTube extraction changes:

```bash
pipx upgrade ytm-player
pipx inject --force ytm-player 'yt-dlp[default]'
pipx upgrade yt-dlp
```

## 4. Start the workspace

Log out and log back in on a local TTY. Bash starts tmux `main` only for an interactive login on `/dev/ttyN`, outside tmux and outside X. SSH logins and terminal windows under X stay in their shell. The tmux session persists after detach.

| Keys | Action |
| --- | --- |
| `Ctrl-a d` | Detach to the login shell |
| `Ctrl-a c` | New window |
| `Ctrl-a 1`…`9` | Select window |
| `Ctrl-a \|` / `Ctrl-a -` | Split right / below |
| `Ctrl-a h/j/k/l` | Focus pane |
| `Ctrl-a H/J/K/L` | Resize pane |
| `Ctrl-a [` | Scroll and copy mode; `q` exits |

Run `nvim`, `ranger`, `lazygit`, `btop`, `w3m`, `ytm`, and `aerc` in separate tmux windows or panes. `ranger` uses text previews and opens text in Neovim. Its `E` key edits a file and `G` opens lazygit. In Neovim, `Space ff` finds files, `Space fg` searches text, `gd` goes to a definition, `K` shows hover information, and `Space F` formats. The configuration uses plain text signs and console colors; a Nerd Font is optional.

On first Neovim launch, lazy.nvim downloads the plugins pinned in `config/nvim/lazy-lock.json`, and Treesitter downloads the listed parsers. Run `:checkhealth vim.lsp` and open a file inside a project to confirm the matching server attaches. `:LspInfo` and `:ConformInfo` help diagnose missing tools. [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) now uses `vim.lsp.config` and `vim.lsp.enable` with Neovim 0.11.3 or newer.

## Theme

One 16-colour palette styles the whole workspace. At a TTY login, `tty-theme` loads it into the console before tmux starts. `startx` loads the same palette into X resources for xterm, i3, and dmenu. tmux, Neovim (`tty16` colorscheme), lazygit, fzf, btop, aerc, ranger, less, and the prompt all refer to palette slots rather than fixed colours, so they change together. Slot 0 is the background, 7 the text, and 8 the dim colour for comments and borders.

| Command | Action |
| --- | --- |
| `tty-theme --list` | Show the palettes in `config/theme` |
| `tty-theme nord` | Preview a palette on this console, including from inside tmux |
| `tty-theme --reset` | Restore the kernel's default console colours |

To keep a palette, change the `TTY_THEME` default in `home.bashrc` and log in again; restart Neovim and X to pick it up there. To add one, copy `config/theme/gruvbox.sh` and set `color0` through `color15` as six hex digits. Backgrounds use only slots 0–7, because tmux on the Linux console turns bright backgrounds into normal ones.

The manifest includes Terminus for a sharper console font. Try sizes with `setfont ter-120n` or `setfont ter-132n` (larger screens); to keep one, set `FONT=` in `/etc/vconsole.conf` as described in the [Arch Linux console guide](https://wiki.archlinux.org/title/Linux_console#Fonts). Borders everywhere use single box-drawing lines because console fonts lack rounded corners.

## 5. Music, video, and mail

Run `ytm setup` on this machine to connect your YouTube Music account, then run `ytm`. The tracked TOML contains only display preferences; `auth.json`, `account.json`, and cookies stay local. The [ytm-player setup guide](https://ytm-player.com/docs/install/) documents browser and manual setup. For authenticated streaming, set `use_session_cookies = true` in `~/.config/ytm-player/config.toml` after `ytm setup` if needed. That preference is safe to track; credentials remain in separate local files.

Direct video uses the active virtual console's DRM device. Check the seat and graphics support, then try a URL or search:

```bash
tty-video-check
tty-video 'https://www.youtube.com/watch?v=...'
tty-video 'search words'
```

The check verifies a local TTY or its tmux session, accessible `/dev/dri/card*`, and an mpv build with the DRM GPU context. Actual playback is the final compatibility test; the machine's driver and console seat still determine whether DRM works. The command uses `mpv --vo=gpu --gpu-context=drm` as documented by the [mpv manual](https://mpv.io/manual/stable/). If direct DRM cannot work on this hardware, use Firefox after `startx` for video.

For personal Gmail, turn on [2-Step Verification and create an app password](https://support.google.com/mail/answer/185833). Set up `pass` and store the app password locally:

```bash
gpg --full-generate-key
pass init <your-GPG-key-id>
pass insert mail/gmail-app
```

Then:

```bash
cp examples/aerc-accounts.conf.example ~/.config/aerc/accounts.conf
chmod 600 ~/.config/aerc/accounts.conf
nvim ~/.config/aerc/accounts.conf  # replace both encoded addresses and From
aerc
```

The account file is ignored by Git. The example uses IMAPS and SMTPS with `pass` credential commands, following the [aerc account](https://man.archlinux.org/man/aerc-accounts.5.en), [IMAP](https://man.archlinux.org/man/aerc-imap.5.en), and [SMTP](https://man.archlinux.org/man/aerc-smtp.5.en) manuals. Aerc composes in Neovim. Gmail may require IMAP to be enabled in its settings. App passwords may be unavailable on some Google accounts.

## 6. Start X when needed

To install Steam, enable `[multilib]` in `/etc/pacman.conf`, refresh package databases, and install the separate official manifest:

```bash
mapfile -t multilib_packages < <(grep -Ev '^(#|$)' packages/multilib.txt)
sudo pacman -Syu --needed "${multilib_packages[@]}"
```

Install the matching 32-bit graphics userspace for Steam: `sudo pacman -S --needed lib32-mesa` on Intel/AMD, or `sudo pacman -S --needed lib32-nvidia-utils` when using the NVIDIA driver. If Steam asks for a 32-bit Vulkan provider, select the one for your GPU; the [Arch Steam guide](https://wiki.archlinux.org/title/Steam) explains this requirement.

On the TTY, press **`Ctrl-a d`** to leave tmux and return to the login shell, then run `startx`. The minimal i3 session offers `Super+Return` for xterm, `Super+Shift+f` for Firefox, and `Super+Shift+s` for Steam. Exit i3 with `Super+Shift+e` to return to the TTY. The [Arch xinit guide](https://wiki.archlinux.org/title/Xinit) covers `startx` and `.xinitrc`.

## Verify on the Arch machine

1. Reboot or log in on a local TTY: confirm the console uses the Gruvbox palette and the tmux status line shows a blue `main` label; run `tty-theme nord` and `tty-theme` to switch and restore; detach and confirm the coloured prompt appears.
2. In tmux, run Neovim on one file per listed language, confirm lazy plugins/parsers install, and check `:LspInfo` for each server. Test `Space fg`, completion, and `Space F`.
3. Run `ranger`, `lazygit`, `btop`, `w3m https://example.org`, `ytm`, and `aerc`; read and compose a test email.
4. Run `tty-video-check` and play a short YouTube video with `tty-video` while X is stopped.
5. Detach, run `startx`, open Firefox and Steam from i3, exit i3, and confirm the TTY shell returns.

The repository was prepared on macOS, so local checks cover installer behavior and Neovim startup. TTY, DRM, Arch package, Gmail, and Steam checks must be completed on the target machine.
