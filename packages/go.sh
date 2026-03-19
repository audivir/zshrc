#!/usr/bin/env zsh
# shellcheck shell=bash
set -euo pipefail

os="$(uname)"
if [ "$os" = "Linux" ]; then
    os="linux"
elif [ "$os" = "Darwin" ]; then
    os="darwin"
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

latest_go="$(curl --fail-with-body -L "https://go.dev/VERSION?m=text" | head -n 1)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT INT TERM
curl --fail-with-body -L "https://go.dev/dl/$latest_go.$os-$arch.tar.gz" | tar -xzC "$tmpdir"
mv "$tmpdir/go" "$XDG_DATA_HOME/golang"
rm -rf "$tmpdir"
trap - EXIT INT TERM
