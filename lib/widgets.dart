import 'package:flutter/material.dart';

import 'time_logic.dart';

const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Seven chips (Mon..Sun) to choose which days are days off.
class WeekendChips extends StatelessWidget {
  const WeekendChips({super.key, required this.value, required this.onChanged});
  final Set<int> value;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: List.generate(7, (i) {
        final day = i + 1;
        return FilterChip(
          label: Text(weekdayNames[i]),
          selected: value.contains(day),
          onSelected: (sel) {
            final next = {...value};
            sel ? next.add(day) : next.remove(day);
            onChanged(next);
          },
        );
      }),
    );
  }
}

Future<int?> pickMinutes(BuildContext context, int initial) async {
  final t = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
  );
  return t == null ? null : t.hour * 60 + t.minute;
}

/// Start and end of working hours as two tappable buttons.
class HoursPicker extends StatelessWidget {
  const HoursPicker({
    super.key,
    required this.start,
    required this.end,
    required this.onChanged,
  });
  final int start;
  final int end;
  final void Function(int start, int end) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () async {
              final m = await pickMinutes(context, start);
              if (m != null) onChanged(m, end);
            },
            child: Text('Start ${fmtMinutes(start)}'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () async {
              final m = await pickMinutes(context, end);
              if (m != null) onChanged(start, m);
            },
            child: Text('End ${fmtMinutes(end)}'),
          ),
        ),
      ],
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );
}
