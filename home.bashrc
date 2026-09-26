[[ $- != *i* ]] && return
export EDITOR=nvim
export VISUAL=nvim
export PAGER=less
export PATH="$HOME/.local/bin:$PATH"
alias ls='ls --color=auto'
alias ll='ls -lah'
alias g='git'
