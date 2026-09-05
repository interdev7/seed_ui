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
#     depend on something older than what they are reading about;
#   * carrying on in a version that is already on pub.dev, which every local
#     file agrees about and none of them can see. That one cost real work: a
#     released section of the CHANGELOG was edited more than once as though it
#     were still open.
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

# Everything above compares this checkout against itself, which cannot notice
# the one thing that matters most: whether this version has already shipped.
# Skipped without a fuss when pub.dev cannot be reached, so an offline build is
# not a failing build.
published=""
if command -v curl >/dev/null 2>&1; then
  published="$(curl -fsS --max-time 10 \
    https://pub.dev/api/packages/seed_ui 2>/dev/null |
    tr ',' '\n' | grep -m1 -oE '"version":"[0-9]+\.[0-9]+\.[0-9]+"' |
    grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true)"
fi
if [ -z "$published" ]; then
  echo "· pub.dev is out of reach, so nothing was checked against it"
elif [ "$published" = "$version" ]; then
  note "pub.dev already serves $version. Bump before going further, and leave its CHANGELOG section alone — it is published."
else
  echo "✓ pub.dev serves $published, so $version is still unreleased"
fi

# The one criterion of the Flutter Favorite programme that is a plain fact
# rather than a judgement: the repository must carry a tag matching the version
# pub.dev serves, so a reader can see exactly which source is in the package.
# Seven releases went out without one before anybody noticed — nothing else
# here could have noticed, since every file in the checkout agreed with itself.
#
# Asked of the remote first: a shallow CI checkout has the commit and none of
# the tags, and reporting a missing tag that is sitting on GitHub would be
# worse than saying nothing.
if [ -n "$published" ] && command -v git >/dev/null 2>&1 &&
  git rev-parse --git-dir >/dev/null 2>&1; then
  tag="v$published"
  tags=""
  if git ls-remote --exit-code --tags origin >/dev/null 2>&1; then
    tags="$(git ls-remote --tags origin 2>/dev/null || true)"
  fi
  if [ -n "$tags" ]; then
    if printf '%s' "$tags" | grep -q "refs/tags/$tag$"; then
      # A tag that exists is not yet a tag that tells the truth. What it points
      # at has to be a commit whose own pubspec names that version — a tag put
      # on the commit *before* the bump, or on an unrelated one, would send a
      # reader to source that is not what shipped.
      tagged="$(git show "$tag:pubspec.yaml" 2>/dev/null |
        awk '/^version:/{print $2; exit}' || true)"
      if [ -z "$tagged" ]; then
        echo "✓ $tag is on the remote (this checkout cannot read it to confirm)"
      elif [ "$tagged" = "$published" ]; then
        echo "✓ $tag is on the remote, so the published source can be found"
      else
        note "$tag points at a commit whose pubspec says $tagged, not $published. Move it to the commit that was published."
      fi
    else
      note "pub.dev serves $published and no $tag tag is on the remote. Tag the commit that was published: git tag -a $tag <commit> -m '$published' && git push origin $tag"
    fi
  elif git rev-parse -q --verify "refs/tags/$tag" >/dev/null 2>&1; then
    echo "✓ $tag exists here (the remote was not reachable to confirm)"
  else
    echo "· tags could not be read, so none were checked"
  fi
fi

if [ "$fail" -ne 0 ]; then
  echo
  echo "Version references disagree. Fix them before merging."
  exit 1
fi

echo "Everything agrees on $version."
