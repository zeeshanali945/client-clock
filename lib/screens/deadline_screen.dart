import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models.dart';
import '../notifications.dart';
import '../providers.dart';
import '../time_logic.dart';
import '../widgets.dart';

/// Enter a deadline in the client's time, see it in your own time.
class DeadlineScreen extends ConsumerStatefulWidget {
  const DeadlineScreen({super.key});

  @override
  ConsumerState<DeadlineScreen> createState() => _DeadlineScreenState();
}

class _DeadlineScreenState extends ConsumerState<DeadlineScreen> {
  String? _clientId;
  late DateTime _date;
  TimeOfDay _time = const TimeOfDay(hour: 17, minute: 0);

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

    final result = convertDeadline(
      clientTz: client.tz,
      ownTz: profile.tz,
      year: _date.year,
      month: _date.month,
      day: _date.day,
      hour: _time.hour,
      minute: _time.minute,
    );
    final own = result.ownTime;
    final remaining = result.remaining(DateTime.now());
    final outside = !isWorking(
      own,
      start: profile.workStart,
      end: profile.workEnd,
      weekend: profile.weekend,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Convert deadline')),
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
          const SectionLabel("Deadline in the client's time"),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
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
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.schedule, size: 18),
                  label: Text(_time.format(context)),
                  onPressed: () async {
                    final t = await showTimePicker(context: context, initialTime: _time);
                    if (t != null) setState(() => _time = t);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('In your time'),
                  Text(fmtDayTime(own), style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('Time left: ${fmtDuration(remaining)}'),
                  Text(
                    'Client zone: ${client.tz.replaceAll('_', ' ')} '
                    '(UTC${_offset(result.clientTime)})',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          if (outside)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('This falls outside your working hours or on a day off.'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          FilledButton.icon(
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Remind me 24 h and 2 h before'),
            onPressed: remaining.isNegative ? null : () => _remind(client, own),
          ),
        ],
      ),
    );
  }

  String _offset(tz.TZDateTime t) {
    final m = t.timeZoneOffset.inMinutes;
    final sign = m < 0 ? '-' : '+';
    final a = m.abs();
    final mm = a % 60;
    return '$sign${a ~/ 60}${mm == 0 ? '' : ':${mm.toString().padLeft(2, '0')}'}';
  }

  Future<void> _remind(Client client, DateTime deadline) async {
    final svc = NotificationService.instance;
    final granted = await svc.requestPermission();
    final msg = ScaffoldMessenger.of(context);
    if (!granted) {
      msg.showSnackBar(const SnackBar(
        content: Text('Notifications are off. Allow them in phone settings to get reminders.'),
      ));
      return;
    }
    final n = await svc.scheduleDeadlineReminders(
      clientName: client.name,
      deadline: deadline,
    );
    msg.showSnackBar(SnackBar(
      content: Text(n == 0
          ? 'Both reminder times have already passed.'
          : '$n reminder${n == 1 ? '' : 's'} set.'),
    ));
  }
}
