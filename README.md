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
      presentation/ # MapScreen: google_maps_flutter + uzun basma/marker/konum
    memory/
      domain/       # Memory (entity), MemoryRepository (arayüz), use case'ler
      data/         # Firestore (`memories` koleksiyonu) + Storage upload/silme
      presentation/ # MemoryProvider, Add/EditMemorySheet, MemoryList/DetailScreen
  app.dart          # MaterialApp + MultiProvider kökü
  firebase_options.dart  # `flutterfire configure` ile YENİDEN oluşturulmalı
  main.dart         # Firebase/GoogleSignIn init + servis kaydı + runApp
firestore.rules      # `memories` koleksiyonu için sahiplik kuralları
storage.rules         # `memories/{ownerId}/...` için sahiplik kuralları
```

Her feature kendi `domain` (saf Dart, Firebase'den habersiz),
`data` (Firebase implementasyonu) ve `presentation` (widget + provider)
katmanlarına sahiptir.

`MemoryProvider`, `AuthProvider`'a bağlı bir `ChangeNotifierProxyProvider`
ile besleniyor: giriş yapan kullanıcı değiştiğinde otomatik olarak o
kullanıcının `memories` koleksiyonuna yeniden abone olur (`app.dart`).

`MapScreen`'in `State` sınıfı bilerek public (`MapScreenState`): `HomeShell`
"Kaydedilenler" listesinden bir anıya dokunulduğunda `GlobalKey` üzerinden
haritaya erişip kamerayı o konuma taşıyabiliyor (`focusOnMemory`).

`ConnectivityProvider` (`core/connectivity/`) auth'tan bağımsız, uygulama
ömrü boyunca yaşayan bir singleton: cihazın bağlantı durumunu izler ve
`HomeShell` çevrimdışıyken üstte bir uyarı şeridi gösterir. Firestore zaten
çevrimdışıyken önbellekten okuyup yazmaları kuyruğa aldığı için bu sadece
bir bilgilendirme; asıl senkronizasyonu Firestore SDK'sı kendisi yapıyor.

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
| `firebase_app_check` | Sahte/otomasyon isteklerine karşı backend doğrulaması |
| `connectivity_plus` | Çevrimdışı uyarı şeridi için bağlantı durumu |
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

### 4. Google Maps

- **Android**: `android/app/src/main/AndroidManifest.xml` içindeki
  `com.google.android.geo.API_KEY` meta-data değerini Google Cloud
  Console'dan aldığınız "Maps SDK for Android" anahtarıyla değiştirin.
- **iOS**: `ios/Runner/AppDelegate.swift` içindeki
  `GMSServices.provideAPIKey("REPLACE_WITH_IOS_MAPS_API_KEY")` satırını
  "Maps SDK for iOS" anahtarınızla güncelleyin.
- Google Cloud Console'da hem **Maps SDK for Android** hem de
  **Maps SDK for iOS**'u etkinleştirmeniz gerekir.

### 5. Firestore / Storage güvenlik kuralları

Yeni bir Firebase projesi varsayılan olarak tüm okuma/yazmayı reddeder.
Depodaki `firestore.rules` ve `storage.rules` dosyaları her kullanıcının
yalnızca kendi `memories` belgelerine/dosyalarına erişebilmesini sağlar.
Firebase Console → Firestore/Storage → Rules sekmesinden yapıştırabilir,
veya Firebase CLI kuruluysa şu şekilde deploy edebilirsiniz:

```bash
firebase deploy --only firestore:rules,storage:rules
```

### 6. Firebase App Check

`main.dart`, debug derlemelerde `AndroidDebugProvider`/`AppleDebugProvider`,
release derlemelerde ise Play Integrity / App Attest kullanacak şekilde
`FirebaseAppCheck.instance.activate(...)` çağrısını zaten yapıyor. Bunu
backend tarafında etkinleştirmek için:

1. Firebase Console → **App Check** → uygulamanızı kaydedin (Android için
   Play Integrity, iOS için App Attest sağlayıcısını seçin).
2. Yerelde debug modda çalıştırdığınızda konsola bir **debug token**
   basılır; bu token'ı Firebase Console → App Check → uygulama → "Manage
   debug tokens" kısmına ekleyin, yoksa yerel derlemeleriniz reddedilir.
3. Sağlayıcılar kayıtlı ve debug token eklenmiş olduğunu doğruladıktan
   **sonra** Firestore/Storage için App Check zorunluluğunu (enforcement)
   açın — aksi halde henüz kaydolmamış istemciler tüm isteklerde
   reddedilir.

### 7. Çalıştırma

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
3. ✅ İnteraktif harita (`google_maps_flutter`): uzun basarak marker ekleme,
   markera dokununca form açılma, mevcut konuma dönme
4. ✅ Mekan ekleme formu (BottomSheet: ad, not, foto/video, 5 yıldız puan) +
   Firestore/Storage kaydı (`memories` koleksiyonu)
5. ✅ Kaydedilenler listesi + haritada seçilen konuma ışınlanma
6. ✅ Anı detay ekranı (foto karuseli, video oynatma, düzenleme/silme)
   — listeden veya haritadaki markera dokununca açılır; düzenlemede
   fotoğraf/video ekleme-çıkarma da desteklenir (Storage'daki dosyalar
   silme/değiştirmede otomatik temizlenir)
7. ✅ İyileştirmeler:
   - Kaydedilenler listesinde arama (ad/not) + minimum puan filtresi
   - Çevrimdışı farkındalığı: Firestore önbellekleme açıkça yapılandırıldı,
     `ConnectivityProvider` bağlantı yokken bir uyarı şeridi gösteriyor
   - Firebase App Check (`main.dart`'ta debug/prod sağlayıcılarıyla
     etkinleştirildi; backend tarafı için Console adımları yukarıda)
