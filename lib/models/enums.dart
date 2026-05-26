enum MetaType {
  financial, // Finansal ve piyasa odaklı veri dökümanı
  scientific, // Bilimsel analiz ve dağılım dökümanı
  statistical, // İstatistiksel ve raporlama odaklı döküman
  dashboard, // Çoklu gösterge ve panel dökümanı
  cartesian3d, // Üç boyutlu (X, Y, Z) derinlikli düzlem
}

enum MetaSubType {
  trading, // Aktif işlem ve teknik analiz arayüzü
  reporting, // Statik veri sunumu ve çıktı raporu
  comparison, // Varlıklar arası kıyaslama analizi
  heatmap, // Matris tabanlı yoğunluk görselleştirmesi
  realtime, // Sürekli akan canlı veri simülasyonu
}

enum Axis {
  x, // Yatay düzlemdeki eksen konumu
  y, // Dikey düzlemdeki eksen konumu
}

enum CoordinateSystem {
  cartesian, // Standart dik açılı (X, Y) koordinat düzlemi
  polar, // Dairesel açı ve yarıçap tabanlı düzlem
  geo, // Coğrafi projeksiyon ve harita düzlemi
  none, // Hiyerarşik veya algoritma tabanlı serbest yerleşim
  cartesian3d, // Üç boyutlu (X, Y, Z) derinlikli düzlem
}

enum BaseAxisType {
  time, // Zaman damgalı (Timestamp) lineer akış ekseni
  category, // Bağımsız grup ve etiketlerden oluşan eksen
  linear, // Sayısal değerlerden oluşan bağımsız değişken ekseni
}

enum GapPolicy {
  skip, // Eksik veri noktalarını boş bırakarak atla
  connect, // Eksik veri noktalarını birleştirerek çizimi devam ettir
  fill, // Eksik verileri varsayılan veya hesaplanmış bir değerle doldur
}

enum TimezoneDisplayMode {
  utc, // Veriyi her zaman ham evrensel zamanında (0) göster
  source, // Verinin geldiği kaynağın/borsanın saat dilimini kullan
  local, // Kullanıcının cihazındaki yerel saat dilimine dönüştür
}

enum LineStyle {
  solid, // Kesintisiz düz çizgi stili
  dashed, // Kesikli kısa çizgili stil
  dotted, // Noktalardan oluşan çizgi stili
}

enum ValueAxisType {
  linear, // Eşit aralıklı standart mutlak değer ölçeği
  // log, // Oransal değişimleri vurgulayan logaritmik ölçek
  // percentage, // Başlangıca veya toplama oranlı yüzdesel ölçek
}

// enum AxisScaleType { time, linear, log, percentage }

// enum FormatType { number, percent }

enum ChartCategory {
  primary, // Ana fiyat serisi (Mumlar, Çizgi Grafik, Heikin Ashi)
  indicator, // Matematiksel formüllerle hesaplanan teknik göstergeler
  drawing, // Kullanıcı tarafından eklenen manuel geometrik çizimler
  overlay, // Mevcut grafiklerin üzerine bindirilen yardımcı araçlar
}

enum ChartSubCategory {
  trend, // Fiyatın yönünü takip eden araçlar (MA, Ichimoku, Parabolic SAR)
  oscillator, // Aşırı alım/satım bölgesini ölçen araçlar (RSI, MACD, Stochastic)
  volatility, // Fiyatın oynaklığını ve bantlarını ölçen araçlar (BB, ATR)
  volume, // İşlem hacmi ve para akışı tabanlı araçlar (OBV, MFI)
  priceAction, // Kurumsal emir blokları ve boşlukları (Orderblock, FVG)
  statistical, // Veri dağılımı ve standart sapma tabanlı araçlar (VWAP)
  signals, // Al/Sat sinyalleri veya haber ikonları gibi markerlar
}

