#!/usr/bin/env bash
set -euo pipefail

MODE="${1:---verify}"
APP_NAME="Bonsai"
BUNDLE_ID="dev.bonsai.Bonsai"
MIN_SYSTEM_VERSION="14.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_FILE="$ROOT_DIR/VERSION"
DIST_DIR="$ROOT_DIR/dist/release"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
ARCHIVE_PATH="$DIST_DIR/$APP_NAME.zip"
APP_ICON_SOURCE="$ROOT_DIR/Assets/AppIcon/Bonsai.icns"
APP_MARK_SOURCE="$ROOT_DIR/Assets/AppIcon/bonsai-worktree-topology.svg"

usage() {
  cat >&2 <<USAGE
usage: script/package_release.sh [--verify|--archive|--notarize|--check-credentials]

  --verify             Build, stage, ad-hoc sign, and validate the release app bundle.
  --archive            Build, Developer ID sign, validate, and write dist/release/Bonsai.zip.
  --notarize           Build, Developer ID sign, archive, submit to notarytool, and staple.
  --check-credentials  Validate Developer ID and notarytool credentials without packaging.

Environment:
  BONSAI_CODESIGN_IDENTITY  Required for --archive and --notarize.
  BONSAI_NOTARY_PROFILE     Required for --notarize; xcrun notarytool keychain profile.
  BONSAI_VERSION            Optional CFBundleShortVersionString override.
  BONSAI_BUILD_NUMBER       Optional CFBundleVersion override.
USAGE
}

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "missing required file: $path" >&2
    exit 1
  fi
}

build_release_binary() {
  cd "$ROOT_DIR"
  swift build -c release
}

app_version() {
  if [[ -n "${BONSAI_VERSION:-}" ]]; then
    printf '%s' "$BONSAI_VERSION"
    return
  fi

  tr -d '[:space:]' <"$VERSION_FILE"
}

build_number() {
  if [[ -n "${BONSAI_BUILD_NUMBER:-}" ]]; then
    printf '%s' "$BONSAI_BUILD_NUMBER"
    return
  fi

  git -C "$ROOT_DIR" rev-list --count HEAD 2>/dev/null || printf '0'
}

stage_app_bundle() {
  local app_version build_binary build_number
  build_binary="$(swift build -c release --show-bin-path)/$APP_NAME"
  app_version="$(app_version)"
  build_number="$(build_number)"

  require_file "$build_binary"
  require_file "$APP_ICON_SOURCE"
  require_file "$APP_MARK_SOURCE"

  rm -rf "$APP_BUNDLE"
  mkdir -p "$APP_MACOS" "$APP_RESOURCES"
  cp "$build_binary" "$APP_BINARY"
  chmod +x "$APP_BINARY"
  cp "$APP_ICON_SOURCE" "$APP_RESOURCES/Bonsai.icns"
  cp "$APP_MARK_SOURCE" "$APP_RESOURCES/bonsai-worktree-topology.svg"

  cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleIconFile</key>
  <string>Bonsai</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$app_version</string>
  <key>CFBundleVersion</key>
  <string>$build_number</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST
}

sign_app_bundle() {
  local identity="$1"
  if [[ "$identity" != "-" ]]; then
    codesign \
      --force \
      --options runtime \
      --timestamp \
      --sign "$identity" \
      "$APP_BUNDLE"
    return
  fi

  codesign \
    --force \
    --options runtime \
    --sign "$identity" \
    "$APP_BUNDLE"
}

