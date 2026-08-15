# Contributing to seed_ui

Thanks for taking the time. Issues and pull requests are both welcome.

## Before you open a pull request

The tree has to be clean on all four counts — CI checks the same things, so
running them locally saves a round trip:

```sh
dart format .
flutter analyze          # must report "No issues found!"
flutter test
cd example && flutter analyze && flutter test
```

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

While the package is on `0.0.x` the API is not stable and breaking changes may
land in any release. They still need a CHANGELOG entry saying so.

## Component documentation

Each component has a page under `doc/`, linked from the README table. A new
component needs one, and a changed API needs its page updated in the same PR.

The directory is `doc/`, not `docs/` — pub.dev only recognises the singular
form.

## Commit messages and releases

Commits use a `type: summary` prefix (`feat:`, `fix:`, `docs:`, `ci:`,
`test:`, `refactor:`).

Releases are tag-driven: pushing `v1.2.3` runs the checks, verifies the tag
matches `pubspec.yaml` and that `CHANGELOG.md` has a matching section, then
opens the GitHub release. **Publishing to pub.dev is done by hand** and is not
part of any workflow.
