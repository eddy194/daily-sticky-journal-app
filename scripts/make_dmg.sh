#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/DailyStickyJournal/dist"

APP_PATH="${1:-}"
OUT_DMG="${2:-}"

if [[ -z "${APP_PATH}" ]]; then
  # Prefer the newest exported .app (from Xcode Organizer or xcodebuild exportArchive).
  APP_PATH="$(ls -td "$DIST_DIR"/Export-*/DailyStickyJournal.app 2>/dev/null | head -n 1 || true)"
fi

if [[ -z "${APP_PATH}" || ! -d "${APP_PATH}" ]]; then
  echo "Could not find DailyStickyJournal.app."
  echo "Pass it explicitly: scripts/make_dmg.sh /path/to/DailyStickyJournal.app [output.dmg]"
  exit 1
fi

if [[ -z "${OUT_DMG}" ]]; then
  mkdir -p "$DIST_DIR"
  OUT_DMG="$DIST_DIR/DailyStickyJournal.dmg"
fi

STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/daily-sticky-journal-dmg.XXXXXX")"
cleanup() { rm -rf "$STAGING_DIR"; }
trap cleanup EXIT

cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

rm -f "$OUT_DMG"
hdiutil create \
  -volname "Daily Sticky Journal" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  -imagekey zlib-level=9 \
  "$OUT_DMG" >/dev/null

echo "DMG created: $OUT_DMG"

