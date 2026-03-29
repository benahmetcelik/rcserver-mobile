import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/server_profile.dart';
import '../storage/server_storage.dart';

final serverStorageProvider = Provider<ServerStorage>((ref) => ServerStorage());

final serversProvider =
    StateNotifierProvider<ServersNotifier, AsyncValue<List<ServerProfile>>>((ref) {
  return ServersNotifier(ref.watch(serverStorageProvider));
});

class ServersNotifier extends StateNotifier<AsyncValue<List<ServerProfile>>> {
  ServersNotifier(this._storage) : super(const AsyncValue.loading()) {
    load();
  }

  final ServerStorage _storage;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _storage.loadServers());
  }

  Future<void> add(ServerProfile profile) async {
    final list = state.valueOrNull ?? [];
    await _storage.saveServers([...list, profile]);
    await load();
  }

  Future<void> remove(String id) async {
    final list = (state.valueOrNull ?? []).where((e) => e.id != id).toList();
    await _storage.saveServers(list);
    state = AsyncValue.data(list);
  }

  Future<void> update(ServerProfile profile) async {
    final list = (state.valueOrNull ?? [])
        .map((e) => e.id == profile.id ? profile : e)
        .toList();
    await _storage.saveServers(list);
    state = AsyncValue.data(list);
  }

  static String newId() => const Uuid().v4();
}
