#!/usr/bin/env bash
# One-command setup for a fresh Arch install:
#   bash <(curl -fsSL https://raw.githubusercontent.com/m-mcnicholas/tty-arch-dotfiles/main/bootstrap.sh)
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: bootstrap.sh [--no-x] [--steam] [--gpu auto|mesa|nvidia|none] [--yes]

  --no-x     skip the X11/i3/Firefox packages
  --steam    enable [multilib] in /etc/pacman.conf and install Steam
  --gpu      graphics userspace to install (default: auto, detected with lspci)
  --yes      never prompt; skip Git identity setup if it is missing
EOF
  exit 2
}

with_x=1 steam=0 gpu=auto assume_yes=0
while (($#)); do
  case "$1" in
    --no-x) with_x=0 ;;
    --steam) steam=1 ;;
    --gpu) [[ $# -ge 2 ]] || usage; gpu="$2"; shift ;;
    --yes) assume_yes=1 ;;
    -h|--help) usage ;;
    *) usage ;;
  esac
  shift
done
case "$gpu" in auto|mesa|nvidia|none) ;; *) usage ;; esac

say() { printf '\n==> %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }
manifest() { grep -Ev '^(#|$)' "$repo/packages/$1"; }
# Prompts read from the terminal so `curl ... | bash` still works.
ask() { local reply; read -r -p "$1" reply </dev/tty; printf '%s' "$reply"; }

[[ -f /etc/arch-release ]] || die 'this script is for Arch Linux'
((EUID != 0)) || die 'run as your regular user, not root; sudo is used where needed'
command -v sudo >/dev/null || die 'sudo is required'

repo_url='https://github.com/m-mcnicholas/tty-arch-dotfiles.git'
repo="${DOTFILES_DIR:-$HOME/tty-arch-dotfiles}"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-}")" 2>/dev/null && pwd -P || true)"
if [[ -n "$script_dir" && -f "$script_dir/install.sh" && -d "$script_dir/packages" ]]; then
  repo="$script_dir"
fi

say 'Installing base packages'
sudo pacman -Syu --needed --noconfirm git
if [[ ! -d "$repo/.git" ]]; then
  git clone "$repo_url" "$repo"
else
  git -C "$repo" pull --ff-only || printf 'warning: could not update %s; using it as is\n' "$repo" >&2
fi

packages=()
mapfile -t -O "${#packages[@]}" packages < <(manifest tty.txt)
((with_x)) && mapfile -t -O "${#packages[@]}" packages < <(manifest x11.txt)

if [[ "$gpu" == auto ]]; then
  gpu=mesa
  if command -v lspci >/dev/null && lspci | grep -Ei 'vga|3d|display' | grep -qi nvidia; then
    gpu=nvidia
  fi
fi
case "$gpu" in
  mesa) packages+=(mesa) ;;
  nvidia) packages+=(nvidia-open nvidia-utils) ;;
esac
sudo pacman -S --needed --noconfirm "${packages[@]}"

if ((steam)); then
  say 'Enabling [multilib] and installing Steam'
  if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
    sudo sed -i '/^#\[multilib\]$/{s/^#//;n;s/^#//}' /etc/pacman.conf
    grep -q '^\[multilib\]' /etc/pacman.conf || die 'could not enable [multilib] in /etc/pacman.conf'
  fi
  steam_packages=()
  mapfile -t steam_packages < <(manifest multilib.txt)
  case "$gpu" in
    mesa) steam_packages+=(lib32-mesa vulkan-radeon vulkan-intel lib32-vulkan-radeon lib32-vulkan-intel) ;;
    nvidia) steam_packages+=(lib32-nvidia-utils) ;;
  esac
  sudo pacman -Syu --needed --noconfirm "${steam_packages[@]}"
fi

say 'Enabling NetworkManager'
sudo systemctl enable --now NetworkManager

say 'Linking dotfiles'
"$repo/install.sh" --apply

git_local="$HOME/.config/git/local.conf"
if [[ ! -f "$git_local" ]] && ((!assume_yes)) && { : </dev/tty; } 2>/dev/null; then
  say 'Git identity'
  name="$(ask 'Git name (blank to skip): ')"
  if [[ -n "$name" ]]; then
    email="$(ask 'Git email: ')"
    mkdir -p -- "$(dirname -- "$git_local")"
    printf '[user]\n    name = %s\n    email = %s\n' "$name" "$email" >"$git_local"
  fi
fi

say 'Installing pipx applications'
export PATH="$HOME/.local/bin:$PATH"
installed="$(pipx list --short 2>/dev/null || true)"
grep -q '^ytm-player ' <<<"$installed" || pipx install ytm-player
pipx inject --force ytm-player 'yt-dlp[default]'
grep -q '^yt-dlp ' <<<"$installed" || pipx install 'yt-dlp[default]'

say 'Installing Neovim plugins'
nvim --headless '+Lazy! restore' +qa || printf 'warning: plugins will install on first nvim launch\n' >&2

cat <<EOF

Done. The remaining steps need your accounts and cannot be automated:
  * ytm setup                          # connect YouTube Music
  * gpg --full-generate-key && pass init <key-id> && pass insert mail/gmail-app
  * cp $repo/examples/aerc-accounts.conf.example ~/.config/aerc/accounts.conf
    chmod 600 ~/.config/aerc/accounts.conf, then edit your addresses
Log out and back in on a TTY to start tmux.
EOF
