# ── fzf ───────────────────────────────────────────────────────────────────────
# Ctrl+R → historial  |  Ctrl+T → archivos  |  Alt+C → directorios
eval "$(fzf --zsh)"

export FZF_DEFAULT_OPTS="
  --height=40%
  --layout=reverse
  --border=rounded
  --color=bg+:#F2F2F7,bg:#FFFFFF,spinner:#2C6E8A,hl:#2C6E8A
  --color=fg:#072436,header:#8FA3AF,info:#2C6E8A,pointer:#2C6E8A
  --color=marker:#2C6E8A,fg+:#072436,prompt:#2C6E8A,hl+:#5B8FA8"

# ── zoxide ────────────────────────────────────────────────────────────────────
# z <dir>   → saltar a directorio frecuente
# zi        → seleccionar con fzf
eval "$(zoxide init zsh)"

# ── bat ───────────────────────────────────────────────────────────────────────
export BAT_THEME="GitHub"
alias cat='bat --paging=never'
export MANPAGER="sh -c 'col -bx | bat -l man --paging=always'"

# ── eza ───────────────────────────────────────────────────────────────────────
alias ls='eza --group-directories-first --color=always'
alias ll='eza -lh --group-directories-first --git'
alias la='eza -lah --group-directories-first --git'
alias lt='eza --tree --level=2 --group-directories-first'
