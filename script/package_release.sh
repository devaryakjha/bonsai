#!/usr/bin/env bash
set -euo pipefail

MODE="${1:---verify}"
APP_NAME="Bonsai"
BUNDLE_ID="dev.bonsai.Bonsai"
MIN_SYSTEM_VERSION="14.0"
GITHUB_RELEASE_REPOSITORY="${BONSAI_GITHUB_REPOSITORY:-devaryakjha/bonsai}"
GITHUB_RELEASE_ENVIRONMENT="${BONSAI_GITHUB_RELEASE_ENVIRONMENT:-release}"
GITHUB_RELEASE_RUNNER="${BONSAI_GITHUB_RELEASE_RUNNER:-jarvis-bonsai}"

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
MANIFEST_PATH="$DIST_DIR/$APP_NAME.release.plist"
APP_ICON_SOURCE="$ROOT_DIR/Assets/AppIcon/Bonsai.icns"
APP_MARK_SOURCE="$ROOT_DIR/Assets/AppIcon/bonsai-worktree-topology.svg"

usage() {
  cat >&2 <<USAGE
usage: script/package_release.sh [--verify|--verify-archive|--archive|--notarize|--verify-artifacts|--check-credentials|--doctor|--github-doctor]

  --verify             Build, stage, ad-hoc sign, and validate the release app bundle.
  --verify-archive     Build, ad-hoc sign, validate, and write a local test archive.
  --archive            Build, Developer ID sign, validate, and write dist/release/Bonsai.zip.
  --notarize           Build, Developer ID sign, archive, submit to notarytool, and staple.
  --verify-artifacts   Validate dist/release/Bonsai.zip against Bonsai.release.plist.
  --check-credentials  Validate Developer ID and notarytool credentials without packaging.
  --doctor             Report local release credential readiness without changing artifacts.
  --github-doctor      Report GitHub release environment readiness without showing secrets.

Environment:
  BONSAI_CODESIGN_IDENTITY  Required for --archive and --notarize.
  BONSAI_NOTARY_PROFILE     Required for --notarize; xcrun notarytool keychain profile.
  BONSAI_NOTARY_KEYCHAIN    Optional keychain path for CI-stored notarytool credentials.
  BONSAI_VERSION            Optional CFBundleShortVersionString override.
  BONSAI_BUILD_NUMBER       Optional CFBundleVersion override.
  BONSAI_GITHUB_REPOSITORY  Optional owner/repo override for --github-doctor.
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
  validate_archive
}

write_release_manifest() {
  local signing_identity="$1" notarized="$2"
  local archive_sha archive_size git_commit signature_kind team_identifier
  local codesign_details

  require_file "$ARCHIVE_PATH"
  archive_sha="$(shasum -a 256 "$ARCHIVE_PATH" | awk '{print $1}')"
  archive_size="$(stat -f%z "$ARCHIVE_PATH")"
  git_commit="$(git -C "$ROOT_DIR" rev-parse HEAD 2>/dev/null || printf 'unknown')"
  codesign_details="$(codesign -dvvv "$APP_BUNDLE" 2>&1 || true)"
  signature_kind="$(printf '%s\n' "$codesign_details" | awk -F= '/^Signature=/{print $2; exit}')"
  team_identifier="$(printf '%s\n' "$codesign_details" | awk -F= '/^TeamIdentifier=/{print $2; exit}')"

  if [[ -z "$signature_kind" ]]; then
    signature_kind="unknown"
  fi
  if [[ -z "$team_identifier" ]]; then
    team_identifier="not set"
  fi
  if [[ "$signing_identity" == "-" ]]; then
    signing_identity="ad-hoc"
  fi

  cat >"$MANIFEST_PATH" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict/>
</plist>
PLIST

  plutil -insert appName -string "$APP_NAME" "$MANIFEST_PATH"
  plutil -insert bundleIdentifier -string "$BUNDLE_ID" "$MANIFEST_PATH"
  plutil -insert version -string "$(app_version)" "$MANIFEST_PATH"
  plutil -insert buildNumber -string "$(build_number)" "$MANIFEST_PATH"
  plutil -insert gitCommit -string "$git_commit" "$MANIFEST_PATH"
  plutil -insert archiveName -string "$(basename "$ARCHIVE_PATH")" "$MANIFEST_PATH"
  plutil -insert archiveByteSize -integer "$archive_size" "$MANIFEST_PATH"
  plutil -insert archiveSHA256 -string "$archive_sha" "$MANIFEST_PATH"
  plutil -insert signingIdentity -string "$signing_identity" "$MANIFEST_PATH"
  plutil -insert signatureKind -string "$signature_kind" "$MANIFEST_PATH"
  plutil -insert teamIdentifier -string "$team_identifier" "$MANIFEST_PATH"
  plutil -insert notarized -bool "$notarized" "$MANIFEST_PATH"
  validate_release_manifest
}

