# 🗺️ SCHRITT 2 & 3: Detaillierte Anleitung für Raster-Vorhersagen
## Wie erstelle ich Prädiktoren-Raster und wende das Modell an?

---

## 📌 ÜBERBLICK

### Was sind Prädiktoren-Raster?
**Prädiktoren** = Die Input-Features (HEIGHT_M, TEMP_C_MEAN, etc.) als **Raster-Layer** in ArcGIS

**Raster** = Gitter mit Pixeln, wobei jedes Pixel einen Wert hat (z.B. Höhe, Temperatur, etc.)

### Ziel
```
Prädiktoren-Raster (für ganz Europa/Region)
      ↓
   [Ihr ArcGIS-Modell]
      ↓
SHI-Vorhersage-Raster (mit Bodengesundheitswerten für jeden Pixel)
```

---

## 🚀 SCHRITT 2: PRÄDIKTOREN-RASTER ERSTELLEN

### Was Sie brauchen
1. **Digitale Höhenmodelle (DEM)** → HEIGHT_M Raster
2. **Klima-Daten (Temperatur)** → TEMP_C_MEAN Raster
3. **Klima-Daten (Niederschlag)** → RAIN_MM Raster
4. **Landnutzung-Daten** → LAND_USE Raster
5. **Landbedeckung-Daten** → LAND_COVER Raster
6. **Köppen-Geiger Klassen** → CLIMATE_CLASS Raster

### Wo bekomme ich diese Daten?

#### 1️⃣ HEIGHT_M (Höhe)
**Quelle:** USGS SRTM oder EU-DEM v1.1
- USGS: https://earthexplorer.usgs.gov/
- EU-DEM: https://www.eea.europa.eu/data-and-maps/data/eu-dem

**Download:**
1. Gehen Sie zur Website
2. Region auswählen (z.B. Europa)
3. Download als GeoTIFF
4. Sie bekommen: `dem.tif` (Höhenwerte in Metern)

**In ArcGIS importieren:**
```
1. ArcGIS Pro öffnen
2. Map → Add Data → dem.tif
3. Dieser Layer ist bereits ein Raster!
4. Rename zu: HEIGHT_M_RASTER
```

---

#### 2️⃣ TEMP_C_MEAN (Temperatur)
**Quelle:** WORLDCLIM v2.1
- Website: https://www.worldclim.org/
- Auflösung: 30 Bogensekunden (~1km)
- Format: GeoTIFF

**Download:**
1. "Download data" → "Current conditions"
2. "WorldClim version 2.1"
3. "Bioclimatic variables"
4. Download Bio01 (Annual Mean Temperature)
5. Sie bekommen: `wc2.1_30s_bio_01.tif`

**In ArcGIS importieren:**
```
1. ArcGIS Pro → Add Data
2. Laden Sie wc2.1_30s_bio_01.tif
3. Wert steht in °C * 10 (also teilen Sie durch 10!)
   → Mit Raster Calculator: bio_01 / 10
4. Rename zu: TEMP_C_MEAN_RASTER
```

---

#### 3️⃣ RAIN_MM (Niederschlag)
**Quelle:** WORLDCLIM v2.1

**Download:**
1. Gleich wie Temperatur
2. Download Bio12 (Annual Precipitation)
3. Sie bekommen: `wc2.1_30s_bio_12.tif`

**In ArcGIS importieren:**
```
1. Add Data → wc2.1_30s_bio_12.tif
2. Wert steht bereits in mm
3. Rename zu: RAIN_MM_RASTER
```

---

#### 4️⃣ LAND_USE (Landnutzung)
**Quelle:** CORINE Land Cover oder LUCAS

**Option A: CORINE Land Cover (Empfohlen)**
- Download: https://land.copernicus.eu/pan-european/corine-land-cover
- Format: GeoTIFF
- Sie bekommen: `clc2018_V2018_20.tif`

**Option B: Für einfacheres Setup**
- Nutzen Sie die bereits in Ihren Trainingsdaten vorhandenen Kategorien:
  - Agriculture, Forestry, Semi-natural areas, Fallow

```
In ArcGIS:
1. Add Data → clc2018_V2018_20.tif
2. Reklassifizieren zu Ihren 4 Kategorien:
   Raster → Reclassify
   
   CORINE-Codes → Ihre Kategorien:
   12, 21, 22, 23, 24, 25 → 1 (Agriculture)
   31, 32, 33 → 2 (Forestry)
   41, 42, 43 → 3 (Semi-natural areas)
   38, 39 → 4 (Fallow)
   
3. Output speichern als: LAND_USE_RASTER
```

---

#### 5️⃣ LAND_COVER (Landbedeckung)
**Quelle:** CORINE Land Cover

