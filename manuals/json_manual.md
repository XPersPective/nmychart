# Grafik Motoru Entegrasyon Json Yapısı Kılavuzu

Bu doküman, Grafik Motoru (Chart Engine) için kullanılan JSON veri protokolünü açıklar.

## 0. PAKET TİPLERİ (`packetType`)

Sunucu ve istemci arasındaki iletişimde kullanılan temel zarf (envelope) tipleri şunlardır:

*   **`snapshot`**: Tam döküman yapısını ve başlangıç verisini içerir. İlk bağlantıda veya reset durumunda kullanılır.
*   **`data`**: Fiyat, indikatör veya sensör verisi gibi "akışkan" verileri içerir.
*   **`patch`**: Ayar, renk, görünüm veya yapısal değişiklikleri içerir. Veri içermez.
*   **`busy`**: Sunucunun meşguliyet durumunu (hesaplama sürüyor vb.) bildirir.
*   **`error`**: Kritik veya uyarı seviyesindeki hataları bildirir.

---

## 1. SNAPSHOT İSKELETİ (`snapshot`)

ChartSet (Grafik Seti) dökümanının en üst seviye yapısıdır. Sahnenin genel yerleşimini ve veri kaynaklarını tanımlar. `packetType: "snapshot"` zorunludur.

```json
{
  "meta": {
    "packetType": "snapshot",
    ...
  },
  "layout": {...},
  "visualSettings": {...},
  "dimensions": {...},
  "baseAxisData": [...],
  "charts": [
    [ {Chart}, {Chart},{Chart}, {Chart}.. ], //slot 0
    [ {Chart}, {Chart}, {Chart} ] //slot 1
    ...
  ]
}
```

*   **meta**: ChartSet dökümanının kimliği, versiyonu ve tip bilgileri.
*   **layout**: Ekran yerleşimi ve slot yapılandırması.
*   **visualSettings**: Global görsel ayarlar.
*   **dimensions**: Eksen tanımları.
*   **baseAxisData**: Temel eksen için paylaşılan ortak veri.
*   **charts**: Liste içinde liste yapısı. Dış liste slotları temsil eder (Örn: İndis 0 ana panel, İndis 1 alt panel), iç liste ise o slota çizilecek grafikleri barındırır.

> **Not:**
> ChartSet dökümanı içerisindeki tüm zaman damgası (timestamp) alanları, sunucudan **milisaniye** cinsinden (Unix Timestamp) ve **UTC** zaman diliminde gelir. Sistem genelinde zaman yönetimi bu standart üzerinden yürütülür.

---

## 2. GENEL İSKELET AÇIKLAMALARI

### 2.1. META VERİSİ (`meta`)

ChartSet dökümanının kimliğini ve türünü belirten bloktur.

```json
"meta": {
  "id": "doc_unique_999",
  "packetType": "snapshot", 
  "type": "finance",
  "subType": "trading",
  "coordinateSystem": "cartesian",
  "schemaVersion": "1.0.0",
  "revision": 1,
  "updatedAt": 1707829200000
}
```

*   **id**: ChartSet dökümanının benzersiz kimliğidir (String).
*   **packetType**: Bu paketin `snapshot` olduğunu belirtir.
*   **schemaVersion**: JSON yapısının versiyon numarasıdır (String).
*   **revision**: ChartSet dökümanının revizyon numarasıdır (Integer).
*   **updatedAt**: ChartSet dökümanının en son güncellendiği zaman damgasıdır (Long/Timestamp).
*   **type**: ChartSet dökümanının ana tipi.
    *   `finance`: Finansal ve piyasa odaklı ChartSet dökümanı.
    *   `scientific`: Bilimsel analiz ve dağılım ChartSet dökümanı.
    *   `statistical`: İstatistiksel ve raporlama odaklı ChartSet dökümanı.
    *   `dashboard`: Çoklu gösterge ve panel ChartSet dökümanı.
    *   `cartesian3d`: Üç boyutlu derinlikli düzlem.
*   **subType**: ChartSet dökümanının alt tipi.
    *   `trading`: Aktif işlem ve teknik analiz arayüzü.
    *   `reporting`: Statik veri sunumu ve çıktı raporu.
    *   `comparison`: Varlıklar arası kıyaslama analizi.
    *   `heatmap`: Matris tabanlı yoğunluk görselleştirmesi.
    *   `realtime`: Sürekli akan canlı veri simülasyonu.
*   **coordinateSystem**: Kullanılan koordinat sistemi.
    *   `cartesian`: Standart dik açılı (X, Y) koordinat düzlemi.
    *   `polar`: Dairesel açı ve yarıçap tabanlı düzlem.
    *   `geo`: Coğrafi projeksiyon ve harita düzlemi.
    *   `cartesian3d`: Üç boyutlu derinlikli düzlem.
    *   `none`: Serbest yerleşim.

### 2.2. YERLEŞİM (`layout`)

Yerleşim (Layout) bloğu, seçilen `type` değerine göre farklı JSON yapılarına sahiptir.

**Geçerli Yerleşim Tipleri:**
*   `vertical`
*   `horizontal`
*   `grid`
*   `single`

#### 2.2.1. Dikey Yerleşim (`vertical`)
Slotları alt alta dizer. Zaman ekseni hizalaması (Sync) için standarttır.

