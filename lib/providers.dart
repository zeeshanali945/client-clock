import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';
import 'storage.dart';

/// Overridden in main() with the opened storage.
final storageProvider = Provider<Storage>((ref) => throw UnimplementedError());

/// Overridden in main() with the device time zone name (IANA), e.g. Asia/Karachi.
final detectedTzProvider = Provider<String>((ref) => 'UTC');

class AppState {
  final Profile? profile;
  final List<Client> clients;
  const AppState({this.profile, this.clients = const []});
}

class AppController extends Notifier<AppState> {
  @override
  AppState build() {
    final s = ref.read(storageProvider);
    return AppState(profile: s.loadProfile(), clients: s.loadClients());
  }

  Future<void> setProfile(Profile p) async {
    state = AppState(profile: p, clients: state.clients);
    await ref.read(storageProvider).saveProfile(p);
  }

  Future<void> upsertClient(Client c) async {
    final list = [...state.clients];
    final i = list.indexWhere((x) => x.id == c.id);
    if (i >= 0) {
      list[i] = c;
    } else {
      list.add(c);
    }
    state = AppState(profile: state.profile, clients: list);
    await ref.read(storageProvider).saveClients(list);
  }

  Future<void> deleteClient(String id) async {
    final list = state.clients.where((c) => c.id != id).toList();
    state = AppState(profile: state.profile, clients: list);
    await ref.read(storageProvider).saveClients(list);
  }
}

final appProvider = NotifierProvider<AppController, AppState>(AppController.new);

/// Ticks every 20 seconds so the home board stays current.
final nowProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 20), (_) => DateTime.now());
});
