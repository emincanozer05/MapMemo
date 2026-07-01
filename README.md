# MapMemo

Android ve iOS için, harita üzerinde anı kaydetmeye yarayan bir Flutter
uygulaması. Kimlik doğrulama, veritabanı ve dosya depolama için Firebase
(Auth, Firestore, Storage) kullanır.

## Mimari

Clean Architecture katmanları + `provider` (state management) + `get_it`
(dependency injection):

```
lib/
  core/
    config/        # Google Sign-In gibi ortama özgü sabitler
    di/             # get_it servis kaydı (service_locator.dart)
    error/          # Ortak exception tipleri (AppException, AuthException, ...)
    theme/          # AppTheme (Material 3)
  features/
    auth/
      domain/       # AppUser (entity), AuthRepository (arayüz), use case'ler
      data/         # FirebaseAuth + google_sign_in ile gerçek uygulama
      presentation/ # AuthProvider (ChangeNotifier), LoginScreen, AuthGate
    home/
      presentation/ # BottomNavigationBar kabuğu (HomeShell)
    map/
      presentation/ # (yer tutucu) İnteraktif harita — sıradaki adım
    memory/
      presentation/ # (yer tutucu) Kaydedilenler listesi — sıradaki adım
  app.dart          # MaterialApp + MultiProvider kökü
  firebase_options.dart  # `flutterfire configure` ile YENİDEN oluşturulmalı
  main.dart         # Firebase/GoogleSignIn init + servis kaydı + runApp
```

Her feature kendi `domain` (saf Dart, Firebase'den habersiz),
`data` (Firebase implementasyonu) ve `presentation` (widget + provider)
katmanlarına sahiptir. `map` ve `memory` modüllerinin domain/data katmanları
bir sonraki adımlarda eklenecek; şu an yalnızca `HomeShell` içinden
gezinilebilen yer tutucu ekranları var.

## Paketler (`pubspec.yaml`)

| Paket | Amaç |
|---|---|
| `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage` | Firebase altyapısı |
| `google_sign_in` | Google ile tek tıkla giriş |
| `google_maps_flutter` | İnteraktif harita |
| `geolocator` | Kullanıcının mevcut konumu |
| `provider` | State management |
| `get_it` | Dependency injection / service locator |
| `image_picker` | Galeri/kameradan fotoğraf-video seçimi |
| `video_player` | Kaydedilen videoları oynatma |
| `cached_network_image` | Firebase Storage görsellerini önbellekli gösterme |
| `flutter_rating_bar` | 5 yıldızlı puanlama bileşeni |
| `uuid` | Mekan/medya için benzersiz kimlikler |
| `intl` | Tarih biçimlendirme |
| `permission_handler` | Kamera/galeri/konum izin akışları |
| `mocktail` (dev) | Use case / repository testleri |

## Kurulum

### 1. Bağımlılıklar

```bash
flutter pub get
```

### 2. Firebase projesi

`lib/firebase_options.dart` ve platform config dosyaları (`google-services.json`,
`GoogleService-Info.plist`) bu depoda **yer tutucu** değerlerle bırakıldı,
çünkü gerçek bir Firebase projesi bilgisi gerektirir. Kendi projenizi bağlamak
için:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Bu komut Android/iOS için Firebase Auth, Firestore ve Storage'ı etkinleştirdiğiniz
bir projeyi seçmenizi ister ve `lib/firebase_options.dart` ile
`android/app/google-services.json` / `ios/Runner/GoogleService-Info.plist`
dosyalarını sizin için üretir/günceller (Android tarafında
`com.google.gms.google-services` Gradle eklentisini de otomatik ekler).

Firebase Console'da **Authentication → Sign-in method → Google**'ı
etkinleştirmeyi unutmayın; bu adım aynı zamanda `google_sign_in`'in Android'de
otomatik olarak kullandığı bir "web" OAuth istemcisi oluşturur.

### 3. Google Sign-In (platforma özgü ek adımlar)

- **Android**: `google-services.json` içinde bir web OAuth istemcisi
  varsa (Firebase Console'dan Google girişini etkinleştirdiyseniz otomatik
  gelir) ekstra bir şey yapmanıza gerek yok. Aksi halde
  `lib/core/config/google_sign_in_config.dart` içindeki
  `googleSignInServerClientId` sabitini web istemci kimliğinizle doldurun.
- **iOS**: `GoogleService-Info.plist` dosyasındaki `REVERSED_CLIENT_ID`
  değerini `ios/Runner/Info.plist` içindeki `CFBundleURLTypes` →
  `CFBundleURLSchemes` alanına yazın (şu an `REPLACE_WITH_REVERSED_CLIENT_ID`
  yer tutucusu var). `flutterfire configure` bu adımı bazen otomatik yapar,
  yapmıyorsa elle güncelleyin.

### 4. Google Maps (sıradaki adımda kullanılacak)

- **Android**: `android/app/src/main/AndroidManifest.xml` içindeki
  `com.google.android.geo.API_KEY` meta-data değerini Google Cloud
  Console'dan aldığınız "Maps SDK for Android" anahtarıyla değiştirin.
- **iOS**: `ios/Runner/AppDelegate.swift` içine
  `GMSServices.provideAPIKey("YOUR_KEY")` satırını eklemeniz gerekecek
  (harita modülü eklenirken birlikte yapılacak).

### 5. Çalıştırma

```bash
flutter run   # bağlı bir Android/iOS cihaz veya emülatör ile
```

### Testler

```bash
flutter analyze
flutter test
```

## Yol haritası

1. ✅ Proje iskeleti, `pubspec.yaml`, Clean Architecture klasör yapısı
2. ✅ Google ile Giriş (Firebase Auth + `google_sign_in`)
3. ⏭️ İnteraktif harita (`google_maps_flutter`) + uzun basarak marker ekleme
4. ⏭️ Mekan ekleme formu (BottomSheet: ad, not, foto/video, 5 yıldız puan) + Firestore/Storage kaydı
5. ⏭️ Kaydedilenler listesi + haritada seçilen konuma ışınlanma
