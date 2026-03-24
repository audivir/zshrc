#!/usr/bin/env zsh
# shellcheck shell=bash
# shellcheck disable=SC1091
set -euo pipefail

. "$ZSHSETUP_HOME/packages/helper.sh"

name="bat"
local_bin="$XDG_BIN_HOME/bat"

# check the currently installed version, echo "" if not installed
check() {
  2>/dev/null "$local_bin" --version | awk '{print $2}' || echo ""
}

# fetch the latest version
fetch() {
  get_latest_crate bat
}

# install the most recent version
install() {
    local version
    version="$1"
    cargo install bat --version "$version" --root "$LOCAL_HOME"
}

# uninstall the installed package
uninstall() {
  rm "$local_bin"
}

main "$name" "$@"
