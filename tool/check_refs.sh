#!/usr/bin/env bash
# Verifies that every backend package's `core_architecture` git ref is a tag
# that exists on origin and carries the same core version as this checkout.
#
# Inside the workspace pub ignores these refs, so a stale or missing tag only
# shows up for consumers — silently, if their pub cache still holds it.
set -euo pipefail

cd "$(dirname "$0")/.."

core_version=$(sed -n 's/^version: //p' packages/core_architecture/pubspec.yaml)
remote_tags=$(git ls-remote --tags origin)
status=0

for pubspec in packages/core_architecture_*/pubspec.yaml; do
  ref=$(sed -n '/^  core_architecture:/,/ref:/s/^ *ref: //p' "$pubspec")

  if ! grep -q "refs/tags/$ref\$" <<<"$remote_tags"; then
    echo "✗ $pubspec: ref $ref is not a tag on origin"
    status=1
    continue
  fi

  git fetch -q origin "refs/tags/$ref:refs/tags/$ref" 2>/dev/null || true
  tagged_version=$(git show "$ref:packages/core_architecture/pubspec.yaml" |
    sed -n 's/^version: //p')

  if [[ "$tagged_version" != "$core_version" ]]; then
    echo "✗ $pubspec: ref $ref has core $tagged_version, this checkout has $core_version"
    status=1
  else
    echo "✓ $pubspec: ref $ref → core $tagged_version"
  fi
done

exit $status
