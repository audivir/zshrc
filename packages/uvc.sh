#!/usr/bin/env zsh
# shellcheck shell=bash
set -euo pipefail

tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT INT TERM
curl -L "https://github.com/audivir/uvc/raw/refs/heads/main/uvc" -o "$tmpfile"
chmod +x "$tmpfile"
mv "$tmpfile" "$XDG_BIN_HOME/uvc"
trap - EXIT INT TERM
