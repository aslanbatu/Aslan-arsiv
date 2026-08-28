# Aslan Arşiv

Kişisel belgeler için Türkçe, yerel çalışan iOS arşiv uygulaması.

## Özellikler
- Premium siyah-altın arayüz
- Aslan Arşiv özel logosu ve uygulama ikonu
- Hazır kişisel klasörler
- Sınırsız klasör ve alt klasör
- Klasörleri yeniden adlandırma/silme
- Belge adıyla tüm arşivde hızlı arama
- iPhone VisionKit ile belge tarama
- Çok sayfalı yüksek kaliteli PDF oluşturma
- PDF ve görselleri Dosyalar uygulamasından içe aktarma
- Belge önizleme ve PDF görüntüleme
- Favoriler
- Belge yeniden adlandırma ve silme
- Yerel kalıcı depolama
- Türkçe Hakkında ekranı: “Bu uygulama Batuhan Aslan tarafından oluşturulup geliştirilmiştir.”

## Gereksinimler
- Xcode 16+
- iOS 17+
- Gerçek iPhone (kamera taraması için)

## Çalıştırma
1. `AslanArsiv.xcodeproj` dosyasını Xcode ile aç.
2. Signing & Capabilities bölümünden kendi Apple Developer Team hesabını seç.
3. Bundle Identifier'ı istersen değiştir.
4. Gerçek iPhone'u seçip Run yap.

## PDF tarama
Tarama VisionKit ile yapılır. VisionKit belge sınırlarını/perspektifi otomatik düzeltir. Tarama tamamlandığında bütün sayfalar tek bir PDF içinde oluşturulur ve arşiv klasörüne kaydedilir.

PDF oluşturma kodu `PDFBuilder.swift` içindedir. Tarama görüntüleri gereksiz şekilde düşük çözünürlüğe indirgenmez; PDF sayfasına oran korunarak yerleştirilir.

## Not
WhatsApp/Mail paylaşım uzantısı bir sonraki target olarak eklenebilir. Bunun için iOS App Group + Share Extension kurulumu gerekir; Apple Developer hesabında ilgili capability etkinleştirilmelidir.