enum ChartPlacement {
  separate, // Grafiği ana panelden bağımsız, yeni bir alt panelde açar
  overlay, // Grafiği mevcut ana fiyat panelinin üzerine bindirerek çizer
}

enum ChartProvider {
  system, // Platform tarafından sunulan standart yerleşik araçlar
  user, // Kullanıcı tarafından oluşturulan veya dışarıdan aktarılan araçlar
}

enum VisibilityType {
  public, // Tüm kullanıcılar tarafından görülebilen ve paylaşılabilen yapı
  private, // Sadece döküman sahibi tarafından erişilebilen gizli yapı
}

enum LegendItemType { input, plot, notation }

enum InputType {
  string, // Serbest metin girişi
  symbol, // Finansal varlık çifti seçimi (BTC/USDT vb.)
  interval, // Zaman dilimi seçimi (1m, 5m, 1h, 4h, 1d)
  integer, // Tam sayı değer girişi (Period, Length vb.)
  double, // Ondalıklı sayı değer girişi (Smoothing, Deviation vb.)
  boolean, // Aç/Kapat (Toggle) şeklinde mantıksal seçim
  dateTime, // Zaman damgası veya tarih seçimi (Start/End Time)
}

enum FieldType {
  string, // Metinsel veri kolonu (Signal names, Descriptions)
  integer, // Tam sayı veri kolonu (Volume, Counter)
  double, // Ondalıklı sayı veri kolonu (Price, Indicator values)
  boolean, // Mantıksal durum kolonu (Trend up/down, IsTrend)
  dateTime, // Zaman damgası kolonu (Close Time, Open Time)
}

/*
 Interval Tipleri

"1s",   // 1 Saniye
"1m",   // 1 Dakika
"3m",   // 3 Dakika
"5m",   // 5 Dakika
"15m",  // 15 Dakika
"30m",  // 30 Dakika
"45m",  // 45 Dakika
"1h",   // 1 Saat
"2h",   // 2 Saat
"3h",   // 3 Saat
"4h",   // 4 Saat
"1d",   // 1 Gün
"1w",   // 1 Hafta
"1M",   // 1 Ay  
 */

enum PlotType {
  line, // Veri noktalarını birbirine bağlayan standart çizgi
  area, // Çizgi ile eksen arasının boyandığı alan grafiği
  candlestick, // Açılış, yüksek, düşük, kapanış gövdesinden oluşan mum
  bar, // Dikey çubuklardan oluşan histogram veya fiyat çubuğu
  band, // İki değer (alt ve üst) arasını boyayan kuşak grafiği
}

enum DataForm {
  scalar, // Tekil sayısal değerlerden oluşan basit veri dizisi
  ohlc, // Dörtlü (Open, High, Low, Close) fiyat paketi
  band, // İkili (Upper, Lower) sınır değer paketi
}

enum GuideType {
  line, // Belirli bir değer seviyesinde çizilen referans çizgisi
  band, // Belirli iki değer aralığını vurgulayan referans bölgesi
}

enum NotationType {
  marker, // Simge veya ikon (Ok, Yıldız, Nokta)
  label, // Düz metin etiketi
}

enum NotationPosition {
  above, // Mumun veya veri noktasının hemen üstü
  below, // Mumun veya veri noktasının hemen altı
  inside, // Tam olarak belirtilen fiyat/değer seviyesi
}

enum ContentPosition {
  topLeft, // Sol üst köşe
  topCenter, // Üst orta
  topRight, // Sağ üst köşe
  middleLeft, // Sol orta kenar
  middleCenter, // Tam merkez
  middleRight, // Sağ orta kenar
  bottomLeft, // Sol alt köşe
  bottomCenter, // Alt orta
  bottomRight, // Sağ alt köşe
}

enum ContentOrientation {
  horizontal, // Elemanları yan yana dizer (Satır)
  vertical, // Elemanları alt alta dizer (Sütun)
}

