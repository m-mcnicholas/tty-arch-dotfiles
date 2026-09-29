#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P || true)
if [[ -f $script_dir/lib/features.sh ]]; then exec bash "$script_dir/bin/tty-setup" "$@"; fi
repo=${DOTFILES_DIR:-$HOME/tty-arch-dotfiles}
if [[ ! -f $repo/bin/tty-setup ]]; then
  for arg in "$@"; do
    [[ $arg != --plan ]] || { echo 'For a change-free plan, clone the repository and run ./bootstrap.sh --plan.' >&2; exit 1; }
  done
  [[ -f /etc/arch-release ]] || { echo 'Requires Arch Linux' >&2; exit 1; }
  ((EUID != 0)) || { echo 'Run as a regular user' >&2; exit 1; }
  command -v pacman >/dev/null || { echo 'pacman is a prerequisite' >&2; exit 1; }
  command -v sudo >/dev/null || { echo 'sudo is required' >&2; exit 1; }
  sudo pacman -Syu --needed git
  git clone https://github.com/m-mcnicholas/tty-arch-dotfiles.git "$repo"
fi
exec bash "$repo/bin/tty-setup" "$@"
