#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist/release"
ARCHIVE_PATH="${BONSAI_RELEASE_ARCHIVE:-$DIST_DIR/Bonsai.zip}"
MANIFEST_PATH="${BONSAI_RELEASE_MANIFEST:-$DIST_DIR/Bonsai.release.plist}"
REPOSITORY="${BONSAI_GITHUB_REPOSITORY:-${GITHUB_REPOSITORY:-devaryakjha/bonsai}}"
VERSION="${BONSAI_VERSION:-$(tr -d '[:space:]' <"$ROOT_DIR/VERSION")}"
BUILD_NUMBER="${BONSAI_BUILD_NUMBER:-$(git -C "$ROOT_DIR" rev-list --count HEAD 2>/dev/null || printf '0')}"
COMMIT_SHA="${GITHUB_SHA:-$(git -C "$ROOT_DIR" rev-parse HEAD)}"
RELEASE_TAG="${BONSAI_RELEASE_TAG:-v$VERSION}"
API_BASE="${BONSAI_GITHUB_API_BASE:-https://api.github.com/repos/$REPOSITORY}"
UPLOADS_BASE="${BONSAI_GITHUB_UPLOADS_BASE:-https://uploads.github.com/repos/$REPOSITORY}"
TEMP_ROOT="${RUNNER_TEMP:-}"
CREATED_TEMP_ROOT=""

usage() {
  cat >&2 <<USAGE
usage: script/create_github_draft_release.sh

Creates a draft GitHub Release for the current Bonsai archive and manifest.
This script is intended for the protected release workflow after notarization
and artifact verification have already passed.

Environment:
  GH_TOKEN                    GitHub token with contents:write permission.
  GITHUB_REPOSITORY           owner/repo, defaults to devaryakjha/bonsai.
  GITHUB_SHA                  audited commit SHA, defaults to current HEAD.
  BONSAI_VERSION              Release version, defaults to VERSION.
  BONSAI_BUILD_NUMBER         Build number, defaults to git commit count.
  BONSAI_RELEASE_TAG          Release tag, defaults to v\$BONSAI_VERSION.
  BONSAI_RELEASE_ARCHIVE      Archive path, defaults to dist/release/Bonsai.zip.
  BONSAI_RELEASE_MANIFEST     Manifest path, defaults to dist/release/Bonsai.release.plist.
USAGE
}

if [[ "$MODE" == "--help" || "$MODE" == "-h" || "$MODE" == "help" ]]; then
  usage
  exit 0
fi

if [[ -n "$MODE" ]]; then
  usage
  exit 2
fi

if [[ -z "${GH_TOKEN:-}" ]]; then
  echo "GH_TOKEN is required" >&2
  exit 1
fi

for tool in curl jq; do
  if ! command -v "$tool" >/dev/null; then
    echo "$tool is required" >&2
    exit 1
  fi
done

for asset in "$ARCHIVE_PATH" "$MANIFEST_PATH"; do
  if [[ ! -f "$asset" ]]; then
    echo "missing release asset: $asset" >&2
    exit 1
  fi
done

if [[ -z "$TEMP_ROOT" ]]; then
  TEMP_ROOT="$(mktemp -d)"
  CREATED_TEMP_ROOT="$TEMP_ROOT"
fi

cleanup_temp_root() {
  if [[ -n "$CREATED_TEMP_ROOT" ]]; then
    rm -rf "$CREATED_TEMP_ROOT"
  fi
}
trap cleanup_temp_root EXIT

api_headers=(
  -H "Authorization: Bearer $GH_TOKEN"
  -H "Accept: application/vnd.github+json"
  -H "X-GitHub-Api-Version: 2022-11-28"
)

urlencode() {
  jq -rn --arg value "$1" '$value | @uri'
}

release_lookup_response="$TEMP_ROOT/bonsai-release-lookup.json"
release_lookup_status="$(
  curl -sS \
    -o "$release_lookup_response" \
    -w "%{http_code}" \
    "${api_headers[@]}" \
    "$API_BASE/releases/tags/$RELEASE_TAG"
)"
if [[ "$release_lookup_status" == "200" ]]; then
  existing_release_draft="$(jq -r '.draft' "$release_lookup_response")"
  existing_release_id="$(jq -r '.id' "$release_lookup_response")"
  if [[ "$existing_release_draft" != "true" ]]; then
    echo "Published GitHub release already exists for $RELEASE_TAG" >&2
    exit 1
  fi
  if [[ -z "$existing_release_id" || "$existing_release_id" == "null" ]]; then
    echo "Existing draft release response did not include an id" >&2
    cat "$release_lookup_response" >&2
    exit 1
  fi

  delete_response="$TEMP_ROOT/bonsai-existing-release-delete.json"
  delete_status="$(
    curl -sS \
      -X DELETE \
      -o "$delete_response" \
      -w "%{http_code}" \
      "${api_headers[@]}" \
      "$API_BASE/releases/$existing_release_id"
  )"
  if [[ "$delete_status" != "204" ]]; then
    echo "Existing draft release deletion failed with status $delete_status" >&2
    cat "$delete_response" >&2
    exit 1
  fi
  echo "Replaced existing draft GitHub release for $RELEASE_TAG"
