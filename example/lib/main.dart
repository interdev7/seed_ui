import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:seed_ui/seed_ui.dart';
import 'package:go_router/go_router.dart';

import 'components/feedback/alert_demo.dart';
import 'components/data_display/avatar_demo.dart';
import 'components/data_display/badge_demo.dart';
import 'components/general/button_demo.dart';
import 'components/data_display/card_demo.dart';
import 'components/data_display/collapse_demo.dart';
import 'components/data_display/countdown_demo.dart';
import 'components/data_display/tree_demo.dart';
import 'components/data_display/listy_demo.dart';
import 'components/data_display/reorderable_list_demo.dart';
import 'components/data_display/timeline_demo.dart';
import 'components/data_display/tour_demo.dart';
import 'components/data_display/popover_demo.dart';
import 'components/data_entry/checkbox_demo.dart';
import 'components/feedback/drawer_demo.dart';
import 'components/data_display/empty_demo.dart';
import 'components/navigation/dropdown_demo.dart';
import 'components/data_entry/input_demo.dart';
import 'components/data_entry/input_number_demo.dart';
import 'components/feedback/message_demo.dart';
import 'components/feedback/modal_demo.dart';
import 'components/feedback/notification_demo.dart';
import 'components/navigation/pagination_demo.dart';
import 'components/feedback/popconfirm_demo.dart';
import 'components/feedback/progress_demo.dart';
import 'components/data_entry/radio_demo.dart';
import 'components/feedback/result_demo.dart';
import 'components/feedback/spin_demo.dart';
import 'components/data_display/segmented_demo.dart';
import 'components/data_display/steps_demo.dart';
import 'components/data_entry/select_demo.dart';
import 'components/data_entry/switch_demo.dart';
import 'components/data_entry/upload_demo.dart';
import 'components/data_display/tabs_demo.dart';
import 'components/data_display/tag_demo.dart';
import 'components/data_display/tooltip_demo.dart';
import 'components/general/new_year_demo.dart';
import 'theme/new_year_theme.dart';

void main() => runApp(const DemoApp());

enum ThemeModeOption { light, dark, newYear, newYearNight }

class ThemeController extends InheritedWidget {
  const ThemeController({
    super.key,
    required this.mode,
    required this.setTheme,
    required super.child,
  });

  final ThemeModeOption mode;
  final ValueChanged<ThemeModeOption> setTheme;

  static ThemeController of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<ThemeController>();
    assert(result != null, 'No ThemeController found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(ThemeController oldWidget) => mode != oldWidget.mode;
}

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  ThemeModeOption _mode = ThemeModeOption.light;

  ThemeData _getTheme() {
    switch (_mode) {
      case ThemeModeOption.dark:
        return ThemeData.dark;
      case ThemeModeOption.newYear:
        return newYearTheme();
      case ThemeModeOption.newYearNight:
        return newYearTheme(dark: true);
      case ThemeModeOption.light:
        return ThemeData.light;
    }
  }

  late final GoRouter _router = GoRouter(
    navigatorKey: UiKit.navigatorKey,
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomePage()),
          GoRoute(
            path: '/demo/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'];
              final demo = demos.firstWhere(
                (d) => d.id == id,
                orElse: () => demos.first,
              );
              return DemoPage(demo: demo);
            },
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return ThemeController(
      mode: _mode,
      setTheme: (mode) => setState(() => _mode = mode),
      child: ConfigProvider(
        theme: _getTheme(),
        child: MaterialApp.router(
          title: 'seed_ui',
          debugShowCheckedModeBanner: false,
          routerConfig: _router,
        ),
      ),
    );
  }
}

