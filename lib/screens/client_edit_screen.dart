import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers.dart';
import '../widgets.dart';
import 'tz_picker.dart';

/// Add a new client or edit / delete an existing one.
class ClientEditScreen extends ConsumerStatefulWidget {
  const ClientEditScreen({super.key, this.existing});
  final Client? existing;

  @override
  ConsumerState<ClientEditScreen> createState() => _ClientEditScreenState();
}

class _ClientEditScreenState extends ConsumerState<ClientEditScreen> {
  late final TextEditingController _name;
  String? _tz;
  int _start = 9 * 60;
  int _end = 17 * 60;
  Set<int> _weekend = {6, 7};

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _name = TextEditingController(text: c?.name ?? '');
    if (c != null) {
      _tz = c.tz;
      _start = c.workStart;
      _end = c.workEnd;
      _weekend = {...c.weekend};
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit client' : 'Add client'),
        actions: [
          if (editing)
            IconButton(
              tooltip: 'Delete client',
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Client name',
              border: OutlineInputBorder(),
            ),
          ),
          const SectionLabel('Client city or time zone'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.public),
              title: Text(_tz == null ? 'Choose a time zone' : _tz!.replaceAll('_', ' ')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final picked = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (_) => const TzPickerScreen()),
                );
                if (picked != null) setState(() => _tz = picked);
              },
            ),
          ),
          const SectionLabel('Client working hours'),
          HoursPicker(
            start: _start,
            end: _end,
            onChanged: (s, e) => setState(() {
              _start = s;
              _end = e;
            }),
          ),
          const SectionLabel('Client days off'),
          WeekendChips(value: _weekend, onChanged: (w) => setState(() => _weekend = w)),
          const SizedBox(height: 28),
          FilledButton(onPressed: _save, child: const Text('Save client')),
        ],
      ),
    );
  }

  Future<void> _save() async {
    String? error;
    if (_name.text.trim().isEmpty) {
      error = 'Enter a client name.';
    } else if (_tz == null) {
      error = 'Choose the client time zone.';
    } else if (_start >= _end) {
      error = 'Working hours must end after they start.';
    }
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final c = Client(
      id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      tz: _tz!,
      workStart: _start,
      workEnd: _end,
      weekend: _weekend,
    );
    await ref.read(appProvider.notifier).upsertClient(c);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete client?'),
        content: Text('Remove ${widget.existing!.name} from your list?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(appProvider.notifier).deleteClient(widget.existing!.id);
      if (mounted) Navigator.pop(context);
    }
  }
}
