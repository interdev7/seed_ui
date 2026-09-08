import 'dart:ui' show Tristate;

import 'package:flutter/material.dart'
    hide ThemeData, Form, Switch, Drawer, Tooltip, Table, TableRow;
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seed_ui/seed_ui.dart';

Widget _host(Widget child) => ConfigProvider(
      theme: ThemeData(),
      child: MaterialApp(
        // The kit's own key: a select's menu and a picker's panel are
        // mounted in the overlay it names.
        navigatorKey: UiKit.navigatorKey,
        home: Scaffold(body: Center(child: SizedBox(width: 320, child: child))),
      ),
    );

/// Runs [body] with the semantics tree switched on.
///
/// The handle has to be let go before the test ends — a tearDown runs after
/// the check that would catch it, so it is done here by hand.
Future<void> reading(WidgetTester tester, Future<void> Function() body) async {
  final handle = tester.ensureSemantics();
  try {
    await body();
  } finally {
    handle.dispose();
  }
}

void main() {
  _theRest();

  _windowsAndTabs();

  _selectAndPickers();

  group('a text field', () {
    testWidgets('is a text field, and says what it is called', (tester) async {
      await reading(tester, () async {
        await tester.pumpWidget(
          _host(const Input(semanticsLabel: 'Email')),
        );
        final node = tester.getSemantics(find.byType(EditableText));
        expect(
          node.flagsCollection.isTextField,
          isTrue,
          reason: 'a screen reader is told what kind of thing this is',
        );
        expect(node.label, 'Email');
      });
    });

    testWidgets('a placeholder names a field that stands on its own',
        (tester) async {
      await reading(tester, () async {
        await tester.pumpWidget(_host(const Input(placeholder: 'Search')));
        expect(tester.getSemantics(find.byType(EditableText)).label, 'Search');
      });
    });

    testWidgets(
        'says it is in trouble, so the red border is not the only '
        'way the news arrives', (tester) async {
      await reading(tester, () async {
        await tester.pumpWidget(_host(const Input(semanticsLabel: 'Email')));
        expect(
          tester.getSemantics(find.byType(EditableText)).validationResult,
          SemanticsValidationResult.none,
        );

        await tester.pumpWidget(
          _host(
            const Input(semanticsLabel: 'Email', status: InputStatus.error),
          ),
        );
        expect(
          tester.getSemantics(find.byType(EditableText)).validationResult,
          SemanticsValidationResult.invalid,
        );
      });
    });

    testWidgets('a warning is not an error', (tester) async {
      await reading(tester, () async {
        await tester.pumpWidget(
          _host(const Input(status: InputStatus.warning)),
        );
        expect(
          tester.getSemantics(find.byType(EditableText)).validationResult,
          SemanticsValidationResult.none,
        );
      });
    });
  });

  group('a form field', () {
    Future<SemanticsNode> pump(
      WidgetTester tester,
      FormController form, {
      Widget label = const Text('Email'),
    }) async {
      await tester.pumpWidget(
        _host(
          Form(
            controller: form,
            child: Column(
              children: [
                FormItem.text(
                  name: 'email',
                  label: label,
                  rules: const [FormRule.required()],
                ),
              ],
            ),
          ),
        ),
      );
      return tester.getSemantics(find.byType(EditableText));
    }

    testWidgets('takes its name from the label written beside it',
        (tester) async {
      await reading(tester, () async {
        final form = FormController();
        addTearDown(form.dispose);
        // A label beside a box is not part of the box: without this a reader
        // hears "text field" and has to guess which one.
        expect((await pump(tester, form)).label, 'Email');
      });
    });

    testWidgets('is marked invalid once the rules have refused it',
        (tester) async {
      await reading(tester, () async {
        final form = FormController();
        addTearDown(form.dispose);
        expect(
          (await pump(tester, form)).validationResult,
          SemanticsValidationResult.none,
        );

        await form.validate();
        await tester.pumpAndSettle();
        expect(
          tester.getSemantics(find.byType(EditableText)).validationResult,
          SemanticsValidationResult.invalid,
        );
      });
    });

    testWidgets('a label built of widgets is left unread rather than guessed',
        (tester) async {
      await reading(tester, () async {
        final form = FormController();
        addTearDown(form.dispose);
        final node = await pump(
          tester,
          form,
          label: const Row(children: [Icon(Icons.mail), Text('Email')]),
        );
        // Half a label in a reader's ear is worse than none: the field keeps
        // whatever the control itself says.
        expect(node.label, isNot('Email'));
      });
    });
  });
}

