#!/usr/bin/env bash
#
# Checks that every property of an exported widget is named in that widget's
# document.
#
# Documentation drifts the quiet way: a property is added, the doc is not, and
# nothing anywhere notices — the code compiles, the tests pass, and the only
# person who finds out is a reader looking for something the doc never
# mentions. Six properties across five widgets had gone that way before this
# existed.
#
# It asks only whether the name appears at all. That is a low bar on purpose:
# a check that tried to judge whether the prose was any good would either be
# wrong or be ignored, and a name that appears nowhere is a fact.
#
# Run it from the repository root:
#
#   ./tool/check_docs.sh
#
set -euo pipefail

cd "$(dirname "$0")/.."

exec python3 - "$@" <<'PY'
import glob
import os
import re
import sys

exported = set(open('test/public_api.txt').read().split())

gaps = []
checked = 0
for source in sorted(glob.glob('lib/src/components/*/*.dart')):
    group = os.path.basename(os.path.dirname(source))
    name = os.path.basename(source)[:-5]
    doc = f'doc/{group}/{name}.md'
    if not os.path.exists(doc):
        gaps.append((name, doc, ['— the document itself is missing']))
        continue
    code = open(source).read()
    prose = open(doc).read()
    for match in re.finditer(
        r'class (\w+)(?:<[^>]*>)? extends (?:StatefulWidget|StatelessWidget)',
        code,
    ):
        widget = match.group(1)
        # Only what a caller can actually reach: a private helper's parameters
        # are nobody's business but ours.
        if widget not in exported:
            continue
        end = code.find('  })', match.start())
        if end < 0:
            continue
        checked += 1
        params = re.findall(
            r'^\s+(?:required )?this\.(\w+)', code[match.start():end], re.M
        )
        missing = [
            p for p in params
            if not re.search(r'\b' + re.escape(p) + r'\b', prose)
        ]
        if missing:
            gaps.append((widget, doc, missing))

for widget, doc, missing in gaps:
    line = f'{widget} has {", ".join(missing)} but {doc} never says so'
    print(f'✗ {line}')
    if os.environ.get('GITHUB_ACTIONS'):
        print(f'::error::{line}')

if gaps:
    print()
    print('Document these before merging, or the reader learns them from the '
          'source.')
    sys.exit(1)

print(f'✓ every property of {checked} exported widgets is named in its document')
PY
