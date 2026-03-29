import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/server_profile.dart';
import '../../core/providers/servers_provider.dart';
import '../home/server_home_screen.dart';
import 'add_server_sheet.dart';

class ServersScreen extends ConsumerWidget {
  const ServersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(serversProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('RC Servers'),
      ),
      body: async.when(
        data: (servers) {
          if (servers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Henüz sunucu yok. Sunucuda install.sh ve ardından '
                  '"rcserver generate hash" çıktısındaki IP, PORT ve HASH bilgilerini ekleyin.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: servers.length,
            itemBuilder: (context, i) {
              final s = servers[i];
              return ListTile(
                leading: const Icon(Icons.dns_outlined),
                title: Text(s.name),
                subtitle: Text('${s.host}:${s.port}'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ServerHomeScreen(profile: s),
                    ),
                  );
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Düzenle',
                      onPressed: () async {
                        final updated = await showModalBottomSheet<ServerProfile>(
                          context: context,
                          isScrollControlled: true,
                          builder: (c) => AddServerSheet(editing: s),
                        );
                        if (updated != null) {
                          await ref.read(serversProvider.notifier).update(updated);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sunucu güncellendi')),
                            );
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Sunucuyu sil'),
                            content: Text('${s.name} kaldırılsın mı?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('İptal')),
                              FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sil')),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await ref.read(serversProvider.notifier).remove(s.id);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Hata: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final profile = await showModalBottomSheet<ServerProfile>(
            context: context,
            isScrollControlled: true,
            builder: (c) => const AddServerSheet(),
          );
          if (profile != null) {
            await ref.read(serversProvider.notifier).add(profile);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Sunucu ekle'),
      ),
    );
  }
}
