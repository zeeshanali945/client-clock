import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import '../widgets.dart';
import 'tz_picker.dart';

/// First-launch setup and later editing of the freelancer's own settings.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.firstRun = false});
  final bool firstRun;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late Profile _p;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(appProvider).profile;
    _p = existing ?? Profile(tz: ref.read(detectedTzProvider));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.firstRun ? 'Welcome to Client Clock' : 'Your settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.firstRun)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Confirm your time zone and working hours. Everything stays on this phone.',
              ),
            ),
          const SectionLabel('Your time zone'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.public),
              title: Text(_p.tz.replaceAll('_', ' ')),
              subtitle: const Text('Detected from your phone. Tap to change.'),
              onTap: () async {
                final picked = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (_) => const TzPickerScreen()),
                );
                if (picked != null) setState(() => _p = _p.copyWith(tz: picked));
              },
            ),
          ),
          const SectionLabel('Your working hours'),
          HoursPicker(
            start: _p.workStart,
            end: _p.workEnd,
            onChanged: (s, e) => setState(() => _p = _p.copyWith(workStart: s, workEnd: e)),
          ),
          const SectionLabel('Your days off'),
          WeekendChips(
            value: _p.weekend,
            onChanged: (w) => setState(() => _p = _p.copyWith(weekend: w)),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _save,
            child: Text(widget.firstRun ? 'Get started' : 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_p.workStart >= _p.workEnd) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Working hours must end after they start.')),
      );
      return;
    }
    await ref.read(appProvider.notifier).setProfile(_p);
    if (!widget.firstRun && mounted) Navigator.pop(context);
  }
}
