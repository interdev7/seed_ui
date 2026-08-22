# Contributing to seed_ui

Thanks for taking the time. Issues and pull requests are both welcome.

## Before you open a pull request

The tree has to be clean on all five counts — CI checks the same things, so
running them locally saves a round trip:

```sh
dart format .
flutter analyze          # must report "No issues found!"
flutter test
cd example && flutter analyze && flutter test
./tool/check_version.sh  # only matters when you touched pubspec.yaml
```

`check_version.sh` compares `pubspec.yaml` against the CHANGELOG heading and
against the constraint quoted in the README and the gallery. Bumping the
version without renaming `## Unreleased` is otherwise only caught by
`pub publish`, and a stale constraint in the README is caught by nothing at
all.

### A hook for the two easiest to forget

Formatting and the version references are both cheap to check and invisible
until something else runs, so a hook is worth installing once:

```sh
git config core.hooksPath tool/hooks
```

It refuses a commit that `dart format` would rewrite, or whose version
references disagree, and prints the command that fixes each. `git commit
--no-verify` skips it.

Analyze and test are deliberately left out: a hook that takes fifteen seconds
gets skipped, and a skipped hook guards nothing. Those wait for CI.

`analysis_options.yaml` is deliberately strict. Two rules matter most:

- **`public_member_api_docs`** — every public member carries a doc comment.
  A new public class, field or enum value without one fails analysis.
- **`prefer_single_quotes`, `directives_ordering`** — `dart format` and
  `dart fix --apply` handle most of it.

## Writing tests

Every behaviour change needs a test. A few things specific to this kit:

- **`Spinner` animates forever.** Any test that renders a loading button, a
  `message.loading()` toast or a spinner **cannot use `pumpAndSettle`** — the
  tree never goes quiet and the call times out. Drive frames by hand:

  ```dart
  await tester.pump();                                  // start it
  await tester.pump(const Duration(milliseconds: 400)); // run it out
  await tester.pump();                                  // let the stack rebuild
  ```

  That last pump matters: overlay entries are removed from an animation
  completion callback, so the container rebuilds on the following frame.

- **Collapsed content stays mounted at zero size.** `Collapse`, `Tree` and
  `TimelineGroupItem` keep hidden children in the tree, so `findsNothing` is
  the wrong assertion. Measure geometry instead:

  ```dart
  final shut = tester.getSize(find.byType(Timeline)).height;
  controller.open();
  await tester.pumpAndSettle();
  expect(tester.getSize(find.byType(Timeline)).height, greaterThan(shut));
  ```

## Changing the public API

`lib/seed_ui.dart` is the only entry point, and every `show` clause in it is a
promise. Adding a name is cheap; removing one is a breaking change.

- Export a type only if it can be explained in terms of what a user is trying
  to do, not in terms of how the kit is built. Painters, layout helpers and
  geometry types belong in `lib/src`, unexported.
- Keep the barrel's exports alphabetical — `directives_ordering` enforces it.

While the package is on `0.x` the API is not stable. A breaking change bumps
the minor version (`0.1.0` → `0.2.0`) and needs a CHANGELOG entry that says
what moved and why.

### What the version number promises

From `1.0.0` on, semantic versioning applies to a specific thing, and it is
worth being exact about which — a promise that covers everything cannot be
kept.

**Covered.** The exported names and their signatures: the contents of
`test/public_api.txt`, plus the parameters and types of everything it lists.
Removing a name, renaming a parameter, narrowing a type or making an optional
parameter required is a breaking change.

**Not covered.** The values behind the tokens, and what the widgets look like.
A default radius, a hover tint, an easing curve or a pixel of padding may
change in any release. Pinning those would mean a major version for every
visual correction, which serves nobody.

Also not covered: anything under `lib/src` that the barrel does not export.
Reaching into it is unsupported, and the snapshot test does not guard it.

`test/public_api.txt` is the machine-readable half of this promise. Note its
limit: it lists names, so it catches one appearing or disappearing, but a
changed signature passes it silently. Review those by hand.

## Component documentation

Each component has a page under `doc/`, linked from the README table. A new
component needs one, and a changed API needs its page updated in the same PR.

The directory is `doc/`, not `docs/` — pub.dev only recognises the singular
form.

## Commit messages and releases

Commits use a `type: summary` prefix (`feat:`, `fix:`, `docs:`, `ci:`,
`test:`, `refactor:`).

Releases are version-driven, not tag-driven: bump `version:` in `pubspec.yaml`
and merge to main. The workflow checks that `CHANGELOG.md` has a matching
section, analyzes, tests and dry-runs the publish, and only then creates the
`v<version>` tag and opens the GitHub release. You never push the tag yourself.

Because the tag comes last, a run that fails leaves the version untagged. It
opens an issue saying so rather than failing quietly, and comments on that
issue instead of opening another if it fails again.

A version that was skipped while the workflow was broken does not get picked
up later: the run only ever looks at the version `pubspec.yaml` carries at that
moment. Tag a skipped one by hand:

```sh
git tag v<version> <the commit that carried it>
git push origin v<version>
```

**Publishing to pub.dev is done by hand** and is not part of any workflow.
