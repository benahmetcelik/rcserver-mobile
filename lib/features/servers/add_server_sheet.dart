import 'package:flutter/material.dart';

import '../../core/models/server_profile.dart';
import '../../core/providers/servers_provider.dart';

/// [editing] null ise yeni sunucu; dolu ise mevcut kayıt güncellenir (aynı `id` korunur).
class AddServerSheet extends StatefulWidget {
  const AddServerSheet({super.key, this.editing});

  final ServerProfile? editing;

  @override
  State<AddServerSheet> createState() => _AddServerSheetState();
}

class _AddServerSheetState extends State<AddServerSheet> {
  late final TextEditingController _name;
  late final TextEditingController _host;
  late final TextEditingController _port;
  late final TextEditingController _hash;
  late bool _tls;
  late bool _insecure;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _name = TextEditingController(text: e?.name ?? '');
    _host = TextEditingController(text: e?.host ?? '');
    _port = TextEditingController(text: e != null ? '${e.port}' : '3300');
    _hash = TextEditingController(text: e?.hash ?? '');
    _tls = e?.useTls ?? true;
    _insecure = e?.allowBadCertificate ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _host.dispose();
    _port.dispose();
    _hash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEdit ? 'Sunucuyu düzenle' : 'Sunucu ekle',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Görünen ad'),
            ),
            TextField(
              controller: _host,
              decoration: const InputDecoration(labelText: 'IP veya hostname'),
            ),
            TextField(
              controller: _port,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Port'),
            ),
            TextField(
              controller: _hash,
              decoration: const InputDecoration(labelText: 'HASH'),
              maxLines: 2,
            ),
            SwitchListTile(
              title: const Text('HTTPS (TLS)'),
              value: _tls,
              onChanged: (v) => setState(() => _tls = v),
            ),
            SwitchListTile(
              title: const Text('Kendi imzalı sertifikaya güven (önerilen: test)'),
              value: _insecure,
              onChanged: (v) => setState(() => _insecure = v),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final port = int.tryParse(_port.text.trim());
                if (_name.text.trim().isEmpty ||
                    _host.text.trim().isEmpty ||
                    port == null ||
                    _hash.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tüm alanları doldurun')),
                  );
                  return;
                }
                Navigator.of(context).pop(
                  ServerProfile(
                    id: widget.editing?.id ?? ServersNotifier.newId(),
                    name: _name.text.trim(),
                    host: _host.text.trim(),
                    port: port,
                    hash: _hash.text.trim(),
                    useTls: _tls,
                    allowBadCertificate: _insecure,
                  ),
                );
              },
              child: Text(_isEdit ? 'Güncelle' : 'Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
