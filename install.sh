#!/usr/bin/env bash
set -euo pipefail

usage() { printf 'Usage: %s --plan|--apply [--features IDs]\n' "$0" >&2; exit 2; }
[[ $# -ge 1 ]] || usage
case "$1" in --plan|--apply) mode="$1" ;; *) usage ;; esac
shift
repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=lib/features.sh
source "$repo/lib/features.sh"
selected=()
if (($#)); then
  [[ $# == 2 && $1 == --features && -n $2 ]] || usage
  IFS=, read -r -a requested <<< "$2"
  resolve "${requested[@]-}"
else
  selected=("${ids[@]}")
fi
links=()
for id in "${selected[@]}"; do
  for pair in $(get feature_links "$id"); do links+=("$pair"); done
done

if ((${#links[@]})); then
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

fi
