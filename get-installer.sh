#!/usr/bin/env bash
# FleetDeck Agent installer downloader for macOS.
#
# Detects the platform, downloads the matching installer and verifies its
# SHA-256 against the published checksums. It never runs the installer.
#
# Usage:
#   chmod +x get-installer.sh
#   ./get-installer.sh            # saves into ./FleetDeck
#   ./get-installer.sh ~/Downloads
set -euo pipefail

REPO="${FLEETDECK_REPO:-jobongriff123-lab/fleetdeck-agent-installer}"
TAG="${FLEETDECK_TAG:-latest}"
DEST="${1:-$PWD/FleetDeck}"

EXE_SHA="daaa8956ccb04d8f50aec2bb0cd39155e1ba223779588e785ba6931b154e0f4f"
DMG_SHA="0c24f2a4dea3b16a0540a931d25b26e40e04a9f94fd54e0f3801426db92013c0"

case "$(uname -s)" in
  Darwin)
    ASSET="FleetDeck-Agent-Setup.dmg"
    SHA="$DMG_SHA"
    ;;
  Linux)
    echo "No Linux build is published. Windows and macOS builds exist."
    exit 1
    ;;
  *)
    echo "Unsupported platform: $(uname -s)"
    exit 1
    ;;
esac

mkdir -p "$DEST"
if [ "$TAG" = "latest" ]; then
  URL="https://github.com/$REPO/releases/latest/download/$ASSET"
else
  URL="https://github.com/$REPO/releases/download/$TAG/$ASSET"
fi

echo "Downloading $ASSET from $URL"
curl -fL --progress-bar -o "$DEST/$ASSET" "$URL"

if command -v shasum >/dev/null 2>&1; then
  GOT="$(shasum -a 256 "$DEST/$ASSET" | awk "{print \$1}")"
else
  GOT="$(sha256sum "$DEST/$ASSET" | awk "{print \$1}")"
fi

if [ "$GOT" != "$SHA" ]; then
  echo "Checksum mismatch for $ASSET. Expected $SHA, got $GOT" >&2
  exit 1
fi

echo ""
echo "Saved    : $DEST/$ASSET"
echo "SHA-256 : $GOT   (verified)"
echo ""
echo "Open the disk image and run the installer inside it."
