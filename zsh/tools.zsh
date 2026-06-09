# ── fzf ───────────────────────────────────────────────────────────────────────
# Ctrl+R → historial  |  Ctrl+T → archivos  |  Alt+C → directorios
eval "$(fzf --zsh)"

export FZF_DEFAULT_OPTS="
  --height=40%
  --layout=reverse
  --border=rounded
  --color=bg+:#1A3040,bg:#0D1F2D,spinner:#5B8FA8,hl:#5B8FA8
  --color=fg:#C8D8E2,header:#4A6070,info:#5B8FA8,pointer:#7BAFD4
  --color=marker:#2ECC71,fg+:#E8F1F5,prompt:#5B8FA8,hl+:#7BAFD4"

# ── zoxide ────────────────────────────────────────────────────────────────────
# z <dir>   → saltar a directorio frecuente
# zi        → seleccionar con fzf
eval "$(zoxide init zsh)"

# ── bat ───────────────────────────────────────────────────────────────────────
export BAT_THEME="TwoDark"
alias cat='bat --paging=never'
export MANPAGER="sh -c 'col -bx | bat -l man --paging=always'"

# ── eza ───────────────────────────────────────────────────────────────────────
alias ls='eza --group-directories-first --color=always'
alias ll='eza -lh --group-directories-first --git'
alias la='eza -lah --group-directories-first --git'
alias lt='eza --tree --level=2 --group-directories-first'