validate_release_manifest() {
  require_file "$MANIFEST_PATH"
  plutil -lint "$MANIFEST_PATH" >/dev/null
  plutil -extract appName raw "$MANIFEST_PATH" >/dev/null
  plutil -extract bundleIdentifier raw "$MANIFEST_PATH" >/dev/null
  plutil -extract version raw "$MANIFEST_PATH" >/dev/null
  plutil -extract buildNumber raw "$MANIFEST_PATH" >/dev/null
  plutil -extract gitCommit raw "$MANIFEST_PATH" >/dev/null
  plutil -extract archiveName raw "$MANIFEST_PATH" >/dev/null
  plutil -extract archiveByteSize raw "$MANIFEST_PATH" >/dev/null
  plutil -extract archiveSHA256 raw "$MANIFEST_PATH" >/dev/null
  plutil -extract signingIdentity raw "$MANIFEST_PATH" >/dev/null
  plutil -extract signatureKind raw "$MANIFEST_PATH" >/dev/null
  plutil -extract teamIdentifier raw "$MANIFEST_PATH" >/dev/null
  plutil -extract notarized raw "$MANIFEST_PATH" >/dev/null
}

verify_release_artifacts() {
  local expected_name actual_name expected_size actual_size expected_sha actual_sha

  validate_archive
  validate_release_manifest

  expected_name="$(plutil -extract archiveName raw "$MANIFEST_PATH")"
  actual_name="$(basename "$ARCHIVE_PATH")"
  if [[ "$expected_name" != "$actual_name" ]]; then
    echo "manifest archiveName mismatch: expected $actual_name, got $expected_name" >&2
    exit 1
  fi

  expected_size="$(plutil -extract archiveByteSize raw "$MANIFEST_PATH")"
  actual_size="$(stat -f%z "$ARCHIVE_PATH")"
  if [[ "$expected_size" != "$actual_size" ]]; then
    echo "manifest archiveByteSize mismatch: expected $actual_size, got $expected_size" >&2
    exit 1
  fi

  expected_sha="$(plutil -extract archiveSHA256 raw "$MANIFEST_PATH")"
  actual_sha="$(shasum -a 256 "$ARCHIVE_PATH" | awk '{print $1}')"
  if [[ "$expected_sha" != "$actual_sha" ]]; then
    echo "manifest archiveSHA256 mismatch: expected $actual_sha, got $expected_sha" >&2
    exit 1
  fi

  echo "Release artifacts verified"
}

validate_archive() {
  local archive_app_bundle archive_extract_dir archive_info_plist
  archive_extract_dir="$(mktemp -d)"

  ditto -x -k "$ARCHIVE_PATH" "$archive_extract_dir"
  archive_app_bundle="$archive_extract_dir/$APP_NAME.app"
  archive_info_plist="$archive_app_bundle/Contents/Info.plist"
  require_file "$archive_info_plist"
  plutil -lint "$archive_info_plist" >/dev/null

  local archived_bundle_id
  archived_bundle_id="$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$archive_info_plist")"
  if [[ "$archived_bundle_id" != "$BUNDLE_ID" ]]; then
    echo "unexpected archived CFBundleIdentifier: $archived_bundle_id" >&2
    exit 1
  fi

  local archived_package_type
  archived_package_type="$(/usr/libexec/PlistBuddy -c "Print :CFBundlePackageType" "$archive_info_plist")"
  if [[ "$archived_package_type" != "APPL" ]]; then
    echo "unexpected archived CFBundlePackageType: $archived_package_type" >&2
    exit 1
  fi

  local archived_short_version
  archived_short_version="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$archive_info_plist")"
  if [[ -z "$archived_short_version" ]]; then
    echo "missing archived CFBundleShortVersionString" >&2
    exit 1
  fi

  local archived_bundle_version
  archived_bundle_version="$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$archive_info_plist")"
  if [[ -z "$archived_bundle_version" ]]; then
    echo "missing archived CFBundleVersion" >&2
    exit 1
  fi

  codesign --verify --strict --verbose=2 "$archive_app_bundle"

  rm -rf "$archive_extract_dir"
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
  local args=(--keychain-profile "$profile")
  if [[ -n "${BONSAI_NOTARY_KEYCHAIN:-}" ]]; then
    args+=(--keychain "$BONSAI_NOTARY_KEYCHAIN")
  fi

  if ! xcrun notarytool history "${args[@]}" >/dev/null; then
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

