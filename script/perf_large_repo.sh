#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

BONSAI_PERF_SMOKE=1 swift test --filter DiffPerformanceSmokeTests/testLargeHistoryAndDiffPerformanceSmoke