void _selectAndPickers() {
  group('a select', () {
    testWidgets('says what it is, what it is called and what is in it',
        (tester) async {
      await reading(tester, () async {
        await tester.pumpWidget(
          _host(
            Select<String>(
              placeholder: 'Country',
              value: const ['fr'],
              options: const [
                SelectOption(
                  value: 'fr',
                  label: Text('France'),
                  filterText: 'France',
                ),
              ],
              onChanged: (_) {},
            ),
          ),
        );
        final node = tester.getSemantics(find.byType(Select<String>));
        expect(node.flagsCollection.isButton, isTrue);
        expect(node.label, contains('Country'));
        // The chosen option in words, taken from the plain text it already
        // carries for searching: a label built of widgets has no one string.
        expect(node.value, 'France');
      });
    });

    testWidgets('says whether it is open', (tester) async {
      await reading(tester, () async {
        await tester.pumpWidget(
          _host(
            Select<String>(
              placeholder: 'Country',
              options: const [
                SelectOption(value: 'fr', filterText: 'France'),
              ],
              onChanged: (_) {},
            ),
          ),
        );
        expect(
          tester
              .getSemantics(find.byType(Select<String>))
              .flagsCollection
              .isExpanded,
          Tristate.isFalse,
          reason: 'shut, and saying so rather than saying nothing',
        );

        await tester.tap(find.byType(Select<String>));
        await tester.pumpAndSettle();
        expect(
          tester
              .getSemantics(find.byType(Select<String>))
              .flagsCollection
              .isExpanded,
          Tristate.isTrue,
        );
      });
    });

    testWidgets('says it is in trouble', (tester) async {
      await reading(tester, () async {
        await tester.pumpWidget(
          _host(
            Select<String>(
              placeholder: 'Country',
              status: SelectStatus.error,
              options: const [SelectOption(value: 'fr', filterText: 'France')],
              onChanged: (_) {},
            ),
          ),
        );
        expect(
          tester.getSemantics(find.byType(Select<String>)).validationResult,
          SemanticsValidationResult.invalid,
        );
      });
    });
  });

  group('a picker', () {
    testWidgets('says what it is called and what it holds', (tester) async {
      await reading(tester, () async {
        await tester.pumpWidget(
          _host(
            DatePicker(
              semanticsLabel: 'When',
              value: DateTime(2026, 3, 10),
              onChanged: (_) {},
            ),
          ),
        );
        final node = tester.getSemantics(find.byType(DatePicker));
        expect(node.flagsCollection.isButton, isTrue);
        expect(node.label, contains('When'));
        expect(node.value, '2026-03-10');
      });
    });

    testWidgets('a time picker says the time it holds', (tester) async {
      await reading(tester, () async {
        await tester.pumpWidget(
          _host(
            TimePicker(
              semanticsLabel: 'What time',
              value: const Duration(hours: 9, minutes: 30),
              onChanged: (_) {},
            ),
          ),
        );
        final node = tester.getSemantics(find.byType(TimePicker));
        expect(node.label, contains('What time'));
        expect(node.value, '09:30:00');
      });
    });
  });
}

/// The kit's own "a window has opened" node, named by its title.
///
/// Flutter puts a scope of its own around a route, so the flag alone finds
/// two; the name is what tells them apart.
Finder _theWindow(String named) => find.byWidgetPredicate(
      (w) =>
          w is Semantics &&
          (w.properties.scopesRoute ?? false) &&
          w.properties.label == named,
    );