```
CORINE-Codes → Ihre Kategorien:
21, 22, 23, 24, 25 → 1 (Cropland)
31, 32, 33 → 2 (Grassland)
41, 42, 43 → 3 (Woodland)
13, 14, 15 → 4 (Bareland)
35 → 5 (Shrubland)

Raster → Reclassify
Output speichern als: LAND_COVER_RASTER
```

---

#### 6️⃣ CLIMATE_CLASS (Köppen-Geiger)
**Quelle:** Köppen-Geiger Klimaklassen

**Download:**
- Website: http://www.gloh2o.org/koppen-geiger/
- Download GIS Layer
- Sie bekommen: `kg_0p0083.tif` (oder ähnlich)

```
In ArcGIS:
1. Add Data → kg_0p0083.tif
2. Wert sind bereits die Klassen (1-30)
3. Rename zu: CLIMATE_CLASS_RASTER
```

---

### ⚠️ WICHTIG: Raster-Ausrichtung

Alle Raster müssen die **gleiche Auflösung und Ausrichtung** haben!

**Raster abstimmen:**
```
1. Alle Raster sollten ~ 1km x 1km Auflösung haben
2. Sie sollten dasselbe Koordinatensystem haben
3. Gehen Sie zu: Raster → Align Rasters
   
   In ArcGIS:
   1. Tools → Align Rasters
   2. Input: Alle 6 Raster
   3. Align to raster: HEIGHT_M_RASTER (als Referenz)
   4. Cell size: 1000 (Meter) oder die native Auflösung
   5. Output location: arcgis-development/rasters/
   
   Output:
   - HEIGHT_M_aligned.tif
   - TEMP_C_aligned.tif
   - RAIN_MM_aligned.tif
   - LAND_USE_aligned.tif
   - LAND_COVER_aligned.tif
   - CLIMATE_CLASS_aligned.tif
```

---

### 📁 Ordner-Struktur nach SCHRITT 2

```
arcgis-development/
├── rasters/                          (NEU)
│   ├── HEIGHT_M_aligned.tif
│   ├── TEMP_C_MEAN_aligned.tif
│   ├── RAIN_MM_aligned.tif
│   ├── LAND_USE_aligned.tif
│   ├── LAND_COVER_aligned.tif
│   └── CLIMATE_CLASS_aligned.tif
│
├── training_full_dataset.csv
├── training_set_80pct.csv
├── test_set_20pct.csv
└── points_for_visualization.csv
```

---

## 🎯 SCHRITT 3: MODELL ANWENDEN (Vorhersagen machen)

### Voraussetzungen
✅ Sie haben das trainierte Modell in ArcGIS (von SCHRITT 1)  
✅ Sie haben alle 6 Prädiktoren-Raster erstellt (von SCHRITT 2)

### Prozess

#### A. Modell speichern (falls nicht bereits geschehen)

```
ArcGIS Pro:
1. Gehen Sie zum Trainingsergebnis
2. Rechtsklick auf das Modell
3. "Save As" → Speichern Sie als .emd Datei
   Pfad: arcgis-development/models/SHI_Forest_Model.emd
```

---

#### B. Vorhersagen mit "Predict Using Trained Model"

```
ArcGIS Pro:
1. Analysis → Machine Learning → Predict Using Trained Model
2. Oder: Tools → Spatial Statistics → Machine Learning → Predict Using Trained Model
```

**Parameter ausfüllen:**

| Parameter | Wert | Erklärung |
|-----------|------|-----------|
| **Trained Model** | SHI_Forest_Model.emd | Ihr trainiertes Modell von SCHRITT 1 |
| **Predictor Raster(s)** | HEIGHT_M_aligned.tif, TEMP_C_MEAN_aligned.tif, RAIN_MM_aligned.tif, LAND_USE_aligned.tif, LAND_COVER_aligned.tif, CLIMATE_CLASS_aligned.tif | Alle 6 Raster in der richtigen Reihenfolge! |
| **Output Prediction Raster** | arcgis-development/SHI_Prediction_Output.tif | Wo soll die Ausgabe gespeichert werden? |
| **Output Probability Raster** | (optional) arcgis-development/SHI_Probability.tif | Unsicherheit der Vorhersage |

---

### ⚠️ WICHTIG: Reihenfolge der Prädiktoren

**Die Raster MÜSSEN in dieser Reihenfolge eingegeben werden:**

1. HEIGHT_M
2. TEMP_C_MEAN
3. RAIN_MM
4. LAND_USE
5. LAND_COVER
6. CLIMATE_CLASS

(Das ist die Reihenfolge aus Ihrem training_full_dataset.csv!)

---

#### C. Vorhersagen ausführen

```
ArcGIS Pro:
1. Alle Parameter eingefüllt?
2. Klicken Sie auf: RUN
3. Warten Sie... (kann 5-30 Minuten dauern je nach Größe)
```

**Was passiert:**
- ArcGIS wird das Modell auf jeden Pixel anwenden
- Für jeden Pixel werden die 6 Features aus den Rastern gelesen
- Das Modell macht eine SHI-Vorhersage für diesen Pixel
- Ergebnis: Ein neues Raster mit SHI-Werten

