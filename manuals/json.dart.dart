// 1. SNAPSHOT PAKETİ (FULL SURUM) ---------------------------------------------------

var snapshotPacket = {
  "meta": {
    "id": "doc_unique_999", // Benzersiz kimlik (ID)
    "packetType":
        "snapshot", // ful json formatı bu dokumanı temsil eder değişmez
    "type": "financial", // Üst Tip
    "subType": "trading", // Alt Tip
    "coordinateSystem": "cartesian", // Eksen Sistemi
    "schemaVersion": "1.0.0",
    "revision": 1,
    "updatedAt": 1707829200000, // Son Güncelleme Zamanı
    // Doğrulama ve Senkronizasyon Katmanı
  },
  "layout": {
    "type": "vertical",
    "resizable": true, // Kullanıcı slot boyutlarıyla oynayabilir mi?
    "separatorSize": 4, // Aradaki çizgi kalınlığı (px)
    "slots": [
      {
        "index": 0, // charts[0] listesini render eder
        "weight": 3.0, // Yükseklik ağırlığı (Flex)
        "minSize": 200, // Minimum yükseklik (px)
      },
      {
        "index": 1, // charts[1] listesini render eder
        "weight": 1.0,
        "minSize": 80,
      },
    ],
  },
  "visualSettings": {
    "crosshair": {
      "mode": "visible",
      "style": "dashed", // LineStyle enum'ını burada kullanabilirsin
      "color": "#888888",
      "showLabels": true,
    },
    "legend": {"position": "topLeft", "orientation": "horizontal"},
    "tooltip": {"position": "topLeft", "orientation": "horizontal"},
  },
  "dimensions": {
    // -----------------------------------------------------------
    // 1. BASE AXIS (TEMEL EKSEN)
    // Tek bir tane olur. Sahnenin hakimidir.
    // -----------------------------------------------------------
    "baseAxis": {
      "id": "axis_price",
      "axis": "x",
      "type": "time", // "time", "category", "linear"
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
        "width": 1.0,
      },
    },
    /* TIME EKSEN ÖRNEĞİ:
    "baseAxis":{
      "id": "axis_price",
      "axis": "x",
      "type": "time", // "time", "category", "linear"
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
        "width": 1.0,
      },
    }

    KATEGORİK EKSEN ÖRNEĞİ:
    "baseAxis": {
      "id": "axis_dept",
      "axis": "x",
      "type": "category",
      "title": "Departmanlar",
      "gapRatio": 0.2,
      "groupGapRatio": 0.1
    },

    SAYISAL (LINEAR) X EKSENİ ÖRNEĞİ:
    "baseAxis": {
      "id": "axis_voltage",
      "axis": "x",
      "type": "linear",
      "title": "Gerilim (V)",
      "isSorted": true,
      "min": 0.0, "max": 100.0, "step": 10.0
    }
    */

    // -----------------------------------------------------------
    // 2. VALUE AXES (DEĞER EKSENLERİ)
    // Birden fazla olabilir (Sol Y, Sağ Y, Üst X vb.)
    // -----------------------------------------------------------
    "valuesAxis": [
      {
        "id": "axis_price",
        "axis": "y",
        "type": "linear", // "linear", "log", "percentage"
        "title": "Fiyat (USDT)",
        "autoScale": true,
        "grid": {
          "visible": false,
          "color": "#E0E0E0",
          "style": "solid",
          "width": 1.0,
        },
      },
      /*
         LINER ÖLÇEK ÖRNEĞİ:
     "valuesAxis":{
        "id": "axis_price",
        "axis": "y",
        "type": "linear", // "linear", "log", "percentage"
        "title": "Fiyat (USDT)",
        "autoScale": true,
        "grid": {
          "visible": false,
          "color": "#E0E0E0",
          "style": "solid",
          "width": 1.0,
        },
      },

      LOGARİTMİK ÖLÇEK ÖRNEĞİ:
      "valuesAxis":{
        "id": "axis_log",
        "axis": "y",
        "type": "log",
        "title": "Logaritmik Ölçek",
        "base": 10,
        "autoScale": true
      },

      YÜZDESEL ÖLÇEK ÖRNEĞİ:
      "valuesAxis":{
        "id": "axis_percent",
        "axis": "y",
        "type": "percentage",
        "title": "Yüzdesel Değişim",
        "min": 0.0, "max": 1.0, "format": {"type": "percent", "precision": 1}
      }
      */
    ],
  },
  "baseAxisData": [],
  "charts": [
    [
      {
        // CHART METADATA (Eski sistemden gelen sağlam yapı)
        "meta": {
          "id": "ohlc_001",
          "name": "Open-High-Low-Close",
          "shortName": "OHLC",
          "description": "Financial price chart",
          "type": "financial",
          "subType": "trading",
          "category": "indicator",
          "subCategory": "oscillator",
          "allowedCoordinateSystems": ["cartesian"],
          "requiresOrderedData": true,
          "placement": "separate",
          "provider": "system",
          "visibility": "public",
          "author": "anonymous",
          "version": "1.0.0",
          "createdAt": 1676985600000,
          "updatedAt": 1676998700000,
        },
        "legend": {
          "visible": true,
          "items": [
            {
              "id": "item_1",
              "type": "input",
              "refId": "symbol",
              "keys": ["value"],
              "template": "{value}",
            },
            {
              "id": "item_2",
              "type": "input",
              "refId": "interval",
              "keys": ["value"],
              "template": "{value}",
            },
            {"id": "item_3", "type": "plot", "refId": "plot_id0"},
            {"id": "item_4", "type": "notation", "refId": "notation_id0"},
          ],
        },
        "inputs": [
          // {
          //   "id": "src",
          //   "name": "Source",
          //   "type": "data_stream",
          //   "dataType": "scalar",
          //  "value": {"sourceRef": "main_price", "fieldRef": "close"},
          // },
          {
            "id": "textExample",
            "name": "Text Example",
            "type": "string",
            "value": "Sample Text",
          },
          {
            "id": "symbol",
            "name": "Symbol",
            "type": "symbol",
            "value": "BTC/USDT",
            "base": "BTC",
            "quote": "USDT",
          },
          {
            "id": "interval",
            "name": "Interval",
            "type": "interval",
            "value": "4h",
          },
          {
            "id": "period",
            "name": "Period",
            "type": "integer",
            "value": 14,
            "min": null,
            "max": null,
          },
          {
            "id": "smoothing",
            "name": "Smoothing",
            "type": "double",
            "value": 0.5,
            "min": 0.0,
            "max": 1.0,
          },
          {
            "id": "showLine",
            "name": "Show Line",
            "type": "boolean",
            "value": true,
          },
          {
            "id": "time",
            "name": "Start time",
            "type": "dateTime",
            "value": 1676985600000,
          },
        ],
        "fields": [
          {"id": "dateTime", "name": "Close Time", "type": "dateTime"},
          {"id": "close", "name": "Close", "type": "integer"},
          {"id": "close", "name": "Close", "type": "double"},
          {"id": "signal", "name": "Signal", "type": "string"},
          {"id": "istrend", "name": "IsTrend", "type": "boolean"},
          {"id": "close", "name": "Close", "type": "double"},
        ],

        "plots": [
          {
            "id": "plot_id0",
            "type": "line",
            "dataForm": "scalar",
            "axis": "y",
            "visible": false,
            "affectsScale": true,
            "showLastValue": true,
            "value": "f_ma",
            "color": "#1890FF",
            "style": "dashed",
          },
          {
            "id": "plot_id1",
            "type": "area",
            "dataForm": "scalar",
            "axis": "y",
            "visible": false,
            "affectsScale": true,
            "showLastValue": false,
            "value": "f_ma",
            "color": "#1890FF",
            "style": "solid",
          },
          {
            "id": "plot_id2",
            "type": "candlestick",
            "dataForm": "ohlc",
            "axis": "y",
            "visible": false,
            "affectsScale": true,
            "showLastValue": true,
            "open": "f_open",
            "high": "f_high",
            "low": "f_low",
            "close": "f_close",
            "upColor": "#089981",
            "downColor": "#F23645",
          },
          {
            "id": "plot_id3",
            "type": "bar",
            "dataForm": "scalar",
            "axis": "y",
            "visible": false,
            "affectsScale": true,
            "showLastValue": false,
            "value": "f_month",
            "color": "#1890FF",
          },
          {
            "id": "plot_id_band",
            "type": "band",
            "dataForm": "band",
            "axis": "y",
            "visible": false,
            "affectsScale": true,
            "showLastValue": false,
            "upper": "f_bb_upper",
            "lower": "f_bb_lower",
            "upperColor": "#2962FF1A",
            "lowerColor": "#2962FF1A",
            "fillColor": "#2962FF1A",
            "style": "solid",
          },
        ],
        "data": [
          [42100.5, 42150.0, 42300.2, 42200.0],
          [42500.0, 42600.5, 42800.0, 42400.0],
          [42000.0, 42100.0, 42200.0, 41900.0],
          [42150.0, 42300.2, 42200.0, 42100.5],
        ],

        "guides": [
          {
            "id": "guide_line_upper",
            "type": "line",
            "axis": "y",
            "visible": false,
            "affectsScale": true,
            "value": "in_upper_val",
            "color": "#F23645",
            "style": "solid",
          },

          {
            "id": "guide_band_zone",
            "type": "band",
            "axis": "y",
            "visible": false,
            "affectsScale": true,
            "upper": "in_upper_val",
            "lower": "in_lower_val",
            "upperColor": "#2962FF1A",
            "lowerColor": "#2962FF1A",
            "fillColor": "#2962FF1A",
            "style": "solid",
          },
        ],
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
              "1": {
                "text": "BUY",
                "icon": "arrow_up",
                "color": "#089981",
                "position": "above",
                "offset": 10.0,
              },
              "-1": {
                "text": "SELL",
                "icon": "arrow_down",
                "color": "#F23645",
                "position": "below",
                "offset": 10.0,
              },
            },
          },
        ],
      },
    ],
  ],
};

