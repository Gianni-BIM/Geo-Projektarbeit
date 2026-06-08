"""
Vorbereitung von Datensätzen für ArcGIS Pro - Forest-based Classification and Regression Tool
==================================================================================================

Dieses Skript erstellt Trainingsdatensätze für das Forest-based and Boosted Classification and Regression Tool 
in ArcGIS Pro. Es nutzt die Ergebnisse des Random Forest Modells aus random_forest_shi.py.
"""

import pandas as pd
import numpy as np
import os
from sklearn.model_selection import train_test_split

# Pfade definieren
input_data_path = "input-ml/points.csv"
output_dir = "arcgis-development"
os.makedirs(output_dir, exist_ok=True)

# ============================================================================
# 1. Daten laden und aufbereiten
# ============================================================================
print("--- Schritt 1: Daten laden ---")
df_raw = pd.read_csv(input_data_path)
print(f"Ursprüngliche Datensätze: {len(df_raw)}")
print(f"Spalten: {list(df_raw.columns)}")

# Kopie für Aufbereitung
df = df_raw.copy()

# Hobley-Regel anwenden (wie in random_forest_shi.py)
print("\n--- Schritt 2: Hobley-Regel anwenden (<30 Beobachtungen ausschließen) ---")
df['kg_climate_class'] = df['kg_climate_class'].astype(int)

# Kategorien mit < 30 Beobachtungen filtern
for col in ['land_use', 'land_cover', 'kg_climate_class']:
    counts = df[col].value_counts()
    low_count_cats = counts[counts < 30].index.tolist()
    if low_count_cats:
        print(f"  Entferne aus {col}: {low_count_cats} (n < 30)")
        df = df[~df[col].isin(low_count_cats)]

print(f"Nach Filterung: {len(df)} Datensätze (entfernt: {len(df_raw) - len(df)})")
df.reset_index(drop=True, inplace=True)

# ============================================================================
# 2. Datensatz mit Features + Zielwert für ArcGIS
# ============================================================================
print("\n--- Schritt 3: Datensatz für ArcGIS vorbereiten ---")

# Feature-Spalten
feature_cols = ['height_m', 'temp_c_mean_1995_2024', 'rain_mmsqm_mean_1995_2024', 
                'land_use', 'land_cover', 'kg_climate_class']
target_col = 'SHI'
geom_cols = ['X', 'Y', 'POINT_ID']

# Vollständiger Datensatz für ArcGIS Tool
df_arcgis = df[geom_cols + feature_cols + [target_col]].copy()
df_arcgis.rename(columns={
    'height_m': 'HEIGHT_M',
    'temp_c_mean_1995_2024': 'TEMP_C_MEAN',
    'rain_mmsqm_mean_1995_2024': 'RAIN_MM',
    'land_use': 'LAND_USE',
    'land_cover': 'LAND_COVER',
    'kg_climate_class': 'CLIMATE_CLASS',
    'SHI': 'SHI_OBSERVED'
}, inplace=True)

# Speichern: Vollständiger Trainingsdatensatz
full_path = os.path.join(output_dir, "training_full_dataset.csv")
df_arcgis.to_csv(full_path, index=False)
print(f"✓ Vollständiger Trainingsdatensatz: {full_path}")
print(f"  - Datensätze: {len(df_arcgis)}")
print(f"  - Spalten: {list(df_arcgis.columns)}")

# ============================================================================
# 3. Train/Test Split für Modellvalidierung
# ============================================================================
print("\n--- Schritt 4: Train/Test Split (80/20) ---")
X = df_arcgis.drop(columns=['SHI_OBSERVED', 'POINT_ID'])
y = df_arcgis['SHI_OBSERVED']

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

# Trainingsdatensatz
df_train = pd.concat([
    X_train.reset_index(drop=True),
    y_train.reset_index(drop=True)
], axis=1)
df_train['POINT_ID'] = df_arcgis.loc[X_train.index, 'POINT_ID'].values
train_path = os.path.join(output_dir, "training_set_80pct.csv")
df_train.to_csv(train_path, index=False)
print(f"✓ Trainingsdatensatz (80%): {train_path}")
print(f"  - Datensätze: {len(df_train)}")

# Testdatensatz (für Validierung in ArcGIS)
df_test = pd.concat([
    X_test.reset_index(drop=True),
    y_test.reset_index(drop=True)
], axis=1)
df_test['POINT_ID'] = df_arcgis.loc[X_test.index, 'POINT_ID'].values
test_path = os.path.join(output_dir, "test_set_20pct.csv")
df_test.to_csv(test_path, index=False)
print(f"✓ Testdatensatz (20%): {test_path}")
print(f"  - Datensätze: {len(df_test)}")

# ============================================================================
# 4. Datensatz mit Koordinaten für räumliche Visualisierung
# ============================================================================
print("\n--- Schritt 5: Koordinaten-Datensatz für ArcGIS-Visualisierung ---")
df_coords = df_arcgis[['X', 'Y', 'POINT_ID', 'SHI_OBSERVED']].copy()
coords_path = os.path.join(output_dir, "points_for_visualization.csv")
df_coords.to_csv(coords_path, index=False)
print(f"✓ Visualisierungs-Datensatz: {coords_path}")
print(f"  - Datensätze: {len(df_coords)}")

# ============================================================================
# 6. Metadaten und Beschreibung
# ============================================================================
print("\n--- Schritt 6: Metadaten speichern ---")

