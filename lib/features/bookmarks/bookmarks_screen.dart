import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/bookmark.dart';
import '../../core/models/server_profile.dart';
import '../../core/providers/servers_provider.dart';
import '../../core/storage/server_storage.dart';

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key, required this.profile});

  final ServerProfile profile;

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  List<DbBookmark> _items = [];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  Future<void> _load() async {
    final storage = ref.read(serverStorageProvider);
    final list = await storage.loadBookmarks(widget.profile.id);
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Bağlantı ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Başlık')),
            TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'URL (https://...)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Kaydet')),
        ],
      ),
    );
    if (ok != true) return;
    final t = titleCtrl.text.trim();
    final u = urlCtrl.text.trim();
    if (t.isEmpty || u.isEmpty) return;
    final b = DbBookmark(id: const Uuid().v4(), title: t, url: u);
    _items = [..._items, b];
    await ref.read(serverStorageProvider).saveBookmarks(widget.profile.id, _items);
    setState(() {});
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Açılamadı')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bağlantılar'),
        actions: [
          IconButton(onPressed: _add, icon: const Icon(Icons.add)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final b = _items[i];
                return ListTile(
                  title: Text(b.title),
                  subtitle: Text(b.url),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _open(b.url),
                );
              },
            ),
    );
  }
}
