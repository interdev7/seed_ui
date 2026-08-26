import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class SelectDemo extends StatefulWidget {
  const SelectDemo({super.key});

  @override
  State<SelectDemo> createState() => _SelectDemoState();
}

class _SelectDemoState extends State<SelectDemo> {
  List<String> _single = const [];
  List<String> _multi = const ['apple', 'banana'];
  List<String> _tags = const ['red'];
  List<String> _hideSelected = const [];

  static const _goods = ['Apples', 'Nails', 'Bananas', 'Helicopters'];

  static const _fruits = [
    SelectOption(value: 'apple', filterText: 'Apple'),
    SelectOption(value: 'banana', filterText: 'Banana'),
    SelectOption(value: 'cherry', filterText: 'Cherry'),
    SelectOption(value: 'durian', filterText: 'Durian', disabled: true),
    SelectOption(value: 'elderberry', filterText: 'Elderberry'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Group(
          'Basic',
          Select<String>(
            value: _single,
            placeholder: 'Select a fruit',
            allowClear: true,
            options: _fruits,
            onChanged: (v) => setState(() => _single = v),
          ),
        ),
        Group(
          'Searchable',
          Select<String>(
            value: _single,
            placeholder: 'Type to filter',
            showSearch: true,
            allowClear: true,
            options: _fruits,
            onChanged: (v) => setState(() => _single = v),
          ),
        ),
        Group(
          'search config (sorted alphabetically)',
          Select<String>(
            value: _single,
            placeholder: 'Filter by label, sorted',
            options: _fruits,
            // The search object: filter + sort in one config.
            search: SelectSearch<String>(
              filterSort: (a, b) => a.filterText!.toLowerCase().compareTo(
                b.filterText!.toLowerCase(),
              ),
              onSearch: (q) => debugPrint('search: $q'),
            ),
            onChanged: (v) => setState(() => _single = v),
          ),
        ),
        Group(
          'Multiple (tags wrap across lines)',
          Select<String>(
            value: _multi,
            mode: SelectMode.multiple,
            placeholder: 'Pick several',
            showSearch: true,
            allowClear: true,
            options: _fruits,
            onChanged: (v) => setState(() => _multi = v),
          ),
        ),
        Group(
          'Multiple — maxTagCount: 2 (+N)',
          Select<String>(
            value: _multi,
            mode: SelectMode.multiple,
            placeholder: 'Pick several',
            maxTagCount: 2,
            options: _fruits,
            onChanged: (v) => setState(() => _multi = v),
          ),
        ),
        Group(
          'Multiple — responsive tags (one line, +N)',
          Select<String>(
            value: _multi,
            mode: SelectMode.multiple,
            placeholder: 'Pick several',
            maxTagCountResponsive: true,
            options: _fruits,
            onChanged: (v) => setState(() => _multi = v),
          ),
        ),
        Group(
          'Tags (free entry)',
          Select<String>(
            value: _tags,
            mode: SelectMode.tags,
            placeholder: 'Add tags',
            options: const [
              SelectOption(value: 'red', filterText: 'Red'),
              SelectOption(value: 'green', filterText: 'Green'),
              SelectOption(value: 'blue', filterText: 'Blue'),
            ],
            onChanged: (v) => setState(() => _tags = v),
          ),
        ),
        Group(
          'Hide already selected options',
          Select<String>(
            value: _hideSelected,
            mode: SelectMode.multiple,
            placeholder: 'Inserted are removed',
            // Filter out what is already picked, so it disappears from the list.
            options: [
              for (final g in _goods)
                if (!_hideSelected.contains(g))
                  SelectOption(value: g, filterText: g),
            ],
            onChanged: (v) => setState(() => _hideSelected = v),
          ),
        ),
        Group(
          'optionRender (custom dropdown rows)',
          Select<String>(
            value: _single,
            placeholder: 'Fruit with a colour dot',
            options: _fruits,
            onChanged: (v) => setState(() => _single = v),
            optionRender: (option, selected) => Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: selected ? Colors.green : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(option.filterText ?? option.value)),
              ],
            ),
          ),
        ),
        Group(
          'itemRender (custom selected label)',
          Select<String>(
            value: _single,
            placeholder: 'Selected shows a star',
            options: _fruits,
            onChanged: (v) => setState(() => _single = v),
            itemRender: (option) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text(option.filterText ?? option.value),
              ],
            ),
          ),
        ),
        const Group(
          'Sizes',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Select<String>(
                size: SoftSize.small,
                placeholder: 'Small',
                options: _fruits,
              ),
              SizedBox(height: 8),
              Select<String>(
                size: SoftSize.large,
                placeholder: 'Large',
                options: _fruits,
              ),
            ],
          ),
        ),
        const Group(
          'A measurement instead of a preset',
          // The same slot takes either: a preset walks the theme's scale,
          // a measurement is taken as given.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 200,
                    child: Select<String>(
                      size: ControlSize.fixed(28),
                      placeholder: 'fixed(28)',
                      options: _fruits,
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: Select<String>(
                      size: ControlSize.fixed(44),
                      placeholder: 'fixed(44)',
                      options: _fruits,
                    ),
                  ),
                  // No SizedBox: this one names its own width too.
                  Select<String>(
                    size: ControlSize.raw(180, 36),
                    placeholder: 'raw(180, 36)',
                    options: _fruits,
                  ),
                  Select<String>(
                    size: ControlSize.raw(80, 30),
                    placeholder: 'raw(80, 30)',
                    options: _fruits,
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'A preset carries a type size of its own; a bare measurement '
                'names only itself, so the standard type stands. The '
                'two-dimensional one needs no SizedBox around it.',
              ),
            ],
          ),
        ),
        const Group(
          'Variants & status',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Select<String>(
                variant: SelectVariant.filled,
                placeholder: 'Filled',
                options: _fruits,
              ),
              SizedBox(height: 8),
              Select<String>(
                status: SelectStatus.error,
                placeholder: 'Error',
                options: _fruits,
              ),
              SizedBox(height: 8),
              Select<String>(
                loading: true,
                placeholder: 'Loading',
                options: _fruits,
              ),
              SizedBox(height: 8),
              Select<String>(
                disabled: true,
                placeholder: 'Disabled',
                options: _fruits,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
