#!/bin/sh
tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT INT TERM
curl -L "https://github.com/audivir/uvc/raw/refs/heads/main/uvc" -o "$tmpfile" || exit 1
chmod +x "$tmpfile" || exit 1
mv "$tmpfile" "$XDG_BIN_HOME/uvc" || exit 1
trap - EXIT INT TERM
