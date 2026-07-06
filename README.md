# Esma-ül Hüsnâ 🌙

Allah'ın 99 güzel ismi (Esmâ-i Hüsnâ) için tasarlanmış, sade ve şık bir **zikirmatik / dijital tesbih** uygulaması. Flutter ile geliştirilmiştir.

Her isim; Arapça yazılışı, okunuşu, Türkçe anlamı, fazileti ve ebced değeriyle birlikte sunulur. Dokunmatik sayaç, huzurlu animasyonlar ve zikir takibi ile modern bir deneyim sağlar.

## ✨ Özellikler

- **99 isim** — Arapça, Latin okunuş, Türkçe okunuş, anlam ve fazilet bilgileriyle
- **Zikirmatik sayaç** — ekrana dokunarak zikir çekme, kalan sayı büyük ve net gösterim
- **İki hedef modu** — her ismin **ebced** değeri ya da kendi belirlediğin **özel** sayı (33, 99, 100…)
- **Işık dalgası (ripple)** animasyonu — her dokunuşta dokunulan noktadan yayılan zarif halkalar
- **Kilometre taşı** animasyonu — her %10 ilerlemede kalan sayı parlayarak yukarı süzülür
- **Titreşim geri bildirimi** (açılıp kapatılabilir)
- **Kısayollar / favoriler** — sık kullandığın isimleri kaydet, tek dokunuşla geç, kolayca kaldır
- **Zikir geçmişi** — ilerleme durumu ve her ismin **kaç kez tamamlandığı**
- **Kolay gezinme** — kenarlardaki geçiş okları ve "3 / 99" konum göstergesi
- Koyu, lacivert gradyan tema

## 📱 Ekran Görüntüleri

> Ekran görüntülerini buraya ekleyebilirsiniz (`screenshots/` klasörü).

## 🛠️ Teknolojiler

- [Flutter](https://flutter.dev/) & Dart
- [shared_preferences](https://pub.dev/packages/shared_preferences) — yerel veri saklama (favoriler, geçmiş, ayarlar)
- [vibration](https://pub.dev/packages/vibration) — dokunuş geri bildirimi
- Özel `CustomPainter` çizimleri (dairesel ilerleme, ışık dalgası animasyonu)

## 🚀 Kurulum

Gereksinim: [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.11+)

```bash
# Bağımlılıkları yükle
flutter pub get

# Uygulamayı çalıştır (bağlı cihaz/emülatör ile)
flutter run
```

### APK oluşturma

```bash
flutter build apk --release
# Çıktı: build/app/outputs/flutter-apk/app-release.apk
```

## 📂 Proje Yapısı

```
lib/
├── main.dart                  # Uygulama girişi
├── data/esma_data.dart        # 99 ismin verisi (Arapça, anlam, fazilet, ebced)
├── models/                    # EsmaModel, ZikirHistory
├── screens/                   # Zikir, geçmiş, favoriler, ayarlar ekranları
├── services/                  # Depolama ve titreşim servisleri
└── widgets/                   # Dairesel ilerleme, ripple, kilometre taşı
```

## 📝 Not (Ebced değerleri hakkında)

Ebced esaslı zikir sayılarının kesin bir dinî dayanağı bulunmamakla birlikte, halk arasında yaygın olarak benimsenmiş bir uygulamadır. Uygulamada bu değerler bilgi ve isteğe bağlı bir hedef seçeneği olarak sunulur; dilerseniz **Özel** moddan kendi sayınızı belirleyebilirsiniz.

## 🤝 Katkı

Katkılar, hata bildirimleri ve öneriler memnuniyetle karşılanır. Bir issue açabilir veya pull request gönderebilirsiniz.

## 📄 Lisans

Bu proje [MIT Lisansı](LICENSE) ile lisanslanmıştır.