class MainLayout extends StatelessWidget {
  const MainLayout({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;
    final themeController = ThemeController.of(context);
    final themeLabel = switch (themeController.mode) {
      ThemeModeOption.light => 'Light ☀️',
      ThemeModeOption.dark => 'Dark 🌙',
      ThemeModeOption.newYear => 'New Year 🎄',
      ThemeModeOption.newYearNight => 'New Year night 🌙🎄',
    };
    final themeIcon = switch (themeController.mode) {
      ThemeModeOption.light => Icons.light_mode,
      ThemeModeOption.dark => Icons.dark_mode,
      ThemeModeOption.newYear => Icons.park,
      ThemeModeOption.newYearNight => Icons.nights_stay,
    };

    return Scaffold(
      backgroundColor: token.colorBgLayout,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: token.colorBgContainer,
              padding: EdgeInsets.symmetric(
                horizontal: token.sizeLG,
                vertical: token.sizeSM,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => context.go('/'),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            width: 50,
                            height: 50,
                          ),
                          Text(
                            'seed_ui',
                            style: TextStyle(
                              fontSize: token.fontSizeXL,
                              color: token.colorText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Dropdown(
                    trigger: const [DropdownTrigger.click],
                    menu: const [
                      DropdownItem(
                        key: ThemeModeOption.light,
                        label: Text('Light ☀️'),
                        icon: Icon(Icons.light_mode),
                      ),
                      DropdownItem(
                        key: ThemeModeOption.dark,
                        label: Text('Dark 🌙'),
                        icon: Icon(Icons.dark_mode),
                      ),
                      DropdownItem(
                        key: ThemeModeOption.newYear,
                        label: Text('New Year 🎄'),
                        icon: Icon(Icons.park),
                      ),
                      DropdownItem(
                        key: ThemeModeOption.newYearNight,
                        label: Text('New Year night 🌙🎄'),
                        icon: Icon(Icons.nights_stay),
                      ),
                    ],
                    onItemTap: (key) {
                      if (key is ThemeModeOption) {
                        themeController.setTheme(key);
                      }
                    },
                    child: Button(
                      onPressed: () {},
                      icon: Icon(themeIcon),
                      child: Text(themeLabel),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: token.colorBorderSecondary),
            Expanded(
              child: DefaultTextStyle(
                style: TextStyle(
                  fontSize: token.fontSize,
                  color: token.colorText,
                  fontFamily: token.fontFamily,
                  fontFamilyFallback: token.fontFamilyFallback,
                  decoration: TextDecoration.none,
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Demo {
  const Demo(this.id, this.title, this.builder);
  final String id;
  final String title;
  final WidgetBuilder builder;
}

final List<Demo> demos = [
  Demo('new_year', 'New Year Theme 🎄', (_) => const NewYearDemo()),
  Demo('avatar', 'Avatar', (_) => const AvatarDemo()),
  Demo('badge', 'Badge', (_) => const BadgeDemo()),
  Demo('countdown', 'Countdown', (_) => const CountdownDemo()),
  Demo('button', 'Button', (_) => const ButtonDemo()),
  Demo('message', 'message', (_) => const MessageDemo()),
  Demo('notification', 'notification', (_) => const NotificationDemo()),
  Demo('modal', 'Modal', (_) => const ModalDemo()),
  Demo('drawer', 'Drawer', (_) => const DrawerDemo()),
  Demo('popconfirm', 'Popconfirm', (_) => const PopconfirmDemo()),
  Demo('tooltip', 'Tooltip', (_) => const TooltipDemo()),
  Demo('popover', 'Popover', (_) => const PopoverDemo()),
  Demo('alert', 'Alert', (_) => const AlertDemo()),
  Demo('progress', 'Progress', (_) => const ProgressDemo()),
  Demo('result', 'Result', (_) => const ResultDemo()),
  Demo('spin', 'Spin', (_) => const SpinDemo()),
  Demo('input', 'Input', (_) => const InputDemo()),
  Demo('inputnumber', 'InputNumber', (_) => const InputNumberDemo()),
  Demo('segmented', 'Segmented', (_) => const SegmentedDemo()),
  Demo('tabs', 'Tabs', (_) => const TabsDemo()),
  Demo('card', 'Card', (_) => const CardDemo()),
  Demo('collapse', 'Collapse', (_) => const CollapseDemo()),
  Demo('tree', 'Tree', (_) => const TreeDemo()),
  Demo('sortablelist', 'SortableList', (_) => const ReorderableListDemo()),
  Demo('listy', 'Listy', (_) => const ListyDemo()),
  Demo('steps', 'Steps', (_) => const StepsDemo()),
  Demo('timeline', 'Timeline', (_) => const TimelineDemo()),
  Demo('tour', 'Tour', (_) => const TourDemo()),
  Demo('switch', 'Switch', (_) => const SwitchDemo()),
  Demo('upload', 'Upload', (_) => const UploadDemo()),
  Demo('select', 'Select', (_) => const SelectDemo()),
  Demo('dropdown', 'Dropdown', (_) => const DropdownDemo()),
  Demo('empty', 'Empty', (_) => const EmptyDemo()),
  Demo('pagination', 'Pagination', (_) => const PaginationDemo()),
  Demo('tag', 'Tag', (_) => const TagDemo()),
  Demo('checkbox', 'Checkbox', (_) => const CheckboxDemo()),
  Demo('radio', 'Radio', (_) => const RadioDemo()),
];

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: token.sizeLG),
      itemCount: demos.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: token.colorSplit),
      itemBuilder: (context, i) {
        final demo = demos[i];
        return _DemoTile(
          title: demo.title,
          onTap: () => context.go('/demo/${demo.id}'),
        );
      },
    );
  }
}

class _DemoTile extends StatelessWidget {
  const _DemoTile({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: token.size),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: token.fontSizeLG,
                color: token.colorText,
              ),
            ),
            Icon(Icons.chevron_right, color: token.colorTextTertiary),
          ],
        ),
      ),
    );
  }
}

class DemoPage extends StatelessWidget {
  const DemoPage({super.key, required this.demo});

  final Demo demo;

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;
    return SingleChildScrollView(
      padding: EdgeInsets.all(token.sizeLG),
      child: Center(
        child: !kIsWeb
            ? ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: demo.builder(context),
              )
            : demo.builder(context),
      ),
    );
  }
}
