import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/dio_errors.dart';
import '../../core/models/server_profile.dart';

class NginxScreen extends StatefulWidget {
  const NginxScreen({super.key, required this.profile});

  final ServerProfile profile;

  @override
  State<NginxScreen> createState() => _NginxScreenState();
}

class _NginxScreenState extends State<NginxScreen> {
  List<dynamic> _sites = [];
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
      final res = await dio.get<Map<String, dynamic>>('/api/v1/nginx/sites');
      setState(() {
        _sites = res.data?['sites'] as List<dynamic>? ?? [];
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = describeDioError(e);
        _loading = false;
      });
    }
  }

  Future<void> _edit(String name) async {
    try {
      final dio = createDio(widget.profile);
      final res = await dio.get<Map<String, dynamic>>('/api/v1/nginx/sites/$name');
      final content = res.data?['content'] as String? ?? '';
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => NginxEditorScreen(profile: widget.profile, name: name, initial: content),
        ),
      );
      await _load();
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeDioError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nginx')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _sites.length,
                    itemBuilder: (context, i) {
                      final name = _sites[i] as String;
                      return ListTile(
                        title: Text(name),
                        trailing: const Icon(Icons.edit),
                        onTap: () => _edit(name),
                      );
                    },
                  ),
                ),
    );
  }
}

class NginxEditorScreen extends StatefulWidget {
  const NginxEditorScreen({
    super.key,
    required this.profile,
    required this.name,
    required this.initial,
  });

  final ServerProfile profile;
  final String name;
  final String initial;

  @override
  State<NginxEditorScreen> createState() => _NginxEditorScreenState();
}

class _NginxEditorScreenState extends State<NginxEditorScreen> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      final dio = createDio(widget.profile);
      await dio.put(
        '/api/v1/nginx/sites/${widget.name}',
        data: {'content': _ctrl.text},
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kaydedildi')));
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeDioError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        actions: [
          IconButton(onPressed: _save, icon: const Icon(Icons.save)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: TextField(
          controller: _ctrl,
          maxLines: null,
          minLines: 24,
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(border: OutlineInputBorder(), alignLabelWithHint: true),
        ),
      ),
    );
  }
}
