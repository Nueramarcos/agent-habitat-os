command -v starship >/dev/null && eval "$(starship init zsh)"

if [[ -z "$COCKPIT_MOTD_SHOWN" ]]; then
  export COCKPIT_MOTD_SHOWN=1
  [[ -x "$HOME/bin/motd" ]] && "$HOME/bin/motd"
fi