#!/bin/sh
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
    arch="$arch"
else
    echo "Unsupported architecture: $arch" >&2
    exit 1
fi

tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT INT TERM
curl -L "https://micro.mamba.pm/api/micromamba/$os-$arch/latest" | tar -xjO bin/micromamba >"$tmpfile" || exit 1
chmod +x "$tmpfile" || exit 1
mv "$tmpfile"
trap - EXIT INT TERM
