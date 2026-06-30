# Terminal-Ausgabe: cforest_shi_latlong.rmd

Dieses Dokument enthält das vollständige Protokoll der Skript-Ausführung im Terminal.

```text
Loading required package: grid
Loading required package: mvtnorm
Loading required package: modeltools
Loading required package: stats4
Loading required package: strucchange
Loading required package: zoo

Attaching package: ‘zoo’

The following objects are masked from ‘package:base’:

    as.Date, as.Date.numeric

Loading required package: sandwich
Loading required package: nlme
This is mgcv 1.9-4. For overview type '?mgcv'.
                       output_lat-long           output_lat-long/Grafiken_png 
                                 FALSE                                  FALSE 
output_lat-long/Modell_Zusammenfassung 
                                 FALSE 
--- Schritt 1: Datenaufbereitung ---
Ursprüngliche Zeilenanzahl: 4467
Ausgeschlossene Spalten: POINT_ID, X, Y
  HINWEIS: lon_x und lat_y bleiben vorerst erhalten (werden in Schritt 1b
           für den GAM-Spline benötigt und danach durch 'spatial_trend' ersetzt).

Verteilung Landnutzung (land_use):

Agriculture (excluding fallow land and kitchen gardens) 
                                                   3096 
                                            Fallow land 
                                                    221 
                                               Forestry 
                                                    849 
              Semi-natural and natural areas not in use 
                                                    301 

Verteilung Landbedeckung (land_cover):

 Bareland  Cropland Grassland Shrubland  Woodland 
      178      2184      1010       131       964 

Köppen-Geiger Legende geladen:
  1: Af   Tropical, rainforest
  2: Am   Tropical, monsoon
  3: Aw   Tropical, savannah
  4: BWh  Arid, desert, hot
  5: BWk  Arid, desert, cold

Prüfe Kategorien auf Hobley-Regel (<30 Beobachtungen ausschließen)...
  Entferne Kategorien aus kg_climate_class: 6 (BSh  Arid, steppe, hot), 18 (Dsb  Cold, dry summer, warm summer), 27 (Dfc  Cold, no dry season, cold summer) (Anzahl: 9, 6, 26)
Zeilenanzahl nach Filterung: 4426 (Entfernt: 41 Zeilen)

Anzahl Features: 8 (davon 3 kategorisch als Faktoren — KEIN One-Hot-Encoding)
  land_use     : 4 Levels
  land_cover   : 5 Levels
  climate_name : 7 Levels

--- Schritt 1b: Räumlicher Trend via GAM (mgcv, Strategie B) ---
Fitte GAM mit s(lon_x, lat_y, bs='tp', k=30) ...
GAM-Zusammenfassung:

Family: gaussian 
Link function: identity 

Formula:
SHI ~ s(lon_x, lat_y, bs = "tp", k = 30)

Parametric coefficients:
            Estimate Std. Error t value Pr(>|t|)    
(Intercept) 3.138251   0.006041   519.5   <2e-16 ***
---
Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

Approximate significance of smooth terms:
                 edf Ref.df     F p-value    
s(lon_x,lat_y) 27.06  28.77 37.05  <2e-16 ***
---
Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

R-sq.(adj) =  0.194   Deviance explained = 19.9%
-REML = 2300.8  Scale est. = 0.16152   n = 4426

Prüfe räumliche Autokorrelation in den GAM-Residuen (Moran's I) ...
Loading required package: spData
To access larger datasets in this package, install the spDataLarge
package with: `install.packages('spDataLarge',
repos='https://nowosad.github.io/drat/', type='source')`
Loading required package: sf
Linking to GEOS 3.13.0, GDAL 3.8.5, PROJ 9.5.1; sf_use_s2() is TRUE
Moran's I (GAM-Residuen): I = 0.0232, p = 0.000000
  HINWEIS: Noch signifikante räumliche Autokorrelation in den Residuen.
  → Erwäge k in s(lon_x, lat_y, k=...) auf 60 oder höher zu setzen.

Neues Feature 'spatial_trend' hinzugefügt:
  Min    = 2.671
  Median = 3.120
  Max    = 3.879
Karte des räumlichen Trends gespeichert.

df_model enthält jetzt 7 Features (inkl. 'spatial_trend', ohne lon_x/lat_y):
  height_m, temp_c_mean_1995_2024, rain_mmsqm_mean_1995_2024, land_use, land_cover, climate_name, spatial_trend

--- Schritt 2: Explorative Datenanalyse (EDA) ---
Korrelationsmatrix der numerischen Variablen (inkl. spatial_trend):
                          height_m temp_c_mean_1995_2024
height_m                     1.000                -0.051
temp_c_mean_1995_2024       -0.051                 1.000
rain_mmsqm_mean_1995_2024    0.044                -0.328
spatial_trend               -0.239                -0.494
SHI                          0.080                -0.350
                          rain_mmsqm_mean_1995_2024 spatial_trend    SHI
height_m                                      0.044        -0.239  0.080
temp_c_mean_1995_2024                        -0.328        -0.494 -0.350
rain_mmsqm_mean_1995_2024                     1.000         0.603  0.455
spatial_trend                                 0.603         1.000  0.447
SHI                                           0.455         0.447  1.000

--- Schritt 3: Hyperparameter-Optimierung ---
Modellformel: SHI ~ height_m + temp_c_mean_1995_2024 + rain_mmsqm_mean_1995_2024 + 
 Modellformel:     land_use + land_cover + climate_name + spatial_trend
  → 'spatial_trend' ist automatisch enthalten (7 Features total)
Starte Grid Search über 9 Kombinationen (ntree=500)...
  [1/9] mtry=2, mincriterion=0.90 ... OOB R²=0.3892, RMSE=0.3499
  [2/9] mtry=3, mincriterion=0.90 ... OOB R²=0.3974, RMSE=0.3475
  [3/9] mtry=4, mincriterion=0.90 ... OOB R²=0.3997, RMSE=0.3469
  [4/9] mtry=2, mincriterion=0.95 ... OOB R²=0.3837, RMSE=0.3515
  [5/9] mtry=3, mincriterion=0.95 ... OOB R²=0.3908, RMSE=0.3495
  [6/9] mtry=4, mincriterion=0.95 ... OOB R²=0.3941, RMSE=0.3485
  [7/9] mtry=2, mincriterion=0.99 ... OOB R²=0.3748, RMSE=0.3540
  [8/9] mtry=3, mincriterion=0.99 ... OOB R²=0.3816, RMSE=0.3521
  [9/9] mtry=4, mincriterion=0.99 ... OOB R²=0.3837, RMSE=0.3515

Beste Parameter gefunden:
  mtry = 4
  mincriterion = 0.90
  Bester OOB R²: 0.3997
  Bester OOB RMSE: 0.3469

--- Schritt 4: Modellevaluation ---
Modell-Performance auf Trainingsdaten:
  Train R²:   0.4552
  Train RMSE: 0.3305
Modell-Performance auf Out-of-Bag (OOB) Daten:
  OOB R²:     0.3997
  OOB RMSE:   0.3469
Warning message:
In annotate("text", x = val_range[1] + 0.1, y = val_range[2] - 0.3,  :
  Ignoring unknown parameters: `label.padding`

--- Schritt 5: Variable Importance ---
Berechne permutationsbasierte Variable Importance (kann einige Minuten dauern)...

Variable Importance (Permutation, unbiased):
                  Variable  Importance Importance_Pct
                land_cover 0.037495104      31.994876
             spatial_trend 0.031339297      26.742075
 rain_mmsqm_mean_1995_2024 0.021583699      18.417545
                  height_m 0.010414389       8.886683
     temp_c_mean_1995_2024 0.006587964       5.621563
                  land_use 0.006115019       5.217995
              climate_name 0.003655495       3.119263

  → 'spatial_trend' liegt auf Rang 2 von 7 (26.7% Anteil)
  → spatial_trend ist SIGNIFIKANT: räumlicher Trend trägt zur Erklärung bei.

--- Schritt 5b: Variablenlegende erstellen ---
Variablenlegende gespeichert: output_lat-long/Modell_Zusammenfassung/variable_legend.md

--- Schritt 6: Partial Dependence Plots (übersprungen wegen Laufzeit) ---

--- Schritt 7: Decision Tree (ctree) ---
pdf 
  2 
Entscheidungsbaum gespeichert.

--- Schritt 8: Ergebnisse zusammenfassen ---
Markdown-Zusammenfassung erstellt unter 'output_lat-long/Modell_Zusammenfassung/model_summary.md'.
Alle Diagramme im Ordner 'output_lat-long/' gespeichert.
--- Analyse erfolgreich abgeschlossen! ---
```
