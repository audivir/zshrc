#!/usr/bin/env zsh
# shellcheck shell=bash
set -euo pipefail

os="$(uname)"
arch="$(uname -m)"
if [ "$os" = "Linux" ]; then
    os="linux"
elif [ "$os" = "Darwin" ]; then
    os="osx"
else
    echo "Unsupported OS: $os" >&2
    exit 1
fi

if [ "$arch" = "x86_64" ] || [ "$arch" = "amd64" ]; then
    arch="64"
elif [ "$arch" = "arm64" ] || [ "$arch" = "aarch64" ]; then
    # shellcheck disable=SC2269
    arch="$arch"
else
    echo "Unsupported architecture: $arch" >&2
    exit 1
fi

tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT INT TERM
latest_release="$(curl --fail-with-body -L https://api.github.com/repos/mamba-org/micromamba-releases/releases/latest | jq -r .tag_name)"
curl --fail-with-body -L "https://github.com/mamba-org/micromamba-releases/releases/download/$latest_release/micromamba-$os-$arch" -o "$tmpfile"
chmod +x "$tmpfile"
mv "$tmpfile" "$XDG_BIN_HOME/micromamba"
trap - EXIT INT TERM
