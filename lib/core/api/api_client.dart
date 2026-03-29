import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../models/server_profile.dart';

Dio createDio(ServerProfile p) {
  final dio = Dio(
    BaseOptions(
      baseUrl: p.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 5),
      headers: {
        'Authorization': 'Bearer ${p.hash}',
        'X-RC-Key': p.hash,
      },
      validateStatus: (code) => code != null && code < 600,
    ),
  );
  // Mobil (dart:io) için: güvenilmeyen sertifika veya özel TLS ayarı
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final c = HttpClient();
      if (p.allowBadCertificate) {
        c.badCertificateCallback = (cert, host, port) => true;
      }
      c.connectionTimeout = const Duration(seconds: 30);
      return c;
    },
  );
  return dio;
}
