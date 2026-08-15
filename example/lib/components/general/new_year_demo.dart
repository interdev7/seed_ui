import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, Switch, Tooltip, Drawer, Card;
import 'package:seed_ui/seed_ui.dart';

import '../../main.dart';
import '../../theme/new_year_theme.dart';
import '../group.dart';

class NewYearDemo extends StatefulWidget {
  const NewYearDemo({super.key});

  @override
  State<NewYearDemo> createState() => _NewYearDemoState();
}

class _NewYearDemoState extends State<NewYearDemo> {
  int _giftsClaimed = 3;
  double _holidayProgress = 0.75;

  @override
  Widget build(BuildContext context) {
    final mode = ThemeController.of(context).mode;
    final isDark =
        mode == ThemeModeOption.dark || mode == ThemeModeOption.newYearNight;
    return ConfigProvider(
      theme: newYearTheme(dark: isDark),
      child: Builder(
        builder: (context) {
          final token = context.softToken;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Both display faces cover Latin and Cyrillic, so a bilingual
                // greeting stays in one typeface all the way through.
                Text(
                  'Merry & Bright · С Новым годом',
                  style: NewYearTypography.bundled.scriptStyle(
                    color: token.primary.base,
                    size: 34,
                  ),
                ),
                Text(
                  'ЁЛКА · TREE · 2026',
                  style: NewYearTypography.bundled.ornamentStyle(
                    color: token.error.base,
                    size: 22,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Text(
                    'Marck Script and Ruslan Display for the headings, Nunito '
                    'for everything else — all three carry Cyrillic, so nothing '
                    'falls back mid-word.',
                    style: TextStyle(
                      color: token.colorTextSecondary,
                      fontSize: token.fontSizeSM,
                    ),
                  ),
                ),

                // Festive Banner
                const Group(
                  'Holiday Banner 🎄',
                  Alert(
                    type: StatusType.warning,
                    message: Text('Happy New Year 2026! 🎄🎅'),
                    description: Text(
                      'Celebrate the holiday season with special discounts, gifts, and festive themes!',
                    ),
                    showIcon: true,
                  ),
                ),

                // Festive Buttons
                Group(
                  'Festive Action Buttons 🎁',
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      Button(
                        color: ButtonColor.primary,
                        icon: const Icon(Icons.card_giftcard),
                        onPressed: () {
                          setState(() {
                            _giftsClaimed++;
                            _holidayProgress = (_holidayProgress + 0.05).clamp(
                              0.0,
                              1.0,
                            );
                          });
                          message.success(
                            'Gift claimed! 🎉 Total: $_giftsClaimed',
                          );
                        },
                        child: const Text('Claim Gift 🎁'),
                      ),
                      Button(
                        color: ButtonColor.success,
                        icon: const Icon(Icons.park),
                        onPressed: () {
                          message.info('Decorated the Christmas Tree! 🎄');
                        },
                        child: const Text('Decorate Tree'),
                      ),
                      Button(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF4D4F), Color(0xFF722ED1)],
                        ),
                        icon: const Icon(Icons.auto_awesome),
                        onPressed: () {
                          message.success('Magic Gradient Activated! ✨');
                        },
                        child: const Text('Magic Gradient'),
                      ),
                      Button(
                        variant: ButtonVariant.outlined,
                        icon: const Icon(Icons.ac_unit),
                        onPressed: () {
                          message.warning('Let it snow! ❄️');
                        },
                        child: const Text('Snowfall'),
                      ),
                    ],
                  ),
                ),

                // Holiday Progress & Badges
                Group(
                  'Holiday Event Progress ⛄',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Holiday Quest Completion',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: token.colorText,
                            ),
                          ),
                          const Tag(
                            color: TagColor.warning,
                            child: Text('LIMITED TIME ⏳'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Progress(
                        percent: _holidayProgress,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF4D4F), Color(0xFFFFD700)],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                'Dashboard Ring 🎛️',
                                style: TextStyle(
                                  color: token.colorTextSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Progress(
                                type: ProgressType.dashboard,
                                percent: _holidayProgress,
                                size: 90,
                                gradient: const SweepGradient(
                                  colors: [
                                    Color(0xFF108EE9),
                                    Color(0xFF87D068),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                '5-Step Quest 🏁',
                                style: TextStyle(
                                  color: token.colorTextSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: 140,
                                child: Progress(
                                  percent: _holidayProgress,
                                  steps: const ProgressSteps(5),
                                  strokeWidth: 10,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF722ED1),
                                      Color(0xFF1677FF),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Elves / Santa Avatar Group
                const Group(
                  'Santa\'s Helpers 🎅',
                  Wrap(
                    spacing: 16,
                    children: [
                      AvatarGroup(
                        maxCount: 4,
                        children: [
                          Avatar(
                            gradient: LinearGradient(
                              colors: [Color(0xFFC62828), Color(0xFFFF8F00)],
                            ),
                            foregroundColor: Colors.white,
                            child: Text('🎅'),
                          ),
                          Avatar(
                            gradient: LinearGradient(
                              colors: [Color(0xFF2E7D32), Color(0xFFAEEA00)],
                            ),
                            foregroundColor: Colors.white,
                            child: Text('🧝'),
                          ),
                          Avatar(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFFB300), Color(0xFFFF6D00)],
                            ),
                            foregroundColor: Colors.white,
                            child: Text('🦌'),
                          ),
                          Avatar(
                            gradient: LinearGradient(
                              colors: [Color(0xFF0288D1), Color(0xFF00E5FF)],
                            ),
                            foregroundColor: Colors.white,
                            child: Text('⛄'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Holiday Card Offer
                Group(
                  'Special Holiday Offer 📜',
                  Card(
                    title: const Text('🎄 New Year Season Pass'),
                    extra: const Tag(
                      color: TagColor.error,
                      child: Text('50% OFF'),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unlock exclusive holiday themes, icons, and special rewards during the New Year event.',
                          style: TextStyle(color: token.colorTextSecondary),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Button(
                              color: ButtonColor.primary,
                              onPressed: () {
                                Modal.confirm(
                                  title: 'Claim Season Pass? 🎟️',
                                  content:
                                      'Enjoy 50% discount on all holiday rewards!',
                                  onOk: () {
                                    message.success('Season Pass Unlocked! 🎆');
                                    return true;
                                  },
                                );
                              },
                              child: const Text('Unlock Now'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
