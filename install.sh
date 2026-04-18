#!/bin/sh
# Install a small command that prints "testing completed!".
# Works with sh on Linux, ash (Alpine/apk / iSH), and sh/zsh on macOS.
#
# Order of operations:
#   1. If needed: on apk-based systems, install missing host tools (see INSTALL_DEPS).
#   2. Copy testing-completed into PREFIX/bin and chmod +x.
#
# Environment:
#   PREFIX           install root (default: $HOME/.local)
#   INSTALL_DEPS=1   on apk systems: apk update, then curl or wget + ca-certificates if missing
#   SKIP_APK=1       never run apk (fail if cp/mkdir/chmod are missing)

set -eu

umask 022

_apk() {
	if [ "$(id -u)" -eq 0 ]; then
		apk "$@"
	elif command -v sudo >/dev/null 2>&1; then
		sudo apk "$@"
	else
		apk "$@"
	fi
}

ensure_host_dependencies() {
	need_core=
	for c in cp mkdir chmod; do
		command -v "$c" >/dev/null 2>&1 || need_core=1
	done

	need_fetch=
	if [ "${INSTALL_DEPS:-0}" = "1" ]; then
		if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
			need_fetch=1
		fi
	fi

	if [ -z "${need_core:-}" ] && [ -z "${need_fetch:-}" ]; then
		return 0
	fi

	if [ "${SKIP_APK:-0}" = "1" ] || ! command -v apk >/dev/null 2>&1; then
		if [ -n "${need_core:-}" ]; then
			printf '%s\n' "install.sh: missing cp, mkdir, or chmod; install busybox/coreutils or run on Alpine/iSH with apk." >&2
			exit 1
		fi
		if [ -n "${need_fetch:-}" ]; then
			printf '%s\n' "install.sh: INSTALL_DEPS=1 but no curl/wget and apk disabled or unavailable." >&2
			exit 1
		fi
		return 0
	fi

	printf '%s\n' "install.sh: installing missing host tools via apk..." >&2
	_apk update
	if [ -n "${need_core:-}" ]; then
		_apk add --no-cache busybox 2>/dev/null || true
	fi
	if [ -n "${need_fetch:-}" ]; then
		_apk add --no-cache ca-certificates curl 2>/dev/null \
			|| _apk add --no-cache ca-certificates wget 2>/dev/null \
			|| true
	fi

	for c in cp mkdir chmod; do
		if ! command -v "$c" >/dev/null 2>&1; then
			printf '%s\n' "install.sh: still missing required command: $c" >&2
			exit 1
		fi
	done
	if [ "${INSTALL_DEPS:-0}" = "1" ]; then
		if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
			printf '%s\n' "install.sh: INSTALL_DEPS=1 but curl/wget could not be installed." >&2
			exit 1
		fi
	fi
}

ensure_host_dependencies

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
