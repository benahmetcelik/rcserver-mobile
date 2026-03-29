import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../core/api/api_client.dart';
import '../../core/api/dio_errors.dart';
import '../../core/models/server_profile.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key, required this.profile});

  final ServerProfile profile;

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  late String _path;
  List<dynamic> _entries = [];
  String? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _path = '';
    _load(initial: true);
  }

  Future<void> _load({bool initial = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = createDio(widget.profile);
      final q = _path.isEmpty ? <String, dynamic>{} : {'path': _path};
      final res = await dio.get<Map<String, dynamic>>('/api/v1/files', queryParameters: q);
      final data = res.data;
      if (data != null && data['entries'] != null) {
        setState(() {
          _entries = data['entries'] as List<dynamic>;
          _path = data['path'] as String? ?? _path;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } on DioException catch (e) {
      setState(() {
        _error = describeDioError(e);
        _loading = false;
      });
    }
  }

  Future<void> _openFile(String path, bool isDir) async {
    if (isDir) {
      setState(() => _path = path);
      await _load();
      return;
    }
    try {
      final dio = createDio(widget.profile);
      final res = await dio.get<List<int>>(
        '/api/v1/files',
        queryParameters: {'path': path, 'download': '1'},
        options: Options(responseType: ResponseType.bytes),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İndirildi: ${res.data?.length ?? 0} bayt')),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeDioError(e))));
    }
  }

  Future<void> _upload() async {
    final r = await FilePicker.platform.pickFiles(withData: true);
    if (r == null || r.files.isEmpty) return;
    final f = r.files.single;
    final name = f.name;
    final bytes = f.bytes;
    if (bytes == null) return;
    try {
      final dio = createDio(widget.profile);
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: name),
        'path': _path,
      });
      await dio.post('/api/v1/files/upload', data: form);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yüklendi')));
      await _load();
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeDioError(e))));
    }
  }

  Future<void> _mkdir() async {
    if (_path.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce kök dizin yüklensin')),
      );
      return;
    }
    final name = await showDialog<String>(
      context: context,
      builder: (c) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Yeni klasör'),
          content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Ad')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('İptal')),
            FilledButton(onPressed: () => Navigator.pop(c, ctrl.text.trim()), child: const Text('Oluştur')),
          ],
        );
      },
    );
    if (name == null || name.isEmpty) return;
    final newPath = p.join(_path, name);
    try {
      final dio = createDio(widget.profile);
      await dio.post('/api/v1/files', data: {'path': newPath, 'is_dir': true});
      await _load();
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeDioError(e))));
    }
  }

  Future<void> _delete(String path) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Sil'),
        content: Text(path),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sil')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final dio = createDio(widget.profile);
      await dio.delete('/api/v1/files', queryParameters: {'path': path});
      await _load();
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(describeDioError(e))));
    }
  }

  void _up() {
    final parent = p.dirname(_path);
    if (parent == _path) return;
    setState(() => _path = parent);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dosyalar'),
        actions: [
          IconButton(onPressed: _up, icon: const Icon(Icons.arrow_upward)),
          IconButton(onPressed: _mkdir, icon: const Icon(Icons.create_new_folder_outlined)),
          IconButton(onPressed: _upload, icon: const Icon(Icons.upload_file)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _entries.length,
                    itemBuilder: (context, i) {
                      final e = _entries[i] as Map<String, dynamic>;
                      final path = e['path'] as String;
                      final isDir = e['is_dir'] as bool;
                      return ListTile(
                        leading: Icon(isDir ? Icons.folder : Icons.insert_drive_file_outlined),
                        title: Text(e['name'] as String? ?? path),
                        subtitle: Text('${e['size']} bayt'),
                        onTap: () => _openFile(path, isDir),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(path),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