// 2. DATA PAKETİ (VERİ PAKETİ) ---------------------------------------------------
// MANTIK: "Columnar" yapı. Veriler her zaman "Field ID" anahtarı altında bir LİSTE olarak gelir.

// A. UPDATE (Canlı Tick) - Sadece son anı günceller
// ignore: non_constant_identifier_names
var dataPacket_update = {
  "packet": {"packetType": "data", "docId": "doc_unique_999", "revision": 100},
  "payload": {
    "action": "update", // ENUM: DataAction.update
    "baseAxisData": [1707845060000],
    "charts": {
      "ohlc_01": {
        "values": [42100.0, 42150.0, 42090.0, 42125.5],
      },
    },
  },
};

// B. APPEND (Yeni Mum/Veri Ekleme)
// ignore: non_constant_identifier_names
var dataPacket_append = {
  "packet": {"packetType": "data", "docId": "doc_unique_999", "revision": 100},
  "payload": {
    "action": "append", // ENUM: DataAction.append
    "baseAxisData": [1707845120000],
    "charts": {
      "ohlc_01": {
        "values": [42125.5, 42125.5, 42125.5, 42125.5],
      },
    },
  },
};

// C. OVERWRITE (Geçmiş Düzeltme / Repaint)
// ignore: non_constant_identifier_names
var dataPacket_overwrite = {
  "packet": {"packetType": "data", "docId": "doc_unique_999", "revision": 100},
  "payload": {
    "action": "overwrite", // ENUM: DataAction.overwrite
    "startIndex":
        -5, // "Sondan 5. veriden başla ve sonrasını bu verilerle değiştir"
    // baseAxisData opsiyoneldir. Eksikse mevcut zamanlar korunur, sadece Y değerleri değişir.
    "charts": {
      "zigzag_01": {
        // 5 adet değer içeren liste
        "val": [10.5, 11.2, 10.8, 12.0, 11.5],
      },
    },
  },
};