fi
if [[ "$release_lookup_status" != "404" ]]; then
  if [[ "$release_lookup_status" != "200" ]]; then
    echo "GitHub release lookup failed with status $release_lookup_status" >&2
    cat "$release_lookup_response" >&2
    exit 1
  fi
fi

encoded_tag="$(urlencode "$RELEASE_TAG")"
tag_lookup_response="$TEMP_ROOT/bonsai-tag-lookup.json"
tag_lookup_status="$(
  curl -sS \
    -o "$tag_lookup_response" \
    -w "%{http_code}" \
    "${api_headers[@]}" \
    "$API_BASE/git/ref/tags/$encoded_tag"
)"
tag_preexisting=false
if [[ "$tag_lookup_status" == "200" ]]; then
  tag_preexisting=true
elif [[ "$tag_lookup_status" != "404" ]]; then
  echo "GitHub tag lookup failed with status $tag_lookup_status" >&2
  cat "$tag_lookup_response" >&2
  exit 1
fi

notes_path="$TEMP_ROOT/bonsai-release-notes.md"
cat >"$notes_path" <<NOTES
Bonsai $VERSION ($BUILD_NUMBER)

Native macOS Git client v0 release candidate.

Evidence:
- Fork-parity matrix: Specs/0242-v0-parity-evidence.md
- Completion audit: Specs/0259-v0-completion-audit.md
- Release checklist: Documentation/ReleaseChecklist.md

Attachments:
- Bonsai.zip
- Bonsai.release.plist

Keep this release as a draft until the downloaded artifact passes the post-release Gatekeeper and smoke checks.
NOTES

create_payload="$TEMP_ROOT/bonsai-release-payload.json"
create_response="$TEMP_ROOT/bonsai-release-response.json"
jq -n \
  --arg tag_name "$RELEASE_TAG" \
  --arg target_commitish "$COMMIT_SHA" \
  --arg name "Bonsai $VERSION" \
  --arg body "$(cat "$notes_path")" \
  '{tag_name: $tag_name, target_commitish: $target_commitish, name: $name, body: $body, draft: true, prerelease: false}' \
  >"$create_payload"

create_status="$(
  curl -sS \
    -X POST \
    -o "$create_response" \
    -w "%{http_code}" \
    "${api_headers[@]}" \
    -H "Content-Type: application/json" \
    --data-binary "@$create_payload" \
    "$API_BASE/releases"
)"
if [[ "$create_status" != "201" ]]; then
  echo "GitHub draft release creation failed with status $create_status" >&2
  cat "$create_response" >&2
  exit 1
fi

release_id="$(jq -r '.id' "$create_response")"
if [[ -z "$release_id" || "$release_id" == "null" ]]; then
  echo "GitHub draft release response did not include an id" >&2
  cat "$create_response" >&2
  exit 1
fi

cleanup_release() {
  curl -sS \
    -X DELETE \
    "${api_headers[@]}" \
    "$API_BASE/releases/$release_id" \
    >/dev/null \
    || true

  if [[ "$tag_preexisting" == "false" ]]; then
    curl -sS \
      -X DELETE \
      "${api_headers[@]}" \
      "$API_BASE/git/refs/tags/$encoded_tag" \
      >/dev/null \
      || true
  fi
}

upload_url="$UPLOADS_BASE/releases/$release_id/assets"
for asset in "$ARCHIVE_PATH" "$MANIFEST_PATH"; do
  asset_name="$(basename "$asset")"
  encoded_asset_name="$(urlencode "$asset_name")"
  upload_response="$TEMP_ROOT/bonsai-release-upload-$asset_name.json"
  upload_status="$(
    curl -sS \
      -X POST \
      -o "$upload_response" \
      -w "%{http_code}" \
      "${api_headers[@]}" \
      -H "Content-Type: application/octet-stream" \
      --data-binary "@$asset" \
      "$upload_url?name=$encoded_asset_name"
  )"
  if [[ "$upload_status" != "201" ]]; then
    echo "GitHub release asset upload failed for $asset_name with status $upload_status" >&2
    cat "$upload_response" >&2
    cleanup_release
    exit 1
  fi
done

echo "Draft GitHub release created for $RELEASE_TAG"
