# Shared feature registry. Works with the Bash bundled by Arch.
ids=()
descriptions=(); packages=(); dependencies=(); probes=(); feature_links=()
get() {
  local field=$1 id=$2 i
  for ((i=0; i<${#ids[@]}; i++)); do
    if [[ ${ids[$i]} == "$id" ]]; then
      case $field in
        descriptions) printf '%s' "${descriptions[$i]}" ;;
        packages) printf '%s' "${packages[$i]}" ;;
        dependencies) printf '%s' "${dependencies[$i]}" ;;
        probes) printf '%s' "${probes[$i]}" ;;
        feature_links) printf '%s' "${feature_links[$i]}" ;;
      esac
      return 0
    fi
  done
  return 1
}
feature() {
  ids+=("$1"); descriptions+=("$2"); packages+=("$3")
  dependencies+=("$4"); probes+=("$5"); feature_links+=("$6")
}
core_packages() {
  local line result=''
  while IFS= read -r line; do
    [[ -z $line || $line == \#* ]] && continue
    result+=" $line"
  done < "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)/packages/tty.txt"
  printf '%s' "${result# }"
}
feature core 'Essential shell, theme, editor and workspace' "$(core_packages)" '' '' 'home.bash_profile:.bash_profile home.bashrc:.bashrc config/tmux.conf:.config/tmux/tmux.conf config/gitconfig:.gitconfig config/nvim:.config/nvim config/theme:.config/theme config/lazygit/config.yml:.config/lazygit/config.yml config/ranger:.config/ranger bin/tty-theme:.local/bin/tty-theme bin/tty-setup:.local/bin/tty-setup'
feature joplin 'Terminal notes (local credentials)' 'nodejs npm' '' joplin ''
feature music 'YouTube Music (account setup required)' 'python-pipx mpv deno' '' ytm config/ytm-player/config.toml:.config/ytm-player/config.toml
feature video 'Console video and YouTube downloads' 'python-pipx mpv deno pciutils' '' tty-video 'config/mpv/mpv.conf:.config/mpv/mpv.conf bin/tty-video:.local/bin/tty-video bin/tty-video-check:.local/bin/tty-video-check'
feature mail 'Mail with aerc and pass' 'aerc pass gnupg' '' aerc config/aerc/aerc.conf:.config/aerc/aerc.conf
feature x11 'X11, i3 and Firefox' 'xorg-server xorg-xinit xorg-xrdb xterm i3-wm dmenu firefox' '' startx 'home.xinitrc:.xinitrc config/i3/config:.config/i3/config'
feature steam 'Steam (enables multilib; requires X11)' steam x11 steam ''
feature ssh-server 'Enable and start the OpenSSH server' openssh '' sshd ''
feature lang-js 'JavaScript / TypeScript' 'typescript typescript-language-server prettier' '' typescript-language-server ''
feature lang-web 'HTML / CSS' 'vscode-html-languageserver vscode-css-languageserver prettier' '' vscode-html-language-server ''
feature lang-json JSON 'vscode-json-languageserver prettier' '' vscode-json-language-server ''
feature lang-python Python 'pyright ruff' '' pyright ''
feature lang-bash Bash 'bash-language-server shfmt shellcheck' '' bash-language-server ''
feature lang-lua Lua 'lua-language-server stylua' '' lua-language-server ''
feature lang-markdown Markdown 'marksman prettier' '' marksman ''
feature lang-rust 'Rust syntax, language server and formatter' rust-analyzer '' rust-analyzer ''

resolve() {
  local id dep
  for id in "$@"; do
    get descriptions "$id" >/dev/null || { printf 'Unknown feature: %s\n' "$id" >&2; return 2; }
    [[ " ${selected[*]-} " == *" $id "* ]] && continue
    for dep in $(get dependencies "$id"); do resolve "$dep" || return; done
    selected+=("$id")
  done
}
