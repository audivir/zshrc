#!/bin/sh
# shellcheck shell=sh

__available() {
    cmd="$1"
    shift
    command "$cmd" "$@" >/dev/null 2>&1
}

if [ -z "$HOME" ]; then
    echo "HOME must be set"
    exit 1
fi

if ! __available curl --help || ! __available git --help; then
    echo "curl and git required!"
    exit 1
fi

if ! __available zsh --help; then
    curl --fail-with-body -L https://raw.githubusercontent.com/romkatv/zsh-bin/master/install | sh -s -- -d "$HOME/.local" -e "no" || exit 1
    ZSH_BIN="$HOME/.local/bin/zsh"
else
    ZSH_BIN="zsh"
fi

curl --fail-with-body https://github.com/audivir/zshrc/raw/refs/heads/main/.zshrc | "$ZSH_BIN" -s -- install
