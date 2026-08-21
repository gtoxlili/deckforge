#!/bin/sh
# DeckForge installer.
#
#   curl -fsSL https://deckforge.gtio.work/install.sh | sh
#
# Env:
#   DECKFORGE_VERSION      pin a release tag (default: latest)
#   DECKFORGE_INSTALL_DIR  install target (default: ~/.local/bin)
#
# Messages are English and state facts only, matching the CLI: this script's
# output is read by the agent that runs it, not only by a person.
set -eu

# Everything comes from the vendor service rather than from GitHub directly.
# GitHub is reachable from the service and frequently is not from where the
# customer sits, so the download path has one host on it and that host is
# behind a CDN with China presence.
ORIGIN="${DECKFORGE_ORIGIN:-https://deckforge.gtio.work}"
INSTALL_DIR="${DECKFORGE_INSTALL_DIR:-$HOME/.local/bin}"

say()  { printf 'deckforge: %s\n' "$1" >&2; }
die()  { printf 'deckforge: error: %s\n' "$1" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"; }

need uname
need mkdir
if command -v curl >/dev/null 2>&1; then
  fetch() { curl -fsSL "$1"; }
  fetch_to() { curl -fsSL -o "$2" "$1"; }
elif command -v wget >/dev/null 2>&1; then
  fetch() { wget -qO- "$1"; }
  fetch_to() { wget -qO "$2" "$1"; }
else
  die "neither curl nor wget is available"
fi

os=$(uname -s | tr '[:upper:]' '[:lower:]')
arch=$(uname -m)
case "$os" in
  darwin) ;;
  mingw*|msys*|cygwin*) os=windows ;;
  linux) die "deckforge ships macOS and Windows builds only; there is no Linux release" ;;
  *) die "unsupported operating system: $os" ;;
esac
case "$arch" in
  x86_64|amd64) arch=amd64 ;;
  arm64|aarch64) arch=arm64 ;;
  *) die "unsupported architecture: $arch" ;;
esac

version="${DECKFORGE_VERSION:-}"
if [ -z "$version" ]; then
  say "resolving the latest release"
  version=$(fetch "$ORIGIN/v1/version" \
    | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)
  [ -n "$version" ] || die "could not resolve the latest release from $ORIGIN"
fi

ext=""; [ "$os" = windows ] && ext=".exe"
asset="deckforge-${os}-${arch}${ext}"
base="$ORIGIN/dl"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT INT TERM

say "downloading $asset ($version)"
fetch_to "$base/$asset" "$tmp/$asset" || die "download failed: $base/$asset"

# Checksum verification is best-effort: a missing sha256 tool should not
# block an install, but a MISMATCH always must.
if fetch_to "$base/checksums.txt" "$tmp/checksums.txt" 2>/dev/null; then
  want=$(grep " $asset\$" "$tmp/checksums.txt" | awk '{print $1}' | head -n1)
  if [ -n "$want" ]; then
    if command -v shasum >/dev/null 2>&1; then
      got=$(shasum -a 256 "$tmp/$asset" | awk '{print $1}')
    elif command -v sha256sum >/dev/null 2>&1; then
      got=$(sha256sum "$tmp/$asset" | awk '{print $1}')
    else
      got=""
      say "no sha256 utility found; checksum not verified"
    fi
    [ -z "$got" ] || [ "$got" = "$want" ] || die "checksum mismatch: expected $want, got $got"
  fi
fi

mkdir -p "$INSTALL_DIR"
target="$INSTALL_DIR/deckforge$ext"
mv "$tmp/$asset" "$target"
chmod +x "$target"

say "installed $target"
case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *) say "$INSTALL_DIR is not on PATH" ;;
esac

"$target" version >/dev/null 2>&1 || die "the installed binary is not executable"
say "DeckForge $("$target" version) ready at $target"
