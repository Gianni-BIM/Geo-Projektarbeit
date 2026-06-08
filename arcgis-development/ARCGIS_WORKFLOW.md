# ArcGIS Pro - Forest-based Classification and Regression Tool
## Workflow für Bodengesundheitsmodellierung (SHI)

---

## 📋 Überblick

Dieser Ordner enthält aufbereitete Datensätze für das **Forest-based and Boosted Classification and Regression Tool** in ArcGIS Pro. Das Tool ermöglicht die Entwicklung eines Machine-Learning-Modells zur Vorhersage des Soil Health Index (SHI) basierend auf klimatischen, topografischen und landnutzungsbezogenen Faktoren.

### ❓ Warum separate ArcGIS-Datensätze?

Die Python-basierten Random Forest Modelle (`random_forest_shi.py`) und ArcGIS Pro ermöglichen:
- **Python-Ansatz:** Detaillierte Modellanalyse, Visualisierungen, Fehlerdiagnose
- **ArcGIS-Ansatz:** Räumliche Integration, kartographische Visualisierung, Vorhersagen auf neuen Datenpunkten

Die Datensätze hier sind speziell für ArcGIS Pro aufbereitet.

---

## 📂 Dateistruktur

### 1️⃣ **training_full_dataset.csv** (HAUPTDATENSATZ)
**Größe:** 4.426 Datensätze | **Spalten:** 10

**Verwendung:** Vollständiger Trainingsdatensatz für das Forest-based Tool

**Spalten:**
```
X                    Longitude (dezimal)
Y                    Latitude (dezimal)
POINT_ID            Eindeutige Punkt-ID
HEIGHT_M            Höhe über Meeresspiegel (Meter)
TEMP_C_MEAN         Mittlere Jahrestemperatur 1995-2024 (°C)
RAIN_MM             Mittlerer Jahresniederschlag 1995-2024 (mm/m²)
LAND_USE            Landnutzungstyp (kategorisch)
LAND_COVER          Landbedeckungstyp (kategorisch)
CLIMATE_CLASS       Köppen-Geiger Klimaklasse (numerisch)
SHI_OBSERVED        Soil Health Index (Zielwert)
```

---

### 2️⃣ **training_set_80pct.csv** (80% der Daten)
**Größe:** 3.540 Datensätze

**Verwendung:** Training-Datensatz für das Forest-based Tool
- Enthält 80% der Daten (zufällig ausgewählt)
- Ziel: Modell-Training

---

### 3️⃣ **test_set_20pct.csv** (20% der Daten)
**Größe:** 886 Datensätze

**Verwendung:** Validierungs-Datensatz
- Enthält 20% der Daten (zufällig ausgewählt)
- Ziel: Modell-Validierung und Performance-Evaluation
- Separat vom Training für unabhängige Bewertung

---

### 4️⃣ **points_for_visualization.csv**
**Größe:** 4.426 Datensätze | **Spalten:** 4

**Verwendung:** Räumliche Visualisierung in ArcGIS Pro

**Spalten:**
```
X               Longitude
Y               Latitude
POINT_ID        Punkt-ID
SHI_OBSERVED    Beobachteter Soil Health Index
```

**Import als Feature Class:**
1. ArcGIS Pro > Geoprocessing > Create XY Event Layer
2. X Field: `X`
3. Y Field: `Y`
4. Spatial Reference: WGS84 (EPSG:4326)

---

## 🚀 Verwendung in ArcGIS Pro

### **OPTION A: Modell selbst trainieren**

**Ziel:** Ein neues Forest-based Regressionsmodell in ArcGIS trainieren und evaluieren

**Schritte:**

1. **ArcGIS Pro öffnen**
   - Neues Projekt erstellen oder bestehendes öffnen
   - Mit Geoprocessing-Werkzeugen navigieren

2. **Werkzeug laden**
   ```
   Menü: Analysis > Machine Learning > Forest-based Classification and Regression
   ```

3. **Eingabeparameter setzen**
   
   | Parameter | Wert |
   |-----------|------|
   | **Input Training Data** | `training_full_dataset.csv` |
   | **Target Field** | `SHI_OBSERVED` |
   | **Feature Fields** | HEIGHT_M, TEMP_C_MEAN, RAIN_MM, LAND_USE, LAND_COVER, CLIMATE_CLASS |
   | **Model Renderer** | (optional) |
   | **Output Predicted Data** | Neuer Ordner, z.B. `model_output` |

