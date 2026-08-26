import 'package:flutter/material.dart';

/// Side-by-side list + detail pane for desktop-width admin list screens —
/// selecting a row shows its detail beside the list instead of pushing a new
/// screen or opening a dialog over it. Callers only reach for this once
/// they've already decided they're at desktop width; there's no responsive
/// switching inside this widget itself.
class MasterDetailLayout extends StatelessWidget {
  const MasterDetailLayout({
    super.key,
    required this.list,
    required this.detail,
    this.placeholder = const _DefaultPlaceholder(),
  });

  final Widget list;
  final Widget? detail;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 3, child: list),
        const VerticalDivider(width: 1),
        Expanded(flex: 2, child: detail ?? placeholder),
      ],
    );
  }
}

class _DefaultPlaceholder extends StatelessWidget {
  const _DefaultPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Select a row to see details',
        style: TextStyle(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}
