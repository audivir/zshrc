#!/usr/bin/env zsh
# shellcheck shell=bash
set -euo pipefail

os="$(uname)"
if [ "$os" = "Linux" ]; then
    os="linux"
elif [ "$os" = "Darwin" ]; then
    os="macos"
else
    echo "Unsupported OS: $os" >&2
    exit 1
fi

arch="$(uname -m)"
if [ "$arch" = "x86_64" ] || [ "$arch" = "amd64" ]; then
    arch="amd64"
elif [ "$arch" = "arm64" ] || [ "$arch" = "aarch64" ]; then
    arch="arm64"
else
    echo "Unsupported architecture: $arch" >&2
    exit 1
fi

tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT INT TERM
latest_release="$(curl --fail-with-body -L https://api.github.com/repos/jqlang/jq/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')"
curl --fail-with-body -L "https://github.com/jqlang/jq/releases/download/$latest_release/jq-$os-$arch" -o "$tmpfile"
chmod +x "$tmpfile"
mv "$tmpfile" "$XDG_BIN_HOME/jq"
trap - EXIT INT TERM
