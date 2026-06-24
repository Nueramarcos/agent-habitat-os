export PATH="$HOME/.local/bin:$HOME/bin:$HOME/.grok/bin:$PATH"
export COLORTERM=truecolor
export EDITOR="${EDITOR:-vim}"
export VISUAL="${VISUAL:-$EDITOR}"

HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY INC_APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_ALL_DUPS

[[ -f "$HOME/.config/cockpit/secrets.env" ]] && source "$HOME/.config/cockpit/secrets.env"