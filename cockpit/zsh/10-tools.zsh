command -v eza >/dev/null && {
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -la --icons --group-directories-first'
  alias la='eza -a --icons'
}
command -v bat >/dev/null && alias cat='bat --paging=never'
command -v rg >/dev/null && alias grep='rg'
command -v fd >/dev/null && alias find='fd'

[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

if command -v zoxide >/dev/null; then
  eval "$(zoxide init zsh)"
  alias j='z'
fi

alias ..='cd ..'
alias ...='cd ../..'