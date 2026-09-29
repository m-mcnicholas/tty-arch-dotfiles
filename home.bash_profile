# Bash login shells on local virtual consoles start the TTY workspace.
[[ -f ~/.bashrc ]] && source ~/.bashrc

if [[ $- == *i* && -z ${TMUX:-} && -z ${DISPLAY:-} && -z ${WAYLAND_DISPLAY:-} ]]; then
  case "$(tty 2>/dev/null)" in
    /dev/tty[0-9]*)
      command -v tty-theme >/dev/null 2>&1 && tty-theme || true
      if command -v tmux >/dev/null 2>&1; then
        tmux new-session -A -s main
      fi
      ;;
  esac
fi
