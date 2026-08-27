#!/bin/bash
# build-dmg.sh — build a signed, notarized DMG of Input Source Pro.
#
# Env vars:
#   SIGNING_IDENTITY  Required codesigning identity from the local keychain.
#   DEVELOPMENT_TEAM  Required Apple Developer Team ID.
#   DMG_OUTPUT_DIR    Where to write the DMG. Default: dist
#   CONFIG            Build configuration for the DMG. Default: Release
#
# Notarization (optional — if unset, the DMG is still built+signed and the
# script stops cleanly before notarization):
#   API key path (recommended):
#     NOTARY_KEY_ID, NOTARY_ISSUER, NOTARY_KEY  (path to AuthKey_<id>.p8)
#   Apple ID path:
#     NOTARY_APPLE_ID, NOTARY_PASSWORD, NOTARY_TEAM_ID
#
# Optional branded background image at scripts/dmg-background.png enables the
# "luxurious" DMG background; icon positioning + /Applications symlink are
# applied regardless.

set -euo pipefail

# --- repo layout -------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

PROJECT="Input Source Pro.xcodeproj"
SCHEME="Input Source Pro"
APP_NAME="Input Source Pro"

# --- config ------------------------------------------------------------------
SIGNING_IDENTITY="${SIGNING_IDENTITY:-}"
DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-}"
CONFIG="${CONFIG:-Release}"
DMG_OUTPUT_DIR="${DMG_OUTPUT_DIR:-dist}"
BUILD_DIR="build"
ENTITLEMENTS="Input Source Pro/Resources/Signing.entitlements"
DMG_BACKGROUND="$SCRIPT_DIR/dmg-background.png"

# Finder stores DMG layout in logical points. On Retina displays these values
# appear as 2x pixels in screenshots.
DMG_WINDOW_X=100
DMG_WINDOW_Y=100
DMG_WINDOW_WIDTH=551
DMG_WINDOW_HEIGHT=414
DMG_WINDOW_RIGHT=$(( DMG_WINDOW_X + DMG_WINDOW_WIDTH ))
DMG_WINDOW_BOTTOM=$(( DMG_WINDOW_Y + DMG_WINDOW_HEIGHT ))
DMG_ICON_SIZE=96
DMG_APP_ICON_X=140
DMG_APP_ICON_Y=145
DMG_APPLICATIONS_ICON_X=395
DMG_APPLICATIONS_ICON_Y=145

log() { printf '\033[1;34m[dmg]\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m[dmg error]\033[0m %s\n' "$*" >&2; }

# --- preflight: signing config + identity must exist -------------------------
if [[ -z "$SIGNING_IDENTITY" ]]; then
  err "Missing required environment variable: SIGNING_IDENTITY"
  exit 1
fi

if [[ -z "$DEVELOPMENT_TEAM" ]]; then
  err "Missing required environment variable: DEVELOPMENT_TEAM"
  exit 1
fi

log "Verifying signing identity is present in the keychain..."
if ! security find-identity -v -p codesigning | grep -qF "$SIGNING_IDENTITY"; then
  err "Signing identity not found: $SIGNING_IDENTITY"
  err "Available identities:"
  security find-identity -v -p codesigning >&2 || true
  exit 1
fi

# --- 1. archive + export with Developer ID distribution ---------------------
# A plain `xcodebuild build` signs with --timestamp=none and injects the
# com.apple.security.get-task-allow entitlement, both of which make Apple
# notarization fail with "Invalid". Archiving then exporting with the
# developer-id method adds a secure timestamp and strips get-task-allow.
log "Archiving $CONFIG with identity '$SIGNING_IDENTITY' (team $DEVELOPMENT_TEAM)..."
# Automatic signing can't find a provisioning profile locally for a bundle id
# that isn't registered for Developer ID distribution, so force Manual style.
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
rm -rf "$ARCHIVE_PATH" "$EXPORT_DIR"

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -derivedDataPath "$BUILD_DIR" \
  -archivePath "$ARCHIVE_PATH" \
  CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
  archive

EXPORT_OPTIONS="$BUILD_DIR/ExportOptions.plist"
cat > "$EXPORT_OPTIONS" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>developer-id</string>
  <key>teamID</key>
  <string>$DEVELOPMENT_TEAM</string>
  <key>signingStyle</key>
  <string>manual</string>
  <key>signingCertificate</key>
  <string>Developer ID Application</string>
