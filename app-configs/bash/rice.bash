# Dark Mountain · interactive Bash. Keep the user's existing history.
export HISTSIZE=50000 HISTFILESIZE=100000
export HISTCONTROL=ignoredups
export HISTTIMEFORMAT='%d/%m %H:%M  '
shopt -s histappend cmdhist checkwinsize
_rice_history_sync() { history -a; history -n; }
if [[ ";${PROMPT_COMMAND[*]-};" != *'_rice_history_sync'* ]]; then
    if declare -p PROMPT_COMMAND 2>/dev/null | command grep -q 'declare -a'; then
        PROMPT_COMMAND+=(_rice_history_sync)
    else
        PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }_rice_history_sync"
    fi
fi
# ANSI palette follows the current rice theme automatically.
PS1='\n\[\e[90m\]\w\[\e[0m\]\n\[\e[34m\]❯\[\e[0m\] '
alias ll='ls -lah --color=auto'
alias c='clear'
_rice_history_search() {
    local rice_line
    rice_line=$(HISTTIMEFORMAT= history | sed -E 's/^ *[0-9]+ +//' | tac | awk '!seen[$0]++' | fzf --height=40% --layout=reverse --prompt='Histórico › ') || return
    READLINE_LINE="$rice_line"; READLINE_POINT=${#READLINE_LINE}
}
if command -v fzf >/dev/null; then bind -x '"\C-r":_rice_history_search'; fi
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
if [[ -n ${KITTY_WINDOW_ID:-} && -z ${TMUX:-} && ${RICE_FETCH_WINDOW:-} != "${KITTY_PID:-$PPID}:$KITTY_WINDOW_ID" ]] && command -v fastfetch >/dev/null; then
    export RICE_FETCH_WINDOW="${KITTY_PID:-$PPID}:$KITTY_WINDOW_ID"
    fastfetch
fi
