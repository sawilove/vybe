#!/usr/bin/env bash
# Prints the CHANGELOG.md section of a version (used as the GitHub release body).
# Usage: tool/release_notes.sh 0.1.0
set -euo pipefail
cd "$(dirname "$0")/.."
awk -v v="$1" '
  $0 ~ "^## \\[" v "\\]" { on = 1; next }
  on && /^## \[/ { exit }
  on && /^\[[^]]+\]: / { exit }
  on { print }
' CHANGELOG.md
