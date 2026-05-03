#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-}"
RUNNER_HOST="${BONSAI_RELEASE_RUNNER_HOST:-jarvis}"
NOTARY_PROFILE="${BONSAI_NOTARY_PROFILE:-bonsai-ci-notary}"

usage() {
  cat >&2 <<USAGE
usage: script/check_release_runner.sh [--local|--workflow|--workflow-local]

Runs a read-only release runner preflight. By default this checks the configured
runner-local signing and notarization credentials over SSH. Use --local to run
the same strict checks on the current machine.

Use --workflow to check whether the configured runner has the no-secret
toolchain required by the GitHub release workflow. Use --workflow-local to run
those workflow checks on the current machine.

Environment:
  BONSAI_RELEASE_RUNNER_HOST  Optional SSH host override. Defaults to jarvis.
  BONSAI_NOTARY_PROFILE       Optional notarytool profile. Defaults to bonsai-ci-notary.
USAGE
}

remote_script='
set -euo pipefail
profile="$1"
check_mode="$2"
failures=0

echo "Bonsai release runner preflight"
echo "Host: $(hostname)"
sw_vers
xcodebuild -version
swift --version

if [[ "$check_mode" == "workflow" ]]; then
  required_commands=(
    sw_vers
    xcodebuild
    swift
    git
    curl
    jq
    codesign
    xcrun
    security
    ditto
    plutil
    shasum
    stat
  )
  for command_name in "${required_commands[@]}"; do
    if command -v "$command_name" >/dev/null; then
      echo "$command_name: available"
    else
      echo "$command_name: missing"
      failures=1
    fi
  done

  if xcrun notarytool --version >/dev/null 2>&1; then
    echo "notarytool: available"
  else
    echo "notarytool: missing"
    failures=1
  fi

  if [[ "$failures" == "0" ]]; then
    echo "Release workflow runner: ready"
  else
    echo "Release workflow runner: not ready"
  fi
  exit "$failures"
fi

developer_id_output="$(security find-identity -p codesigning -v 2>&1 || true)"
developer_id_count="$(printf "%s\n" "$developer_id_output" | grep -c "Developer ID Application" || true)"
if [[ "$developer_id_count" == "0" ]]; then
  echo "Developer ID Application identities: none"
  failures=1
else
  echo "Developer ID Application identities: $developer_id_count"
  printf "%s\n" "$developer_id_output" | grep "Developer ID Application" || true

  signing_identity="$(printf "%s\n" "$developer_id_output" | sed -n "s/.*\"\(Developer ID Application:.*\)\".*/\1/p" | head -n 1)"
  signing_smoke_file="$(mktemp)"
  signing_smoke_stdout="$(mktemp)"
  signing_smoke_stderr="$(mktemp)"
  printf "bonsai signing smoke" >"$signing_smoke_file"
  if codesign --force --options runtime --timestamp --sign "$signing_identity" "$signing_smoke_file" >"$signing_smoke_stdout" 2>"$signing_smoke_stderr"; then
    echo "Developer ID signing smoke: valid"
  else
    echo "Developer ID signing smoke: failed"
    sed -n "1,3p" "$signing_smoke_stderr"
    failures=1
  fi
  rm -f "$signing_smoke_file" "$signing_smoke_stdout" "$signing_smoke_stderr"
fi

notary_stdout="$(mktemp)"
notary_stderr="$(mktemp)"
if xcrun notarytool history --keychain-profile "$profile" >"$notary_stdout" 2>"$notary_stderr"; then
  echo "notarytool profile $profile: valid"
else
  failures=1
  if grep -q "keychainLocked" "$notary_stderr"; then
    echo "notarytool profile $profile: keychain locked"
  elif grep -qi "No Keychain password item found" "$notary_stderr"; then
    echo "notarytool profile $profile: missing"
  else
    echo "notarytool profile $profile: unavailable"
    sed -n "1,3p" "$notary_stderr"
  fi
fi
rm -f "$notary_stdout" "$notary_stderr"

if [[ "$failures" == "0" ]]; then
  echo "Release runner: ready"
else
  echo "Release runner: not ready"
fi
exit "$failures"
'

case "$MODE" in
  --local|local)
    bash -c "$remote_script" -- "$NOTARY_PROFILE" credentials
    ;;
  --workflow-local|workflow-local)
    bash -c "$remote_script" -- "$NOTARY_PROFILE" workflow
    ;;
  --workflow|workflow)
    ssh "$RUNNER_HOST" bash -s -- "$NOTARY_PROFILE" workflow <<<"$remote_script"
    ;;
  ""|--ssh|ssh)
    ssh "$RUNNER_HOST" bash -s -- "$NOTARY_PROFILE" credentials <<<"$remote_script"
    ;;
  --help|-h|help)
    usage
    ;;
  *)
    usage
    exit 2
    ;;
esac