4. **Modell trainieren**
   - Klicken Sie auf "Run"
   - Der Prozess trainiert einen Random Forest mit den besten Hyperparametern
   - Ergebnis: Vorhersage-Raster oder Punkte

5. **Modell bewerten**
   - Öffnen Sie den generierten **Training Model Report**
   - Prüfen Sie Metriken: R², RMSE, Feature Importance
   - Vergleichen Sie mit Python-Modell-Ergebnissen

6. **Mit Testdaten validieren** (optional)
   - Laden Sie `test_set_20pct.csv`
   - Führen das trainierte Modell darauf aus
   - Vergleichen Sie vorhergesagte vs. beobachtete Werte

---

### **OPTION B: Nur räumliche Visualisierung**

**Ziel:** Die Trainingsdaten als Punktdatensatz in ArcGIS visualisieren

**Schritte:**

1. **Feature Class erstellen**
   - Geoprocessing > Create XY Event Layer
   - Input: `points_for_visualization.csv`
   - X Field: `X`, Y Field: `Y`
   - Output: Feature Class (z.B. `SHI_Training_Points`)

2. **Symbologisieren**
   - Layer > Symbology
   - Graduated Colors
   - Field: `SHI_OBSERVED`
   - Farbschema: z.B. Rot (niedrig) → Grün (hoch)

3. **Räumliche Muster erkunden**
   - Wo ist die Bodengesundheit am höchsten?
   - Korrelation mit Landnutzung?
   - Klimatische Unterschiede?

---

### **OPTION C: Vorhersagen auf neuen Daten**

**Ziel:** Das trainierte Modell auf neue Punkte anwenden

**Vorbereitung:** Datensatz mit gleichen Features (ohne SHI_OBSERVED)

**Schritte:**

1. CSV mit neuen Daten vorbereiten:
   ```
   X, Y, POINT_ID, HEIGHT_M, TEMP_C_MEAN, RAIN_MM, LAND_USE, LAND_COVER, CLIMATE_CLASS
   ```

2. Forest-based Tool neu laden:
   - Input Training Data: Verwenden Sie das trainierte Modell aus OPTION A
   - Input Prediction Data: Ihre neue CSV
   - Run

3. Ergebnis: Vorhersagte SHI-Werte für neue Punkte

---

## 📊 Datenquellen und Aufbereitung

### Ursprung der Features:

| Feature | Quelle | Bereich |
|---------|--------|--------|
| **HEIGHT_M** | Digital Elevation Model (DEM) | 0–3.500m |
| **TEMP_C_MEAN** | WORLDCLIM v2.1 (1995–2024) | –20 bis +40°C |
| **RAIN_MM** | WORLDCLIM v2.1 (1995–2024) | 0–15.000mm |
| **LAND_USE** | CORINE Land Cover / LUCAS | 4 Kategorien nach Filterung |
| **LAND_COVER** | CORINE Land Cover / LUCAS | 5 Kategorien nach Filterung |
| **CLIMATE_CLASS** | Köppen-Geiger Klassifikation | 30 Klassen → 27 nach Filterung |
| **SHI_OBSERVED** | LUCAS Soil Module Survey | 2.0–4.5 |

### Datenaufbereitung (Hobley-Regel):

**Ausgeschlossene Kategorien (< 30 Beobachtungen):**
- Köppen-Klasse 6 (BSh – Arid, Steppe, heiß): 9 Punkte
- Köppen-Klasse 18 (Dsb – Kalt, trockener Sommer, warmer Sommer): 6 Punkte
- Köppen-Klasse 27 (Dfc – Kalt, keine Trockenzeit, kalter Sommer): 26 Punkte

**Resultat:** 4.467 → 4.426 Datensätze (41 Punkte entfernt)

---

## 🎯 Feature Beschreibungen für ArcGIS

### Numerische Features

- **HEIGHT_M** (Höhe)
  - Einheit: Meter
  - Einfluss: Positiv auf SHI (höhere Lagen = bessere Bodengesundheit)
  - Begründung: Höhere Lagen haben oft bessere Drainage, weniger Verdichtung

