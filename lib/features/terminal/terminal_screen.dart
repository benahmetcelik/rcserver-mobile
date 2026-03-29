import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/api/api_client.dart';
import '../../core/api/dio_errors.dart';
import '../../core/models/server_profile.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key, required this.profile});

  final ServerProfile profile;

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final _scroll = ScrollController();
  final _input = TextEditingController();
  final _oneShot = TextEditingController();
  final _buf = StringBuffer();
  WebSocketChannel? _ch;
  String? _wsError;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    final uri = Uri.parse('${widget.profile.wsBaseUrl}/api/v1/ws/terminal');
    try {
      final client = HttpClient();
      if (widget.profile.allowBadCertificate) {
        client.badCertificateCallback = (cert, host, port) => true;
      }
      final ws = await WebSocket.connect(
        uri.toString(),
        customClient: client,
        headers: {
          'Authorization': 'Bearer ${widget.profile.hash}',
          'X-RC-Key': widget.profile.hash,
        },
      );
      _ch = IOWebSocketChannel(ws);
      _ch!.stream.listen((event) {
        try {
          final j = jsonDecode(event as String) as Map<String, dynamic>;
          if (j['type'] == 'output') {
            _buf.write(j['data']);
            setState(() {});
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scroll.hasClients) {
                _scroll.jumpTo(_scroll.position.maxScrollExtent);
              }
            });
          }
        } catch (_) {
          _buf.write(event.toString());
          setState(() {});
        }
      }, onError: (e) {
        setState(() => _wsError = '$e');
      }, onDone: () {
        setState(() => _wsError = 'Bağlantı kapandı');
      });
      setState(() => _wsError = null);
    } catch (e) {
      setState(() => _wsError = '$e');
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _input.dispose();
    _oneShot.dispose();
    _ch?.sink.close();
    super.dispose();
  }

  Future<void> _sendInput() async {
    final t = _input.text;
    _input.clear();
    if (t.isEmpty || _ch == null) return;
    _ch!.sink.add(jsonEncode({'type': 'input', 'data': t}));
  }

  Future<void> _execOnce() async {
    final raw = _oneShot.text.trim();
    if (raw.isEmpty) return;
    final parts = raw.split(RegExp(r'\s+'));
    final cmd = parts.first;
    final args = parts.length > 1 ? parts.sublist(1) : <String>[];
    try {
      final dio = createDio(widget.profile);
      final res = await dio.post<Map<String, dynamic>>(
        '/api/v1/exec',
        data: {'command': cmd, 'args': args},
      );
      final d = res.data;
      if (d != null) {
        _buf.writeln('\n--- exec: $raw ---');
        _buf.writeln(d['stdout'] ?? '');
        if ((d['stderr'] as String?)?.isNotEmpty == true) {
          _buf.writeln(d['stderr']);
        }
        _buf.writeln('exit: ${d['exit_code']}');
        setState(() {});
      }
    } on DioException catch (e) {
      _buf.writeln('Hata: ${describeDioError(e)}');
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terminal')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_wsError != null)
            MaterialBanner(
              content: Text(_wsError!),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() => _wsError = null);
                    _connect();
                  },
                  child: const Text('Yeniden dene'),
                ),
              ],
            ),
          Expanded(
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.all(8),
              child: SingleChildScrollView(
                controller: _scroll,
                child: SelectableText(
                  _buf.toString().isEmpty ? 'Bağlanıyor...' : _buf.toString(),
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    decoration: const InputDecoration(
                      labelText: 'Shell girdisi',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendInput(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _sendInput, child: const Text('Gönder')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _oneShot,
                    decoration: const InputDecoration(
                      labelText: 'Tek seferlik komut (örn: uname -a)',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _execOnce(),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: _execOnce, child: const Text('Çalıştır')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
