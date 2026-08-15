import 'package:flutter/widgets.dart';

/// Entry point for the kit's context-free APIs such as `message` and
/// `notification`.
///
/// Those APIs can be called from anywhere — including code that holds no
/// [BuildContext] — because they render into the root navigator's [Overlay].
/// Reaching that overlay requires a navigator key, so the application must
/// hand one over:
///
/// ```dart
/// MaterialApp(
///   navigatorKey: UiKit.navigatorKey,
///   home: HomePage(),
/// )
/// ```
class UiKit {
  UiKit._();

  /// Install this on your `MaterialApp`/`CupertinoApp`.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'seed_ui');

  /// The overlay every floating layer is inserted into.
  static OverlayState? get overlay => navigatorKey.currentState?.overlay;

  /// The root navigator's context, used to read theme and media data.
  static BuildContext? get context => navigatorKey.currentContext;

  /// Returns the overlay, asserting with actionable guidance when the
  /// navigator key was never installed.
  static OverlayState requireOverlay() {
    final state = overlay;
    assert(
      state != null,
      'seed_ui: no Overlay found.\n'
      'Pass UiKit.navigatorKey as the navigatorKey of your '
      'MaterialApp/CupertinoApp, otherwise message and notification have '
      'nowhere to render.',
    );
    return state!;
  }
}

/// Shared machinery for stacked transient layers such as message and
/// notification.
///
/// Tracks the live entries, enforces [maxCount], and mounts or removes the
/// backing [OverlayEntry] as the stack fills and empties.
class StackedOverlay<T extends OverlayItem> {
  /// Creates a [StackedOverlay].
  StackedOverlay();

  final List<T> _items = [];

  /// Maximum simultaneous entries; older ones are dropped past this limit.
  int? maxCount;

  /// The live entries, oldest first. Unmodifiable — mutate through [add],
  /// [remove] and [destroyAll].
  List<T> get items => List.unmodifiable(_items);

  /// Bumped whenever the stack changes so the container can rebuild.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  OverlayEntry? _entry;

  /// Inserts the backing overlay entry if it is not mounted yet.
  ///
  /// [builder] renders the container around the current [items].
  void ensureMounted(WidgetBuilder builder) {
    if (_entry != null) return;
    _entry = OverlayEntry(builder: builder);
    UiKit.requireOverlay().insert(_entry!);
  }

  /// Pushes [item] onto the stack, mounting the overlay entry if needed.
  void add(T item, WidgetBuilder containerBuilder) {
    ensureMounted(containerBuilder);
    _items.add(item);
    final limit = maxCount;
    // Overflow is trimmed from the head, so the newest entry always survives.
    // Closing may be animated and therefore asynchronous, so pick the victims
    // up front instead of looping until the list shrinks.
    if (limit != null && _items.length > limit) {
      for (final victim in _items.take(_items.length - limit).toList()) {
        victim.close();
      }
    }
    revision.value++;
  }

  /// Drops [item] from the stack, tearing the overlay entry down when the
  /// last one goes.
  void remove(T item) {
    if (!_items.remove(item)) return;
    revision.value++;
    if (_items.isEmpty) {
      _entry?.remove();
      _entry = null;
    }
  }

  /// Closes every item on the stack.
  void destroyAll() {
    for (final item in List<T>.of(_items)) {
      item.close();
    }
  }
}

/// A stack entry that knows how to dismiss itself.
abstract class OverlayItem {
  /// Dismisses this entry.
  void close();
}

/// A lightweight [PopEntry] helper that binds an open overlay (such as a [Modal],
/// [Drawer], or [PopoverController]) to Flutter's native [PopScope] engine.
///
/// When system back navigation occurs (e.g. Android back button, back gesture,
/// browser back button, or `Navigator.pop`), Flutter's active route calls
/// [onPopInvoked], closing the floating layer rather than popping the page.
class OverlayPopScope implements PopEntry<dynamic> {
  /// Creates an [OverlayPopScope].
  OverlayPopScope({required this.onPop})
      : canPopNotifier = ValueNotifier<bool>(false);

  /// Called when a system back gesture should dismiss the topmost entry.
  final VoidCallback onPop;

  @override
  final ValueNotifier<bool> canPopNotifier;

  @override
  void onPopInvoked(bool didPop) {
    if (!didPop) onPop();
  }

  @override
  void onPopInvokedWithResult(bool didPop, dynamic result) {
    if (!didPop) onPop();
  }

  ModalRoute<dynamic>? _registeredRoute;

  /// Registers this pop entry on the active page route.
  void register([BuildContext? context]) {
    final route = _findRoute(context);
    if (route != null) {
      _registeredRoute = route;
      route.registerPopEntry(this);
      route.popped.then((_) {
        unregister();
        onPop();
      });
    }
  }

  /// Unregisters this pop entry from the page route when the overlay closes.
  void unregister() {
    final route = _registeredRoute;
    if (route != null && route.isActive) {
      route.unregisterPopEntry(this);
      _registeredRoute = null;
    }
  }

  static ModalRoute<dynamic>? _findRoute(BuildContext? context) {
    if (context != null && context.mounted) {
      final route = ModalRoute.of(context);
      if (route != null) return route;
    }
    final focusContext = FocusManager.instance.primaryFocus?.context;
    if (focusContext != null && focusContext.mounted) {
      final route = ModalRoute.of(focusContext);
      if (route != null) return route;
    }
    final navState = UiKit.navigatorKey.currentState;
    if (navState != null && navState.mounted) {
      ModalRoute<dynamic>? activeRoute;
      navState.popUntil((route) {
        if (route is ModalRoute) {
          activeRoute = route;
        }
        return true;
      });
      if (activeRoute != null) return activeRoute;
    }
    return null;
  }
}
