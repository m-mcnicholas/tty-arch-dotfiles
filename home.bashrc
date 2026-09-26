[[ $- != *i* ]] && return
export EDITOR=nvim
export VISUAL=nvim
export PAGER=less
export PATH="$HOME/.local/bin:$PATH"

# Palette in ~/.config/theme used by the console, X, and every 16-colour app.
export TTY_THEME="${TTY_THEME:-gruvbox}"
export LESS='-R --use-color -Dd+r$Du+b$'
export MANPAGER='less -R --use-color -Dd+r -Du+b'
export MANROFFOPT='-P -c'
export FZF_DEFAULT_OPTS='--color=16'

alias ls='ls --color=auto'
alias ll='ls -lah'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ip='ip -color=auto'
alias btop='btop --tty'
alias g='git'

[[ -r /usr/share/git/completion/git-prompt.sh ]] && source /usr/share/git/completion/git-prompt.sh
declare -F __git_ps1 >/dev/null || __git_ps1() { :; }
GIT_PS1_SHOWDIRTYSTATE=1

# Blue path, yellow Git branch, and a prompt mark that turns red after a failure.
__prompt() {
  local status=$? mark='\[\e[32m\]'
  ((status)) && mark='\[\e[31m\]'
  PS1="${SSH_CONNECTION:+\u@\h }\[\e[1;34m\]\w\[\e[0;33m\]$(__git_ps1 ' %s')\n${mark}\$\[\e[0m\] "
}
PROMPT_COMMAND=__prompt
