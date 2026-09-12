#!/usr/bin/env bash
# Renders the pub.dev screenshots that pubspec.yaml points at.
#
#     ./tool/shoot.sh
#
# Flutter is the only thing that can lay out and paint a Flutter widget, so
# the scenes are a test file: `tool/screenshots/shoot_test.dart` writes one
# PNG per theme. This joins each pair — light beside dark, one slot in the
# gallery instead of two — and encodes the WebP.
set -euo pipefail
cd "$(dirname "$0")/.."

command -v cwebp >/dev/null || { echo "cwebp not found (brew install webp)"; exit 1; }
command -v ffmpeg >/dev/null || { echo "ffmpeg not found (brew install ffmpeg)"; exit 1; }

out=tool/screenshots/out
rm -rf "$out"
flutter test tool/screenshots/shoot_test.dart

for light in "$out"/*.light.png; do
  name=$(basename "$light" .light.png)
  dark="$out/$name.dark.png"
  [ -f "$dark" ] || { echo "no dark half for $name"; exit 1; }
  # A hairline between the halves, so the join reads as two themes rather
  # than one picture that changes its mind in the middle.
  ffmpeg -loglevel error -y -i "$light" -i "$dark" \
    -filter_complex "[0:v][1:v]hstack=inputs=2" "$out/$name.png"
  cwebp -quiet -q 92 "$out/$name.png" -o "doc/screenshots/$name.webp"
  echo "✓ doc/screenshots/$name.webp  ($(identify_size() { :; }; echo "$(sips -g pixelWidth -g pixelHeight "$out/$name.png" | awk '/pixel/{printf "%s ", $2}')"))"
done