</dict>
</plist>
EOF

log "Exporting archive with Developer ID distribution method..."
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS" \
  -exportPath "$EXPORT_DIR"

APP_PATH="$EXPORT_DIR/$APP_NAME.app"
if [[ ! -d "$APP_PATH" ]]; then
  err "Exported app not found at: $APP_PATH"
  exit 1
fi
log "Exported app: $APP_PATH"

# --- 2. verify the app + embedded frameworks --------------------------------
log "Verifying deep signature..."
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
log "Designated requirement:"
codesign -d -r- -- "$APP_PATH" 2>&1 || true

# --- 3. read version from the built app --------------------------------------
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist" 2>/dev/null || true)"
if [[ -z "$VERSION" ]]; then
  err "Could not read CFBundleShortVersionString from built app."
  exit 1
fi
log "App version: $VERSION"

# --- 4. build the luxurious DMG ---------------------------------------------
mkdir -p "$DMG_OUTPUT_DIR"
STAGING="$(mktemp -d -t inputsourcepro-dmg)"
trap 'rm -rf "$STAGING"; [[ -n "${RW_DMG:-}" ]] && hdiutil detach "${MOUNT_POINT:-/dev/null}" -force >/dev/null 2>&1 || true; rm -f "${RW_DMG:-}"' EXIT

log "Staging DMG contents in $STAGING..."
cp -R "$APP_PATH" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

VOLNAME="$APP_NAME $VERSION"
DMG_NAME="$APP_NAME-$VERSION.dmg"
DMG_PATH="$DMG_OUTPUT_DIR/$DMG_NAME"
RW_DMG="$STAGING/$DMG_NAME"

# Size the read-write image to fit the app + slack for layout/background.
APP_SIZE_KB="$(du -sk "$APP_PATH" | awk '{print $1}')"
IMAGE_SIZE_KB=$(( APP_SIZE_KB + 20480 ))
log "Creating read-write DMG (${IMAGE_SIZE_KB}KB)..."
# NB: hdiutil create -srcfolder yields a read-only image that cannot be
# attached read-write, so we create a blank UDRW image, attach it, and copy in.
hdiutil create -ov -volname "$VOLNAME" -fs HFS+ \
  -size "${IMAGE_SIZE_KB}k" "$RW_DMG"

# Mount RW dmg and apply layout via Finder/AppleScript.
MOUNT_POINT="$(hdiutil attach -readwrite -nobrowse "$RW_DMG" | grep -m1 '/Volumes' | sed 's/.*\/Volumes/\/Volumes/' | xargs)"
log "Mounted RW image at: $MOUNT_POINT"

log "Copying app + Applications symlink into the image..."
cp -R "$STAGING/$APP_NAME.app" "$MOUNT_POINT/"
ln -s /Applications "$MOUNT_POINT/Applications"
log "Applying DMG layout (${DMG_WINDOW_WIDTH}x${DMG_WINDOW_HEIGHT}, icon size ${DMG_ICON_SIZE})..."

APPLESCRIPT='tell application "Finder"
  tell disk "'"$VOLNAME"'"
    open
    delay 1
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set pathbar visible of container window to false
    set sidebar width of container window to 0
    set the bounds of container window to {'"$DMG_WINDOW_X"', '"$DMG_WINDOW_Y"', '"$DMG_WINDOW_RIGHT"', '"$DMG_WINDOW_BOTTOM"'}'
if [[ -f "$DMG_BACKGROUND" ]]; then
  log "Using branded background: $DMG_BACKGROUND"
  cp "$DMG_BACKGROUND" "$MOUNT_POINT/.background.png"
fi
APPLESCRIPT+='
    set theViewOptions to the icon view options of container window
    set arrangement of theViewOptions to not arranged
    set icon size of theViewOptions to '"$DMG_ICON_SIZE"'
    set label position of theViewOptions to bottom'
if [[ -f "$DMG_BACKGROUND" ]]; then
  APPLESCRIPT+='
    set background picture of theViewOptions to file ".background.png" of disk "'"$VOLNAME"'"'
fi
APPLESCRIPT+='
    set position of item "'"$APP_NAME"'.app" of container window to {'"$DMG_APP_ICON_X"', '"$DMG_APP_ICON_Y"'}
    set position of item "Applications" of container window to {'"$DMG_APPLICATIONS_ICON_X"', '"$DMG_APPLICATIONS_ICON_Y"'}
    close
    open
    update without registering applications
  end tell
