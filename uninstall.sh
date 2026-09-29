#!/usr/bin/env bash
set -euo pipefail

usage() { printf 'Usage: %s --plan|--apply [--features IDs]\n' "$0" >&2; exit 2; }
[[ $# -ge 1 ]] || usage
case $1 in --plan|--apply) mode=$1 ;; *) usage ;; esac
shift
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=lib/features.sh
source "$repo/lib/features.sh"

if (($#)); then
  [[ $# == 2 && $1 == --features && -n $2 ]] || usage
  IFS=, read -r -a selected <<< "$2"
  ((${#selected[@]})) || usage
  for id in "${selected[@]}"; do
    [[ -n $id ]] && get descriptions "$id" >/dev/null || usage
  done
else
  selected=("${ids[@]}")
fi

state=${XDG_STATE_HOME:-$HOME/.local/state}/tty-setup
config=${XDG_CONFIG_HOME:-$HOME/.config}/tty-setup

remove_link() {
  local target=$1 source=$2 backup candidate
  if [[ ! -L $target || $(readlink -- "$target") != "$source" ]]; then
    if [[ -e $target || -L $target ]]; then
      printf 'skip   %s (not managed by this checkout)\n' "$target"
    fi
    return
  fi

  backup=
  shopt -s nullglob
  for candidate in "$target".backup-*; do
    [[ -e $candidate || -L $candidate ]] && backup=$candidate
  done
  shopt -u nullglob
  if [[ -n $backup ]]; then
    printf 'restore %s from %s\n' "$target" "$backup"
  else
    printf 'remove %s\n' "$target"
  fi
  if [[ $mode == --apply ]]; then
    rm -- "$target"
    [[ -z $backup ]] || mv -- "$backup" "$target"
  fi
}

remove_marker() {
  local path=$1
  [[ -f $path && ! -L $path ]] || return 0
  printf 'remove %s\n' "$path"
  [[ $mode != --apply ]] || rm -- "$path"
}

for id in "${selected[@]}"; do
  for pair in $(get feature_links "$id"); do
    remove_link "$HOME/${pair#*:}" "$repo/${pair%%:*}"
  done
  if [[ $id == joplin ]]; then
    remove_link "$HOME/.local/bin/joplin" "$HOME/.joplin-bin/bin/joplin"
  fi
  remove_marker "$state/$id"
  if [[ $id == lang-* ]]; then
    remove_marker "$config/languages/$id"
  fi
done

if [[ $mode == --apply ]]; then
  rmdir -- "$config/languages" "$state" 2>/dev/null || true
fi
