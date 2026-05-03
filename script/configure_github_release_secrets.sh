#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-}"
GITHUB_RELEASE_REPOSITORY="${BONSAI_GITHUB_REPOSITORY:-devaryakjha/bonsai}"
GITHUB_RELEASE_ENVIRONMENT="${BONSAI_GITHUB_RELEASE_ENVIRONMENT:-release}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat >&2 <<USAGE
usage: script/configure_github_release_secrets.sh [--dry-run|--print-template]

Uploads Bonsai release secrets to the protected GitHub Actions environment.
Secret values are read from environment variables and are never printed. Dry-run
and upload modes validate the Developer ID .p12 in a temporary keychain before
any GitHub secrets are changed.

Environment:
  BONSAI_CODESIGN_IDENTITY                    Developer ID Application identity.
  BONSAI_DEVELOPER_ID_CERTIFICATE_PATH        Password-protected Developer ID .p12 path.
  BONSAI_DEVELOPER_ID_CERTIFICATE_PASSWORD    Password used when exporting the .p12.
  BONSAI_NOTARY_APPLE_ID                      Apple ID email for notarization.
  BONSAI_NOTARY_APP_PASSWORD                  App-specific password for notarization.
  BONSAI_NOTARY_TEAM_ID                       Apple Developer Team ID.
  BONSAI_GITHUB_REPOSITORY                    Optional owner/repo override.
  BONSAI_GITHUB_RELEASE_ENVIRONMENT           Optional environment override.
USAGE
}

failures=0

mark_failure() {
  failures=1
}

check_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "$name: missing"
    mark_failure
    return
  fi

  echo "$name: ready"
}

check_certificate_path() {
  if [[ -z "${BONSAI_DEVELOPER_ID_CERTIFICATE_PATH:-}" ]]; then
    echo "BONSAI_DEVELOPER_ID_CERTIFICATE_PATH: missing"
    mark_failure
    return
  fi

  if [[ ! -f "$BONSAI_DEVELOPER_ID_CERTIFICATE_PATH" ]]; then
    echo "BONSAI_DEVELOPER_ID_CERTIFICATE_PATH: file not found"
    mark_failure
    return
  fi

  echo "BONSAI_DEVELOPER_ID_CERTIFICATE_PATH: ready"
  echo "BONSAI_DEVELOPER_ID_CERTIFICATE_BASE64: ready from certificate file"
}

check_codesign_identity() {
  if [[ -z "${BONSAI_CODESIGN_IDENTITY:-}" ]]; then
    echo "BONSAI_CODESIGN_IDENTITY: missing"
    mark_failure
    return
  fi

  if [[ "$BONSAI_CODESIGN_IDENTITY" != Developer\ ID\ Application:* ]]; then
    echo "BONSAI_CODESIGN_IDENTITY: invalid prefix"
    mark_failure
    return
  fi

  echo "BONSAI_CODESIGN_IDENTITY: ready"
}

check_github_environment() {
  if ! command -v gh >/dev/null; then
    echo "GitHub CLI: missing"
    mark_failure
    return
  fi

  echo "GitHub CLI: available"

  local environment_name
  if environment_name="$(gh api "repos/$GITHUB_RELEASE_REPOSITORY/environments/$GITHUB_RELEASE_ENVIRONMENT" --jq '.name' 2>/dev/null)"; then
    if [[ "$environment_name" == "$GITHUB_RELEASE_ENVIRONMENT" ]]; then
      echo "release environment: available"
      return
    fi
  fi

  echo "release environment: unavailable"
  mark_failure
}

