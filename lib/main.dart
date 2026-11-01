import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'notifications.dart';
import 'providers.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Compact time zone data (about 10 years) keeps the app small.
  tzdata.initializeTimeZones();

  var detected = 'UTC';
  try {
    detected = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(detected));
  } catch (_) {
    detected = 'UTC';
    tz.setLocalLocation(tz.getLocation('UTC'));
  }

  final storage = await Storage.open();

  try {
    await NotificationService.instance.init();
  } catch (_) {
    // The app still works without reminders.
  }

  runApp(ProviderScope(
    overrides: [
      storageProvider.overrideWithValue(storage),
      detectedTzProvider.overrideWithValue(detected),
    ],
    child: const ClientClockApp(),
  ));
}

class ClientClockApp extends ConsumerWidget {
  const ClientClockApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasProfile = ref.watch(appProvider.select((s) => s.profile != null));
    return MaterialApp(
      title: 'Client Clock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.dark,
        ),
      ),
      home: hasProfile ? const HomeScreen() : const ProfileScreen(firstRun: true),
    );
  }
}
