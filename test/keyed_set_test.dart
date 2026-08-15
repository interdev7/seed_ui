import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/src/utils/keyed_set.dart';

void main() {
  test('uncontrolled: seeds from initial and commits internally', () {
    final s = KeyedSet(['a']);
    expect(s.effective(null), {'a'});

    // Uncontrolled commit stores and reports a change.
    expect(s.commit(null, {'a', 'b'}), isTrue);
    expect(s.effective(null), {'a', 'b'});

    // Same set → no change.
    expect(s.commit(null, {'b', 'a'}), isFalse);
  });

  test('controlled: value wins and commit is a no-op', () {
    final s = KeyedSet(['a']);
    // The controlled value overrides the internal set.
    expect(s.effective(['x', 'y']), {'x', 'y'});

    // Committing while controlled does not touch the internal state.
    expect(s.commit(['x'], {'z'}), isFalse);
    expect(s.effective(null), {'a'});
  });

  test('effective returns a copy for controlled input', () {
    final s = KeyedSet();
    final controlled = ['a'];
    final got = s.effective(controlled)..add('b');
    expect(controlled, ['a']); // caller mutation does not leak back
    expect(got, {'a', 'b'});
  });
}
