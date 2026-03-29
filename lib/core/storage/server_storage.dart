import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/bookmark.dart';
import '../models/server_profile.dart';

const _kServers = 'rc_servers_json';
const _kBookmarksPrefix = 'rc_bookmarks_';

class ServerStorage {
  ServerStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<List<ServerProfile>> loadServers() async {
    final raw = await _storage.read(key: _kServers);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => ServerProfile.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveServers(List<ServerProfile> servers) async {
    final raw = jsonEncode(servers.map((e) => e.toJson()).toList());
    await _storage.write(key: _kServers, value: raw);
  }

  Future<List<DbBookmark>> loadBookmarks(String serverId) async {
    final raw = await _storage.read(key: '$_kBookmarksPrefix$serverId');
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => DbBookmark.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveBookmarks(String serverId, List<DbBookmark> items) async {
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await _storage.write(key: '$_kBookmarksPrefix$serverId', value: raw);
  }
}