validate_certificate_import() {
  local temp_dir keychain keychain_password import_stderr identity_output validation_failed
  if ! command -v security >/dev/null; then
    echo "Developer ID certificate: security tool missing"
    mark_failure
    return
  fi

  temp_dir="$(mktemp -d)"
  keychain="$temp_dir/bonsai-release-secret-validation.keychain-db"
  keychain_password="bonsai-temporary-validation-password"
  import_stderr="$temp_dir/security-import.stderr"
  validation_failed=0

  if ! security create-keychain -p "$keychain_password" "$keychain" >/dev/null 2>"$import_stderr"; then
    echo "Developer ID certificate: temporary keychain failed"
    sed -n "1,3p" "$import_stderr"
    validation_failed=1
  elif ! security unlock-keychain -p "$keychain_password" "$keychain" >/dev/null 2>"$import_stderr"; then
    echo "Developer ID certificate: temporary keychain unlock failed"
    sed -n "1,3p" "$import_stderr"
    validation_failed=1
  elif ! security import "$BONSAI_DEVELOPER_ID_CERTIFICATE_PATH" \
    -k "$keychain" \
    -P "$BONSAI_DEVELOPER_ID_CERTIFICATE_PASSWORD" \
    -T /usr/bin/codesign \
    >/dev/null 2>"$import_stderr"; then
    echo "Developer ID certificate: import failed"
    sed -n "1,3p" "$import_stderr"
    validation_failed=1
  else
    identity_output="$(security find-identity -p codesigning -v "$keychain" 2>"$import_stderr" || true)"
    if printf '%s\n' "$identity_output" | grep -F -- "$BONSAI_CODESIGN_IDENTITY" >/dev/null; then
      echo "Developer ID certificate: importable"
      echo "Developer ID certificate identity: matches configured identity"
    else
      echo "Developer ID certificate identity: configured identity not found in .p12"
      validation_failed=1
    fi
  fi

  security delete-keychain "$keychain" >/dev/null 2>&1 || true
  rm -rf "$temp_dir"

  if [[ "$validation_failed" != "0" ]]; then
    mark_failure
  fi
}

validate_inputs() {
  echo "Bonsai GitHub release secret configurator"
  echo "Repository: $GITHUB_RELEASE_REPOSITORY"
  echo "Environment: $GITHUB_RELEASE_ENVIRONMENT"

  check_github_environment
  check_codesign_identity
  check_certificate_path
  check_env BONSAI_DEVELOPER_ID_CERTIFICATE_PASSWORD
  check_env BONSAI_NOTARY_APPLE_ID
  check_env BONSAI_NOTARY_APP_PASSWORD
  check_env BONSAI_NOTARY_TEAM_ID

  if [[ "$failures" == "0" ]]; then
    validate_certificate_import
  fi

  if [[ "$failures" != "0" ]]; then
    echo "GitHub release secrets: not ready"
    return 1
  fi

  echo "GitHub release secrets: ready"
}

set_environment_secret() {
  local name="$1" value="$2"
  printf '%s' "$value" \
    | gh secret set "$name" \
      --repo "$GITHUB_RELEASE_REPOSITORY" \
      --env "$GITHUB_RELEASE_ENVIRONMENT" \
      >/dev/null
  echo "$name: uploaded to $GITHUB_RELEASE_ENVIRONMENT"
}

upload_secrets() {
  local certificate_base64
  certificate_base64="$(base64 <"$BONSAI_DEVELOPER_ID_CERTIFICATE_PATH" | tr -d '\n')"

  set_environment_secret BONSAI_CODESIGN_IDENTITY "$BONSAI_CODESIGN_IDENTITY"
  set_environment_secret BONSAI_DEVELOPER_ID_CERTIFICATE_BASE64 "$certificate_base64"
  set_environment_secret BONSAI_DEVELOPER_ID_CERTIFICATE_PASSWORD "$BONSAI_DEVELOPER_ID_CERTIFICATE_PASSWORD"
  set_environment_secret BONSAI_NOTARY_APPLE_ID "$BONSAI_NOTARY_APPLE_ID"
  set_environment_secret BONSAI_NOTARY_APP_PASSWORD "$BONSAI_NOTARY_APP_PASSWORD"
  set_environment_secret BONSAI_NOTARY_TEAM_ID "$BONSAI_NOTARY_TEAM_ID"

  "$ROOT_DIR/script/package_release.sh" --github-doctor
}

print_template() {
  cat <<'TEMPLATE'
# Fill these values in locally. Do not commit this output.
export BONSAI_CODESIGN_IDENTITY="Developer ID Application: Example, Inc. (TEAMID)"
export BONSAI_DEVELOPER_ID_CERTIFICATE_PATH="/absolute/path/to/DeveloperID.p12"
export BONSAI_DEVELOPER_ID_CERTIFICATE_PASSWORD="replace-with-p12-export-password"
export BONSAI_NOTARY_APPLE_ID="developer@example.com"
export BONSAI_NOTARY_APP_PASSWORD="replace-with-app-specific-password"
export BONSAI_NOTARY_TEAM_ID="TEAMID"

make release-secrets-dry-run
make release-secrets-upload
make release-github-doctor
TEMPLATE
}

case "$MODE" in
  --print-template|print-template)
    print_template
    ;;
  --dry-run|dry-run)
    validate_inputs
    echo "Dry run complete; no GitHub secrets were changed"
    ;;
  ""|--upload|upload)
    validate_inputs
    upload_secrets
    ;;
  --help|-h|help)
    usage
    ;;
  *)
    usage
    exit 2
    ;;
esac