void _windowsAndTabs() {
  group('a window that has come over the page', () {
    testWidgets('a modal says it is one, and gives its title as the name',
        (tester) async {
      await reading(tester, () async {
        await tester.pumpWidget(
          _host(const Text('the page behind')),
        );
        // ignore: unawaited_futures
        Modal.confirm(title: 'Delete?', content: 'Forever.');
        await tester.pumpAndSettle();
        final node = tester.getSemantics(_theWindow('Delete?'));
        expect(node.flagsCollection.scopesRoute, isTrue);
        expect(node.flagsCollection.namesRoute, isTrue);
        expect(node.label, contains('Delete?'));
      });
    });

    testWidgets('a drawer says the same', (tester) async {
      await reading(tester, () async {
        await tester.pumpWidget(_host(const Text('the page behind')));
        // ignore: unawaited_futures
        Drawer.open(
          const DrawerConfig(title: Text('Filters'), child: Text('body')),
        );
        await tester.pumpAndSettle();
        final node = tester.getSemantics(_theWindow('Filters'));
        expect(node.flagsCollection.scopesRoute, isTrue);
        expect(node.label, contains('Filters'));
      });
    });
  });

  group('a tab', () {
    testWidgets('says it can be pressed, and which one is showing',
        (tester) async {
      await reading(tester, () async {
        await tester.pumpWidget(
          _host(
            const Tabs(
              items: [
                TabItem(key: 'a', label: Text('One'), content: Text('first')),
                TabItem(key: 'b', label: Text('Two'), content: Text('second')),
              ],
            ),
          ),
        );
        final one = tester.getSemantics(find.text('One'));
        final two = tester.getSemantics(find.text('Two'));
        expect(one.flagsCollection.isButton, isTrue);
        expect(one.flagsCollection.isSelected, Tristate.isTrue);
        expect(two.flagsCollection.isSelected, Tristate.isFalse);
      });
    });
  });
}

/// The pressable header the words [label] sit in.
Finder _headerOf(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate(
        (w) => w is Semantics && (w.properties.button ?? false),
      ),
    );

void _theRest() {
  group('a tree node', () {
    testWidgets('says whether it is picked and whether its branch is open',
        (tester) async {
      await reading(tester, () async {
        await tester.pumpWidget(
          _host(
            const Tree(
              defaultExpandedKeys: ['fruit'],
              defaultSelectedKeys: ['apple'],
              nodes: [
                TreeNode(
                  key: 'fruit',
                  title: Text('Fruit'),
                  children: [TreeNode(key: 'apple', title: Text('Apple'))],
                ),
              ],
            ),
          ),
        );
        final branch = tester.getSemantics(find.text('Fruit'));
        final leaf = tester.getSemantics(find.text('Apple'));
        expect(branch.flagsCollection.isExpanded, Tristate.isTrue);
        expect(branch.flagsCollection.isSelected, Tristate.isFalse);
        expect(leaf.flagsCollection.isSelected, Tristate.isTrue);
        // A leaf has nothing to open, so it says nothing about opening.
        expect(leaf.flagsCollection.isExpanded, Tristate.none);
      });
    });
  });

  group('an accordion header', () {
    testWidgets('says whether its panel is open', (tester) async {
      await reading(tester, () async {
        await tester.pumpWidget(
          _host(
            const Collapse(
              defaultActiveKeys: ['a'],
              items: [
                CollapseItem(
                    key: 'a', label: Text('Open one'), content: Text('x')),
                CollapseItem(
                    key: 'b', label: Text('Shut one'), content: Text('y')),
              ],
            ),
          ),
        );
        // The header's own node, not the label's: a word inside a control
        // has a node of its own and knows nothing of the control.
        expect(
          tester.getSemantics(_headerOf('Open one')).flagsCollection.isExpanded,
          Tristate.isTrue,
        );
        expect(
          tester.getSemantics(_headerOf('Shut one')).flagsCollection.isExpanded,
          Tristate.isFalse,
        );
      });
    });
  });

  group('a tooltip', () {
    testWidgets('carries its words on the thing it describes', (tester) async {
      await reading(tester, () async {
        await tester.pumpWidget(
          _host(
            const Tooltip(
              message: Text('What this does'),
              child: Icon(Icons.help),
            ),
          ),
        );
        // The bubble opens on a hover nobody hovering with a keyboard can
        // make, so the words have to reach a reader without it.
        expect(
          tester.getSemantics(find.byType(Icon)).tooltip,
          'What this does',
        );
      });
    });
  });

  group('a table', () {
    testWidgets('a heading says it is one, and which way it is sorted',
        (tester) async {
      await reading(tester, () async {
        await tester.pumpWidget(
          _host(
            Table<int>(
              data: const [1, 2],
              columns: [
                TableColumn<int>(
                  title: const Text('Number'),
                  value: (n) => '$n',
                  sortable: true,
                  sorter: (a, b) => a.compareTo(b),
                ),
              ],
            ),
          ),
        );
        final node = tester.getSemantics(find.text('Number'));
        expect(node.flagsCollection.isHeader, isTrue);
        expect(node.value, isNotEmpty,
            reason: 'the carets say it in a picture');
      });
    });
  });
}