```json
"layout": {
  "type": "vertical",
  "resizable": true,
  "separatorSize": 4,
  "slots": [
    {
      "index": 0,
      "weight": 3.0,
      "minSize": 200
    },
    {
      "index": 1,
      "weight": 1.0,
      "minSize": 80
    }
  ]
}
```
*   **type**: Bu yerleşim tipi için sabit değer `vertical`'dır.
*   **resizable**: Kullanıcının slot boyutlarını değiştirip değiştiremeyeceğini belirler (`true`/`false`).
*   **separatorSize**: Slotlar arasındaki ayırıcı çizginin piksel cinsinden kalınlığıdır (Double).
*   **slots**: Slot ayarlarının listesidir.
    *   **index**: Render edilecek grafik slotunun indisi (0'dan başlar).
    *   **weight**: Slotun kaplayacağı alan ağırlığıdır (Flex değeri).
    *   **minSize**: Slotun alabileceği minimum piksel yüksekliğidir.

#### 2.2.2. Yatay Yerleşim (`horizontal`)
Slotları yan yana dizer.

```json
"layout": {
  "type": "horizontal",
  "resizable": true,
  "separatorSize": 4,
  "slots": [
    {
      "index": 0,
      "weight": 1.0,
      "minSize": 150
    },
    {
      "index": 1,
      "weight": 1.0,
      "minSize": 150
    }
  ]
}
```
*   **type**: Bu yerleşim tipi için sabit değer `horizontal`'dır.
*   **resizable**: Kullanıcının slot boyutlarını değiştirip değiştiremeyeceğini belirler (`true`/`false`).
*   **separatorSize**: Slotlar arasındaki ayırıcı çizginin piksel cinsinden kalınlığıdır (Double).
*   **slots**: Slot ayarlarının listesidir.
    *   **index**: Render edilecek grafik slotunun indisi.
    *   **weight**: Slotun kaplayacağı genişlik ağırlığıdır (Flex değeri).
    *   **minSize**: Slotun alabileceği minimum piksel genişliğidir.

#### 2.2.3. Izgara Yerleşim (`grid`)
Slotları satır/sütun matrisine böler.

```json
"layout": {
  "type": "grid",
  "columns": 2,
  "rows": 2,
  "gap": 8,
  "slots": [
    {
      "index": 0,
      "col": 0,
      "row": 0,
      "colSpan": 1,
      "rowSpan": 1
    },
    {
      "index": 1,
      "col": 1,
      "row": 0,
      "colSpan": 1,
      "rowSpan": 1
    },
    {
      "index": 2,
      "col": 0,
      "row": 1,
      "colSpan": 2,
      "rowSpan": 1
    }
  ]
}
```
*   **type**: Bu yerleşim tipi için sabit değer `grid`'dir.
*   **columns**: Toplam sütun sayısıdır (Integer).
*   **rows**: Toplam satır sayısıdır (Integer).
*   **gap**: Paneller arasındaki boşluk miktarını (piksel) belirler (Double).
*   **slots**: Slot ayarlarının listesidir.
    *   **index**: Render edilecek grafik slotunun indisi.
    *   **col**: Slotun başlangıç sütun koordinatıdır (0 tabanlı).
    *   **row**: Slotun başlangıç satır koordinatıdır (0 tabanlı).
    *   **colSpan**: Slotun kaç sütun boyunca yayılacağını belirtir.
    *   **rowSpan**: Slotun kaç satır boyunca yayılacağını belirtir.

#### 2.2.4. Tekil Yerleşim (`single`)
Sadece ana slotu (Index 0) tam ekran gösterir.

```json
"layout": {
  "type": "single",
  "padding": 10,
  "slots": [
    {
      "index": 0,
      "weight": 1.0
    }
  ]
}
```
*   **type**: Bu yerleşim tipi için sabit değer `single`'dır.
*   **padding**: Slotun etrafındaki kenar boşluğu miktarıdır (Double).
*   **slots**: Tek bir eleman içeren listedir.
    *   **index**: Genellikle 0'dır.
    *   **weight**: Genellikle 1.0'dır (Tam alan).

### 2.3. GÖRSEL AYARLAR (`visualSettings`)

Sahne genelindeki görsel yardımcıları yöneten bloktur.

```json
"visualSettings": {
  "crosshair": {
    "mode": "visible",
    "style": "dashed",
    "color": "#888888",
    "showLabels": true
  },
  "legend": {
    "position": "topLeft",
    "orientation": "horizontal"
  },
  "tooltip": {
    "position": "topLeft",
    "orientation": "horizontal"
  }
}
```

*   **crosshair**: İmleç takipçi çizgilerinin ayarlarıdır.
    *   **mode**: Görünürlük durumunu belirler (Örn: `visible`).
    *   **style**: Çizgi stilini belirler.
        *   `solid`: Düz çizgi.
        *   `dashed`: Kesikli çizgi.
        *   `dotted`: Noktalı çizgi.
    *   **color**: Çizginin rengidir (Hex code string).
    *   **showLabels**: Eksen etiketlerinin görünüp görünmeyeceğini belirler (`true`/`false`).
*   **legend**: Grafik lejantının (açıklama kutusu) ayarlarıdır.
    *   **position**: Lejantın ekrandaki konumudur.
        *   `topLeft`: Sol üst köşe.
        *   `topCenter`: Üst orta.
        *   `topRight`: Sağ üst köşe.
        *   `middleLeft`: Sol orta kenar.
        *   `middleCenter`: Tam merkez.
        *   `middleRight`: Sağ orta kenar.
        *   `bottomLeft`: Sol alt köşe.
        *   `bottomCenter`: Alt orta.
        *   `bottomRight`: Sağ alt köşe.
    *   **orientation**: Lejant elemanlarının dizilim yönüdür.
        *   `horizontal`: Yatay (yan yana).
        *   `vertical`: Dikey (alt alta).
*   **tooltip**: Veri gösterge kutusunun (hover bilgi penceresi) ayarlarıdır.
    *   **position**: Tooltip'in konumu (Yukarıdaki pozisyon tipleri ile aynıdır).
    *   **orientation**: Tooltip içeriğinin dizilim yönü (`horizontal`, `vertical`).

### 2.4. EKSENLER (`dimensions`)

Sahnenin matematiksel uzayını ve koordinat eksenlerini tanımlar. İki ana eksen grubu içerir:

**Eksen Grupları:**
*   `baseAxis` (Temel Eksen)
*   `valuesAxis` (Değer Eksenleri Listesi)

```json
"dimensions": {
  "baseAxis": {...},   // Temel Eksen
  "valuesAxis": [...] // Değer Eksenleri
}
```

#### 2.4.1. Base Axis (Temel Eksen)
Sahnenin tekili ve hakimidir. `type` değerine göre farklı JSON kapasitelerine sahiptir.

**Geçerli Base Axis Tipleri:**
*   `time` (Zaman Serisi)
*   `category` (Kategorik)
*   `linear` (Lineer Sayısal)

---

**Tip 1: Zaman Ekseni (`time`)**
X ekseni zamandır (int timestamp).

```json
{
  "id": "axis_time",
  "axis": "x",
  "type": "time",
  "title": "Tarih",

  "isSorted": true,
  "isEquidistant": true,
  "gapPolicy": "skip",
  "timezone": "UTC",
  "timezoneDisplayMode": "source",
  
  "grid": {
    "visible": true,
    "color": "#E0E0E0",
    "style": "dashed",
    "width": 1.0
  }
}
```

*   **isSorted**: Verinin zaman damgasına (timestamp) göre sıralı gelip gelmediğini belirler (`true`/`false`).
*   **isEquidistant**: Veri noktaları arası mesafenin eşit kabul edilip edilmeyeceğini belirler (Hafta sonu boşlukları vb. durumlar için).
*   **gapPolicy**: Veri bulunmayan (null/missing) noktalarda çizimin nasıl davranacağı.
    *   `skip`: Eksik veriyi atlar, çizgi kopuk görünür.
    *   `connect`: Eksik noktalar arasında doğrusal birleşim yapar.
    *   `fill`: Eksik veriyi varsayılan veya hesaplanmış bir değerle doldurur.
*   **timezone**: Eksenin hesaplamalarda kullandığı ana zaman dilimi (Örn: `UTC`).
*   **timezoneDisplayMode**: Saat diliminin kullanıcıya nasıl gösterileceğidir.
    *   `utc`: Her zaman UTC olarak gösterir.
    *   `source`: Veri kaynağının/borsanın saat dilimini kullanır.
    *   `local`: Kullanıcının yerel saatini kullanır.

---

**Tip 2: Kategorik Eksen (`category`)**
X ekseni String etiketlerdir (Departmanlar, Ülkeler, İsimler vb.).

```json
{
  "id": "axis_dept",
  "axis": "x",
  "type": "category",
  "title": "Departmanlar",
  "visible": true,
  "gapRatio": 0.2,
  "groupGapRatio": 0.1
}
```

*   **gapRatio**: Kategorik elemanlar (barlar, sütunlar vb.) arasındaki boşluk oranı (0.0 - 1.0 arası).
*   **groupGapRatio**: Kategorik veri grupları arasındaki boşluk oranı (0.0 - 1.0 arası).

---

**Tip 3: Sayısal X Ekseni (`linear`)**
X ekseni sayıdır (Fizik deneyleri, Scatter Plot, Matematiksel fonksiyonlar).

```json
{
  "id": "axis_voltage",
  "axis": "x",
  "type": "linear",
  "title": "Gerilim (V)",
  "visible": true,
  "isSorted": true,
  "min": 0.0,
  "max": 100.0,
  "step": 10.0,
  "grid": {
    "visible": true,
    "color": "#CCCCCC",
    "style": "solid",
    "width": 1.0
  }
}
```

*   **isSorted**: Verinin X değerlerine göre sıralı olup olmadığı. Çizgi grafikleri için genelde `true`, Scatter Plot için `false` olabilir.
*   **min / max**: Eksenin başlangıç ve bitiş değerlerini sabitler. Belirtilmezse otomatik (auto-scale) hesaplanır.
*   **step**: Eksen üzerindeki kılavuz çizgilerinin (ticks) adım aralığıdır. `null` bırakılırsa sistem otomatik belirler.




#### 2.4.2. Value Axes (Değer Eksenleri)
Bir veya birden fazla olabilir. Her bir `valuesAxis` öğesi, `type` değerine göre farklı özellikler alır.

**Geçerli Value Axis Tipleri:**
*   `linear` (Lineer)
*   `log` (Logaritmik)
*   `percentage` (Yüzdesel)

**Tip 1: Lineer Ölçek (`linear`)**
```json
{
  "id": "axis_price",
  "axis": "y",
  "type": "linear",
  "title": "Fiyat (USDT)",
  "autoScale": true,
  "grid": { "visible": false, "color": "#E0E0E0", "style": "solid", "width": 1.0 }
}
```
*   **type**: Bu eksen tipi için sabit değer `linear`'dır.
*   **id**: Eksenin benzersiz kimliğidir.
*   **axis**: Eksenin yönünü belirtir. Değer ekseni için genellikle `y`'dir.
*   **title**: Eksen başlığıdır.
*   **autoScale**: Veriye göre otomatik ölçekleme yapılıp yapılmayacağını belirler (`true`/`false`).
*   **grid**: Izgara ayarlarıdır.

**Tip 2: Logaritmik Ölçek (`log`)**
```json
{
  "id": "axis_price",
  "axis": "y",
  "type": "log",
  "title": "Logaritmik Fiyat",
  "visible": true,
  "base": 10,
  "autoScale": true,
  "treatZeroAs": null,
  "format": {"type": "number", "precision": 2},
  "grid": { "visible": false }
}
```
*   **type**: Bu eksen tipi için sabit değer `log`'dur.
*   **base**: Logaritma tabanıdır (Örn: `10` veya `e` için 2.718).
*   **treatZeroAs**: Sıfır veya negatif değerlerin logaritmik hesaplamada nasıl ele alınacağı. `null` alabilir.
*   **format**: Sayı görüntüleme formatıdır (`type`, `precision`).

**Tip 3: Yüzdesel Ölçek (`percentage`)**
```json
{
  "id": "axis_price",
  "axis": "y",
  "type": "percentage",
  "title": "Oran",
  "visible": true,
  "min": 0.0,
  "max": 1.0,
  "format": {"type": "percent", "precision": 1},
  "grid": {"visible": true}
}
```
*   **type**: Bu eksen tipi için sabit değer `percentage`'dır.
*   **min**: Eksenin minimum sabit değeridir (Örn: `0.0`).
*   **max**: Eksenin maksimum sabit değeridir (Örn: `1.0`).
*   **format**: Yüzde görüntüleme formatıdır.

---

## 3. CHART (GRAFİK) YAPISI

`charts` dizisi içindeki her bir eleman tekil bir grafik objesidir.

### 3.1. GRAFİK İSKELETİ

```json
{
  "meta": { },
  "legend": { },
  "inputs": [ ],
  "fields": [ ],
  "plots": [ ],
  "data": [ ],
  "guides": [ ],
  "notations": [ ]
}
```

*   **meta**: Grafik meta verisi.
*   **legend**: Lejant ayarları.
*   **inputs**: Kullanıcı parametreleri.
*   **fields**: Veri sütun tanımları.
*   **plots**: Çizim katmanları.
*   **data**: Ham veri matrisi.
*   **guides**: Sabit referans (input) çizgileri.
*   **notations**: Sinyal ve işaretleyiciler.

### 3.2. GRAFİK METADATA (`meta`)

```json
"meta": {
  "id": "ohlc_001",
  "name": "Open-High-Low-Close",
  "shortName": "OHLC",
  "description": "Financial price chart",
  "type": "finance",
  "subType": "trading",
  "category": "indicator",
  "subCategory": "oscillator",
  "allowedCoordinateSystems": [ "cartesian", "categorical" ],
  "requiresOrderedData": true,
  "placement": "separate",
  "provider": "system",
  "visibility": "public",
  "author": "anonymous",
  "version": "1.0.0",
  "createdAt": 1676985600000,
  "updatedAt": 1676998700000
}
```

*   **id**: Grafiğin benzersiz kimliğidir (String).
*   **name**: Grafiğin tam adı (String).
*   **shortName**: Grafiğin kısa adı veya kısaltması (String).
*   **description**: Grafiğin ne işe yaradığını anlatan açıklama metni (String).
*   **type**: Grafiğin ait olduğu/çalıştığı **Varsayılan ChartSet (Grafik Seti) Tipi**. Bu grafik bir ChartSet'e (Grafik Seti) eklendiğinde uyumluluk kontrolü bu alan üzerindeki ChartSet tipiyle yapılır. (Örn: `finance`, `scientific`)
*   **subType**: Grafiğin ait olduğu/çalıştığı **Varsayılan ChartSet (Grafik Seti) Alt Tipi**. Bu grafik için ChartSet düzeyindeki varsayılan alt çalışma ortamını belirtir. (Örn: `trading`, `reporting`)
*   **category**: Grafiğin ana kategorisidir.
    *   `primary`: Ana fiyat grafiği.
    *   `indicator`: Teknik gösterge.
    *   `drawing`: Çizim aracı.
    *   `overlay`: Üst katman.
*   **subCategory**: Grafiğin alt kategorisidir.
    *   `trend`: Trend takipçisi.
    *   `oscillator`: Osilatör.
    *   `volatility`: Volatilite.
    *   `volume`: Hacim.
    *   `priceAction`: Fiyat hareketi.
    *   `statistical`: İstatistiksel.
    *   `signals`: Sinyaller.
*   **placement**: Grafiğin nereye yerleşeceğini belirtir.
    *   `separate`: Kendi panelinde ayrı olarak açılır.
    *   `overlay`: Mevcut bir panelin (genellikle ana fiyat) üzerine biner.
*   **provider**: Grafiğin sağlayıcısıdır.
    *   `system`: Yerleşik sistem aracı.
    *   `user`: Kullanıcı tanımlı araç.
*   **visibility**: Grafiğin görünürlük/paylaşım durumudur.
    *   `public`: Herkese açık.
    *   `private`: Özel.
*   **allowedCoordinateSystems**: Bu grafiğin desteklediği koordinat sistemleri listesidir (Örn: `["cartesian"]`).
*   **requiresOrderedData**: Verinin sıralı olmasının zorunlu olup olmadığı (`true`/`false`).
*   **version**: Versiyon numarası.
*   **createdAt**: Versiyon oluşturulma tarihi.
*   **updatedAt**: Versiyon güncellenme tarihi.

### 3.3. LEJANT (`legend`)

**Geçerli Lejant Eleman Tipleri:**
*   `input`
*   `plot`
*   `notation`

```json
"legend": {
  "visible": true,
  "items": [
    { "id": "item_1", "type": "input", "refId": "symbol", "keys": ["value"], "template": "{value}" },
    { "id": "item_3", "type": "plot", "refId": "plot_id0" },
    { "id": "item_4", "type": "notation", "refId": "notation_id0" }
  ]
}
```

*   **visible**: Lejantın görünür olup olmadığını belirler (`true`/`false`).
*   **items**: Lejant elemanları listesidir.
    *   **id**: Eleman kimliği.
    *   **type**: Eleman tipi.
    *   **refId**: Referans verilen objenin ID'sidir.
        *   Eğer `type` **input** ise: `inputs` dizisindeki bir objenin `id`'sine referans verir.
        *   Eğer `type` **plot** ise: `plots` dizisindeki bir objenin `id`'sine referans verir.
        *   Eğer `type` **notation** ise: `notations` dizisindeki bir objenin `id`'sine referans verir.
    *   **template**: Görüntüleme şablonudur. `{value}` gibi yer tutucular kullanılır.
    *   **keys**: Referans verilen objenin (`refId`) içindeki alanların anahtarlarına karşılık gelir.

### 3.4. GİRDİLER (`inputs`)

Kullanıcının değiştirebileceği parametreler listesidir.

**Geçerli Input Tipleri:**
*   `string` (Metin)
*   `symbol` (Finansal Sembol)
*   `interval` (Zaman Aralığı)
*   `integer` (Tam Sayı)
*   `double` (Ondalıklı Sayı)
*   `boolean` (Mantıksal/Checkbox)
*   `dateTime` (Tarih/Zaman Damgası)

**Toplu Görünüm (Örnek):**
```json
"inputs": [
  { "id": "textExample", "name": "Text Example", "type": "string", "value": "Sample Text" },
  { "id": "symbol", "name": "Symbol", "type": "symbol", "value": "BTC/USDT", "base": "BTC", "quote": "USDT" },
  { "id": "interval", "name": "Interval", "type": "interval", "value": "4h" },
  { "id": "period", "name": "Period", "type": "integer", "value": 14, "min": null, "max": null },
  { "id": "smoothing", "name": "Smoothing", "type": "double", "value": 0.5, "min": 0.0, "max": 1.0 },
  { "id": "showLine", "name": "Show Line", "type": "boolean", "value": true },
  { "id": "time", "name": "Start time", "type": "dateTime", "value": 1676985600000 }
]
```

**Tip Detayları:**

**1. Serbest Metin (`string`)**
```json
{ "id": "textExample", "name": "Text Example", "type": "string", "value": "Sample Text" }
```
*   **type**: `string` olarak ayarlayın.
*   **value**: Varsayılan metin değeridir (String).

**2. Sembol (`symbol`)**
```json
{ "id": "symbol", "name": "Symbol", "type": "symbol", "value": "BTC/USDT", "base": "BTC", "quote": "USDT" }
```
*   **type**: `symbol` olarak ayarlayın.
*   **value**: Sembol çiftinin tam adıdır (String).
*   **base**: Baz döviz (String, Örn: BTC).
*   **quote**: Karşıt döviz (String, Örn: USDT).

**3. Zaman Aralığı (`interval`)**
```json
{ "id": "interval", "name": "Interval", "type": "interval", "value": "4h" }
```
*   **type**: `interval` olarak ayarlayın.
*   **value**: Varsayılan zaman aralığı (String). Şu değerlerden birini almalıdır:
    *   `1s`, `1m`, `3m`, `5m`, `15m`, `30m`, `45m`
    *   `1h`, `2h`, `3h`, `4h`
    *   `1d`, `1w`, `1M`

**4. Tam Sayı (`integer`)**
```json
{ "id": "period", "name": "Period", "type": "integer", "value": 14, "min": null, "max": null }
```
*   **type**: `integer` olarak ayarlayın.
*   **value**: Varsayılan tamsayı değeri (Integer).
*   **min**: Alabileceği minimum değer. `null` ise sınır yoktur.
*   **max**: Alabileceği maksimum değer. `null` ise sınır yoktur.

**5. Ondalıklı Sayı (`double`)**
```json
{ "id": "smoothing", "name": "Smoothing", "type": "double", "value": 0.5, "min": 0.0, "max": 1.0 }
```
*   **type**: `double` olarak ayarlayın.
*   **value**: Varsayılan ondalıklı değer (Double).
*   **min**: Alabileceği minimum değer. `null` ise sınır yoktur.
*   **max**: Alabileceği maksimum değer. `null` ise sınır yoktur.

**6. Mantıksal (`boolean`)**
```json
{ "id": "showLine", "name": "Show Line", "type": "boolean", "value": true }
```
*   **type**: `boolean` olarak ayarlayın.
*   **value**: `true` veya `false` değeri.

**7. Tarih/Zaman (`dateTime`)**
```json
{ "id": "time", "name": "Start time", "type": "dateTime", "value": 1676985600000 }
```
*   **type**: `dateTime` olarak ayarlayın.
*   **value**: Unix Timestamp milisaniye cinsinden zaman damgası (Long).

### 3.5. VERİ ALANLARI (`fields`)

Gelen `data` matrisinin sütun haritasıdır.

**Geçerli Field Tipleri:**
*   `string`
*   `integer`
*   `double`
*   `boolean`
*   `dateTime`

**Toplu Görünüm:**
```json
"fields": [ 
  { "id": "close", "name": "Close", "type": "integer" },
  { "id": "signal", "name": "Signal", "type": "string" },
  { "id": "istrend", "name": "IsTrend", "type": "boolean" },
  { "id": "price", "name": "Price", "type": "double" },
  { "id": "date", "name": "Date", "type": "dateTime" }
]
```

**Tip Detayları:**

**1. Metin Alanı (`string`)**
*   **type**: `string`
*   **id**: Alanın benzersiz kimliği.
*   **name**: Kullanıcıya görünen adı.

**2. Tam Sayı Alanı (`integer`)**
*   **type**: `integer`
*   **id**: Alanın benzersiz kimliği.
*   **name**: Kullanıcıya görünen adı.

**3. Ondalıklı Sayı Alanı (`double`)**
*   **type**: `double`
*   **id**: Alanın benzersiz kimliği.
*   **name**: Kullanıcıya görünen adı.

**4. Mantıksal Alan (`boolean`)**
*   **type**: `boolean`
*   **id**: Alanın benzersiz kimliği.
*   **name**: Kullanıcıya görünen adı.

**5. Tarih/Zaman Alanı (`dateTime`)**
*   **type**: `dateTime`
*   **id**: Alanın benzersiz kimliği.
*   **name**: Kullanıcıya görünen adı.

### 3.6. ÇİZİMLER (`plots`)

Verinin görselleştirildiği katmanlardır.

**Ortak Parametreler:**
*   **id**: Çizim katmanının benzersiz kimliğidir.
*   **type**: Çizim tipi (`line`, `area`, `candlestick`, `band`, `bar`).
*   **dataForm**: Veri formu (`scalar`, `ohlc`, `band`).
*   **axis**: Çizimin bağlanacağı değer ekseninin (`valuesAxis`) kimliğidir.
*   **visible**: Görünürlük durumu (`true`/`false`).
*   **affectsScale**: Bu katmanın Y ekseninin otomatik ölçeklendirme hesabını etkileyip etkilemeyeceği (`true`/`false`).
*   **showLastValue**: Son değeri temsil eden yatay çizginin gösterilip gösterilmeyeceği (`true`/`false`).

**Geçerli Plot Tipleri:**
*   `line` (Çizgi)
*   `area` (Alan)
*   `candlestick` (Mum)
*   `band` (Bant)
*   `bar` (Çubuk)

**Toplu Görünüm:**
```json
"plots": [
  { "id": "plot_line", "type": "line", "axis": "y", "visible": false, "affectsScale": true, "showLastValue": true, "dataForm": "scalar", "value": "f_ma", "color": "#1890FF", "style": "dashed" },
  { "id": "plot_area", "type": "area", "axis": "y", "visible": false, "affectsScale": true, "showLastValue": false, "dataForm": "scalar", "value": "f_ma", "color": "#1890FF", "style": "solid" },
  { "id": "plot_candle", "type": "candlestick", "axis": "y", "visible": true, "affectsScale": true, "showLastValue": true, "dataForm": "ohlc", "open": "f_open", "high": "f_high", "low": "f_low", "close": "f_close", "upColor": "#089981", "downColor": "#F23645" },
  { "id": "plot_bar", "type": "bar", "axis": "y", "visible": true, "affectsScale": true, "showLastValue": false, "dataForm": "scalar", "value": "f_vol", "color": "#1890FF" },
  { "id": "plot_band", "type": "band", "axis": "y", "visible": true, "affectsScale": true, "showLastValue": false, "dataForm": "band", "upper": "f_bb_upper", "lower": "f_bb_lower", "upperColor": "#2962FF", "lowerColor": "#2962FF", "fillColor": "#2962FF1A", "style": "solid" }
]
```

**Tip Detayları:**

**1. Çizgi Grafik (`line`)**
```json
{ "id": "plot_line", "type": "line", "dataForm": "scalar", "axis": "y", "visible": false, "affectsScale": true, "value": "f_ma", "color": "#1890FF", "style": "dashed" }
```
*   **type**: `line` olarak ayarlayın.
*   **dataForm**: `scalar`.
*   **value**: `fields` dizisindeki ilgili veri alanının `id`sine karşılık gelir.
*   **color**: Çizgi rengi.
*   **style**: Çizgi stili (`solid`, `dashed`, `dotted`).

**2. Alan Grafiği (`area`)**
```json
{ "id": "plot_area", "type": "area", "dataForm": "scalar", "axis": "y", "visible": false, "affectsScale": true, "value": "f_ma", "color": "#1890FF", "style": "solid" }
```
*   **type**: `area` olarak ayarlayın.
*   **dataForm**: `scalar`.
*   **value**: `fields` dizisindeki ilgili veri alanının `id`sine karşılık gelir.
*   **color**: Dolgu rengi.

**3. Mum Grafik (`candlestick`)**
```json
{ "id": "plot_candle", "type": "candlestick", "dataForm": "ohlc", "axis": "y", "visible": true, "affectsScale": true, "open": "f_open", "high": "f_high", "low": "f_low", "close": "f_close", "upColor": "#089981", "downColor": "#F23645" }
```
*   **type**: `candlestick` olarak ayarlayın.
*   **dataForm**: `ohlc`.
*   **open**: `fields` dizisindeki açılış fiyatını temsil eden alanın `id`sine karşılık gelir.
*   **high**: `fields` dizisindeki en yüksek fiyatı temsil eden alanın `id`sine karşılık gelir.
*   **low**: `fields` dizisindeki en düşük fiyatı temsil eden alanın `id`sine karşılık gelir.
*   **close**: `fields` dizisindeki kapanış fiyatını temsil eden alanın `id`sine karşılık gelir.
*   **upColor**: Yükselen mum gövde rengi.
*   **downColor**: Düşen mum gövde rengi.

**4. Bant Grafiği (`band`)**
```json
{ "id": "plot_band", "type": "band", "dataForm": "band", "axis": "y", "visible": true, "affectsScale": true, "upper": "f_bb_upper", "lower": "f_bb_lower", "upperColor": "#2962FF", "lowerColor": "#2962FF", "fillColor": "#2962FF1A", "style": "solid" }
```
*   **type**: `band` olarak ayarlayın.
*   **dataForm**: `band`.
*   **upper**: `fields` dizisindeki üst sınır değerini temsil eden alanın `id`sine karşılık gelir.
*   **lower**: `fields` dizisindeki alt sınır değerini temsil eden alanın `id`sine karşılık gelir.
*   **upperColor**: Üst çizgi rengi.
*   **lowerColor**: Alt çizgi rengi.
*   **fillColor**: Aradaki dolgu rengi.
*   **style**: Çizgi stili (`solid`, `dashed`, `dotted`).

**5. Çubuk Grafik (`bar`)**
```json
{ "id": "plot_bar", "type": "bar", "dataForm": "scalar", "axis": "y", "visible": true, "affectsScale": true, "value": "f_vol", "color": "#1890FF" }
```
*   **type**: `bar` olarak ayarlayın.
*   **dataForm**: `scalar`.
*   **value**: `fields` dizisindeki çubuk yüksekliğini temsil eden alanın `id`sine karşılık gelir.

### 3.7. REHBERLER (`guides`)

Veriden bağımsız, sabit referans çizgileridir.

**Geçerli Guide Tipleri:**
*   `line`
*   `band`

**Toplu Görünüm:**
```json
"guides": [
  { "id": "guide_line", "type": "line", "axis": "y", "visible": true, "affectsScale": true, "value": "in_limit_val", "color": "#F23645", "style": "solid" },
  { "id": "guide_zone", "type": "band", "axis": "y", "visible": true, "affectsScale": true, "upper": "in_upper_limit", "lower": "in_lower_limit", "upperColor": "#2962FF1A", "lowerColor": "#2962FF1A", "fillColor": "#2962FF1A" }
]
```

**Tip Detayları:**

**1. Sabit Çizgi (`line`)**
```json
{ "id": "guide_line", "type": "line", "axis": "y", "visible": true, "affectsScale": true, "value": "in_limit_val", "color": "#F23645", "style": "solid" }
```
*   **type**: `line` olarak ayarlayın.
*   **affectsScale**: Bu rehberin Y ekseni ölçekleme hesabına katılıp katılmayacağı (`true`/`false`).
*   **value**: `inputs` dizisindeki ilgili girdinin `id`sine karşılık gelir.
*   **color**: Renk.
*   **style**: Çizgi stili.

**2. Sabit Bölge (`band`)**
```json
{ "id": "guide_zone", "type": "band", "axis": "y", "visible": true, "affectsScale": true, "upper": "in_upper_limit", "lower": "in_lower_limit", "upperColor": "#2962FF1A", "lowerColor": "#2962FF1A", "fillColor": "#2962FF1A" }
```
*   **type**: `band` olarak ayarlayın.
*   **affectsScale**: Bu rehberin Y ekseni ölçekleme hesabına katılıp katılmayacağı (`true`/`false`).
*   **upper**: `inputs` dizisindeki üst sınır değerini tutan girdinin `id`sine karşılık gelir.
*   **lower**: `inputs` dizisindeki alt sınır değerini tutan girdinin `id`sine karşılık gelir.
*   **upperColor**: Üst çizgi rengi.
*   **lowerColor**: Alt çizgi rengi.
*   **fillColor**: Bölge dolgu rengi.

### 3.8. İŞARETÇİLER (`notations`)

Belirli koşullara göre veri üzerinde beliren ikonlar veya metinlerdir.

**Geçerli Notation Tipleri:**
*   `marker`
*   `label`

**Toplu Görünüm:**
```json
"notations": [
  {
    "id": "not_signals_001",
    "type": "marker",
    "axis": "y",
    "value": "f_signal_logic",
    "anchor": "f_high",
    "visible": true,
    "affectsScale": false,
    "rules": {
      "1": { "text": "BUY", "icon": "arrow_up", "color": "#089981", "position": "above", "offset": 10.0 },
      "-1": { "text": "SELL", "icon": "arrow_down", "color": "#F23645", "position": "below", "offset": 10.0 }
    }
  }
]
```

**Tip Detayları:**

**1. İşaretçi (`marker`) / Etiket (`label`)**
*   **type**: İşaretçi tipidir (`marker` veya `label`).
*   **value**: `fields` dizisindeki kontrol edilecek veri alanının `id`sine karşılık gelir.
*   **anchor**: `fields` dizisindeki hizalama yapılacak veri alanının `id`sine karşılık gelir.
*   **affectsScale**: Bu işaretçinin Y ekseni ölçekleme hesabına katılıp katılmayacağı (`true`/`false`).
*   **rules**: Değer eşleşme kuralları objesidir. **Anahtar (Key)**, `value` ile belirtilen veri alanındaki değerin **string** karşılığıdır (Örn: Veri tam sayı `5` ise, anahtar `"5"` dize formatında olmalıdır).
    *   **text**: Gösterilecek metin.
    *   **icon**: Gösterilecek ikon adı.
    *   **color**: İkon veya metin rengi.
    *   **position**: Konum (`above`, `below`, `inside`).
    *   **offset**: Veri noktasından uzaklık mesafesi (px).

---

## 4. DATA PAKETİ (`data`)

Canlı veri akışında ve tarihsel veri güncellemelerinde kullanılır. `packetType: "data"` zorunludur.

Tüm veri paketleri **Columnar (Sütun Bazlı)** yapıyı kullanır. Yani veriler, her bir "Field ID" için bir liste `[]` içinde gönderilir.

### 4.1. UPDATE (Canlı Güncelleme)
Mevcut son zaman dilimindeki veriyi günceller (Tick Data).

```json
{
  "packet": { "packetType": "data", "docId": "doc_id", "revision": 100 },
  "payload": {
    "action": "update", // ENUM: DataAction.update
    "baseAxisData": [1707845060000], // İlgili zaman damgası
    "charts": {
      "ohlc_01": { // Chart ID
        "close": [42125.5], // Field ID -> Değer Listesi
        "vol": [1500]
      }
    }
  }
}
```
*   **action**: `update` (Güncelleme).
*   **baseAxisData**: Güncellenecek zaman diliminin değeri (örneğin timestamp).

### 4.2. APPEND (Veri Ekleme)
Zaman ekseninin sonuna yeni bir veri noktası (örneğin yeni mum) ekler.

```json
{
  "packet": { "packetType": "data", "docId": "doc_id", "revision": 100 },
  "payload": {
    "action": "append", // ENUM: DataAction.append
    "baseAxisData": [1707845120000], // Yeni zaman damgası
    "charts": {
      "ohlc_01": { [42100.5, 42150.0, 42300.2, 42200.0] }
    }
  }
}
```
*   **action**: `append` (Ekleme).
*   **baseAxisData**: Eklenecek yeni zaman damgası.

### 4.3. OVERWRITE (Üzerine Yazma / Repaint)
Geçmişe dönük belirli bir aralıktaki verileri değiştirir. İndikatörlerin geçmiş veriyi yeniden hesapladığı durumlarda kullanılır.

```json
{
  "packet": { "packetType": "data", "docId": "doc_id", "revision": 100 },
  "payload": {
    "action": "overwrite", // ENUM: DataAction.overwrite
    "startIndex": -5,      // Sondan 5. veriden başla
    "charts": {
      "zigzag_01": {
        "val": [10.5, 11.2, 10.8, 12.0, 11.5] // 5 elemanlı yeni değer listesi
      }
    }
  }
}
```
*   **action**: `overwrite` (Üzerine Yazma).
*   **startIndex**: Yazmaya başlanacak indeks (Negatif değerler sondan geriye sayar).

### 4.4. CLEAR (Temizleme)
Tüm veriyi temizler.

```json
{
  "packet": { "packetType": "data", "docId": "doc_id", "revision": 100 },
  "payload": {
    "action": "clear" // ENUM: DataAction.clear
  }
}
```

## 5. PATCH PAKETİ (`patch`)

Dökümanın yapısını (Ayar, Renk, Görünüm) değiştirmek için kullanılır. Veri içermez. `packetType: "patch"` zorunludur.

Operasyonlar `operations` dizisi içinde sırayla işlenir.

### 5.1. REPLACE (Değer Değiştirme)
Mevcut bir objenin özelliklerini değiştirir.

```json
{
  "packet": { "packetType": "patch", "docId": "doc_id", "revision": 105 },
  "payload": {
    "operations": [
      {
        "op": "replace",
        "scope": "root",
        "path": "visualSettings.crosshair", 
        "value": { "color": "#FF0000", "style": "dashed" } // Yeni değerler (Merge edilir)
      }
    ]
  }
}
```
*   **op**: `replace`.
*   **scope**: Etki alanı (`root`, `chart`, `plot`, `input` vb.).
*   **path**: Alt özellik yolu.
*   **value**: Yeni değer.

### 5.2. ADD (Ekleme)
Yeni bir obje (Grafik, İndikatör vb.) ekler.

```json
{
  "packet": { "packetType": "patch", "docId": "doc_id", "revision": 106 },
  "payload": {
    "operations": [
      {
        "op": "add",
        "scope": "charts",
        "targetSlot": 1, 
        "value": { "meta": { "id": "macd_01" }, "plots": [...] } // Eklenecek obje
      }
    ]
  }
}
```
*   **op**: `add`.
*   **value**: Eklenecek objenin tam tanımı.

### 5.3. REMOVE (Silme)
Mevcut bir objeyi siler.

```json
{
  "packet": { "packetType": "patch", "docId": "doc_id", "revision": 107 },
  "payload": {
    "operations": [
      {
        "op": "remove",
        "scope": "chart",
        "targetId": "macd_01" // Silinecek ID
      }
    ]
  }
}
```
*   **op**: `remove`.
*   **targetId**: Silinecek objenin ID'si.

### 5.4. MOVE (Taşıma)
Bir objenin sırasını veya yerini değiştirir.

```json
{
  "packet": { "packetType": "patch", "docId": "doc_id", "revision": 108 },
  "payload": {
    "operations": [
      {
        "op": "move",
        "scope": "charts",
        "targetId": "ohlc_01",
        "toIndex": 1 
      }
    ]
  }
}
```
*   **op**: `move`.
*   **toIndex**: Taşınacak yeni indeks.

---

## 6. DİĞER PAKETLER

### 6.1. BUSY (Meşguliyet)
İşlem yapıldığını bildirir.

```json
{
  "packet": { "packetType": "busy", "docId": "doc_id" },
  "payload": {
    "message": "İndikatör hesaplanıyor...",
    "progress": 0.45
  }
}
```

### 6.2. ERROR (Hata)
Hata durumlarını bildirir.

```json
{
  "packet": { "packetType": "error", "docId": "doc_id" },
  "payload": {
    "severity": "critical", // critical: Sayfayı yenile, warning: Uyarı göster
    "code": 500,
    "message": "Veri tutarsızlığı tespit edildi."
  }
}
```
