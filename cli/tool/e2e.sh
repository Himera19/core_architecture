#!/usr/bin/env bash
# Scaffolds one app per config in tool/e2e/, in parallel, and fails unless
# every one analyzes clean and passes its own tests. Needs network: the apps
# depend on core_architecture at the CLI's packageRef, fetched from GitHub.
#
#   bash tool/e2e.sh [--ref <tag-or-commit>]
set -uo pipefail

cd "$(dirname "$0")/.."
out=$(mktemp -d)
echo "Scaffolding into $out"

for config in tool/e2e/*.yaml; do
  name=$(basename "$config" .yaml)_app
  (
    dart run bin/core_architecture.dart create "$name" --config "$config" --yes -o "$out" "$@" \
      && (cd "$out/$name" && flutter test)
  ) >"$out/$name.log" 2>&1 && echo "✓ $name" || echo "✗ $name — see $out/$name.log" &
done
wait

failed=0
for log in "$out"/*.log; do
  grep -q "All tests passed" "$log" || failed=1
done
exit $failed
