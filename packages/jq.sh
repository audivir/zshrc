#!/usr/bin/env zsh
# shellcheck shell=bash
# shellcheck disable=SC1091
set -euo pipefail

. "$ZSHSETUP_HOME/packages/helper.sh"

name="jq."
local_bin="$XDG_BIN_HOME/jq"

# check the currently installed version, echo "" if not installed
check() {
    local version
    version=$(2>/dev/null "$local_bin" --version) || return 0
    echo "${version%-apple}"
}

# fetch the latest version
fetch() {
    get_latest_github jqlang/jq
}

# install the most recent version
install() {
    local version
    version="$1"
    set_os_arch "linux" "amd64" "linux" "amd64" "macos" "arm64" "macos" "arm64"
    tmpfile=$(mktemp)
    jq_bootstrap=$(mktemp)
    trap 'rm -f "$tmpfile" "$jq_bootstrap"' EXIT INT TERM
    curl --fail-with-body -L "https://github.com/jqlang/jq/releases/download/jq-1.8.0/jq-$os-$arch" -o "$jq_bootstrap"
    chmod +x "$jq_bootstrap"
    curl --fail-with-body -L "https://github.com/jqlang/jq/releases/download/$version/jq-$os-$arch" -o "$tmpfile"
    chmod +x "$tmpfile"
    mv "$tmpfile" "$XDG_BIN_HOME/jq"
    rm "$jq_bootstrap"
    trap - EXIT INT TERM
}

# uninstall the installed package
uninstall() {
    rm "$local_bin"
}

main "$name" "$@"
