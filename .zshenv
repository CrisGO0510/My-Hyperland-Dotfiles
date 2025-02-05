#!/usr/bin/env zsh

# → Define color variables for output messages
typeset -A colors
colors=(
    reset  '\e[0m'     red  '\e[1;31m'  
    green  '\e[1;32m'  purple  '\e[1;35m'
    bright  '\e[0;1m'
)

# ────────────────────────────────────────────
#  Command-not-found handler
# ────────────────────────────────────────────
function command_not_found_handler {
    printf "zsh: command not found: %s\n" "$1"
    local entries=(${(f)"$(/usr/bin/pacman -F --machinereadable -- "/usr/bin/$1")"})
    (( ${#entries[@]} )) || return 127
    printf "${colors[bright]}$1${colors[reset]} may be found in:\n"
    local pkg=""
    for entry in "${entries[@]}"; do
        local fields=(${(0)entry})
        [[ "$pkg" != "${fields[2]}" ]] && printf "${colors[purple]}%s/${colors[bright]}%s ${colors[green]}%s${colors[reset]}\n" "${fields[1]}" "${fields[2]}" "${fields[3]}"
        printf '    /%s\n' "${fields[4]}"
        pkg="${fields[2]}"
    done
    return 127
}

# ────────────────────────────────────────────
#  Detect and load Oh-My-Zsh
# ────────────────────────────────────────────
zsh_paths=(
    "$HOME/.oh-my-zsh"
    "/usr/local/share/oh-my-zsh"
    "/usr/share/oh-my-zsh"
)
for zsh_path in "${zsh_paths[@]}"; do [[ -d $zsh_path ]] && export ZSH=$zsh_path && break; done

hyde_plugins=(git zsh-256color zsh-autosuggestions zsh-syntax-highlighting)
plugins+=("${hyde_plugins[@]}")
plugins=($(printf "%s\n" "${plugins[@]}" | sort -u))  # Remove duplicates

[[ -r $ZSH/oh-my-zsh.sh ]] && source $ZSH/oh-my-zsh.sh

# ────────────────────────────────────────────
#  Install packages (Arch + AUR)
# ────────────────────────────────────────────
function in {
    local -a arch aur
    for pkg in "$@"; do
        pacman -Si "$pkg" &>/dev/null && arch+=("$pkg") || aur+=("$pkg")
    done
    [[ ${#arch[@]} -gt 0 ]] && sudo pacman -S "${arch[@]}"
    [[ ${#aur[@]} -gt 0 ]] && ${aurhelper} -S "${aur[@]}"
}

# ────────────────────────────────────────────
#  Slow shell load warning
# ────────────────────────────────────────────

# ────────────────────────────────────────────
#  Error handling and cleanup
# ────────────────────────────────────────────
trap 'rm -f /tmp/.hyde_slow_load_warning.lock' EXIT  # Remove lock file on exit

# ────────────────────────────────────────────
#  Load Powerlevel10k theme
# ────────────────────────────────────────────
P10k_THEME=${P10k_THEME:-/usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme}
[[ -r $P10k_THEME ]] && source "$P10k_THEME"
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ────────────────────────────────────────────
#  Detect AUR Helper (Yay or Paru)
# ────────────────────────────────────────────
aur_cache="/tmp/.aurhelper.zshrc"
if [[ -f $aur_cache ]]; then
    aurhelper=$(<"$aur_cache")
else
    aurhelper=$(command -v yay || command -v paru || echo "")
    echo "$aurhelper" > "$aur_cache"
fi

# ────────────────────────────────────────────
#  Load additional user configuration
# ────────────────────────────────────────────
[[ -f ~/.hyde.zshrc ]] && source ~/.hyde.zshrc

# ────────────────────────────────────────────
#  Enable slow load warning if shell takes too long
# ────────────────────────────────────────────
autoload -Uz add-zsh-hook

# ────────────────────────────────────────────
#  Useful aliases
# ────────────────────────────────────────────
if command -v eza &>/dev/null; then
    alias ls='eza'
    alias l='eza -lh --icons=auto'
    alias ll='eza -lha --icons=auto --sort=name --group-directories-first'
    alias ld='eza -lhD --icons=auto'
    alias lt='eza --icons=auto --tree'
fi

alias c='clear'
alias un='$aurhelper -Rns'
alias up='$aurhelper -Syu'
alias pl='$aurhelper -Qs'
alias pa='$aurhelper -Ss'
alias pc='$aurhelper -Sc'
alias po='$aurhelper -Qtdq | $aurhelper -Rns -'
alias vc='code .'
alias fastfetch='fastfetch --logo-type kitty'
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'
alias mkdir='mkdir -p'
