# 🌍 GESAMTPROJEKTSTRUKTUR - BODENGESUNDHEITSMODELLIERUNG
## Random Forest + ArcGIS Pro Integration

```
Geo-Projektarbeit-main/
│
├── 📊 DATENAUFBEREITUNG & EXPLORATION
├── data-prep/                          # Jupyter Notebooks für Datenaufbereitung
│   ├── a_auto_run_all_notebooks.ipynb
│   ├── calculate_shi.ipynb
│   ├── data_clean_and_transform.ipynb
│   ├── explore_indicator_data.ipynb
│   └── 01_input/                       # Rohdaten (CSV)
│
├── input-ml/
│   ├── points.csv                      # ⭐ HAUPTDATENSATZ (4.467 Punkte mit Features)
│   ├── legend.txt                      # Köppen-Geiger Klimaklassen-Legende
│   └── testfile
│
├── 🤖 MACHINE LEARNING - RANDOM FOREST (PYTHON)
├── random_forest_shi.py                # ⭐ Haupt-Modell (Random Forest Regressor)
├── prepare_arcgis_dataset.py           # ⭐ ArcGIS-Datensatz-Vorbereitung
│
├── 📈 MODELL-OUTPUTS & VISUALISIERUNGEN
├── output/                             # ✓ Bilder und Zusammenfassungen
│   ├── correlation_matrix.png          # Korrelation der Features
│   ├── decision_tree.png               # Visualisierter Entscheidungsbaum
│   ├── feature_importance.png          # Relative Wichtigkeit der Features
│   ├── observed_vs_predicted.png       # OOB-Vorhersagen vs. Beobachtungen
│   ├── parameter_optimization.png      # Grid Search Ergebnisse
│   ├── partial_dependence.png          # Einflussrichtungen der Features
│   ├── residuals_plot.png              # Residuenanalyse
│   ├── shi_by_climate.png              # SHI nach Klimaklasse
│   ├── shi_by_land_use_and_cover.png   # SHI nach Landnutzung/Bedeckung
│   ├── shi_distribution.png            # Histogramm SHI
│   ├── model_summary.txt               # Detaillierte Modellzusammenfassung
│   ├── parameter_grid_results.csv      # Grid Search Hyperparameter
│   └── tree.dot                        # Graphviz Entscheidungsbaum-Datei
│
├── 🏢 ARCGIS PRO - VORBEREITUNG & WORKFLOW
├── arcgis-development/                 # ⭐ ArcGIS Pro Datensätze
│   ├── training_full_dataset.csv       # (4.426) Vollständiger Trainingsdatensatz
│   ├── training_set_80pct.csv          # (3.540) 80% für Training
│   ├── test_set_20pct.csv              # (886)   20% für Validierung
│   ├── points_for_visualization.csv    # (4.426) Mit Koordinaten für Visualisierung
│   ├── ARCGIS_WORKFLOW.md              # 📖 Ausführliches Handbuch
│   └── README_ARCGIS_TOOL.txt          # Quick Start Guide
│
├── arcgis-visualisierung/              # (Legacy) Visualisierungsordner
│   └── input/                          # (Leer - predictions.csv wurde gelöscht)
│
└── 📚 DOKUMENTATION
    ├── README.md                       # Projekt-Übersicht
    ├── model_summary.txt               # Modell-Ergebnisse (Kurzfassung)
    └── Workflow/                       # UML-Diagramme und Workflow
```

---

## 🔄 WORKFLOW-ÜBERSICHT

### Phase 1: Datenaufbereitung (Input-ML)
```
input-ml/points.csv (4.467 Punkte)
         │
         │ Hobley-Regel: Kategorien mit < 30 Beobachtungen ausschließen
         │ (Entfernt: 41 Punkte)
         ▼
       4.426 bereinigte Datensätze
         │
         └─ Feature-Engineering
            └─ One-Hot-Encoding für kategorische Features
            └─ Normalisierung numerischer Features
```

### Phase 2: Random Forest Modellierung (Python)
```
random_forest_shi.py
│
├─ Schritt 1: Datenaufbereitung
├─ Schritt 2: Explorative Datenanalyse (EDA)
│  └─ Korrelationsmatrix
│  └─ SHI nach Klimaklasse
│  └─ SHI nach Landnutzung/Bedeckung
│
├─ Schritt 3: Hyperparameter-Optimierung
│  └─ Grid Search über 16 Kombinationen
│  └─ Beste Parameter: ntree=500, mtry=0.33, fraction=0.632
│
├─ Schritt 4: Modellevaluation
│  └─ OOB R²: 0.40 (40% Varianz erklärt)
│  └─ OOB RMSE: 0.35
│
├─ Schritt 5: Feature Importance (Permutation)
├─ Schritt 6: Partial Dependence Plots (PDP)
├─ Schritt 7: Decision Tree Export
└─ Schritt 8: Modellzusammenfassung

         │
         │ WICHTIG: Modell wird nicht in CSV exportiert!
         │ (Die Vorhersagen sind in output/ als Bilder gespeichert)
         ▼
    output/ (Bilder und Zusammenfassungen)
```

