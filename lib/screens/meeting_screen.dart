import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../time_logic.dart';
import '../widgets.dart';

/// Shows when both people are inside working hours on a chosen day.
class MeetingScreen extends ConsumerStatefulWidget {
  const MeetingScreen({super.key});

  @override
  ConsumerState<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends ConsumerState<MeetingScreen> {
  String? _clientId;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _date = DateTime(n.year, n.month, n.day);
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    final profile = app.profile!;
    final clients = app.clients;
    final client = clients.firstWhere(
      (c) => c.id == _clientId,
      orElse: () => clients.first,
    );

    final windows = findOverlap(
      ownTz: profile.tz,
      ownStart: profile.workStart,
      ownEnd: profile.workEnd,
      ownWeekend: profile.weekend,
      clientTz: client.tz,
      clientStart: client.workStart,
      clientEnd: client.workEnd,
      clientWeekend: client.weekend,
      year: _date.year,
      month: _date.month,
      day: _date.day,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Find a meeting time')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            value: client.id,
            decoration: const InputDecoration(
              labelText: 'Client',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final c in clients) DropdownMenuItem(value: c.id, child: Text(c.name)),
            ],
            onChanged: (v) => setState(() => _clientId = v),
          ),
          const SectionLabel('Day (in your time)'),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(fmtDay(_date)),
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
              );
              if (d != null) setState(() => _date = d);
            },
          ),
          const SectionLabel('Both of you are working'),
          if (windows.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No shared working hours on this day. Try another day.'),
              ),
            ),
          for (final w in windows)
            Card(
              child: ListTile(
                title: Text('You: ${fmtTime(w.ownStart)} to ${fmtTime(w.ownEnd)}'),
                subtitle: Text(
                  '${client.name}: ${fmtTime(w.clientStart)} to ${fmtTime(w.clientEnd)}'
                  '${w.clientStart.day != w.ownStart.day ? ' (${fmtDay(w.clientStart)})' : ''}',
                ),
                trailing: IconButton(
                  tooltip: 'Copy message',
                  icon: const Icon(Icons.copy),
                  onPressed: () async {
                    final text = 'Suggested meeting time: '
                        '${fmtDay(w.ownStart)}, ${fmtTime(w.ownStart)} to ${fmtTime(w.ownEnd)} '
                        '(${profile.tz.replaceAll('_', ' ')}) = '
                        '${fmtDay(w.clientStart)}, ${fmtTime(w.clientStart)} to ${fmtTime(w.clientEnd)} '
                        '(${client.tz.replaceAll('_', ' ')})';
                    await Clipboard.setData(ClipboardData(text: text));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied. Paste it into your message.')),
                      );
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
