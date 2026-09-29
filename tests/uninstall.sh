#!/usr/bin/env bash
set -euo pipefail
repo=$(cd -- "$(dirname -- "$0")/.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export HOME=$tmp/home XDG_CONFIG_HOME=$tmp/home/.config XDG_STATE_HOME=$tmp/home/.local/state
mkdir -p "$HOME" "$XDG_STATE_HOME/tty-setup" "$XDG_CONFIG_HOME/tty-setup/languages"

printf 'original bashrc\n' > "$HOME/.bashrc"
"$repo/install.sh" --apply --features core,mail >/dev/null
touch "$XDG_STATE_HOME/tty-setup/core" "$XDG_STATE_HOME/tty-setup/mail"
printf 'personal config\n' > "$HOME/.gitconfig.personal"
rm -- "$HOME/.gitconfig"
mv -- "$HOME/.gitconfig.personal" "$HOME/.gitconfig"

"$repo/uninstall.sh" --plan --features core > "$tmp/plan"
[[ -L $HOME/.bashrc ]]
rg -q '^restore .*\.bashrc from .*\.bashrc\.backup-' "$tmp/plan"
"$repo/uninstall.sh" --apply --features core > "$tmp/applied"
[[ ! -L $HOME/.bashrc && $(cat "$HOME/.bashrc") == 'original bashrc' ]]
! compgen -G "$HOME/.bashrc.backup-*" >/dev/null
[[ ! -e $HOME/.local/bin/tty-theme ]]
[[ $(cat "$HOME/.gitconfig") == 'personal config' ]]
[[ -L $HOME/.config/aerc/aerc.conf ]]
[[ ! -e $XDG_STATE_HOME/tty-setup/core && -e $XDG_STATE_HOME/tty-setup/mail ]]
rg -q '^skip   .*\.gitconfig ' "$tmp/applied"

mkdir -p "$XDG_STATE_HOME/tty-setup" "$XDG_CONFIG_HOME/tty-setup/languages"
touch "$XDG_STATE_HOME/tty-setup/lang-rust" "$XDG_CONFIG_HOME/tty-setup/languages/lang-rust"
"$repo/uninstall.sh" --apply --features mail,lang-rust >/dev/null
[[ ! -e $HOME/.config/aerc/aerc.conf && ! -e $XDG_STATE_HOME/tty-setup/mail ]]
[[ ! -e $XDG_STATE_HOME/tty-setup/lang-rust && ! -e $XDG_CONFIG_HOME/tty-setup/languages/lang-rust ]]

printf 'previous joplin command\n' > "$HOME/.local/bin/joplin.backup-123-456"
ln -s "$HOME/.joplin-bin/bin/joplin" "$HOME/.local/bin/joplin"
"$repo/uninstall.sh" --apply --features joplin >/dev/null
[[ ! -L $HOME/.local/bin/joplin && $(cat "$HOME/.local/bin/joplin") == 'previous joplin command' ]]
echo 'uninstall tests passed'
