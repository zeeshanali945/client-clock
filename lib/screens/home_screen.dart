import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models.dart';
import '../providers.dart';
import '../time_logic.dart';
import 'client_edit_screen.dart';
import 'deadline_screen.dart';
import 'meeting_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    final profile = app.profile!;
    final now = ref.watch(nowProvider).value ?? DateTime.now();
    final ownNow = tz.TZDateTime.from(now, tz.getLocation(profile.tz));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Clock'),
        actions: [
          IconButton(
            tooltip: 'Your settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add client'),
        onPressed: () => _addClient(context, app.clients.length),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Your time'),
                        Text(
                          fmtTime(ownNow),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text('${fmtDay(ownNow)}  |  ${profile.tz.replaceAll('_', ' ')}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.event_available),
                  label: const Text('Convert deadline'),
                  onPressed: app.clients.isEmpty
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const DeadlineScreen()),
                          ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.groups_outlined),
                  label: const Text('Meeting time'),
                  onPressed: app.clients.isEmpty
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MeetingScreen()),
                          ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (app.clients.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  'No clients yet.\nTap Add client to see their local time here.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          for (final c in app.clients) _ClientTile(client: c, profile: profile, now: now),
        ],
      ),
    );
  }

  void _addClient(BuildContext context, int count) {
    if (count >= freeClientLimit) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Free plan limit'),
          content: Text(
            'The free plan includes up to $freeClientLimit clients. '
            'Premium (unlimited clients) is planned for a later version.',
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientEditScreen()));
  }
}

class _ClientTile extends StatelessWidget {
  const _ClientTile({required this.client, required this.profile, required this.now});
  final Client client;
  final Profile profile;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final cl = tz.TZDateTime.from(now, tz.getLocation(client.tz));
    final ownNow = tz.TZDateTime.from(now, tz.getLocation(profile.tz));
    final isWeekend = client.weekend.contains(cl.weekday);
    final working = isWorking(
      cl,
      start: client.workStart,
      end: client.workEnd,
      weekend: client.weekend,
    );
    final status = isWeekend ? 'Day off' : (working ? 'Working hours' : 'Off hours');
    final scheme = Theme.of(context).colorScheme;
    final statusColor = working ? Colors.green.shade700 : scheme.onSurfaceVariant;

    return Card(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ClientEditScreen(existing: client)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(client.name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${client.tz.replaceAll('_', ' ')}  |  ${gapLabel(profile.tz, client.tz, now)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          working ? Icons.check_circle : Icons.bedtime_outlined,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(status, style: TextStyle(color: statusColor)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(fmtTime(cl), style: Theme.of(context).textTheme.headlineSmall),
                  Text(relativeDay(cl, ownNow)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
