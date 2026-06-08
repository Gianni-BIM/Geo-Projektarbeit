
ARCGIS PRO - FOREST-BASED CLASSIFICATION AND REGRESSION TOOL
Vorbereitung und Verwendung
======================================================================

DATENSÄTZE IN DIESEM ORDNER:
----------------------------------------------------------------------

1. training_full_dataset.csv (HAUPTDATENSATZ)
   - Datensätze: 4426
   - Verwendung: Vollständiger Trainingsdatensatz für ArcGIS Tool
   - Features: HEIGHT_M, TEMP_C_MEAN, RAIN_MM, LAND_USE, LAND_COVER, CLIMATE_CLASS
   - Zielwert (Dependent Variable): SHI_OBSERVED
   - Koordinaten: X, Y (für räumliche Analyse)

2. training_set_80pct.csv
   - Datensätze: 3540 (80.0%)
   - Verwendung: Training des Modells in ArcGIS
   
3. test_set_20pct.csv
   - Datensätze: 886 (20.0%)
   - Verwendung: Validierung und Evaluation des Modells

4. points_for_visualization.csv
   - Datensätze: 4426
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

Resultat: 4467 → 4426 Datensätze (41 Punkte entfernt)


WEITERE RESSOURCEN:
----------------------------------------------------------------------
- Random Forest Modell Ergebnisse: ../output/
- Explorative Datenanalyse: ../output/*.png
- Feature Importance Analyse: ../output/feature_importance.png
