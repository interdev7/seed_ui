/// Controlled-or-uncontrolled state for a set of string keys — the pattern
/// shared by `Collapse` (open panels) and the Tree family (expanded / selected
/// / checked nodes).
///
/// A parent may *control* the set by passing a non-null value on every build, or
/// leave it *uncontrolled*, in which case this object holds the internal set,
/// seeded from a default. The owning `State` keeps one instance per set:
///
/// ```dart
/// final _open = KeyedSet(widget.defaultActiveKeys);
/// Set<String> get _active => _open.effective(widget.activeKeys);
///
/// void _toggle(String key) {
///   final next = {..._active};
///   next.contains(key) ? next.remove(key) : next.add(key);
///   if (_open.commit(widget.activeKeys, next)) setState(() {});
///   widget.onChange?.call(next.toList());
/// }
/// ```
///
/// It intentionally knows nothing about *how* the next set is derived (toggle,
/// single-select, checkbox cascade) — that stays with the component.
class KeyedSet {
  /// Creates a [KeyedSet].
  KeyedSet([Iterable<String>? initial]) : _internal = {...?initial};

  Set<String> _internal;

  /// The effective set: [controlled] when non-null, otherwise the internal one.
  /// Treat the result as read-only and copy before mutating.
  Set<String> effective(Iterable<String>? controlled) =>
      controlled != null ? {...controlled} : _internal;

  /// Stores [next] as the internal set while uncontrolled, returning whether it
  /// changed (so the owner can rebuild). When [controlled] is non-null the
  /// parent owns the state and this is a no-op returning false.
  bool commit(Iterable<String>? controlled, Set<String> next) {
    if (controlled != null) return false;
    if (_internal.length == next.length && _internal.containsAll(next)) {
      return false;
    }
    _internal = {...next};
    return true;
  }
}