end tell'
osascript -e "$APPLESCRIPT"

# Give Finder a moment to persist layout, then detach.
sleep 2
hdiutil detach "$MOUNT_POINT" -force >/dev/null 2>&1
MOUNT_POINT=""
log "Converting to compressed read-only DMG..."
hdiutil convert "$RW_DMG" -format UDZO -imagekey zlib-level=9 -ov -o "$DMG_PATH"
rm -f "$RW_DMG"; RW_DMG=""
log "DMG written: $DMG_PATH"

# --- 5. sign the DMG ---------------------------------------------------------
log "Signing the DMG..."
codesign --sign "$SIGNING_IDENTITY" --timestamp "$DMG_PATH"
codesign --verify --verbose=2 "$DMG_PATH"

# --- 6. notarize (only if credentials are provided) -------------------------
has_api_key=0
has_apple_id=0
if [[ -n "${NOTARY_KEY_ID:-}" && -n "${NOTARY_ISSUER:-}" && -n "${NOTARY_KEY:-}" && -f "${NOTARY_KEY}" ]]; then
  has_api_key=1
elif [[ -n "${NOTARY_APPLE_ID:-}" && -n "${NOTARY_PASSWORD:-}" && -n "${NOTARY_TEAM_ID:-}" ]]; then
  has_apple_id=1
fi

if [[ $has_api_key -eq 0 && $has_apple_id -eq 0 ]]; then
  log "Notarization skipped (no NOTARY_* credentials set)."
  log "Set one of:"
  log "  API key path: NOTARY_KEY_ID / NOTARY_ISSUER / NOTARY_KEY (path to AuthKey_<id>.p8)"
  log "  Apple ID path: NOTARY_APPLE_ID / NOTARY_PASSWORD / NOTARY_TEAM_ID"
  log "Signed DMG (not notarized): $DMG_PATH"
  exit 0
fi

log "Submitting DMG to Apple notarization (this may take several minutes)..."
NOTARY_OUT="$(mktemp -t notaryout)"
if [[ $has_api_key -eq 1 ]]; then
  xcrun notarytool submit "$DMG_PATH" \
    --key-id "$NOTARY_KEY_ID" \
    --issuer "$NOTARY_ISSUER" \
    --key "$NOTARY_KEY" \
    --wait > "$NOTARY_OUT" 2>&1 || { cat "$NOTARY_OUT"; rm -f "$NOTARY_OUT"; exit 1; }
  NOTARY_AUTH=(--key-id "$NOTARY_KEY_ID" --issuer "$NOTARY_ISSUER" --key "$NOTARY_KEY")
else
  xcrun notarytool submit "$DMG_PATH" \
    --apple-id "$NOTARY_APPLE_ID" \
    --password "$NOTARY_PASSWORD" \
    --team-id "$NOTARY_TEAM_ID" \
    --wait > "$NOTARY_OUT" 2>&1 || { cat "$NOTARY_OUT"; rm -f "$NOTARY_OUT"; exit 1; }
  NOTARY_AUTH=(--apple-id "$NOTARY_APPLE_ID" --password "$NOTARY_PASSWORD" --team-id "$NOTARY_TEAM_ID")
fi
cat "$NOTARY_OUT"

if ! grep -q 'status: Accepted' "$NOTARY_OUT"; then
  SUBMISSION_ID="$(grep -E '^\s*id:' "$NOTARY_OUT" | head -1 | awk '{print $2}')"
  rm -f "$NOTARY_OUT"
  err "Notarization was NOT accepted by Apple — cannot staple."
  if [[ -n "$SUBMISSION_ID" ]]; then
    err "Fetching notarization log for submission $SUBMISSION_ID..."
    xcrun notarytool log "$SUBMISSION_ID" "${NOTARY_AUTH[@]}" 2>&1 || true
  fi
  err "Fix the issues above and re-run make dmg."
  exit 1
fi
rm -f "$NOTARY_OUT"

log "Stapling notarization ticket..."
xcrun stapler staple "$DMG_PATH"
xcrun stapler validate "$DMG_PATH"

log "Done. Notarized DMG: $DMG_PATH"
log "App Gatekeeper assessment:"
spctl --assess --type execute --verbose=4 -- "$APP_PATH" 2>&1 || true
