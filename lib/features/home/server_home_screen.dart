import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/server_profile.dart';
import '../../core/providers/servers_provider.dart';
import '../bookmarks/bookmarks_screen.dart';
import '../deploy/deploy_screen.dart';
import '../docker/docker_screen.dart';
import '../files/files_screen.dart';
import '../nginx/nginx_screen.dart';
import '../servers/add_server_sheet.dart';
import '../system/system_screen.dart';
import '../terminal/terminal_screen.dart';

class ServerHomeScreen extends ConsumerStatefulWidget {
  const ServerHomeScreen({super.key, required this.profile});

  final ServerProfile profile;

  @override
  ConsumerState<ServerHomeScreen> createState() => _ServerHomeScreenState();
}

class _ServerHomeScreenState extends ConsumerState<ServerHomeScreen> {
  late ServerProfile _profile = widget.profile;

  Future<void> _openEdit() async {
    final updated = await showModalBottomSheet<ServerProfile>(
      context: context,
      isScrollControlled: true,
      builder: (c) => AddServerSheet(editing: _profile),
    );
    if (updated != null) {
      await ref.read(serversProvider.notifier).update(updated);
      setState(() => _profile = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sunucu bilgileri güncellendi')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_profile.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Sunucuyu düzenle',
            onPressed: _openEdit,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${_profile.host}:${_profile.port}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            '${_profile.useTls ? 'HTTPS' : 'HTTP'} · '
            '${_profile.allowBadCertificate ? 'Güvensiz sertifika kabul' : 'Sertifika doğrulama'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          _tile(context, Icons.monitor_heart_outlined, 'Sistem (CPU, RAM)', () {
            Navigator.push(context, MaterialPageRoute<void>(builder: (_) => SystemScreen(profile: _profile)));
          }),
          _tile(context, Icons.terminal_outlined, 'Terminal', () {
            Navigator.push(context, MaterialPageRoute<void>(builder: (_) => TerminalScreen(profile: _profile)));
          }),
          _tile(context, Icons.folder_open_outlined, 'Dosya yöneticisi', () {
            Navigator.push(context, MaterialPageRoute<void>(builder: (_) => FilesScreen(profile: _profile)));
          }),
          _tile(context, Icons.view_list_outlined, 'Docker', () {
            Navigator.push(context, MaterialPageRoute<void>(builder: (_) => DockerScreen(profile: _profile)));
          }),
          _tile(context, Icons.settings_ethernet_outlined, 'Nginx siteleri', () {
            Navigator.push(context, MaterialPageRoute<void>(builder: (_) => NginxScreen(profile: _profile)));
          }),
          _tile(context, Icons.cloud_upload_outlined, 'Statik site yayını', () {
            Navigator.push(context, MaterialPageRoute<void>(builder: (_) => DeployScreen(profile: _profile)));
          }),
          _tile(context, Icons.bookmarks_outlined, 'Veritabanı / bağlantılar', () {
            Navigator.push(context, MaterialPageRoute<void>(builder: (_) => BookmarksScreen(profile: _profile)));
          }),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
