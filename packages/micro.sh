#/bin/sh
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT INT TERM
cd "$tmpdir"
git clone https://github.com/micro-editor/micro "$tmpdir" --depth 1 --branch master || exit 1
CGO_ENABLED=1 make build || exit 1
mv micro "$XDG_BIN_HOME/micro" || exit 1
rm -rf "$tmpdir"
trap - EXIT INT TERM