---

#### D. Ergebnis überprüfen

```
Nach erfolgreicher Vorhersage:
1. Sie sehen: SHI_Prediction_Output.tif
2. Layer wird automatisch zur Map hinzugefügt
3. Sie sehen: Raster mit Pixelwerten (SHI zwischen ~2.0 und ~4.5)
```

---

## 📊 VISUALISIERUNG DES ERGEBNISSES

### Schritt A: Farben anpassen

```
ArcGIS Pro:
1. Rechtsklick auf SHI_Prediction_Output
2. Symbology
3. "Stretched" oder "Classified"
4. Color Scheme: z.B. "Green to Red Diverging" oder "RdYlGn"
   (Rot = schlechte Bodengesundheit, Grün = gute)
```

### Schritt B: Legende erstellen

```
1. Map → Legend
2. Fügen Sie SHI_Prediction_Output hinzu
3. Beschriftung: "Soil Health Index (SHI) Prediction"
```

### Schritt C: Vergleich mit Original-Trainingsdaten

```
1. Laden Sie points_for_visualization.csv
2. Create XY Event Layer (X, Y Koordinaten)
3. Überlagern Sie mit dem Vorhersage-Raster
4. Vergleichen Sie: Stimmen die Vorhersagen mit den Beobachtungen überein?
```

---

## 📈 QUALITÄTSKONTROLLE

### Frage 1: Ist die Vorhersage sinnvoll?

**Gutes Zeichen ✅:**
- Niederschlagreiche Gebiete haben höhere SHI-Werte
- Waldflächen haben höhere Werte als intensive Landwirtschaft
- Räumliche Muster sind glatt (keine wilden Sprünge zwischen Pixeln)

**Schlechtes Zeichen ❌:**
- Alle Pixel haben den gleichen Wert
- Extreme Werte außerhalb des Trainingsbereichs (< 2.0 oder > 4.5)
- Raue, zufällige Muster (deutet auf Fehler hin)

---

### Frage 2: Stimmt die Auflösung?

```
1. Rechtsklick auf Raster → Properties
2. Überprüfen Sie die Pixel-Größe
3. Normal: ~1000m x 1000m (1 km²)
4. Wenn: 30m x 30m oder 100m x 100m → Ist auch okay!
```

---

### Frage 3: Stimmt das Koordinatensystem?

```
1. Rechtsklick auf Raster → Properties
2. Coordinate System section
3. Sollte sein: WGS 84 oder ähnlich
4. Wenn nicht: Reproject Raster
```

---

## 🎯 TIPPS FÜR ERFOLG

### Tipp 1: Mit kleineren Bereichen starten
```
Statt ganz Europa:
1. Laden Sie nur einen Landkreis als Raster
2. Testen Sie die Vorhersage dort
3. Wenn okay → Erweitern Sie auf ganz Europa
```

### Tipp 2: Fehlende Daten behandeln
```
Wenn Sie "NoData" Fehler bekommen:
1. Gehen Sie zu: Raster → Conditional → Set Null
2. Set Null: Wo VALUE <= 0, dann NoData
3. Das behebt viele Lücken
```

### Tipp 3: Speichern & Backup
```
1. Speichern Sie regelmäßig: File → Save
2. Exportieren Sie das Vorhersage-Raster als:
   - GeoTIFF (universal, komprimierbar)
   - Cloud Raster Format (CRF) für große Raster
```

---

## 📝 ZUSAMMENFASSUNG: SCHRITT 2 & 3

| Schritt | Was? | Wie? | Output |
|--------|------|------|--------|
| **SCHRITT 2** | Prädiktoren-Raster erstellen | Download DEM, WORLDCLIM, CORINE → Align in ArcGIS | 6 Raster (alle 1km Auflösung) |
| **SCHRITT 3** | Modell anwenden | Predict Using Trained Model Tool → Input 6 Raster → Run | SHI_Prediction_Output.tif |

---

## ✅ CHECKLISTE

- [ ] DEM heruntergeladen und importiert
- [ ] WORLDCLIM Temperatur & Niederschlag heruntergeladen
- [ ] CORINE Land Cover heruntergeladen und reklassifiziert
- [ ] Köppen-Geiger Raster heruntergeladen
- [ ] Alle 6 Raster aligned (gleiche Auflösung & Ausrichtung)
- [ ] Trainiertes Modell gespeichert (.emd)
- [ ] "Predict Using Trained Model" Tool konfiguriert
- [ ] Vorhersagen erfolgreich ausgeführt
- [ ] Ergebnis-Raster visualisiert
- [ ] Räumliche Muster überprüft

---

**Nächster Schritt:** Beginnen Sie mit DEM-Download und arbeiten Sie sich durch die Checkliste! 🗺️
