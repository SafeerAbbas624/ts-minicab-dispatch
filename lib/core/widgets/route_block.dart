import 'package:flutter/material.dart';

/// Pickup → drop-off as two stops joined by a line: the shape every driver
/// already reads from navigation apps. Pickup is a ring, drop-off a filled
/// square, so the two ends differ by shape, not just colour.
class RouteBlock extends StatelessWidget {
  const RouteBlock({
    super.key,
    required this.pickup,
    required this.dropoff,
    this.vias = const [],
    this.dense = false,
    this.maxLines = 2,
  });

  final String pickup;
  final String dropoff;

  /// Stops on the way, in order.
  final List<String> vias;
  final bool dense;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final style = dense ? Theme.of(context).textTheme.bodyMedium : Theme.of(context).textTheme.bodyLarge;
    final gap = dense ? 10.0 : 14.0;

    Widget stop(String label, String text, Widget marker) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 20, child: Padding(padding: const EdgeInsets.only(top: 3), child: Center(child: marker))),
            const SizedBox(width: 10),
            Expanded(
              child: Semantics(
                label: '$label: $text',
                excludeSemantics: true,
                child: Text(text, style: style, maxLines: maxLines, overflow: maxLines == null ? null : TextOverflow.ellipsis),
              ),
            ),
          ],
        );

    return Stack(
      children: [
        // Connector between the two markers.
        Positioned(
          left: 9.25,
          top: 18,
          bottom: 18,
          child: Container(width: 1.5, color: c.outlineVariant),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            stop(
              'Pickup',
              pickup,
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.surfaceContainerLowest,
                  border: Border.all(color: c.tertiary, width: 3),
                ),
              ),
            ),
            SizedBox(height: gap),
            for (var i = 0; i < vias.length; i++) ...[
              stop(
                vias.length > 1 ? 'Stop ${i + 1}' : 'Via',
                vias[i],
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: c.outline),
                ),
              ),
              SizedBox(height: gap),
            ],
            stop(
              'Drop-off',
              dropoff,
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(2.5)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