enum LayoutType {
  /// Slotları alt alta dizer. Zaman ekseni hizalaması (Sync) için standarttır.
  /// Uyumlu: [Finance/Trading], [Scientific] | coordinateSystem: [TimeSeries] | Grafik: Candle, Line, Area, OHLC.
  vertical,

  /// Slotları yan yana dizer. Kare oranlı (1:1) alan gerektirenler içindir.
  /// Uyumlu: [Report/Comparison] | coordinateSystem: [Polar], [Categorical] | Grafik: Pie, Radar, Donut.
  horizontal,

  /// Slotları satır/sütun matrisine böler. Çoklu veri özeti içindir.
  /// Uyumlu: [Dashboard/Analytics] | coordinateSystem: [Categorical], [XY/Scatter] | Grafik: Bar, Heatmap, Bubble.
  grid,

  /// Sadece ana slotu (Index 0) tam ekran gösterir.
  /// Uyumlu: [Any] (Tüm Meta Tipleri) | Mobil görünüm ve Odak modu için evrenseldir.
  single,
}

/// Zarfın Tipi (packet.type)
enum PacketType {
  snapshot, // Tam döküman (HTTP GET)
  data, // Fiyat/Veri akışı (WebSocket)
  patch, // Ayar/Yapı değişikliği (WebSocket)
  busy, // Sunucu meşguliyet durumu (WebSocket)
  error, // Hata bildirimi (WebSocket)
}

/// Veri Aksiyonu (payload.action) - Sadece 'data' tipi için
enum DataAction {
  update, // Son veriyi güncelle (Tick)
  append, // Sona ekle (Bar Close)
  prepend, // Başa ekle
  overwrite, // Aralığı ez (Repaint / Geçmiş Düzeltme)
  clear, // Listeyi temizle
}

/// Yama Operasyonu (op) - Sadece 'patch' tipi için
enum PatchOperation {
  replace, // Değer değiştir
  add, // Obje ekle
  remove, // Obje sil
  move, // Obje taşı
}

/// Hata Seviyesi (severity) - Sadece 'error' tipi için
enum ErrorSeverity {
  warning, // Uyarı göster, devam et
  critical, // Reset at (Snapshot iste)
}

/// Yama işleminin etki alanını belirler.
enum PatchScope {
  /// 1. KÖK DÜZEYİ: Tüm dökümanı etkiler (Layout, VisualSettings).
  /// ID Gereksinimi: HİÇBİRİ.
  root,

  /// 2. GRAFİK DÜZEYİ: Tek bir grafik panelini etkiler (Meta, Legend).
  /// ID Gereksinimi: `targetId` (Chart ID).
  chart,

  /// 3. ÇİZİM DÜZEYİ: Grafiğin içindeki çizgileri/mumları etkiler (Renk, Stil).
  /// ID Gereksinimi: `targetId` (Chart ID) + `childId` (Plot ID).
  plot,

  /// 4. GİRDİ DÜZEYİ: İndikatör parametrelerini etkiler (Periyot, Kaynak).
  /// ID Gereksinimi: `targetId` (Chart ID) + `childId` (Input ID).
  input,

  /// 5. EKSEN DÜZEYİ: X veya Y eksenlerini etkiler.
  /// ID Gereksinimi: `childId` (Axis ID). (Eksenler global tanımlandığı için targetId opsiyoneldir).
  dimensions,
}

/// Root kapsamının alt bölümlerini tanımlar.
enum RootScope {
  /// Ekran yerleşimi, slotlar ve panel boyutları.
  /// JSON Yolu: "layout.*"
  layout,

  /// Döküman genelindeki görsel ayarlar (Crosshair, Tooltip, Legend).
  /// JSON Yolu: "visualSettings.*"
  visualSettings,

  /// Döküman kimliği, tipi ve versiyon bilgileri.
  /// JSON Yolu: "meta.*"
  meta,

  /// Eksen tanımları havuzu (BaseAxis, ValuesAxes).
  /// JSON Yolu: "dimensions.*"
  dimensions,
}
