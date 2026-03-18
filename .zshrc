#!/usr/bin/env zsh
# shellcheck shell=bash
# shellcheck disable=SC1091
# expect $USER and $HOME to be set

export ZSHSETUP_REPO="ssh://git@git.audivir.de/tihoph/zshrc"
export ZSHSETUP_HOME="$HOME/.config/zshsetup"

__eprint() {
    echo "$1" >&2
    return 1
}

__assure_link() {
    local link_file expected_target
    link_file="$1"
    expected_target="$2"
    if [ -L "$link_file" ]; then
        actual_target=$(readlink "$link_file") || return 1
        if [ "$actual_target" != "$expected_target" ]; then
            __eprint "$link_file points to $actual_target. Rewriting to $expected_target..."
            ln -snf "$expected_target" "$link_file"
        fi
    elif [ -d "$link_file" ] || [ -f "$link_file" ]; then
        __eprint "$link_file is a directory or file, please backup and move it first"
    else
        ln -s "$expected_target" "$link_file"
    fi
}

__assure_dir() {
    local dir_to_check
    dir_to_check="$1"
    mkdir -p "$dir_to_check" || __eprint "$dir_to_check not found and not creatable"
}

__menu() {
    PYTHONPATH="$ZSHSETUP_HOME:$PYTHONPATH" python3 - <<EOF "${@}"
import sys

from simple_term_menu import TerminalMenu

options = sys.argv[1:]
terminal_menu = TerminalMenu(options)
menu_entry_index = terminal_menu.show()
if menu_entry_index is None:
    raise SystemExit(1)
print(options[menu_entry_index])
EOF
}

__package_manager() {
    local brew_package apt_package os mgr
    local -a options
    brew_package="$1"
    apt_package="$2"

    os="$(uname)"
    if [ "$os" = "Darwin" ] && [ -n "$brew_package" ]; then
        options+=("brew")
    elif [ "$os" = "Linux" ] && [ -n "$apt_package" ]; then
        options+=("apt")
    fi

    options+=("manual")

    mgr="$(__menu "${options[@]}")" || return 1

    case "$mgr" in
        "manual")
            return 0
            ;;
        "brew")
            NONINTERACTIVE=1 brew install "$brew_package" || return 1
            return 2
            ;;
        "apt")
            sudo DEBIAN_FRONTEND=noninteractive apt-get install "$apt_package" --no-install-recommends --yes || return 1
            return 3
            ;;
        *)
            return 1
            ;;
    esac
}

__source() {
  local env
  env=$("$@") || return 1
  eval "$env"
}

__missing() {
    local cmd
    cmd="$1"
    shift
    command "$cmd" "$@" &>/dev/null && return 1
    echo "$cmd is missing..."
}

__init_cache() {
    local user_cache scratch_cache
    user_cache="$HOME/.cache"
    scratch_cache="/scratch/$USER/.cache"
    # if /home if mounted, look for /scratch to use as cache directory
    if [ -d "/scratch" ]; then
        __assure_dir "$scratch_cache" || return 1
        __assure_link "$user_cache" "$scratch_cache" || return 1
        CACHE_DIR="$scratch_cache"
    else
        CACHE_DIR="$user_cache"
    fi
}

