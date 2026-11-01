import 'package:flutter/material.dart';

/// Most stops a booking can have between pickup and drop-off (same limit as
/// the website and the API).
const maxViaStops = 5;

/// The operator's "via" stops for a telephone booking, in order.
class ViaStopsController {
  ViaStopsController([List<String> initial = const []])
      : fields = [for (final s in initial) TextEditingController(text: s)];

  final List<TextEditingController> fields;

  /// Filled-in stops, in order.
  List<String> get values => fields.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();

  /// Empties the list. The removed fields may still be on screen until the
  /// next frame, so their controllers are disposed after it.
  void clear() {
    final removed = List.of(fields);
    fields.clear();
    _disposeAfterFrame(removed);
  }

  void dispose() {
    for (final c in fields) {
      c.dispose();
    }
    fields.clear();
  }
}

void _disposeAfterFrame(List<TextEditingController> controllers) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    for (final c in controllers) {
      c.dispose();
    }
  });
}

/// Up to [maxViaStops] stop fields with add/remove buttons, placed between
/// the pickup and drop-off fields of the booking forms.
class ViaStopsFields extends StatefulWidget {
  const ViaStopsFields({super.key, required this.controller});

  final ViaStopsController controller;

  @override
  State<ViaStopsFields> createState() => _ViaStopsFieldsState();
}

class _ViaStopsFieldsState extends State<ViaStopsFields> {
  List<TextEditingController> get _fields => widget.controller.fields;

  void _add() => setState(() => _fields.add(TextEditingController()));

  void _remove(int i) => setState(() => _disposeAfterFrame([_fields.removeAt(i)]));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _fields.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextFormField(
              key: ObjectKey(_fields[i]),
              controller: _fields[i],
              decoration: InputDecoration(
                labelText: 'Stop ${i + 1} (via)',
                suffixIcon: IconButton(
                  tooltip: 'Remove stop ${i + 1}',
                  icon: const Icon(Icons.close),
                  onPressed: () => _remove(i),
                ),
              ),
            ),
          ),
        if (_fields.length < maxViaStops)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: Text(_fields.isEmpty ? 'Add a stop (via)' : 'Add another stop'),
            ),
          ),
      ],
    );
  }
}
