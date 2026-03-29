import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../core/api/dio_errors.dart';
import '../../core/models/server_profile.dart';

class SystemScreen extends StatefulWidget {
  const SystemScreen({super.key, required this.profile});

  final ServerProfile profile;

  @override
  State<SystemScreen> createState() => _SystemScreenState();
}

class _SystemScreenState extends State<SystemScreen> {
  Map<String, dynamic>? _data;
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
      final res = await dio.get<Map<String, dynamic>>('/api/v1/system');
      setState(() {
        _data = res.data;
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = describeDioError(e);
        _loading = false;
      });
    }
  }

  String _bytes(num? n) {
    if (n == null) return '-';
    final fmt = NumberFormat.decimalPattern();
    if (n >= 1e9) return '${fmt.format(n / 1e9)} GB';
    if (n >= 1e6) return '${fmt.format(n / 1e6)} MB';
    return '${fmt.format(n)} B';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sistem')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_data != null) ...[
                        _row('Hostname', '${_data!['hostname']}'),
                        _row('OS', '${_data!['os']} ${_data!['platform']}'),
                        _row('Uptime (sn)', '${_data!['uptime_sec']}'),
                        _row('CPU çekirdek', '${_data!['cpu_count']}'),
                        _row('CPU %', '${(_data!['cpu_percent'] as num?)?.toStringAsFixed(1) ?? '-'}'),
                        _row('Load', '${_data!['load1']} / ${_data!['load5']} / ${_data!['load15']}'),
                        _row('RAM', '${_bytes(_data!['mem_used_bytes'] as num?)} / ${_bytes(_data!['mem_total_bytes'] as num?)} '
                            '(${(_data!['mem_percent'] as num?)?.toStringAsFixed(1)}%)'),
                        _row('Disk (${_data!['disk_path']})',
                            '${_bytes(_data!['disk_used_bytes'] as num?)} / ${_bytes(_data!['disk_total_bytes'] as num?)}'),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}
