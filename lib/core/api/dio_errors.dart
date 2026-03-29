import 'package:dio/dio.dart';

/// Dio hatalarını kullanıcıya gösterilecek kısa Türkçe metne çevirir.
String describeDioError(Object error) {
  if (error is! DioException) {
    return error.toString();
  }
  final e = error;
  final detail = e.message ?? e.error?.toString() ?? '';
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Zaman aşımı. Sunucu yanıt vermiyor veya adres/port yanlış olabilir.\n$detail';
    case DioExceptionType.connectionError:
      return 'Bağlantı kurulamadı. Kontrol edin:\n'
          '• Sunucu çalışıyor mu (rcserver serve / firewall)?\n'
          '• IP ve port doğru mu?\n'
          '• HTTPS kullanıyorsanız “kendi imzalı sertifikaya güven” açık mı?\n'
          '• HTTP kullanıyorsanız Android/iOS ağ izinleri (güncel uygulama sürümü) yüklü mü?\n'
          '$detail';
    case DioExceptionType.badCertificate:
      return 'Sertifika doğrulanamadı. Sunucu eklerken “kendi imzalı sertifikaya güven” seçeneğini açın.\n$detail';
    case DioExceptionType.badResponse:
      return 'Sunucu yanıtı: ${e.response?.statusCode ?? '?'}\n$detail';
    case DioExceptionType.cancel:
      return 'İstek iptal edildi.';
    case DioExceptionType.unknown:
      return 'Bilinmeyen ağ hatası.\n$detail';
  }
}