// D. CLEAR (Temizle)
// ignore: non_constant_identifier_names
var dataPacket_clear = {
  "packet": {"packetType": "data", "docId": "doc_unique_999", "revision": 100},
  "payload": {
    "action": "clear", // ENUM: DataAction.clear
  },
};

// 3. PATCH PAKETİ (YAMA PAKETİ) ---------------------------------------------------
// MANTIK: "Structure" değişimi. Veri içermez.

// A. REPLACE (Ayar Değiştirme)
// ignore: non_constant_identifier_names
var patchPacket_replace = {
  "packet": {"packetType": "patch", "docId": "doc_unique_999", "revision": 105},
  "payload": {
    "operations": [
      // KÖK (ROOT) DEĞİŞİMİ
      {
        "op": "replace",
        "scope": "root",
        "path": "visualSettings.crosshair", // Nokta notasyonu ile derinlik
        "value": {"color": "#FF0000", "style": "dashed"},
      },
      // GRAFİK (CHART) DEĞİŞİMİ
      {
        "op": "replace",
        "scope": "chart",
        "targetId": "ohlc_01",
        "path": "legend",
        "value": {"visible": false},
      },
    ],
  },
};

// B. ADD (Yeni Grafik Ekleme)
// ignore: non_constant_identifier_names
var patchPacket_add = {
  "packet": {"packetType": "patch", "docId": "doc_unique_999", "revision": 106},
  "payload": {
    "operations": [
      {
        "op": "add",
        "scope": "charts",
        "targetSlot": 1, // Layout slot index'i
        "value": {
          "meta": {"id": "macd_01", "type": "financial"},
          "plots": [],
          "inputs": [],
        },
      },
    ],
  },
};

// C. REMOVE (Grafik Silme)
// ignore: non_constant_identifier_names
var patchPacket_remove = {
  "packet": {"packetType": "patch", "docId": "doc_unique_999", "revision": 107},
  "payload": {
    "operations": [
      {"op": "remove", "scope": "chart", "targetId": "macd_01"},
    ],
  },
};

// D. MOVE (Grafik Taşıma)
// ignore: non_constant_identifier_names
var patchPacket_move = {
  "packet": {"packetType": "patch", "docId": "doc_unique_999", "revision": 108},
  "payload": {
    "operations": [
      {"op": "move", "scope": "charts", "targetId": "ohlc_01", "toIndex": 1},
    ],
  },
};

// 4. BUSY PAKETİ (İşlem Modu) ---------------------------------------------------
// ignore: non_constant_identifier_names
var busyPacket = {
  "packet": {"packetType": "busy", "docId": "doc_unique_999"},
  "payload": {
    "message": "İndikatör hesaplanıyor...",
    "progress": 0.45, // %45
  },
};

// 5. ERROR PAKETİ (Hata Modu) ---------------------------------------------------
// ignore: non_constant_identifier_names
var errorPacket = {
  "packet": {"packetType": "error", "docId": "doc_unique_999"},
  "payload": {
    "severity":
        "critical", // ENUM: ErrorSeverity.critical -> Full Reload Gerekir
    "code": 500,
    "message":
        "Veri tutarsızlığı (Sequence Mismatch). Lütfen sayfayı yenileyin.",
  },
};
