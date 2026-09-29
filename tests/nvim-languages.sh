#!/usr/bin/env bash
set -euo pipefail
command -v nvim >/dev/null || { echo 'nvim is required for this test' >&2; exit 1; }
repo=$(cd -- "$(dirname -- "$0")/.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export HOME=$tmp XDG_CONFIG_HOME=$tmp/.config
mkdir -p "$XDG_CONFIG_HOME/tty-setup/languages"
run() {
  nvim --clean --headless -u NONE "+lua package.path='$repo/config/nvim/lua/?.lua;'..package.path; $1" +qa
}
run "local m=require('tty_languages'); assert(#m.parsers()==0); assert(#m.servers()==0); assert(next(m.formatters())==nil)"
for entry in 'lang-js javascript ts_ls javascript prettier' 'lang-web html html html prettier' 'lang-json json jsonls json prettier' 'lang-python python pyright python ruff_format' 'lang-bash bash bashls bash shfmt' 'lang-lua lua lua_ls lua stylua' 'lang-markdown markdown marksman markdown prettier' 'lang-rust rust rust_analyzer rust rustfmt'; do
  read -r id parser server ft formatter <<< "$entry"
  touch "$XDG_CONFIG_HOME/tty-setup/languages/$id"
  run "local m=require('tty_languages'); assert(vim.tbl_contains(m.parsers(), '$parser')); assert(vim.tbl_contains(m.servers(), '$server')); assert(m.formatters().$ft[1]=='$formatter')"
  rm "$XDG_CONFIG_HOME/tty-setup/languages/$id"
done
printf 'Neovim language tests passed\n'