### Phase 3: ArcGIS Pro Vorbereitung (Python)
```
prepare_arcgis_dataset.py
│
├─ Lädt input-ml/points.csv
├─ Wendet Hobley-Regel an (< 30 Beobachtungen)
│
├─ Erstellt Datensätze:
│  ├─ training_full_dataset.csv (4.426 Datensätze)
│  │  └─ Alle Features + SHI_OBSERVED
│  │  └─ Für Modelltraining im ArcGIS Tool
│  │
│  ├─ training_set_80pct.csv (3.540 Datensätze)
│  │  └─ 80% für Training
│  │  └─ Train/Test Split
│  │
│  ├─ test_set_20pct.csv (886 Datensätze)
│  │  └─ 20% für Validierung
│  │  └─ Unabhängige Performance-Evaluation
│  │
│  └─ points_for_visualization.csv (4.426 Datensätze)
│     └─ X, Y, POINT_ID, SHI_OBSERVED
│     └─ Für räumliche Visualisierung als Feature Class

         │
         ▼
    arcgis-development/ (Alle Dateien)
```

### Phase 4: ArcGIS Pro Modelltraining
```
ArcGIS Pro: Forest-based Classification and Regression Tool
│
├─ Input Training Data: training_full_dataset.csv
├─ Target Field: SHI_OBSERVED
├─ Features: HEIGHT_M, TEMP_C_MEAN, RAIN_MM, LAND_USE, LAND_COVER, CLIMATE_CLASS
│
├─ Trainiert neues Modell im ArcGIS
│  └─ Kann gegenüber Python-Modell variieren
│  └─ Vorteil: Räumliche Integration in Karten
│
└─ Output: Vorhersage-Raster oder Feature Class mit SHI_PRED

    ALTERNATIVE: Test-Validierung mit test_set_20pct.csv
```

---

## 📊 DATENFLUSS - VERGLEICH VORHER/NACHHER

### ❌ VORHER (Nicht sinnvoll)
```
random_forest_shi.py
    │
    └─ predictions.csv (redundant!)
       ├─ X, Y (schon in input-ml/points.csv)
       ├─ SHI_pred (Vorhersagen ohne Nutzen)
       └─ ❌ Nicht sinnvoll für ArcGIS Tool
```

### ✅ NACHHER (Strukturiert & Sinnvoll)
```
random_forest_shi.py
    │
    └─ Ruft prepare_arcgis_dataset.py auf
       │
       └─ arcgis-development/
          │
          ├─ training_full_dataset.csv
          │  └─ ✓ Vollständiger Trainingsdatensatz
          │  └─ ✓ Für ArcGIS Forest-based Tool
          │  └─ ✓ Features + SHI_OBSERVED
          │
          ├─ training_set_80pct.csv + test_set_20pct.csv
          │  └─ ✓ Für Train/Test Split
          │  └─ ✓ Für Modellvalidierung
          │
          ├─ points_for_visualization.csv
          │  └─ ✓ Für räumliche Visualisierung
          │  └─ ✓ Mit X, Y Koordinaten
          │
          └─ ARCGIS_WORKFLOW.md
             └─ ✓ Detaillierte Anleitung
```

---

## 🎯 HAUPTERKENNTNISSE

### Random Forest Modell (Python)
| Metrik | Wert |
|--------|------|
| **OOB R²** | 0.40 (40% Varianz erklärt) |
| **OOB RMSE** | 0.35 |
| **Training R²** | 0.56 (leichte Überoptimierung) |
| **Top Feature** | Niederschlag (30.8%) |
| **Optimale Bäume** | 500 |

### Feature-Wichtigkeit (Permutation Importance)
1. 🌧️ **Niederschlag (rain_mmsqm_mean_1995_2024)** – 30.8%
2. 🌳 **Landbedeckung (land_cover)** – 19.5%
3. 🌡️ **Temperatur (temp_c_mean_1995_2024)** – 19.2%
4. 📏 **Höhe (height_m)** – 15.9%
5. 🌍 **Klimaklasse (climate_name)** – 9.7%
6. 🌾 **Landnutzung (land_use)** – 4.8%

### Einflussrichtungen (PDP)
- 🟢 **Positiv:** Mehr Niederschlag, höhere Lagen, Forstwirtschaft
- 🔴 **Negativ:** Höhere Temperaturen, intensive Landwirtschaft

---

## 🚀 VERWENDUNG DER DATENSÄTZE

### Wann welche Datei?

| Datei | Wann? | Warum? |
|-------|-------|-------|
| **training_full_dataset.csv** | Modelltraining in ArcGIS | Kompletter Datensatz, beste Generalisierung |
| **training_set_80pct.csv** | Test/Validierung | Wenn Sie selbst Train/Test Split kontrollieren möchten |
| **test_set_20pct.csv** | Finale Evaluation | Unabhängige Performance-Bewertung |
| **points_for_visualization.csv** | Räumliche Visualisierung | Kartendarstellung in ArcGIS |

---

## 📝 NÄCHSTE SCHRITTE

1. ✅ **Random Forest trainiert** (Python)
   - Alle Bilder im `output/` Ordner

2. ✅ **ArcGIS-Datensätze vorbereitet** 
   - Alle CSVs im `arcgis-development/` Ordner

3. ⏭️ **ArcGIS Pro Modelltraining**
   - Lesen Sie: `arcgis-development/ARCGIS_WORKFLOW.md`
   - Laden Sie: `training_full_dataset.csv`
   - Starten Sie: Forest-based Tool

4. ⏭️ **Räumliche Visualisierung**
   - Import: `points_for_visualization.csv`
   - Create XY Event Layer
   - Symbologisieren nach SHI_OBSERVED

---

**Version:** 1.0  
**Datum:** 2026-06-06  
**Projekt:** Geo-Projektarbeit - Bodengesundheitsmodellierung  
**Status:** ✅ Produktionsreife
