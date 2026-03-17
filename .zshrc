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
    if (( pipestatus[1] != 0 || pipestatus[2] != 0 )); then
      __eprint "Failed to download $file"
    else
      return 0
    fi
}

__menu() {
    local menu
    menu="$ZSH_CUSTOM/simple_term_menu.py"
    if [ ! -f "$menu" ]; then
        __download simple_term_menu.py >"$menu" || return 1
    fi
    PYTHONPATH="$ZSH_CUSTOM:$PYTHONPATH" python3 - <<EOF "${@}"
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
    local brew_package apt_package mgr
    brew_package="$1"
    apt_package="$2"
    local -a options

    case "$OSTYPE" in
        darwin*)
            if [ ! -z "$brew_package" ]; then
                options+=("brew")
            fi
            ;;
        linux-gnu*)
            if [ ! -z "$apt_package" ]; then
                options+=("apt")
            fi
            ;;
    esac

    options+=("manual")

    mgr="$(__menu "${options[@]}")"

    if [ $? -ne 0 ] || [ -z "$mgr" ]; then
        return 1
    fi

    echo "$mgr"

    case "$mgr" in
        "manual")
            return 0
            ;;
        "brew")
            NONINTERACTIVE=1 brew install "$brew_package" &>/dev/null
            ;;
        "apt")
            sudo DEBIAN_FRONTEND=noninteractive apt-get install "$apt_package" --no-install-recommends --yes &>/dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

__missing() {
    local cmd
    cmd="$1"
    shift
    command "$cmd" "$@" &>/dev/null && return 1
    echo "$cmd is missing..."
}

__curl() {
    local url output
    url="$1"
    output="$2"
    curl -sL "$url" -o "$output"
}

