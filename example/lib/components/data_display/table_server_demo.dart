import 'dart:convert';

import 'package:flutter/material.dart' hide Table, TableRow, ThemeData;
import 'package:http/http.dart' as http;
import 'package:seed_ui/seed_ui.dart';

import '../group.dart';

class Post {
  const Post(this.id, this.title);
  final int id;
  final String title;
}

/// A table paged by the server, one request per page.
///
/// The table is told a [TablePagination.total] it could not work out for
/// itself, and handed one page of rows. It draws them as they came and asks
/// for another page through `onChanged`.
class TableServerDemo extends StatefulWidget {
  const TableServerDemo({super.key});

  @override
  State<TableServerDemo> createState() => _TableServerDemoState();
}

class _TableServerDemoState extends State<TableServerDemo> {
  static const _total = 100;

  int _page = 1;
  int _size = 10;
  List<Post> _rows = const [];
  bool _loading = false;
  String? _failed;
  int _requests = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _failed = null;
      _requests++;
    });
    try {
      final response = await http.get(
        Uri.parse(
          'https://jsonplaceholder.typicode.com/posts'
          '?_start=${(_page - 1) * _size}&_limit=$_size',
        ),
      );
      final decoded = (jsonDecode(response.body) as List)
          .cast<Map<String, dynamic>>()
          .map((p) => Post(p['id'] as int, p['title'] as String))
          .toList();
      if (!mounted) return;
      setState(() {
        _rows = decoded;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _failed = '$error';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Group(
          'One request per page',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Table<Post>(
                bordered: true,
                loading: _loading,
                data: _rows,
                pagination: TablePagination(
                  // The page is ours, not the table's: it says what was
                  // asked for and we fetch it.
                  page: _page,
                  pageSize: _size,
                  // What the server says there is. Without it the table would
                  // count the ten rows in front of it and draw one page.
                  total: _total,
                  showSizeChanger: true,
                  pageSizeOptions: const [5, 10, 20],
                  showTotal: (total, from, to) =>
                      Text('$from–$to of $total posts'),
                  onChanged: (page, size) {
                    setState(() {
                      _page = page;
                      _size = size;
                    });
                    _fetch();
                  },
                ),
                columns: [
                  TableColumn(
                    title: const Text('id'),
                    width: 64,
                    align: TableAlign.end,
                    value: (p) => p.id,
                  ),
                  TableColumn(
                    title: const Text('Title'),
                    ellipsis: true,
                    value: (p) => p.title,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _failed != null
                    ? 'The request failed: $_failed'
                    : 'Requests so far: $_requests. Turn the page and that '
                          'goes up by one — the rows for a page are fetched '
                          'when the page is asked for, never all hundred at '
                          'once. The table is told the total because it cannot '
                          'know it: what it holds is one page.',
              ),
              const SizedBox(height: 8),
              const Text(
                'Sorting and narrowing would work on the ten rows in hand, '
                'not on the hundred, so a table paged this way leaves both to '
                'the server as well.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
