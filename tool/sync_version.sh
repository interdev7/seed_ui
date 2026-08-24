#!/usr/bin/env bash
#
# Regenerates the gallery's version constant from pubspec.yaml.
#
# The gallery shows the version beside its logo, and a Dart constant is the
# only way it can know one at runtime. Run this after bumping `version:`;
# `./tool/check_version.sh` fails the build if you forget.
set -euo pipefail

cd "$(dirname "$0")/.."

version="$(awk '/^version:/{print $2; exit}' pubspec.yaml)"
[ -n "$version" ] || { echo "pubspec.yaml has no version:" >&2; exit 1; }

cat > example/lib/version.dart <<EOF
// Generated from the package's pubspec.yaml — do not edit by hand.
//
// The gallery shows which version of the kit it was built against, so a
// screenshot or a deployed page says what it is. \`tool/check_version.sh\`
// fails the build if this drifts from \`pubspec.yaml\`.

/// The version of \`seed_ui\` this gallery was built against.
const seedUiVersion = '$version';
EOF

echo "example/lib/version.dart now declares $version"
