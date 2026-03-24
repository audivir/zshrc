#!/bin/sh
# shellcheck shell=sh

__available() {
    local cmd
    cmd="$1"
    shift
    command "$cmd" "$@" &>/dev/null
}

if [ ! __available curl --help ] || [ ! __available git --help ]; then
    echo "curl and git required!"
    exit 1
fi

if [ ! __available zsh ]; then
    curl --fail-with-body -L https://raw.githubusercontent.com/romkatv/zsh-bin/master/install | sh -s -- -d ~/.local -e "no" || exit 1
    ZSH_BIN="~/.local/bin/zsh"
else
    ZSH_BIN="zsh"
fi

git archive --remote=ssh://git@git.audivir.de/tihoph/zshrc HEAD .zshrc | tar xO | "$ZSH_BIN" -s -- install
