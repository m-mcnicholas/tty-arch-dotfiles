#!/usr/bin/env bash
set -euo pipefail
repo=$(cd -- "$(dirname -- "$0")/.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export HOME=$tmp
export XDG_CONFIG_HOME=$tmp/.config
"$repo/bootstrap.sh" --plan > "$tmp/default-plan"
rg -q 'core: .*' "$tmp/default-plan"
rg -q 'joplin: .*' "$tmp/default-plan"
! rg -q '^  (music|video|mail|x11|steam|lang-)' "$tmp/default-plan"
"$repo/bootstrap.sh" --plan --features steam,lang-rust > "$tmp/optional-plan"
rg -q 'x11: ' "$tmp/optional-plan"
rg -q 'lang-rust: ' "$tmp/optional-plan"
"$repo/install.sh" --apply --features core > /dev/null
[[ -x $HOME/.local/bin/tty-theme ]]
[[ -L $HOME/.local/bin/tty-setup ]]
"$HOME/.local/bin/tty-theme" --list > "$tmp/themes"
rg -q '^gruvbox$' "$tmp/themes"
"$HOME/.local/bin/tty-theme" --set nord >/dev/null 2>&1
[[ $(cat "$XDG_CONFIG_HOME/tty-setup/theme") == nord ]]
rm "$HOME/.bashrc"
printf 'original\n' > "$HOME/.bashrc"
"$repo/install.sh" --apply --features core > /dev/null
[[ -L $HOME/.bashrc ]]
rg -q '^original$' "$HOME"/.bashrc.backup-*
bash --noprofile --norc -ic 'source "$1"; __prompt; [[ $PS1 == *"\\u"* && $PS1 == *"\\w"* ]]' _ "$repo/home.bashrc" 2>/dev/null
SSH_CONNECTION=1 bash --noprofile --norc -ic 'source "$1"; __prompt; [[ $PS1 == *"@\\h"* ]]' _ "$repo/home.bashrc" 2>/dev/null
"$repo/install.sh" --plan --features core > "$tmp/link-plan"
! rg -q '^backup ' "$tmp/link-plan"
echo 'smoke tests passed'