__init_shell() {
    local os arch uid mgr
    os="$(uname)"
    arch="$(uname -m)"
    uid="$(id -u)"

    # if /home if mounted, look for /scratch to use as cache directory
    local user_cache scratch_user scratch_user_msg scratch_cache scratch_cache_msg link_target
    user_cache="$HOME/.cache"
    if [ -d "/scratch" ]; then
        scratch_user="/scratch/$USER"
        scratch_user_msg="/scratch found, but $scratch_user not found and not creatable"
        scratch_cache="$scratch_user/.cache"
        scratch_cache_msg="$scratch_user found, but $scratch_cache not found and not creatable"
        __assure_dir "$scratch_user" "$scratch_user_msg" || return 1
        __assure_dir "$scratch_cache" "$scratch_cache_msg" || return 1
        if [ -L "$user_cache" ]; then
            link_target=$(readlink "$user_cache")
            if [ "$link_target" != "$scratch_cache" ]; then
                __eprint "$user_cache points to $link_target. Rewriting to $scratch_cache..."
                ln -snf "$scratch_cache" "$user_cache"
            fi
        elif [ -d "$user_cache" ] || [ -f "$user_cache" ]; then
            __eprint "$user_cache is a directory or file, please backup and move it first"
            return 1
        else
            ln -s "$scratch_cache" "$user_cache"
        fi
        CACHE_DIR="$scratch_cache"
    else
        CACHE_DIR="$user_cache"
    fi

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
    local brew_env
    if [ -f "/opt/homebrew/bin/brew" ]; then
        brew_env="$(/opt/homebrew/bin/brew shellenv)"
        [ "$?" -ne 0 ] && return 1
        eval "$brew_env" || return 1
        alias homebrewupdate='brew update && brew upgrade --formulae && brew cu --yes && cd /opt/homebrew && git stash pop &>/dev/null || true && cd -'
    fi
    # END HOMEBREW

    # BEGIN MICROMAMBA
    local mamba_url mamba_env
    if __missing micromamba --help; then
        mgr="$(__package_manager micromamba-static micromamba)"
        if [ "$mgr" = "manual" ]; then
            if [ "$os" != "Linux" ] || [ "$arch" != "x86_64" ]; then
                __eprint "Manual micromamba install only for Linux 64"
                return 1
            fi
            mamba_url="https://micro.mamba.pm/api/micromamba/linux-64/latest"
            curl -sL "$mamba_url" | tar -xjO bin/micromamba >"$XDG_BIN_HOME/micromamba"
            [ "$?" -ne 0 ] && return 1
            chmod +x "$XDG_BIN_HOME/micromamba" || return 1
        fi
    fi
    alias conda='micromamba'
    mamba_env="$(command micromamba shell hook --shell zsh)"
    [ "$?" -ne 0 ] && return 1
    eval "$mamba_env" || return 1
    export MAMBA_ROOT_PREFIX="$XDG_DATA_HOME/micromamba"
    # END MICROMAMBA

    # BEGIN GO
    local latest_go
    PATH="$XDG_DATA_HOME/go/bin:$XDG_DATA_HOME/golang/bin:$PATH"
    if __missing go help; then
        mgr="$(__package_manager go golang)"
        if [ "$mgr" = "manual" ]; then
            if [ "$os" != "Linux" ] || [ "$arch" != "x86_64" ]; then
                __eprint "Manual go install only for Linux 64"
                return 1
            fi
            tmpdir="$(mktemp -d)"
            trap 'rm -rf "$tmpdir"' EXIT INT TERM
            latest_go="$(curl -sL "https://go.dev/VERSION?m=text" | head -n 1)"
            curl -sL "https://go.dev/dl/$latest_go.linux-amd64.tar.gz" | tar -xzC "$tmpdir"
            mv "$tmpdir/go" "$XDG_DATA_HOME/golang" || return 1
            rm -rf "$tmpdir"
            trap - EXIT INT TERM
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
        curl -sL https://sh.rustup.rs | sh -s -- \
            --default-toolchain nightly-2026-01-28 --no-update-default-toolchain --no-modify-path -y \
            &>/dev/null
    fi
    # END RUST

    # BEGIN PYTHON
    local uvc_env
    if __missing uv --help; then
        mgr="$(__package_manager uv "")"
        [ "$?" -ne 0 ] && return 1
        if [ "$mgr" = "manual" ]; then
            command cargo install uv --root "$LOCAL_HOME" || return 1
        fi
    fi
    if __missing uvc --help; then
        mgr="$(__package_manager uvc "")"
        [ "$?" -ne 0 ] && return 1
        if [ "$mgr" = "manual" ]; then
            curl -sL "https://github.com/audivir/uvc/raw/refs/heads/main/uvc" >"$XDG_BIN_HOME/uvc" || return 1
            chmod +x "$XDG_BIN_HOME/uvc" || return 1
        fi
    fi
    uvc_env="$(command uvc shell zsh)"
    [ "$?" -ne 0 ] && return 1
    eval "$uvc_env" || return 1
    # END PYTHON

    # BEGIN EXTRA TOOLS
    if __missing bat --help; then
        mgr="$(__package_manager bat bat)"
        [ "$?" -ne 0 ] && return 1
        if [ "$mgr" = "apt" ]; then
            sudo ln -sf /usr/bin/batcat /usr/local/bin/bat || return 1
        elif [ "$mgr" = "manual" ]; then
            cargo install bat --root "$LOCAL_HOME" || return 1
        fi
    fi

    if __missing micro --help; then
        mgr="$(__package_manager micro micro)"
        [ "$?" -ne 0 ] && return 1
        if [ "$mgr" = "manual" ]; then
            tmpdir="$(mktemp -d)"
            trap 'rm -rf "$tmpdir"' EXIT INT TERM
            git clone https://github.com/micro-editor/micro "$tmpdir" --depth 1 --branch master || return 1
            pushd "$tmpdir"
            CGO_ENABLED=1 make build || return 1
            mv micro "$XDG_BIN_HOME/micro" || return 1
            popd
            rm -rf "$tmpdir"
            trap - EXIT INT TERM
        fi
    fi
    # END EXTRA TOOLS

    # BEGIN ALIASES
    alias b="bat --paging=never --style=plain --tabs=4"
    alias sb="sudo bat --paging=never --style=plain --tabs=4"
    # END ALIASES

    export PATH

    # BEGIN THEME VIEWER
    local theme_viewer
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
        # '1,/^# BEGIN CUSTOM/d' deletes everything from line 1
        # up to and including the marker, leaving only the custom code.
        sed '1,/^# BEGIN CUSTOM/d' "$HOME/.zshrc" >> "$tmp_file"
    fi

    mv "$tmp_file" "$HOME/.zshrc"
    echo "Update complete."

    trap - EXIT INT TERM
}

__init_shell

# BEGIN CUSTOM
