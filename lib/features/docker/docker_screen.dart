import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/dio_errors.dart';
import '../../core/models/server_profile.dart';

class DockerScreen extends StatefulWidget {
  const DockerScreen({super.key, required this.profile});

  final ServerProfile profile;

  @override
  State<DockerScreen> createState() => _DockerScreenState();
}

class _DockerScreenState extends State<DockerScreen> {
  List<dynamic> _items = [];
  String? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = createDio(widget.profile);
      final res = await dio.get<List<dynamic>>('/api/v1/docker/containers');
      setState(() {
        _items = res.data ?? [];
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = describeDioError(e);
        _loading = false;
      });
    }
  }

  String _name(Map<String, dynamic> c) {
    final names = c['Names'];
    if (names is List && names.isNotEmpty) {
      return names.first.toString().replaceFirst(RegExp(r'^/'), '');
    }
    return (c['Id'] as String?)?.substring(0, 12) ?? '?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Docker'),
        actions: [
          IconButton(onPressed: _pull, icon: const Icon(Icons.download_outlined)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      final c = _items[i] as Map<String, dynamic>;
                      final id = c['Id'] as String;
                      return ListTile(
                        title: Text(_name(c)),
                        subtitle: Text('${c['State']} · ${c['Image']}'),
                        onTap: () => _detail(context, id, _name(c)),
                      );
                    },
                  ),
                ),
    );
  }

  Future<void> _pull() async {
    final img = await showDialog<String>(
      context: context,
      builder: (c) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Docker pull'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(labelText: 'Image (örn: nginx:alpine)'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('İptal')),
            FilledButton(onPressed: () => Navigator.pop(c, ctrl.text.trim()), child: const Text('Çek')),
          ],
        );
      },
    );
    if (img == null || img.isEmpty) return;
    try {
      final dio = createDio(widget.profile);
      await dio.post('/api/v1/docker/pull', data: {'image': img});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İşlem başlatıldı')));
      await _load();
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeDioError(e))));
    }
  }

  Future<void> _detail(BuildContext context, String id, String name) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (c) => _ContainerSheet(profile: widget.profile, id: id, name: name),
    );
  }
}

class _ContainerSheet extends StatefulWidget {
  const _ContainerSheet({required this.profile, required this.id, required this.name});

  final ServerProfile profile;
  final String id;
  final String name;

  @override
  State<_ContainerSheet> createState() => _ContainerSheetState();
}

class _ContainerSheetState extends State<_ContainerSheet> {
  final _cmd = TextEditingController();
  String _logText = '';

  @override
  void dispose() {
    _cmd.dispose();
    super.dispose();
  }

  Future<void> _fetchLogs() async {
    try {
      final dio = createDio(widget.profile);
      final res = await dio.get<Map<String, dynamic>>(
        '/api/v1/docker/containers/${widget.id}/logs',
        queryParameters: {'tail': '200'},
      );
      setState(() => _logText = res.data?['logs'] as String? ?? '');
    } on DioException catch (e) {
      setState(() => _logText = describeDioError(e));
    }
  }

  Future<void> _exec() async {
    final raw = _cmd.text.trim();
    if (raw.isEmpty) return;
    final parts = raw.split(RegExp(r'\s+'));
    try {
      final dio = createDio(widget.profile);
      final res = await dio.post<Map<String, dynamic>>(
        '/api/v1/docker/containers/${widget.id}/exec',
        data: {'cmd': parts},
      );
      if (!mounted) return;
      final out = res.data?['output'] ?? '';
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('Çıkış: ${res.data?['exit_code']}'),
          content: SingleChildScrollView(child: SelectableText('$out')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Kapat')),
          ],
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeDioError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _cmd,
            decoration: const InputDecoration(
              labelText: 'Konteyner içi komut',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _exec(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton(onPressed: _exec, child: const Text('Çalıştır')),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: _fetchLogs, child: const Text('Logları getir')),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: SingleChildScrollView(
              child: SelectableText(_logText.isEmpty ? 'Loglar için butona basın' : _logText),
            ),
          ),
        ],
      ),
    );
  }
}
