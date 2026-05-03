#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

DURATION="${BONSAI_UI_SAMPLE_SECONDS:-8}"
WARMUP="${BONSAI_UI_SAMPLE_WARMUP_SECONDS:-2}"
STAMP="$(date +%Y%m%d-%H%M%S)"
SAMPLE_FILE="${BONSAI_UI_SAMPLE_FILE:-/tmp/bonsai-ui-$STAMP.sample.txt}"

./script/build_and_run.sh --verify >/dev/null
PID="$(pgrep -x Bonsai | tail -1)"

sleep "$WARMUP"

osascript <<'OSA' >/dev/null 2>&1 &
tell application "Bonsai" to activate
delay 0.5
tell application "System Events"
  tell process "Bonsai"
    repeat with i from 1 to 8
      try
        click menu item "Toggle Sidebar" of menu "View" of menu bar 1
      end try
      delay 0.35
    end repeat
  end tell
end tell
OSA

sample "$PID" "$DURATION" -file "$SAMPLE_FILE" >/dev/null

HOT_PATTERN="SystemSegmentedControl|RichDiffTextView\\.attributedDiff|SplitDiffTextView\\.attributedDiff|GitParsers\\.parse|DiffHeaderControls"
HOT_FRAME_COUNT="$(grep -E "$HOT_PATTERN" "$SAMPLE_FILE" | wc -l | tr -d '[:space:]' || true)"

echo "BonsaiUISample file=$SAMPLE_FILE pid=$PID seconds=$DURATION hot_frames=$HOT_FRAME_COUNT"
ps -o pid,%cpu,%mem,time,command -p "$PID"

if [[ "$HOT_FRAME_COUNT" -gt "${BONSAI_UI_SAMPLE_HOT_FRAME_LIMIT:-0}" ]]; then
  echo "Unexpected hot UI/diff frames found:" >&2
  grep -E "$HOT_PATTERN" "$SAMPLE_FILE" | head -40 >&2
  exit 1
fi
