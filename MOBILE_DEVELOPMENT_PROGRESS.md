# Mobile Development Progress

Bu dosya PWA -> Flutter mobile parity ve market release hazırlığı için yapılan işleri takip eder.

## Tamamlananlar

- [x] Android release signing debug key bağımlılığından ayrıldı
- [x] Android cleartext traffic sadece debug build için açık hale getirildi
- [x] Release imzalama örnek yapılandırması eklendi
- [x] Shop ekranı PWA tab yapısına yaklaştırıldı
- [x] Home dashboard PWA ödül / joker / premium alanlarına yaklaştırıldı
- [x] League ekranında ham UUID yerine oyuncu adı/kısa oyuncu fallback gösterimi eklendi
- [x] Profile bildirim tercihi backend ayarıyla bağlandı
- [x] Native share altyapısı eklendi ve tüm oyun sonuç ekranlarına bağlandı
- [x] Analytics event iskeleti eklendi ve Quick/Daily/Millionaire/Duel/Tournament/Profile olaylarına bağlandı
- [ ] Push notification mobil altyapısı eklendi
- [x] IAP mobil altyapısı eklendi
- [x] Reklam mobil altyapısı eklendi
- [x] Analytics mobil altyapısı eklendi
- [x] Kritik Flutter testleri genişletildi
- [x] Achievements ekranındaki build-time profile refresh yan etkisi düzeltildi
- [x] Social ekranında ham kullanıcı id yerine oyuncu adı/kısa fallback gösterimi iyileştirildi
- [x] Leaderboard native paylaşım aksiyonu eklendi
- [x] Profile ekranı PWA detaylarına yaklaştırıldı: joker envanteri, kozmetik bilgisi, ses/titreşim/bildirim ayarları, profil paylaşımı
- [x] Achievements ekranı PWA başarım kataloğu, ilerleme yüzdesi ve ödül detaylarıyla genişletildi
- [x] PWA'daki `/play`, `/profile`, `/themes` navigasyon karşılıkları mobil route yapısına eklendi
- [x] Home alt navigasyonu PWA ana sekmelerine yaklaştırıldı: Ana Sayfa, Oyna, Sıralama, Profil, Mağaza
- [x] Flutter analyze/test doğrulandı

## Dev Hesabı Gerektirdiği İçin Bekleyenler

- [ ] App Store / Play Store gerçek IAP product tanımları
- [ ] AdMob production app id ve ad unit id değerleri
- [ ] Firebase/FCM production push kurulumu
- [ ] iOS signing / provisioning / TestFlight
- [ ] Android Play Console release signing final ayarı

## Notlar

- Başlangıç önceliği: store release güvenliği, sonra kullanıcı-facing parity farkları.
- Native push/IAP/reklam işleri bağımlılık ve platform konfigürasyonu gerektirir; gerçek cihaz QA ile tamamlanmalı.
- 2026-04-24: Android release signing placeholder, cleartext build type ayrımı, shop tab ayrımı, shop koleksiyon/stok/bakiye görünümü, home günlük ödül ve joker envanteri eklendi. `flutter analyze` ve `flutter test` temiz geçti.
- 2026-04-24: Profile bildirim ayarı PATCH `/api/me` ile bağlandı. `share_plus` eklendi, tüm oyun sonuç paylaşımı native share sheet'e bağlandı.
- 2026-04-24: Analytics servis iskeleti eklendi; Quick/Daily/Millionaire/Duel/Tournament start-complete ve profile settings eventleri tek merkezden izlenebilir hale getirildi.
- 2026-04-24: Auth widget testleri login ve register modlarını kapsayacak şekilde genişletildi.
- 2026-04-24: `in_app_purchase` eklendi; IAP katalog, satın alma, backend verify ve premium günlük gem claim akışı Shop ekranına bağlandı. Gerçek ürünler App Store / Play Store tarafında aynı product id'lerle tanımlanmalı.
- 2026-04-24: `google_mobile_ads` eklendi; rewarded ad servisi, AdMob test app id/ad unit varsayılanları ve Home rewarded reward claim akışı `/api/ads/reward` ile bağlandı.
- 2026-04-24: Dev üyeliği gerektiren production adımlar beklemeye alındı. Achievements refresh yan etkisi düzeltildi, Social isim fallbackleri iyileştirildi, Leaderboard paylaşımı eklendi.
- 2026-04-24: Profile ekranına joker envanteri, aktif tema/frame bilgisi, ses/titreşim/bildirim tercihleri, pazar hazırlığı özeti ve native profil paylaşımı eklendi.
- 2026-04-24: Achievements ekranına PWA'daki sabit başarım kataloğu, rarity/category etiketleri, ödül dökümü, yeni açılan rozet göstergesi ve profil metriklerinden ilerleme hesaplama eklendi. `flutter analyze` ve `flutter test` temiz geçti.
- 2026-04-24: Web'deki oyun modları sayfasına karşılık mobil `/play` ekranı eklendi; mod kuralları, enerji gereksinimi, ödül bilgisi ve günlük seri özeti gösteriliyor. `/profile` ve `/themes` route alias'ları eklendi, Home alt navigasyonu web ana sekmelerine yaklaştırıldı. `flutter analyze` ve `flutter test` temiz geçti.
