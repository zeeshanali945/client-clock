import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

/// Searchable list of IANA time zones. Pops with the chosen zone name.
class TzPickerScreen extends StatefulWidget {
  const TzPickerScreen({super.key});

  @override
  State<TzPickerScreen> createState() => _TzPickerScreenState();
}

class _TzPickerScreenState extends State<TzPickerScreen> {
  late final List<String> _all =
      (tz.timeZoneDatabase.locations.keys.where((k) => k.contains('/')).toList()..sort());
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase().replaceAll(' ', '_');
    final shown = q.isEmpty ? _all : _all.where((n) => n.toLowerCase().contains(q)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Choose city or time zone')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search, for example New_York or Karachi',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: shown.length,
              itemBuilder: (_, i) => ListTile(
                title: Text(shown[i].replaceAll('_', ' ')),
                onTap: () => Navigator.pop(context, shown[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
