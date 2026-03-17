# shellcheck shell=bash
# expect $USER and $HOME to be set

__eprint() {
    echo "$1" >&2
    exit 1
}

__assure_dir() {
    local dir base_msg msg
    dir="$1"
    base_msg="$dir not found and not creatable"
    msg="${2:-$base_msg}"
    [ ! -d "$dir" ] && (mkdir "$dir" || __eprint "$msg")
}

__init_shell() {
    local uid scratch_user scratch_user_msg local_dir theme_viewer

    uid="$(id -u)"

    # if /home if mounted, look for /scratch to use as cache directory
    if [ -d "/scratch" ]; then
        scratch_user="/scratch/$USER"
        scratch_user_msg="/scratch found, but $scratch_user not found and not creatable"
        __assure_dir "$scratch_user" "$scratch_user_msg"
        CACHE_DIR="$scratch_user/.cache"
    else
        CACHE_DIR="$HOME/.cache"
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
        __assure_dir "$dir"
    done

    export ZSH="$XDG_CONFIG_HOME/ohmyzsh"
    plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
    ZSH_CACHE="$XDG_CACHE_HOME/zsh"
    __assure_dir "$ZSH_CACHE"
    ZSH_COMPDUMP="$ZSH_CACHE/zcompdump-${SHORT_HOST}-${ZSH_VERSION}"
    ZSH_CUSTOM="$ZSH/custom"
    ZSH_THEME="robbyrussell"
    . "$ZSH/oh-my-zsh.sh"
    HISTFILE="$ZSH_CUSTOM/zsh_history"

    # BEGIN THEME VIEWER
    theme_viewer="$ZSH_CUSTOM/theme_viewer"
    # TODO(tihoph) automatically download it
    [ -f "$theme_viewer" ] || __eprint "Theme viewer script not found"
    . "$theme_viewer"
    # END THEME VIEWER

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

    # TODO(tihoph): install uv if not available
    if which uvc >/dev/null; then
        eval "$(command uvc shell zsh)"
    fi

    # BEGIN ALIASES
    alias b="bat --paging=never --style=plain --tabs=4"
    alias sb="sudo bat --paging=never --style=plain --tabs=4"
    # END ALIASES

    export PATH
}

__init_shell