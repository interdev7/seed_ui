#!/usr/bin/env bash
#
# Checks that everything naming a version agrees with pubspec.yaml.
#
# Two mistakes this catches, both of which have reached CI before:
#
#   * bumping `version:` without renaming the CHANGELOG's `## Unreleased`
#     heading, which `pub publish` rejects — but only at publish time, long
#     after the change was merged;
#   * leaving the README's install snippet or the gallery's constraint on the
#     previous version, which nothing rejects at all: it just tells readers to
#     depend on something older than what they are reading about.
#
# Run it from the repository root:
#
#   ./tool/check_version.sh
#
set -euo pipefail

cd "$(dirname "$0")/.."

fail=0
note() {
  echo "✗ $1"
  # Annotates the pull request when running on GitHub Actions; harmless
  # locally, where the line above is what a human reads.
  if [ -n "${GITHUB_ACTIONS:-}" ]; then echo "::error::$1"; fi
  fail=1
}

version="$(awk '/^version:/{print $2; exit}' pubspec.yaml)"
if [ -z "$version" ]; then
  note "pubspec.yaml has no version:"
  exit 1
fi
echo "pubspec.yaml declares $version"

# `## 0.4.0`, `## 0.4.0 - 2026-08-17` and `##  0.4.0` all count; `## 0.4.0-rc`
# does not, so a pre-release cannot pass on its stable section.
if grep -qE "^##[[:space:]]+${version//./\\.}([^0-9.]|$)" CHANGELOG.md; then
  echo "✓ CHANGELOG.md has a '## $version' section"
else
  note "CHANGELOG.md has no '## $version' section. Rename the '## Unreleased' heading before releasing."
fi

# The install snippet and the gallery should point at the version being
# developed, not the one before it.
check_constraint() {
  local file="$1" found
  found="$(grep -oE '^\s*seed_ui: \^[0-9]+\.[0-9]+\.[0-9]+' "$file" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true)"
  if [ -z "$found" ]; then
    echo "· $file names no seed_ui constraint, skipping"
  elif [ "$found" = "$version" ]; then
    echo "✓ $file points at ^$version"
  else
    note "$file says 'seed_ui: ^$found' but pubspec.yaml is $version"
  fi
}

check_constraint README.md
check_constraint example/pubspec.yaml

# The gallery prints its version in the header, from a constant generated out
# of pubspec.yaml. Nothing else would notice it going stale — a screenshot
# would simply claim the wrong version.
constant_file="example/lib/version.dart"
if [ -f "$constant_file" ]; then
  found="$(grep -oE "seedUiVersion = '[^']+'" "$constant_file" | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" || true)"
  if [ "$found" = "$version" ]; then
    echo "✓ $constant_file declares $version"
  else
    note "$constant_file says '$found' but pubspec.yaml is $version. Regenerate it with ./tool/sync_version.sh"
  fi
fi

if [ "$fail" -ne 0 ]; then
  echo
  echo "Version references disagree. Fix them before merging."
  exit 1
fi

echo "Everything agrees on $version."