check_archive_credentials() {
  local identity
  identity="$(developer_id_identity)"
  check_developer_id_identity "$identity"
}

release_doctor() {
  local failures=0 identity profile developer_id_count

  echo "Bonsai release doctor"
  echo "Version: $(app_version)"
  echo "Build: $(build_number)"

  developer_id_count="$(
    security find-identity -p codesigning -v \
      | grep -c 'Developer ID Application' \
      || true
  )"
  if [[ "$developer_id_count" == "0" ]]; then
    echo "Developer ID identities: none found"
    failures=1
  else
    echo "Developer ID identities: $developer_id_count found"
  fi

  if [[ -z "${BONSAI_CODESIGN_IDENTITY:-}" ]]; then
    echo "BONSAI_CODESIGN_IDENTITY: missing"
    failures=1
  else
    identity="$BONSAI_CODESIGN_IDENTITY"
    if [[ "$identity" != Developer\ ID\ Application:* ]]; then
      echo "BONSAI_CODESIGN_IDENTITY: invalid prefix"
      failures=1
    elif security find-identity -p codesigning -v | grep -F -- "$identity" >/dev/null; then
      echo "BONSAI_CODESIGN_IDENTITY: available"
    else
      echo "BONSAI_CODESIGN_IDENTITY: not found in login keychain"
      failures=1
    fi
  fi

  if [[ -z "${BONSAI_NOTARY_PROFILE:-}" ]]; then
    echo "BONSAI_NOTARY_PROFILE: missing"
    failures=1
  else
    profile="$BONSAI_NOTARY_PROFILE"
    local args=(--keychain-profile "$profile")
    if [[ -n "${BONSAI_NOTARY_KEYCHAIN:-}" ]]; then
      args+=(--keychain "$BONSAI_NOTARY_KEYCHAIN")
    fi

    if xcrun notarytool history "${args[@]}" >/dev/null 2>&1; then
      echo "BONSAI_NOTARY_PROFILE: valid"
    else
      echo "BONSAI_NOTARY_PROFILE: could not be validated"
      failures=1
    fi
  fi

  if [[ "$failures" == "0" ]]; then
    echo "Distribution credentials: ready"
    return 0
  fi

  echo "Distribution credentials: not ready"
  return 1
}

