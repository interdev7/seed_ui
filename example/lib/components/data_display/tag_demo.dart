import 'package:flutter/material.dart'
    hide ThemeData, Checkbox, Radio, RadioGroup, Switch, Tooltip, Drawer;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class TagDemo extends StatefulWidget {
  const TagDemo({super.key});

  @override
  State<TagDemo> createState() => _TagDemoState();
}

class _TagDemoState extends State<TagDemo> {
  final _tags = ['Tag 1', 'Tag 2', 'Removable'];
  final _checked = <String>{'Movies'};
  List<String> _group = const ['movies'];
  List<String> _single = const ['a'];

  static const _variants = TagVariant.values;

  // The named preset colours, as hex.
  static const _presets = <String, Color>{
    'magenta': Color(0xFFEB2F96),
    'red': Color(0xFFF5222D),
    'volcano': Color(0xFFFA541C),
    'orange': Color(0xFFFA8C16),
    'gold': Color(0xFFFAAD14),
    'lime': Color(0xFFA0D911),
    'green': Color(0xFF52C41A),
    'cyan': Color(0xFF13C2C2),
    'blue': Color(0xFF1677FF),
    'geekblue': Color(0xFF2F54EB),
    'purple': Color(0xFF722ED1),
  };

  static const _customs = <String, Color>{
    '#f50': Color(0xFFFF5500),
    '#2db7f5': Color(0xFF2DB7F5),
    '#87d068': Color(0xFF87D068),
    '#108ee9': Color(0xFF108EE9),
  };

  String _variantName(TagVariant v) => v.name;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Group(
          'Status presets (outlined)',
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Tag(child: Text('default')),
              Tag(color: TagColor.primary, child: Text('primary')),
              Tag(color: TagColor.success, child: Text('success')),
              Tag(color: TagColor.processing, child: Text('processing')),
              Tag(color: TagColor.warning, child: Text('warning')),
              Tag(color: TagColor.error, child: Text('error')),
            ],
          ),
        ),
        const Group(
          'Status presets (filled)',
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Tag(variant: TagVariant.filled, child: Text('default')),
              Tag(
                variant: TagVariant.filled,
                color: TagColor.primary,
                child: Text('primary'),
              ),
              Tag(
                variant: TagVariant.filled,
                color: TagColor.success,
                child: Text('success'),
              ),
              Tag(
                variant: TagVariant.filled,
                color: TagColor.processing,
                child: Text('processing'),
              ),
              Tag(
                variant: TagVariant.filled,
                color: TagColor.warning,
                child: Text('warning'),
              ),
              Tag(
                variant: TagVariant.filled,
                color: TagColor.error,
                child: Text('error'),
              ),
            ],
          ),
        ),
        const Group(
          'Status presets (solid)',
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Tag(variant: TagVariant.solid, child: Text('default')),
              Tag(
                variant: TagVariant.solid,
                color: TagColor.primary,
                child: Text('primary'),
              ),
              Tag(
                variant: TagVariant.solid,
                color: TagColor.success,
                child: Text('success'),
              ),
              Tag(
                variant: TagVariant.solid,
                color: TagColor.processing,
                child: Text('processing'),
              ),
              Tag(
                variant: TagVariant.solid,
                color: TagColor.warning,
                child: Text('warning'),
              ),
              Tag(
                variant: TagVariant.solid,
                color: TagColor.error,
                child: Text('error'),
              ),
            ],
          ),
        ),
        for (final variant in _variants)
          Group(
            'Presets (${_variantName(variant)})',
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in _presets.entries)
                  Tag(
                    color: TagColor(e.value),
                    variant: variant,
                    child: Text(e.key),
                  ),
              ],
            ),
          ),
        for (final variant in _variants)
          Group(
            'Custom (${_variantName(variant)})',
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in _customs.entries)
                  Tag(
                    color: TagColor(e.value),
                    variant: variant,
                    child: Text(e.key),
                  ),
              ],
            ),
          ),
        const Group(
          'With icon',
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Tag(
                color: TagColor.success,
                icon: Icon(Icons.check_circle),
                child: Text('Done'),
              ),
              Tag(
                color: TagColor.processing,
                icon: Icon(Icons.sync),
                child: Text('Running'),
              ),
            ],
          ),
        ),
        Group(
          'Closable',
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in _tags)
                Tag(
                  closable: true,
                  onClose: () => setState(() => _tags.remove(t)),
                  child: Text(t),
                ),
            ],
          ),
        ),
        Group(
          'Checkable (filter chips)',
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in ['Movies', 'Books', 'Music'])
                CheckableTag(
                  checked: _checked.contains(c),
                  onChanged: (v) => setState(() {
                    v ? _checked.add(c) : _checked.remove(c);
                  }),
                  child: Text(c),
                ),
            ],
          ),
        ),
        Group(
          'CheckableTagGroup (multiple)',
          CheckableTagGroup<String>(
            multiple: true,
            value: _group,
            options: const [
              CheckableTagOption(value: 'movies', label: Text('Movies')),
              CheckableTagOption(value: 'books', label: Text('Books')),
              CheckableTagOption(value: 'music', label: Text('Music')),
              CheckableTagOption(value: 'games', label: Text('Games')),
            ],
            onChanged: (v) => setState(() => _group = v),
          ),
        ),
        Group(
          'CheckableTagGroup (single)',
          CheckableTagGroup<String>(
            value: _single,
            options: const [
              CheckableTagOption(value: 'a', label: Text('Option A')),
              CheckableTagOption(value: 'b', label: Text('Option B')),
              CheckableTagOption(
                value: 'c',
                label: Text('Disabled'),
                disabled: true,
              ),
            ],
            onChanged: (v) => setState(() => _single = v),
          ),
        ),
      ],
    );
  }
}
