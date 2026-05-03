#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-}"
RUNNER_HOST="${BONSAI_RELEASE_RUNNER_HOST:-jarvis}"
NOTARY_PROFILE="${BONSAI_NOTARY_PROFILE:-bonsai-ci-notary}"

usage() {
  cat >&2 <<USAGE
usage: script/check_release_runner.sh [--local]

Runs a read-only release runner preflight. By default this checks the configured
runner over SSH. Use --local to run the same checks on the current machine.

Environment:
  BONSAI_RELEASE_RUNNER_HOST  Optional SSH host override. Defaults to jarvis.
  BONSAI_NOTARY_PROFILE       Optional notarytool profile. Defaults to bonsai-ci-notary.
USAGE
}

remote_script='
set -euo pipefail
profile="$1"

echo "Bonsai release runner preflight"
echo "Host: $(hostname)"
sw_vers
xcodebuild -version
swift --version

developer_id_output="$(security find-identity -p codesigning -v 2>&1 || true)"
developer_id_count="$(printf "%s\n" "$developer_id_output" | grep -c "Developer ID Application" || true)"
if [[ "$developer_id_count" == "0" ]]; then
  echo "Developer ID Application identities: none"
else
  echo "Developer ID Application identities: $developer_id_count"
  printf "%s\n" "$developer_id_output" | grep "Developer ID Application" || true
fi

notary_stdout="$(mktemp)"
notary_stderr="$(mktemp)"
if xcrun notarytool history --keychain-profile "$profile" >"$notary_stdout" 2>"$notary_stderr"; then
  echo "notarytool profile $profile: valid"
else
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
'

case "$MODE" in
  --local|local)
    bash -c "$remote_script" -- "$NOTARY_PROFILE"
    ;;
  ""|--ssh|ssh)
    ssh "$RUNNER_HOST" bash -s -- "$NOTARY_PROFILE" <<<"$remote_script"
    ;;
  --help|-h|help)
    usage
    ;;
  *)
    usage
    exit 2
    ;;
esac
