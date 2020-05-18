autoload -U compinit && compinit

bindkey -v
bindkey '\eOH' beginning-of-line
bindkey '\eOF' end-of-line
alias ls="ls --color=auto"
alias grep="grep --color"
export PAGER="vimpager"

eval "$(starship init zsh)"
