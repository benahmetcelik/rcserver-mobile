# RC Servers — mobil istemci

## Bağlantı hatası (“The connection errored…” / Dio)

1. **Sunucu:** `rcserver` çalışıyor mu, firewall’da port (örn. 3300) açık mı?
2. **Adres:** Telefonda `127.0.0.1` sunucu makinesini değil, **gerçek sunucu IP’sini** kullanın.
3. **HTTPS + kendi imzalı sertifika:** Sunucu eklerken “kendi imzalı sertifikaya güven” seçeneğini açın.
4. **HTTP:** Uygulama `AndroidManifest` içinde cleartext izinlidir; iOS’ta `Info.plist` ATS ayarları güncel sürümde açılmıştır.
5. Uygulamayı **yeniden derleyin** (platform izinleri değiştiyse `flutter run` / `flutter build`).

---

## Getting Started (Flutter)

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