validate_app_bundle() {
  require_file "$APP_BINARY"
  require_file "$INFO_PLIST"
  require_file "$APP_RESOURCES/Bonsai.icns"
  require_file "$APP_RESOURCES/bonsai-worktree-topology.svg"

  plutil -lint "$INFO_PLIST" >/dev/null

  local executable
  executable="$(/usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "$INFO_PLIST")"
  if [[ "$executable" != "$APP_NAME" ]]; then
    echo "unexpected CFBundleExecutable: $executable" >&2
    exit 1
  fi

  local package_type
  package_type="$(/usr/libexec/PlistBuddy -c "Print :CFBundlePackageType" "$INFO_PLIST")"
  if [[ "$package_type" != "APPL" ]]; then
    echo "unexpected CFBundlePackageType: $package_type" >&2
    exit 1
  fi

  local icon_file
  icon_file="$(/usr/libexec/PlistBuddy -c "Print :CFBundleIconFile" "$INFO_PLIST")"
  if [[ "$icon_file" != "Bonsai" ]]; then
    echo "unexpected CFBundleIconFile: $icon_file" >&2
    exit 1
  fi

  local short_version
  short_version="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST")"
  if [[ -z "$short_version" ]]; then
    echo "missing CFBundleShortVersionString" >&2
    exit 1
  fi

  local bundle_version
  bundle_version="$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$INFO_PLIST")"
  if [[ -z "$bundle_version" ]]; then
    echo "missing CFBundleVersion" >&2
    exit 1
  fi

  codesign --verify --strict --verbose=2 "$APP_BUNDLE"
}

create_archive() {
  rm -f "$ARCHIVE_PATH"
  ditto -c -k --keepParent "$APP_BUNDLE" "$ARCHIVE_PATH"
  require_file "$ARCHIVE_PATH"
}

developer_id_identity() {
  if [[ -z "${BONSAI_CODESIGN_IDENTITY:-}" ]]; then
    echo "BONSAI_CODESIGN_IDENTITY is required for $MODE" >&2
    exit 1
  fi
  printf '%s' "$BONSAI_CODESIGN_IDENTITY"
}

notary_profile() {
  if [[ -z "${BONSAI_NOTARY_PROFILE:-}" ]]; then
    echo "BONSAI_NOTARY_PROFILE is required for --notarize" >&2
    exit 1
  fi
  printf '%s' "$BONSAI_NOTARY_PROFILE"
}

check_developer_id_identity() {
  local identity="$1"
  if [[ "$identity" != Developer\ ID\ Application:* ]]; then
    echo "BONSAI_CODESIGN_IDENTITY must be a Developer ID Application identity for public distribution: $identity" >&2
    exit 1
  fi

  if ! security find-identity -p codesigning -v | grep -F -- "$identity" >/dev/null; then
    echo "Developer ID identity is not available in the login keychain: $identity" >&2
    exit 1
  fi
}

check_notary_credentials() {
  local profile="$1"
  if ! xcrun notarytool history --keychain-profile "$profile" >/dev/null; then
    echo "notarytool keychain profile could not be validated: $profile" >&2
    exit 1
  fi
}

check_distribution_credentials() {
  local identity profile
  identity="$(developer_id_identity)"
  check_developer_id_identity "$identity"
  profile="$(notary_profile)"
  check_notary_credentials "$profile"
}

package_with_identity() {
  local identity="$1"
  build_release_binary
  stage_app_bundle
  sign_app_bundle "$identity"
  validate_app_bundle
}

case "$MODE" in
  --verify|verify)
    package_with_identity "-"
    ;;
  --archive|archive)
    package_with_identity "$(developer_id_identity)"
    create_archive
    ;;
  --notarize|notarize)
    check_distribution_credentials
    package_with_identity "$(developer_id_identity)"
    create_archive
    xcrun notarytool submit "$ARCHIVE_PATH" \
      --keychain-profile "$(notary_profile)" \
      --wait
    xcrun stapler staple "$APP_BUNDLE"
    spctl -a -vv -t exec "$APP_BUNDLE"
    ;;
  --check-credentials|check-credentials)
    check_distribution_credentials
    echo "Developer ID and notarytool credentials are available"
    ;;
  --help|-h|help)
    usage
    ;;
  *)
    usage
    exit 2
    ;;
esac

echo "Packaged $APP_BUNDLE"
