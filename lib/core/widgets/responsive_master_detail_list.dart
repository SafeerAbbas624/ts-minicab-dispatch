import 'package:flutter/material.dart';

import 'master_detail_layout.dart';
import 'responsive_nav_scaffold.dart';

/// Below [ResponsiveNavScaffold.desktopBreakpoint], just renders [mobileList]
/// unchanged — every admin list screen's existing Card/ListTile list keeps
/// working exactly as before. At/above it, renders [items] as a [DataTable]
/// with [detailFor] of the selected row shown beside it via
/// [MasterDetailLayout] — the shared shape behind every admin list screen's
/// desktop table+pane view.
class ResponsiveMasterDetailList<T> extends StatefulWidget {
  const ResponsiveMasterDetailList({
    super.key,
    required this.items,
    required this.itemKey,
    required this.columns,
    required this.cellsFor,
    required this.detailFor,
    required this.mobileList,
  });

  final List<T> items;
  final String Function(T item) itemKey;
  final List<DataColumn> columns;
  final List<DataCell> Function(T item) cellsFor;
  final Widget Function(T item) detailFor;
  final Widget mobileList;

  @override
  State<ResponsiveMasterDetailList<T>> createState() => _ResponsiveMasterDetailListState<T>();
}

class _ResponsiveMasterDetailListState<T> extends State<ResponsiveMasterDetailList<T>> {
  String? _selectedKey;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= ResponsiveNavScaffold.desktopBreakpoint;
    if (!isDesktop) return widget.mobileList;

    T? selected;
    for (final item in widget.items) {
      if (widget.itemKey(item) == _selectedKey) {
        selected = item;
        break;
      }
    }

    final table = SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: widget.columns,
          rows: [
            for (final item in widget.items)
              DataRow(
                selected: widget.itemKey(item) == _selectedKey,
                onSelectChanged: (_) => setState(() => _selectedKey = widget.itemKey(item)),
                cells: widget.cellsFor(item),
              ),
          ],
        ),
      ),
    );

    return MasterDetailLayout(
      list: table,
      detail: selected == null
          ? null
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(child: widget.detailFor(selected)),
            ),
    );
  }
}