__init_shell() {
    local uid returncode
    uid="$(id -u)"

    __init_cache || return 1

    export LOCAL_HOME="$HOME/.local"
    export XDG_CONFIG_HOME="$HOME/.config"
    export XDG_DATA_HOME="$LOCAL_HOME/share"
    export XDG_BIN_HOME="$LOCAL_HOME/bin"
    export XDG_CACHE_HOME="$CACHE_DIR"
    export XDG_RUNTIME_DIR="/run/user/$uid"
    export XDG_STATE_HOME="$LOCAL_HOME/state"

    for dir in "$LOCAL_HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_BIN_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"; do
        __assure_dir "$dir" || return 1
    done

    # BEGIN OH-MY-ZSH
    export ZSH="$ZSHSETUP_HOME/oh-my-zsh"
    if [ ! -d "$ZSH" ]; then
        "$ZSHSETUP_HOME/packages/oh-my-zsh.sh" || return 1
    fi
    local plugin_dir
    plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
    for plugin in "${plugins[@]}"; do
        plugin_dir="$ZSH/plugins/$plugin"
        if [ ! -d "$plugin_dir" ]; then
          git clone "https://github.com/zsh-users/$plugin" "$plugin_dir" || return 1
        fi
    done
    ZSH_CACHE="$XDG_CACHE_HOME/zsh"
    __assure_dir "$ZSH_CACHE" || return 1
    # shellcheck disable=SC2034
    ZSH_COMPDUMP="$ZSH_CACHE/zcompdump-${SHORT_HOST}-${ZSH_VERSION}"
    # shellcheck disable=SC2034
    ZSH_CUSTOM="$ZSH/custom"
    # shellcheck disable=SC2034
    ZSH_THEME="robbyrussell"
    . "$ZSH/oh-my-zsh.sh"
    # END OH-MY-ZSH

    HISTFILE="$ZSHSETUP_HOME/zsh_history"
    PATH="$XDG_BIN_HOME:$HOME/bin:$PATH"

    # BEGIN HOMEBREW
    if [ -f "/opt/homebrew/bin/brew" ]; then
        __source /opt/homebrew/bin/brew shellenv || return 1
        alias homebrewupdate='brew update && brew upgrade --formulae && brew cu --yes && cd /opt/homebrew && git stash pop &>/dev/null || true && cd -'
    fi
    # END HOMEBREW

    # BEGIN MICROMAMBA
    if __missing micromamba --help; then
        __package_manager micromamba-static micromamba
        returncode="$?"
        if [ "$returncode" -eq 1 ]; then
            return 1
        elif [ "$returncode" -eq 0 ]; then
             "$ZSHSETUP_HOME/packages/micromamba.sh" || return 1
        fi
    fi
    alias conda='micromamba'
    __source command micromamba shell hook --shell zsh || return 1
    export MAMBA_ROOT_PREFIX="$XDG_DATA_HOME/micromamba"
    # END MICROMAMBA

    # BEGIN GO
    PATH="$XDG_DATA_HOME/go/bin:$XDG_DATA_HOME/golang/bin:$PATH"
    if __missing go help; then
        __package_manager go golang
        returncode="$?"
        if [ "$returncode" -eq 1 ]; then
            return 1
        elif [ "$returncode" -eq 0 ]; then
            "$ZSHSETUP_HOME/packages/go.sh" || return 1
            PATH="$XDG_DATA_HOME/golang/bin:$PATH"
        fi
    fi
    if [ -d "$XDG_DATA_HOME/golang" ]; then
        export GOROOT="$XDG_DATA_HOME/golang"
    fi
    export GOPATH="$XDG_DATA_HOME/go"
    # END GO

    # BEGIN RUST
    PATH="$XDG_DATA_HOME/cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH"
    export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
    export CARGO_HOME="$XDG_DATA_HOME/cargo"
    if __missing rustup --help; then
        __package_manager rustup rustup
        returncode="$?"
        if [ "$returncode" -eq 1 ]; then
            return 1
        elif [ "$returncode" -eq 0 ]; then
            "$ZSHSETUP_HOME/packages/rustup.sh" || return 1
        fi
    fi
    # END RUST

    # BEGIN PYTHON
    if __missing uv --help; then
        __package_manager uv ""
        returncode="$?"
        if [ "$returncode" -eq 1 ]; then
            return 1
        elif [ "$returncode" -eq 0 ]; then
            command cargo install uv --root "$LOCAL_HOME" || return 1
        fi
    fi
    if __missing uvc --help; then
        __package_manager uvc ""
        returncode="$?"
        if [ "$returncode" -eq 1 ]; then
            return 1
        elif [ "$returncode" -eq 0 ]; then
            "$ZSHSETUP_HOME/packages/uvc.sh" || return 1
        fi
    fi
    __source command uvc shell zsh || return 1
    # END PYTHON

    # BEGIN EXTRA TOOLS
    if __missing bat --help; then
        __package_manager bat bat
        returncode="$?"
        if [ "$returncode" -eq 1 ]; then
            return 1
        elif [ "$returncode" -eq 0 ]; then
            cargo install bat --root "$LOCAL_HOME" || return 1
        elif [ "$returncode" -eq 3 ]; then
            sudo ln -sf /usr/bin/batcat /usr/local/bin/bat || return 1
        fi
    fi

    if __missing micro --help; then
        __package_manager micro micro
        returncode="$?"
        if [ "$returncode" -eq 1 ]; then
            return 1
        elif [ "$returncode" -eq 0 ]; then
            "$ZSHSETUP_HOME/packages/micro.sh" || return 1
        fi
    fi
    # END EXTRA TOOLS

    # BEGIN ALIASES
    alias b="bat --paging=never --style=plain --tabs=4"
    alias sb="sudo bat --paging=never --style=plain --tabs=4"
    # END ALIASES

    # BEGIN ENVIRONMENT
    export GNUPGHOME="$XDG_DATA_HOME/gnupg"
    export MPLCONFIGDIR="$XDG_CONFIG_HOME/matplotlib"
    export PYTHON_HISTORY="$XDG_DATA_HOME/python/python_history"
    # END ENVIRONMENT

    export PATH

    # BEGIN THEME VIEWER
    . "$ZSHSETUP_HOME/theme_viewer.sh"
    # END THEME VIEWER
}

__install_shell() {
    if [ -d "$ZSHSETUP_HOME" ]; then
        __assure_link "$HOME/.zshrc" "$ZSHSETUP_HOME/.zshrc" || return 1
        __eprint "$ZSHSETUP_HOME already exists, updating instead"
        __update_shell
        return 0
    fi
    trap 'rm -rf "$ZSHSETUP_HOME"' EXIT INT TERM
    if ! git clone "$ZSHSETUP_REPO" "$ZSHSETUP_HOME"; then
        __eprint "Failed to clone $ZSHSETUP_REPO to $ZSHSETUP_HOME"
        return 1
    fi
    __assure_link "$HOME/.zshrc" "$ZSHSETUP_HOME/.zshrc" || return 1
    trap - EXIT INT TERM
    __eprint "zshsetup installed and linked"
    return 0
}

__update_shell() {
    local returncode
    if [ ! -d "$ZSHSETUP_HOME" ]; then
        __eprint "$ZSHSETUP_HOME does not exist, installing instead"
        __install_shell
        return "$?"
    fi
    pushd "$ZSHSETUP_HOME" || return 1
    git fetch || __eprint "Failed to fetch new data from $ZSHSETUP_REPO"
    git stash || __eprint "Failed to stash local changes"
    git merge || __eprint "Failed to merge updates"
    git stash pop || __eprint "Failed to reapply local changes"
    popd || return 1
}

if [ "$1" = "install" ]; then
  __install_shell
  exit "$?"
elif [ "$1" = "update" ]; then
  __update_shell
  exit "$?"
fi

__init_shell

# BEGIN CUSTOM
