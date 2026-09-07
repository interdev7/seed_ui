#!/usr/bin/env bash
#
# Checks that every property of an exported widget is named in that widget's
# document, and that the documents keep to one shape.
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
# The second half asks for a shape rather than a schema. Every document opens
# with its widget's name, a sentence saying what it is, and an example; and
# every component that has a `*Token` class ends with `## Design tokens`,
# spelled that way and only that way. What goes between is the writer's — the
# documents explain themselves in whatever order suits the component, and a
# forced `## Properties` in each of forty-four would flatten that for nothing.
# What is fixed is what a reader, or a program reading for one, has to be able
# to find without guessing.
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
shape = []
checked = 0

# Two spellings of one heading is two headings to look for. The one on the
# right is the kit's.
SYNONYMS = {
    '## Tokens': '## Design tokens',
    '## Design Tokens': '## Design tokens',
    '## Size': '## Sizes',
    '## Not yet': '## Not here yet',
    '## Coming later': '## Not here yet',
}
for source in sorted(glob.glob('lib/src/components/*/*.dart')):
    group = os.path.basename(os.path.dirname(source))
    name = os.path.basename(source)[:-5]
    doc = f'doc/{group}/{name}.md'
    if not os.path.exists(doc):
        gaps.append((name, doc, ['— the document itself is missing']))
        continue
    code = open(source).read()
    prose = open(doc).read()
    lines = prose.split('\n')

    # The opening: a title, a sentence, an example. A reader arriving from a
    # link and a program building an answer both start here.
    if not lines[0].startswith('# '):
        shape.append(f'{doc} does not open with a `# Title`')
    elif len(lines) > 2 and (
        not lines[2].strip() or lines[2].startswith(('#', '|', '```'))
    ):
        shape.append(f'{doc} says nothing about itself before its first '
                     f'heading or table')
    if '```dart' not in prose:
        shape.append(f'{doc} shows no example')

    for wrong, right in SYNONYMS.items():
        if re.search(r'^' + re.escape(wrong) + r'\s*$', prose, re.M):
            shape.append(f'{doc} says `{wrong}` where the kit says `{right}`')

    # A component with tokens says so under the heading everything else uses.
    tokens = [c for c in re.findall(r'class (\w+Token)\b', code)
              if c in exported]
    if tokens and not re.search(r'^## Design tokens\s*$', prose, re.M):
        shape.append(f'{doc} never reaches `## Design tokens`, though '
                     f'{tokens[0]} exists')

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

for line in shape:
    print(f'✗ {line}')
    if os.environ.get('GITHUB_ACTIONS'):
        print(f'::error::{line}')

for widget, doc, missing in gaps:
    line = f'{widget} has {", ".join(missing)} but {doc} never says so'
    print(f'✗ {line}')
    if os.environ.get('GITHUB_ACTIONS'):
        print(f'::error::{line}')

if gaps or shape:
    print()
    print('Document these before merging, or the reader learns them from the '
          'source.')
    sys.exit(1)

print(f'✓ every property of {checked} exported widgets is named in its '
      f'document')
print('✓ every document opens the same way and names its tokens the same way')
PY
