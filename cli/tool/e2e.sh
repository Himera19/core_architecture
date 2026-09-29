#!/usr/bin/env bash
# Scaffolds one app per config in tool/e2e/, one after another, and fails unless
# every one analyzes clean and passes its own tests. Needs network: the apps
# depend on core_architecture at the CLI's packageRef, fetched from GitHub.
#
#   bash tool/e2e.sh [--ref <tag-or-commit>]
set -uo pipefail

cd "$(dirname "$0")/.."
out=$(mktemp -d)
echo "Scaffolding into $out"

scaffold() {
  local config=$1 name
  name=$(basename "$config" .yaml)_app
  if (
    dart run bin/core_architecture.dart create "$name" --config "$config" --yes -o "$out" "${@:2}" \
      && (cd "$out/$name" && flutter test)
  ) >"$out/$name.log" 2>&1; then
    echo "✓ $name"
  else
    echo "✗ $name — see $out/$name.log"
  fi
}

# One at a time. Concurrent `pub add`s of the same git package re-fetch and
# replace the one shared clone in pub's git cache, and lose that race at
# random ("Deletion failed", a missing --git-dir), with a cold cache or not.
for config in tool/e2e/*.yaml; do
  scaffold "$config" "$@"
done

failed=0
for log in "$out"/*.log; do
  grep -q "All tests passed" "$log" || failed=1
done
exit $failed
