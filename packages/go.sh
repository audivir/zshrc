#!/usr/bin/env zsh
# shellcheck shell=bash
# shellcheck disable=SC1091
set -euo pipefail

. "$ZSHSETUP_HOME/packages/helper.sh"

name="go"
local_bin="$XDG_DATA_HOME/golang/bin/go"

# check the currently installed version, echo "" if not installed
check() {
    2>/dev/null "$local_bin" version | awk '{print $3}' || echo ""
}

# fetch the latest version
fetch() {
    curl --fail-with-body -L "https://go.dev/VERSION?m=text" | head -n 1
}

# install the most recent version
install() {
    local version
    version="$1"
    set_os_arch "linux" "amd64" "linux" "arm64" "darwin" "amd64" "darwin" "arm64"
    tmpdir="$(mktemp -d)"
    trap 'rm -rf "$tmpdir"' EXIT INT TERM
    curl --fail-with-body -L "https://go.dev/dl/$version.$os-$arch.tar.gz" | tar -xzC "$tmpdir"
    mv "$tmpdir/go" "$XDG_DATA_HOME/golang"
    rm -rf "$tmpdir"
    trap - EXIT INT TERM
}

# uninstall the installed package
uninstall() {
    rm -r "$XDG_DATA_HOME/golang"
}

main "$name" "$@"
