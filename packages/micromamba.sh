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
curl -L "https://micro.mamba.pm/api/micromamba/$os-$arch/latest" | tar -xjO bin/micromamba >"$tmpfile"
chmod +x "$tmpfile"
mv "$tmpfile" "$XDG_BIN_HOME/micromamba"
trap - EXIT INT TERM
