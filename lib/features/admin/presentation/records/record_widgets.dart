import 'package:flutter/material.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/csv_export.dart';

/// Small shared pieces for the complaints / lost property / staff register
/// screens.

/// Text field bound to a map key; `null` value means empty.
class RecordField extends StatelessWidget {
  const RecordField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.required = false,
    this.maxLines = 1,
    this.keyboard,
    this.caps = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool required;
  final int maxLines;
  final TextInputType? keyboard;
  final bool caps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        minLines: maxLines > 1 ? 2 : 1,
        keyboardType: keyboard ?? (maxLines > 1 ? TextInputType.multiline : null),
        textCapitalization: caps ? TextCapitalization.characters : TextCapitalization.sentences,
        decoration: InputDecoration(labelText: required ? '$label *' : label, hintText: hint, alignLabelWithHint: maxLines > 1),
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}

/// Date (+ optional time) picker row.
class DateTimeRow extends StatelessWidget {
  const DateTimeRow({super.key, required this.label, required this.value, required this.onChanged, this.withTime = true});

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool withTime;

  @override
  Widget build(BuildContext context) {
    final v = value;
    final text = v == null
        ? 'Not set'
        : '${v.day.toString().padLeft(2, '0')}/${v.month.toString().padLeft(2, '0')}/${v.year}'
            '${withTime ? ' ${v.hour.toString().padLeft(2, '0')}:${v.minute.toString().padLeft(2, '0')}' : ''}';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(text),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (v != null) IconButton(tooltip: 'Clear', icon: const Icon(Icons.clear), onPressed: () => onChanged(null)),
        const Icon(Icons.event_outlined),
      ]),
      onTap: () async {
        final now = DateTime.now();
        final date = await showDatePicker(
          context: context,
          initialDate: v ?? now,
          firstDate: DateTime(now.year - 80),
          lastDate: DateTime(now.year + 1, 12, 31),
          helpText: label,
        );
        if (date == null || !context.mounted) return;
        if (!withTime) return onChanged(date);
        final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(v ?? now));
        onChanged(DateTime(date.year, date.month, date.day, time?.hour ?? 0, time?.minute ?? 0));
      },
    );
  }
}

String? trimOrNull(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
String? isoOrNull(DateTime? d) => d?.toUtc().toIso8601String();

/// Downloads/shares a generated file and reports API errors in a snackbar.
Future<void> downloadRecord(BuildContext context, Future<List<int>> Function() fetch, String fileName, String mimeType) async {
  try {
    final bytes = await fetch();
    await shareFile(bytes, fileName, mimeType: mimeType);
  } on ApiException catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
  }
}

/// Status chip for open/closed records.
class OpenClosedChip extends StatelessWidget {
  const OpenClosedChip({super.key, required this.open});
  final bool open;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(open ? 'Open' : 'Closed'),
      backgroundColor: open ? c.tertiaryContainer : c.surfaceContainerHighest,
      labelStyle: TextStyle(color: open ? c.onTertiaryContainer : c.onSurfaceVariant, fontWeight: FontWeight.w600),
      side: BorderSide.none,
    );
  }
}
