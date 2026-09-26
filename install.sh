#!/usr/bin/env bash
set -euo pipefail

usage() { printf 'Usage: %s --plan|--apply\n' "$0" >&2; exit 2; }
[[ $# == 1 ]] || usage
case "$1" in --plan|--apply) mode="$1" ;; *) usage ;; esac
repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

links=(
  'home.bash_profile:.bash_profile'
  'home.bashrc:.bashrc'
  'home.xinitrc:.xinitrc'
  'config/tmux.conf:.config/tmux/tmux.conf'
  'config/gitconfig:.gitconfig'
  'config/nvim:.config/nvim'
  'config/ranger:.config/ranger'
  'config/aerc/aerc.conf:.config/aerc/aerc.conf'
  'config/ytm-player/config.toml:.config/ytm-player/config.toml'
  'config/mpv/mpv.conf:.config/mpv/mpv.conf'
  'config/i3/config:.config/i3/config'
  'bin/tty-video:.local/bin/tty-video'
  'bin/tty-video-check:.local/bin/tty-video-check'
)

for pair in "${links[@]}"; do
  source_path="$repo/${pair%%:*}"
  target_path="$HOME/${pair#*:}"
  if [[ -L "$target_path" && "$(readlink -- "$target_path")" == "$source_path" ]]; then
    printf 'ok     %s\n' "$target_path"
    continue
  fi
  if [[ -e "$target_path" || -L "$target_path" ]]; then
    if [[ "$mode" == --plan ]]; then
      printf 'backup %s then link %s\n' "$target_path" "$source_path"
      continue
    fi
    stamp="$(date -u +%Y%m%dT%H%M%SZ)"
    backup="$target_path.backup-$stamp"
    suffix=1
    while [[ -e "$backup" || -L "$backup" ]]; do
      backup="$target_path.backup-$stamp-$suffix"
      ((suffix += 1))
    done
    mv -- "$target_path" "$backup"
    printf 'backed up %s to %s\n' "$target_path" "$backup"
  else
    printf 'link   %s -> %s\n' "$target_path" "$source_path"
  fi
  if [[ "$mode" == --apply ]]; then
    mkdir -p -- "$(dirname -- "$target_path")"
    ln -s -- "$source_path" "$target_path"
  fi
done
