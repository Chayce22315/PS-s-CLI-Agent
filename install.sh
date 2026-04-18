#!/bin/sh
# Install a small command that prints "testing completed!".
# Works with sh on Linux, ash (Alpine/apk), and sh/zsh on macOS.

set -eu

umask 022

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
src="$script_dir/testing-completed"

if ! [ -f "$src" ]; then
	printf '%s\n' "install.sh: missing companion file: $src" >&2
	exit 1
fi

# Default: per-user install. Override with PREFIX=/usr/local sh install.sh
prefix=${PREFIX:-"$HOME/.local"}
bindir="$prefix/bin"

mkdir -p "$bindir"
cp "$src" "$bindir/testing-completed"
chmod 755 "$bindir/testing-completed"

printf '%s\n' "Installed: $bindir/testing-completed"

case ":${PATH:-}:" in
*":$bindir:"*) ;;
*)
	printf '%s\n' "Add this directory to PATH if needed:" >&2
	printf '%s\n' "  export PATH=\"$bindir:\$PATH\"" >&2
	;;
esac
