import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/dio_errors.dart';
import '../../core/models/server_profile.dart';

class DeployScreen extends StatefulWidget {
  const DeployScreen({super.key, required this.profile});

  final ServerProfile profile;

  @override
  State<DeployScreen> createState() => _DeployScreenState();
}

class _DeployScreenState extends State<DeployScreen> {
  final _site = TextEditingController();
  final _serverName = TextEditingController();

  @override
  void dispose() {
    _site.dispose();
    _serverName.dispose();
    super.dispose();
  }

  Future<void> _deploy() async {
    final site = _site.text.trim();
    final sn = _serverName.text.trim();
    if (site.isEmpty || sn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Site adı ve server_name gerekli')),
      );
      return;
    }
    try {
      final dio = createDio(widget.profile);
      final res = await dio.post<Map<String, dynamic>>(
        '/api/v1/deploy/static',
        data: {
          'site_name': site,
          'server_name': sn,
        },
      );
      if (!mounted) return;
      final root = res.data?['web_root'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Oluşturuldu. Web kökü: $root')),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeDioError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statik site')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nginx için basit bir server bloğu ve web kökü oluşturur. '
              'Dosyaları dosya yöneticisinden ilgili köke yükleyin.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _site,
              decoration: const InputDecoration(
                labelText: 'Site adı (dosya adı)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _serverName,
              decoration: const InputDecoration(
                labelText: 'server_name (örn: example.com)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _deploy, child: const Text('Oluştur ve nginx reload')),
          ],
        ),
      ),
    );
  }
}