metadata = f"""
ARCGIS PRO - FOREST-BASED CLASSIFICATION AND REGRESSION TOOL
Vorbereitung und Verwendung
======================================================================

DATENSÄTZE IN DIESEM ORDNER:
----------------------------------------------------------------------

1. training_full_dataset.csv (HAUPTDATENSATZ)
   - Datensätze: {len(df_arcgis)}
   - Verwendung: Vollständiger Trainingsdatensatz für ArcGIS Tool
   - Features: HEIGHT_M, TEMP_C_MEAN, RAIN_MM, LAND_USE, LAND_COVER, CLIMATE_CLASS
   - Zielwert (Dependent Variable): SHI_OBSERVED
   - Koordinaten: X, Y (für räumliche Analyse)

2. training_set_80pct.csv
   - Datensätze: {len(df_train)} ({len(df_train)/len(df_arcgis)*100:.1f}%)
   - Verwendung: Training des Modells in ArcGIS
   
3. test_set_20pct.csv
   - Datensätze: {len(df_test)} ({len(df_test)/len(df_arcgis)*100:.1f}%)
   - Verwendung: Validierung und Evaluation des Modells

4. points_for_visualization.csv
   - Datensätze: {len(df_coords)}
   - Verwendung: Import in ArcGIS als Feature Class für räumliche Visualisierung
   - Enthält: X, Y, POINT_ID, SHI_OBSERVED (beobachtete Bodengesundheit)


VERWENDUNG IN ARCGIS PRO:
----------------------------------------------------------------------

OPTION A: Modell in ArcGIS trainieren
-------------------------------------
1. Öffnen Sie ArcGIS Pro
2. Navigieren Sie zu: Analysis > Machine Learning > Forest-based Classification and Regression
3. Laden Sie "training_full_dataset.csv" als Input Training Data
4. Setzen Sie Dependent Variable: SHI_OBSERVED
5. Wählen Sie Features:
   - HEIGHT_M (numerisch)
   - TEMP_C_MEAN (numerisch)
   - RAIN_MM (numerisch)
   - LAND_USE (kategorial)
   - LAND_COVER (kategorial)
   - CLIMATE_CLASS (kategorial)
6. Führen Sie das Modell aus
7. Nutzen Sie test_set_20pct.csv zur Validierung der Vorhersagen

OPTION B: Räumliche Visualisierung der Trainingsdaten
---------------------------------------------------
1. Importieren Sie "points_for_visualization.csv" in ArcGIS Pro
2. Erstellen Sie eine Feature Class (Make XY Event Layer)
   - X Field: X
   - Y Field: Y
   - Coordinate System: WGS84 (EPSG:4326) oder passend zu Ihren Daten
3. Symbologisieren Sie nach "SHI_OBSERVED" zur räumlichen Verteilung


FEATURE ERKLÄRUNGEN:
----------------------------------------------------------------------
- HEIGHT_M: Höhe über Meeresspiegel (Meter)
- TEMP_C_MEAN: Mittlere Jahrestemperatur 1995-2024 (°C)
- RAIN_MM: Mittlerer Jahresniederschlag 1995-2024 (mm/m²)
- LAND_USE: Landnutzungstyp (z.B. Agriculture, Forestry, etc.)
- LAND_COVER: Landbedeckungstyp (z.B. Cropland, Grassland, Woodland, etc.)
- CLIMATE_CLASS: Köppen-Geiger Klimaklasse (als Code)
- SHI_OBSERVED: Soil Health Index (beobachtete Zielwerte)


HOBLEY-REGEL (ANGEWENDET):
----------------------------------------------------------------------
Kategorien mit < 30 Beobachtungen wurden ausgeschlossen:
- Klasse 6 (BSh - Arid, steppe, hot): 9 Punkte
- Klasse 18 (Dsb - Cold, dry summer, warm summer): 6 Punkte  
- Klasse 27 (Dfc - Cold, no dry season, cold summer): 26 Punkte

Resultat: {len(df_raw)} → {len(df_arcgis)} Datensätze (41 Punkte entfernt)


WEITERE RESSOURCEN:
----------------------------------------------------------------------
- Random Forest Modell Ergebnisse: ../output/
- Explorative Datenanalyse: ../output/*.png
- Feature Importance Analyse: ../output/feature_importance.png
"""

metadata_path = os.path.join(output_dir, "README_ARCGIS_TOOL.txt")
with open(metadata_path, 'w') as f:
    f.write(metadata)
print(f"✓ Metadaten: {metadata_path}")

# ============================================================================
# 7. Zusammenfassung
# ============================================================================
print("\n" + "="*70)
print("ZUSAMMENFASSUNG - ArcGIS DATENSATZ-VORBEREITUNG")
print("="*70)
print(f"\n✓ Alle Datensätze wurden erfolgreich vorbereitet!")
print(f"\n  Speicherort: {os.path.abspath(output_dir)}")
print(f"\n  Verfügbare Dateien:")
print(f"    • training_full_dataset.csv ({len(df_arcgis)} Datensätze)")
print(f"    • training_set_80pct.csv ({len(df_train)} Datensätze)")
print(f"    • test_set_20pct.csv ({len(df_test)} Datensätze)")
print(f"    • points_for_visualization.csv ({len(df_coords)} Punkte)")
print(f"    • README_ARCGIS_TOOL.txt (Anleitung)")
print(f"\n  Nächster Schritt:")
print(f"    1. Öffnen Sie arcgis-development/ im ArcGIS Projekt")
print(f"    2. Laden Sie training_full_dataset.csv")
print(f"    3. Verwenden Sie Forest-based Tool zur Modellentwicklung/Validierung")
print("\n" + "="*70)