- **TEMP_C_MEAN** (Temperatur)
  - Einheit: Grad Celsius
  - Einfluss: Negativ auf SHI (höhere Temperaturen = schlechtere Bodengesundheit)
  - Begründung: Wärmestress reduziert Bodenbiologie, erhöht Verdunstung

- **RAIN_MM** (Niederschlag)
  - Einheit: Millimeter/Quadratmeter
  - Einfluss: Positiv auf SHI (mehr Wasser = bessere Bodenfeuchtigkeit)
  - Begründung: Wasser ist essentiell für Mikrobenleben und Nährstofftransport
  - Warnung: Zu viel Regen (>1.500mm) kann auch schlecht sein (Staunässe)

### Kategorische Features

- **LAND_USE** (Landnutzung)
  - Kategorien: Agriculture, Forestry, Semi-natural areas, Fallow
  - Beste Kategorie: Forestry (SHI ~3,37)
  - Schlechteste Kategorie: Agriculture (SHI ~3,08)

- **LAND_COVER** (Landbedeckung)
  - Kategorien: Cropland, Grassland, Woodland, Bareland, Shrubland
  - Beste Kategorie: Woodland
  - Schlechteste Kategorie: Bareland

- **CLIMATE_CLASS** (Köppen-Geiger Klasse)
  - 27 verbleibende Klassen
  - Beste Klassen: Temperiert, warm, keine Trockenzeit (Cfb)
  - Schlechteste Klassen: Arid, kalt, tropisch trocken

---

## 📈 Erwartete Modellperformance

Basierend auf dem Python-Random-Forest-Modell:

```
Out-of-Bag R²:        0.40 (40% der Varianz erklärt)
Out-of-Bag RMSE:      0.35 (Durchschnittlicher Fehler)
Training R²:          0.56 (Modell etwas überoptimiert)
```

**Interpretation:**
- Das Modell erklärt ~40% der Variabilität in der Bodengesundheit
- Andere Faktoren (Bodenart, organische Substanz, pH, Mikrobiologie) sind auch wichtig
- Die verbleibenden 60% könnten durch spezialisierte Bodenmessungen erfasst werden

---

## ⚠️ Wichtige Hinweise

### Datenqualität
- **Fehlende Werte:** Keine NA-Werte in den Trainingsdaten
- **Ausreißer:** Daten wurden auf Konsistenz geprüft
- **Koordinaten:** WGS84 (EPSG:4326)

### Modellgültigkeitsbereich
- **Geografisch:** Europa (LUCAS Soil Modul Stichproben)
- **Klimatisch:** Gemäßigte bis subtropische Zonen
- **Landnutzung:** Hauptsächlich Agrar- und Waldgebiete

### Begrenztungen
- Modell basiert auf Stichprobendaten (4.426 Punkte)
- SHI ist nur ein Indikator für Bodengesundheit
- Hochauflösende lokale Bodenkarten könnten bessere Vorhersagen liefern

---

## 📞 Weitere Ressourcen

- **Python Modellanalyse:** Siehe `../output/` Ordner
- **Feature Importance:** `../output/feature_importance.png`
- **Partial Dependence Plots:** `../output/partial_dependence.png`
- **Modellzusammenfassung:** `../output/model_summary.txt`
- **Entscheidungsbaum:** `../output/decision_tree.png`

---

## 🔄 Workflow-Checkliste

- [ ] `prepare_arcgis_dataset.py` ausgeführt ✓
- [ ] Datensätze in `arcgis-development/` vorhanden ✓
- [ ] ArcGIS Pro geöffnet
- [ ] Forest-based Tool konfiguriert
- [ ] Trainingsdatensatz geladen
- [ ] Feature-Spalten ausgewählt
- [ ] SHI_OBSERVED als Zielwert gesetzt
- [ ] Modell trainiert
- [ ] Modellbericht überprüft
- [ ] Vorhersagen visualisiert
- [ ] Mit Test-Datensatz validiert

---

**Datum Erstellt:** 2026-06-06  
**Version:** 1.0  
**Projekt:** Geo-Projektarbeit - Bodengesundheitsmodellierung  
