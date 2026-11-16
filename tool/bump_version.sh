#!/usr/bin/env bash
# Bumps the app version everywhere: pubspec.yaml (+ build number), lib/core/version.dart
# and CHANGELOG.md (moves "Unreleased" under the new version).
# Usage: tool/bump_version.sh 0.2.0
set -euo pipefail
cd "$(dirname "$0")/.."

new="${1:?usage: tool/bump_version.sh <major.minor.patch>}"
[[ "$new" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.]+)?$ ]] || { echo "Not a SemVer version: $new" >&2; exit 1; }

old_build=$(sed -nE 's/^version: [^+]+\+([0-9]+)$/\1/p' pubspec.yaml)
build=$(( ${old_build:-0} + 1 ))
sed -i.bak -E "s/^version: .*/version: ${new}+${build}/" pubspec.yaml && rm pubspec.yaml.bak
sed -i.bak -E "s/^const appVersion = '.*';/const appVersion = '${new}';/" lib/core/version.dart && rm lib/core/version.dart.bak

today=$(date +%Y-%m-%d)
python3 - "$new" "$today" <<'PY'
import re, sys
new, today = sys.argv[1], sys.argv[2]
s = open('CHANGELOG.md').read()
s = s.replace('## [Unreleased]\n', f'## [Unreleased]\n\n## [{new}] - {today}\n', 1)
s = re.sub(r'\[Unreleased\]: (.*)/compare/v[^.]+\.[^.]+\.[^.]+\.\.\.HEAD',
           lambda m: f'[Unreleased]: {m.group(1)}/compare/v{new}...HEAD\n[{new}]: {m.group(1)}/releases/tag/v{new}', s, count=1)
open('CHANGELOG.md', 'w').write(s)
PY

echo "Version is now ${new}+${build}. Review CHANGELOG.md, commit, merge, then: git tag v${new} && git push origin v${new}"
