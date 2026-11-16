#!/usr/bin/env bash
# Fails if pubspec.yaml, lib/core/version.dart, CHANGELOG.md (and the tag, if given) disagree.
# Usage: tool/check_version.sh [vX.Y.Z]
set -euo pipefail
cd "$(dirname "$0")/.."

pub=$(sed -nE 's/^version: ([^+]+).*/\1/p' pubspec.yaml)
dart=$(sed -nE "s/^const appVersion = '(.*)';/\1/p" lib/core/version.dart)
[ "$pub" = "$dart" ] || { echo "pubspec.yaml ($pub) != lib/core/version.dart ($dart)" >&2; exit 1; }
grep -q "^## \[$pub\]" CHANGELOG.md || { echo "CHANGELOG.md has no section for $pub" >&2; exit 1; }
if [ -n "${1:-}" ]; then
  [ "${1#v}" = "$pub" ] || { echo "Tag $1 does not match version $pub" >&2; exit 1; }
fi
echo "Version $pub is consistent."
