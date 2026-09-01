import 'package:flutter/material.dart'
    hide Table, TableRow, ThemeData, Tooltip, Drawer;
import 'package:seed_ui/seed_ui.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import '../group.dart';

/// A table of the same shape as the kit's own, built on
/// `two_dimensional_scrollables` instead, so the two can be put side by side.
///
/// The package is a dependency of the example only — the kit itself stays
/// dependency-free, and nothing here is imported by `lib/`.
class TableTwoDDemo extends StatelessWidget {
  const TableTwoDDemo({super.key});

  /// The same load the kit's table was measured under: enough rows that
  /// building them all would tell, and enough columns to run off the edge.
  static const _rows = 500;
  static const _columns = 15;

  static String _cell(int row, int column) => switch (column) {
    0 => 'Row ${row + 1}',
    1 => '${20 + row % 50}',
    2 => ['Bristol', 'Galway', 'Chengdu'][row % 3],
    _ => 'Note ${column - 3}·$row',
  };

  static String _heading(int column) => switch (column) {
    0 => 'Name',
    1 => 'Age',
    2 => 'City',
    _ => 'Note ${column - 3}',
  };

  @override
  Widget build(BuildContext context) {
    final token = context.softToken;

    // The package draws nothing of its own: a span carries a decoration, and
    // a cell carries whatever widget you hand it. So the look has to be spelt
    // out in tokens — which is the point of the comparison.
    final line = BorderSide(color: token.colorBorderSecondary);
    final text = TextStyle(
      fontSize: token.fontSize,
      color: token.colorText,
      fontFamily: token.fontFamily,
      fontFamilyFallback: token.fontFamilyFallback,
      decoration: TextDecoration.none,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Group(
          '$_rows rows and $_columns columns, on TableView.builder',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: token.colorBgContainer,
                  border: Border.all(color: token.colorBorderSecondary),
                  borderRadius: BorderRadius.circular(token.borderRadiusLG),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(token.borderRadiusLG),
                  child: SizedBox(
                    height: 320,
                    child: TableView.builder(
                      // The heading is a row like any other, held at the top;
                      // the name column is a column like any other, held at
                      // the start. Both stay put for free.
                      pinnedRowCount: 1,
                      pinnedColumnCount: 1,
                      // A trackpad sweeps in both directions at once, so the
                      // table has to follow the finger rather than pick an
                      // axis and hold it.
                      diagonalDragBehavior: DiagonalDragBehavior.free,
                      rowCount: _rows + 1,
                      columnCount: _columns,
                      rowBuilder: (row) => TableSpan(
                        extent: FixedTableSpanExtent(
                          token.controlHeight + token.sizeSM,
                        ),
                        backgroundDecoration: TableSpanDecoration(
                          color: row == 0 ? token.colorFillQuaternary : null,
                          border: TableSpanBorder(trailing: line),
                        ),
                      ),
                      columnBuilder: (column) => TableSpan(
                        extent: FixedTableSpanExtent(column == 0 ? 160 : 120),
                        backgroundDecoration: TableSpanDecoration(
                          // The pinned column needs a seam of its own, or it
                          // sits flush against whatever scrolls beneath it.
                          border: column == 0
                              ? TableSpanBorder(trailing: line)
                              : null,
                        ),
                      ),
                      cellBuilder: (context, vicinity) => TableViewCell(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: token.size),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              vicinity.row == 0
                                  ? _heading(vicinity.column)
                                  : _cell(vicinity.row - 1, vicinity.column),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: vicinity.row == 0
                                  ? text.copyWith(
                                      fontWeight: token.fontWeightStrong,
                                    )
                                  : text,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Only the cells on screen are built, so the row count costs '
                'nothing. In exchange every column needs a width in pixels: '
                'the viewport lays cells out before it can measure them, so '
                'nothing here can be as wide as its widest cell.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