github_release_doctor() {
  local failures=0
  local repo="$GITHUB_RELEASE_REPOSITORY"
  local environment="$GITHUB_RELEASE_ENVIRONMENT"
  local runner="$GITHUB_RELEASE_RUNNER"
  local required_secrets=(
    BONSAI_CODESIGN_IDENTITY
    BONSAI_DEVELOPER_ID_CERTIFICATE_BASE64
    BONSAI_DEVELOPER_ID_CERTIFICATE_PASSWORD
    BONSAI_NOTARY_APPLE_ID
    BONSAI_NOTARY_APP_PASSWORD
    BONSAI_NOTARY_TEAM_ID
  )
  local required_labels=(self-hosted macOS ARM64 jarvis)

  echo "Bonsai GitHub release doctor"
  echo "Repository: $repo"
  echo "Environment: $environment"
  echo "Runner: $runner"

  if ! command -v gh >/dev/null; then
    echo "GitHub CLI: missing"
    echo "GitHub release configuration: not ready"
    return 1
  fi
  echo "GitHub CLI: available"

  local environment_name
  if environment_name="$(gh api "repos/$repo/environments/$environment" --jq '.name' 2>/dev/null)"; then
    if [[ "$environment_name" == "$environment" ]]; then
      echo "release environment: available"
    else
      echo "release environment: unexpected response"
      failures=1
    fi
  else
    echo "release environment: missing"
    failures=1
  fi

  local reviewers reviewers_display
  reviewers="$(
    gh api "repos/$repo/environments/$environment" \
      --jq '.protection_rules[]? | select(.type == "required_reviewers") | .reviewers[]?.reviewer.login' \
      2>/dev/null \
      || true
  )"
  if [[ -n "$reviewers" ]]; then
    reviewers_display="$(printf '%s\n' "$reviewers" | awk 'BEGIN { first = 1 } NF { if (!first) { printf ", " } printf "%s", $0; first = 0 }')"
    echo "required reviewers: $reviewers_display"
  else
    echo "required reviewers: missing"
    failures=1
  fi

  local runner_rows runner_status runner_labels
  runner_rows="$(
    gh api "repos/$repo/actions/runners" \
      --jq '.runners[]? | [.name,.status,([.labels[].name] | join(","))] | @tsv' \
      2>/dev/null \
      || true
  )"
  runner_status=""
  runner_labels=""
  while IFS=$'\t' read -r name status labels; do
    if [[ "$name" == "$runner" ]]; then
      runner_status="$status"
      runner_labels="$labels"
    fi
  done <<<"$runner_rows"

  if [[ -z "$runner_status" ]]; then
    echo "release runner: missing"
    failures=1
  else
    echo "release runner: $runner $runner_status"
    if [[ "$runner_status" != "online" ]]; then
      failures=1
    fi
    for label in "${required_labels[@]}"; do
      if [[ ",$runner_labels," == *",$label,"* ]]; then
        echo "runner label $label: available"
      else
        echo "runner label $label: missing"
        failures=1
      fi
    done
  fi

  local environment_secret_names
  if environment_secret_names="$(
    gh secret list \
      --repo "$repo" \
      --env "$environment" \
      --json name \
      --jq '.[].name' \
      2>/dev/null
  )"; then
    for secret in "${required_secrets[@]}"; do
      if printf '%s\n' "$environment_secret_names" | grep -Fx -- "$secret" >/dev/null; then
        echo "$secret: configured"
      else
        echo "$secret: missing"
        failures=1
      fi
    done
  else
    echo "environment secrets: unavailable"
    failures=1
  fi

  local repository_secret_names scoped_repo_secret_count
  repository_secret_names="$(
    gh secret list \
      --repo "$repo" \
      --json name \
      --jq '.[].name' \
      2>/dev/null \
      || true
  )"
  scoped_repo_secret_count=0
  for secret in "${required_secrets[@]}"; do
    if printf '%s\n' "$repository_secret_names" | grep -Fx -- "$secret" >/dev/null; then
      scoped_repo_secret_count=$((scoped_repo_secret_count + 1))
    fi
  done
  if [[ "$scoped_repo_secret_count" == "0" ]]; then
    echo "repository-level release secrets: none"
  else
    echo "repository-level release secrets: $scoped_repo_secret_count should move to environment"
    failures=1
  fi

  if [[ "$failures" == "0" ]]; then
    echo "GitHub release configuration: ready"
    return 0
  fi

  echo "GitHub release configuration: not ready"
  return 1
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
  --verify-archive|verify-archive)
    package_with_identity "-"
    create_archive
    write_release_manifest "-" false
    ;;
  --archive|archive)
    check_archive_credentials
    package_with_identity "$(developer_id_identity)"
    create_archive
    write_release_manifest "$(developer_id_identity)" false
    ;;
  --notarize|notarize)
    check_distribution_credentials
    package_with_identity "$(developer_id_identity)"
    create_archive
    notary_submit_args=(--keychain-profile "$(notary_profile)")
    if [[ -n "${BONSAI_NOTARY_KEYCHAIN:-}" ]]; then
      notary_submit_args+=(--keychain "$BONSAI_NOTARY_KEYCHAIN")
    fi
    xcrun notarytool submit "$ARCHIVE_PATH" "${notary_submit_args[@]}" --wait
    xcrun stapler staple "$APP_BUNDLE"
    xcrun stapler validate "$APP_BUNDLE"
    spctl -a -vv -t exec "$APP_BUNDLE"
    create_archive
    write_release_manifest "$(developer_id_identity)" true
    ;;
  --verify-artifacts|verify-artifacts)
    verify_release_artifacts
    ;;
  --check-credentials|check-credentials)
    check_distribution_credentials
    echo "Developer ID and notarytool credentials are available"
    ;;
  --doctor|doctor)
    release_doctor
    ;;
  --github-doctor|github-doctor)
    github_release_doctor
    ;;
  --help|-h|help)
    usage
    ;;
  *)
    usage
    exit 2
    ;;
esac

case "$MODE" in
  --verify|verify|--verify-archive|verify-archive|--archive|archive|--notarize|notarize)
    echo "Packaged $APP_BUNDLE"
    ;;
esac
