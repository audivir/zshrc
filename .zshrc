# shellcheck shell=bash
# expect $USER and $HOME to be set

__eprint() {
    echo "$1" >&2
    return 1
}

__assure_dir() {
    local dir base_msg msg
    dir="$1"
    base_msg="$dir not found and not creatable"
    msg="${2:-$base_msg}"
    [ -d "$dir" ] && return 0
    mkdir "$dir" || __eprint "$msg"
}

__download() {
    local url file
    url="ssh://git@git.audivir.de/tihoph/zshrc"
    file="$1"
    echo "Downloading $file..." >&2
    git archive --remote="$url" HEAD "$file" | tar xO
    if (( ${pipestatus[(I)1]} )); then
      __eprint "Failed to download $file"
    else
      return 0
    fi
}

__init_shell() {
    local uid user_cache scratch_user scratch_user_msg 
    local scratch_cache scratch_cache_msg local_dir theme_viewer

    uid="$(id -u)"

    # if /home if mounted, look for /scratch to use as cache directory
    user_cache="$HOME/.cache"
    if [ -d "/scratch" ]; then
        scratch_user="/scratch/$USER"
        scratch_user_msg="/scratch found, but $scratch_user not found and not creatable"
        scratch_cache="$scratch_user/.cache"
        scratch_cache_msg="$scratch_user found, but $scratch_cache not found and not creatable"
        __assure_dir "$scratch_user" "$scratch_user_msg" || return 1
        __assure_dir "$scratch_cache" "$scratch_cache_msg" || return 1
        CACHE_DIR="$scratch_cache"
    else
        CACHE_DIR="$user_cache"
    fi

    local_dir="$HOME/.local"
    __assure_dir "$local_dir"

    export XDG_CONFIG_HOME="$HOME/.config"
    export XDG_DATA_HOME="$local_dir/share"
    export XDG_BIN_HOME="$local_dir/bin"
    export XDG_CACHE_HOME="$CACHE_DIR"
    export XDG_RUNTIME_DIR="/run/user/$uid"
    export XDG_STATE_HOME="$local_dir/state"

    for dir in "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_BIN_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"; do
        __assure_dir "$dir" || return 1
    done

    export ZSH="$XDG_CONFIG_HOME/ohmyzsh"
    plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
    ZSH_CACHE="$XDG_CACHE_HOME/zsh"
    __assure_dir "$ZSH_CACHE" || return 1
    ZSH_COMPDUMP="$ZSH_CACHE/zcompdump-${SHORT_HOST}-${ZSH_VERSION}"
    ZSH_CUSTOM="$ZSH/custom"
    ZSH_THEME="robbyrussell"
    . "$ZSH/oh-my-zsh.sh"
    HISTFILE="$ZSH_CUSTOM/zsh_history"

    PATH="$XDG_BIN_HOME:$HOME/bin:$PATH"

    # BEGIN HOMEBREW
    if [ -f "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        alias homebrewupdate='brew update && brew upgrade --formulae && brew cu --yes && cd /opt/homebrew && git stash pop &>/dev/null || true && cd -'
    fi
    # END HOMEBREW

    # BEGIN MICROMAMBA
    if which micromamba >/dev/null; then
        alias conda='micromamba'
        eval "$(command micromamba shell hook --shell zsh)"
    fi
    export MAMBA_ROOT_PREFIX="$XDG_DATA_HOME/micromamba"
    # END MICROMAMBA

    # BEGIN GO
    # TODO(tihoph): install go if not available
    export GOPATH="$XDG_DATA_HOME/go"
    PATH="$XDG_DATA_HOME/go/bin:$PATH"
    # END GO

    # BEGIN RUST
    # TODO(tihoph): install rust if not available
    export CARGO_HOME="$XDG_DATA_HOME/cargo"
    export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
    PATH="$XDG_DATA_HOME/cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH"
    # END RUST

    # BEGIN PYTHON
    # TODO(tihoph): install uv if not available
    if which uvc >/dev/null; then
        eval "$(command uvc shell zsh)"
    fi
    # END PYTHON

    # BEGIN ALIASES
    alias b="bat --paging=never --style=plain --tabs=4"
    alias sb="sudo bat --paging=never --style=plain --tabs=4"
    # END ALIASES

    export PATH

    # BEGIN THEME VIEWER
    theme_viewer="$ZSH_CUSTOM/theme_viewer"
    if [ ! -f "$theme_viewer" ]; then
        __download theme_viewer >"$theme_viewer"
    fi
    . "$theme_viewer"
    # END THEME VIEWER
}

update_zshrc() {
    local tmp_file
    tmp_file=$(mktemp)
    trap 'rm -f "$tmp_file"' EXIT INT TERM

    echo "Updating .zshrc..." >&2
    __download .zshrc >"$tmp_file" || return 1
    
    if [ -f "$HOME/.zshrc" ]; then
        # Search for # BEGIN CUSTOM and append everything from there to the EOF
        sed -n '/# BEGIN CUSTOM/,$p' "$HOME/.zshrc" >> "$tmp_file"
    else
        echo -e "\n# BEGIN CUSTOM" >> "$tmp_file"
    fi

    mv "$tmp_file" "$HOME/.zshrc"    
    echo "Update complete."
    
    trap - EXIT INT TERM
}

__init_shell

# BEGIN CUSTOM
