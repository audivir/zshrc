#!/usr/bin/env zsh
# shellcheck shell=bash
set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT INT TERM
cd "$tmpdir"
git clone https://github.com/micro-editor/micro "$tmpdir" --depth 1 --branch master
CGO_ENABLED=1 make build
mv micro "$XDG_BIN_HOME/micro"
rm -rf "$tmpdir"
trap - EXIT INT TERM
