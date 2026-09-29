#!/usr/bin/env bash
set -euo pipefail
repo=$(cd -- "$(dirname -- "$0")/.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export HOME=$tmp/home XDG_CONFIG_HOME=$tmp/home/.config XDG_STATE_HOME=$tmp/home/.local/state
export MOCK_ROOT=$tmp MOCK_LOG=$tmp/log TTY_SETUP_ARCH_RELEASE=$tmp/arch-release TTY_SETUP_PACMAN_CONF=$tmp/pacman.conf
mkdir -p "$HOME" "$tmp/bin" "$XDG_CONFIG_HOME"; touch "$TTY_SETUP_ARCH_RELEASE"; printf '[multilib]\n' > "$TTY_SETUP_PACMAN_CONF"
printf 'XDG_DOWNLOAD_DIR="$HOME/My Downloads"\n' > "$XDG_CONFIG_HOME/user-dirs.dirs"
cat > "$tmp/bin/sudo" <<'MOCK'
#!/usr/bin/env bash
[[ ${1:-} == -v ]] && exit 0
"$@"
MOCK
cat > "$tmp/bin/pacman" <<'MOCK'
#!/usr/bin/env bash
case $1 in
  -Q) rg -qx "$2" "$MOCK_ROOT/packages" 2>/dev/null ;;
  -Sp) exit 0 ;;
  -Syu)
    printf 'pacman %s\n' "$*" >> "$MOCK_LOG"
    [[ ${MOCK_FAIL_PACKAGE:-} != 1 ]] || exit 7
    shift
    for item in "$@"; do [[ $item == -* ]] || printf '%s\n' "$item" >> "$MOCK_ROOT/packages"; done
    ;;
esac
MOCK
cat > "$tmp/bin/systemctl" <<'MOCK'
#!/usr/bin/env bash
printf 'systemctl %s\n' "$*" >> "$MOCK_LOG"
[[ $1 != is-enabled ]] || rg -q 'enable --now sshd' "$MOCK_LOG"
MOCK
cat > "$tmp/bin/xdg-user-dir" <<'MOCK'
#!/usr/bin/env bash
if [[ $1 == DOWNLOAD ]]; then echo "$HOME/My Downloads"; else echo "$HOME/$1"; fi
MOCK
cat > "$tmp/bin/xdg-user-dirs-update" <<'MOCK'
#!/usr/bin/env bash
exit 0
MOCK
cat > "$tmp/bin/npm" <<'MOCK'
#!/usr/bin/env bash
printf 'npm %s\n' "$*" >> "$MOCK_LOG"
mkdir -p "$NPM_CONFIG_PREFIX/bin"
printf '#!/bin/sh\nexit 0\n' > "$NPM_CONFIG_PREFIX/bin/joplin"
chmod +x "$NPM_CONFIG_PREFIX/bin/joplin"
MOCK
cat > "$tmp/bin/nvim" <<'MOCK'
#!/usr/bin/env bash
[[ ${MOCK_FAIL_NVIM:-} != 1 ]] || exit 8
printf 'nvim %s\n' "$*" >> "$MOCK_LOG"
MOCK
cat > "$tmp/bin/dialog" <<'MOCK'
#!/usr/bin/env bash
exit 1
MOCK
cat > "$tmp/bin/uname" <<'MOCK'
#!/usr/bin/env bash
echo x86_64
MOCK
chmod +x "$tmp/bin"/*
export PATH="$tmp/bin:$PATH"
"$repo/bootstrap.sh" > "$tmp/cancel"
[[ ! -e $tmp/packages && ! -e $XDG_STATE_HOME/tty-setup/core ]]
"$repo/bootstrap.sh" --features joplin --yes > "$tmp/first"
[[ -f $XDG_STATE_HOME/tty-setup/core && -f $XDG_STATE_HOME/tty-setup/joplin ]]
[[ -L $HOME/.local/bin/joplin && -x $HOME/.local/bin/tty-theme ]]
[[ -d $HOME/'My Downloads' && -d $HOME/Projects ]]
rg -q 'pacman -Syu' "$MOCK_LOG"
rg -q '^openssh$' "$tmp/packages"
! rg -q '^steam$|^mpv$|^aerc$|^firefox$|^rust-analyzer$' "$tmp/packages"
! rg -q 'sshd' "$MOCK_LOG"
MOCK_FAIL_PACKAGE=1 "$repo/bootstrap.sh" --features lang-rust --yes > "$tmp/fail-out" 2> "$tmp/fail-err" && exit 1
rg -q 'Failed step: core packages' "$tmp/fail-err"
[[ -f $XDG_STATE_HOME/tty-setup/core ]]
"$repo/bootstrap.sh" --features lang-rust --yes > "$tmp/rust"
[[ -f $XDG_STATE_HOME/tty-setup/lang-rust ]]
[[ -f $XDG_CONFIG_HOME/tty-setup/languages/lang-rust ]]
[[ ! -e $HOME/.config/nvim/lua/tty_languages.lua.backup ]]
"$repo/bootstrap.sh" --features ssh-server --yes > "$tmp/ssh"
rg -q 'enable --now sshd' "$MOCK_LOG"
echo 'mock install tests passed'
