# Zusammenfassung: Conditional Inference Forest zur Bewertung der Bodengesundheit (SHI)

## Angewandte Fixes und Methodenverbesserungen

- **FIX 1 — replace konsistent:** Grid Search und finales Modell verwenden
  jetzt beide `replace=FALSE, fraction=0.632` (Subsampling ohne Zurücklegen,
  Strobl et al. 2007).
- **FIX 2 — GAM k=60:** Thin-Plate-Spline mit k=60 statt k=30, absorbiert
  atlantisch-kontinentale und nordsüdliche Klimagradienten sowie
  biogeographische Muster (Bodentypen, Geologie) als räumliche Kontrollvariable.
  Moran's I nach k=60: I=-0.0066, p=0.9905 → keine signifikante räumliche
  Autokorrelation mehr in den GAM-Residuen.
- **FIX 3 — PDPs aktiviert (gecacht):** Partial Dependence Plots für Top-3-Variablen
  berechnet und als CSV gecacht für reproduzierbare Nachnutzung.
- **NEU — Spatial Cross-Validation:** 10-fache Leave-One-Block-Out CV mit
  k-means-Blöcken auf geographischen Koordinaten. Mindestabstand zwischen
  Blöcken: ~462 km (aus Moran's I-Testdistanz d=2.0° abgeleitet).

## Modell-Informationen

- Algorithmus: Conditional Inference Forest (party::cforest, Hothorn et al. 2006)
- Räumliche Erweiterung: GAM Thin-Plate-Spline s(lon_x, lat_y, bs='tp', k=60)
- Datenpunkte gesamt: 4467 | Nach Hobley-Filterung: 4426

## Räumlicher Trend (GAM, k=60)

- EDF (effective degrees of freedom): 78.82
- GAM adj. R²: 0.258 (Deviance explained: 25.8%)
- Moran's I Residuen: I=-0.0066, p=0.9905 — OK — räumliche Autokorrelation vollständig absorbiert
- Interpretation: spatial_trend absorbiert großräumige Gradienten (atlantisch-
  kontinental, nordsüdlich) sowie ungemessene biogeographische Kovariaten
  (Bodentypen, geologischer Untergrund). Dient als Kontrollvariable, ist
  keine direkte Antwort auf die Forschungsfrage.

## Modellgüte — Vergleich der Validierungsstrategien

| Metrik | Wert | Interpretation |
|--------|------|----------------|
| Train R² | 0.4696 | Auf Trainingsdaten (Overfitting-Check) |
| OOB R² | 0.4161 (41.6%) | Zufällige Splits — leicht optimistisch |
| OOB RMSE | 0.3421 SHI-Einh. | Mittlerer Vorhersagefehler (OOB) |
| **Spatial CV R²** | **0.3650 (36.5%)** | **Räumlich getrennte Blöcke — belastbarste Schätzung** |
| Spatial CV RMSE | 0.3568 SHI-Einh. | Mittlerer Vorhersagefehler (Spatial CV) |
| Optimismus-Bias | 0.0511 | OOB minus Spatial CV — Einfluss räumlicher Korrelation |

> **Optimismus-Bias > 0.05:** Spatial CV R² ist die empfohlene Kennzahl für Publikationen.

## Optimierte Hyperparameter

| Parameter | Wert | Bedeutung |
|-----------|------|-----------|
| ntree | 500 | Anzahl Bäume im Forest |
| mtry | 4 | Features pro Split (getestet: 2/3/4 von 7) |
| mincriterion | 0.900 | p-Wert-Schwelle für Splits (getestet: 0.90/0.95/0.99) |
| replace | FALSE | Subsampling ohne Zurücklegen (Strobl et al. 2007) |
| fraction | 0.632 | Anteil der Daten pro Baum |

## Beantwortung der Forschungsfrage

### Frage 1: Welche Umweltfaktoren beeinflussen den SHI?

Nach Kontrolle des räumlichen Hintergrundtrends (spatial_trend als
Kontrollvariable):

1. **spatial_trend**: 44.2% unbed. / 0.0109 bed. Importance ← Kontrollvariable (räumlicher Gradient)
2. **land_cover**: 26.9% unbed. / 0.0066 bed. Importance
3. **rain_mmsqm_mean_1995_2024**: 11.9% unbed. / 0.0016 bed. Importance
4. **height_m**: 7.4% unbed. / 0.0015 bed. Importance
5. **land_use**: 4.7% unbed. / 0.0003 bed. Importance
6. **temp_c_mean_1995_2024**: 3.3% unbed. / 0.0004 bed. Importance
7. **climate_name**: 1.7% unbed. / 0.0001 bed. Importance

### Frage 2: Wie stark wirken sie und in welche Richtung? (Partial Dependence)

- **Landbedeckung (26.9%):** Stärkste kategorial differenzierte Wirkung.
  Höchster SHI: Woodland. Niedrigster SHI: Cropland.
- **Räumlicher Trend (44.2% unkond.):** Kontrollvariable — repräsentiert
  ungemessene regionalen Kovariaten. Zur Forschungsfrage: zeigt, dass
  großräumige geographische Faktoren bedeutsam sind.
- **Niederschlag (11.9%):** Wirkungsrichtung positiv (monoton steigend) auf SHI.
  Sättigungseffekte oder Schwellenwerte erkennbar im PDP.
- **Höhenlage (7.4%):** Moderater positiver Effekt (r=0.080 mit SHI).
- **Temperatur (3.3%):** Negativer Effekt in wärmeren Regionen (r=-0.350 mit SHI).

### Frage 3: Wechselwirkungen

- Decision Tree (Schritt 7) zeigt hierarchische Interaktionen (visual).
- Formale Quantifizierung (Friedmans H-Statistik, 2D-PDPs): empfohlen
  für künftige Arbeit.

## Limitationen und Ausblick

1. **Fehlende Bodeneigenschaften:** Die verbleibenden 63% unerklärter
   Varianz (Spatial CV) sind vermutlich auf fehlende Prädiktoren
   zurückzuführen (pH-Wert, organischer Kohlenstoff, Bodenstruktur/-textur).
2. **Spatial CV Block-Design:** k-means-Blöcke sind ein pragmatischer
   Ansatz; blockCV::cv_spatial() mit automatischer Variogram-basierten
   Blockgröße wäre methodisch noch robuster.
3. **Interaktionsanalyse:** Friedmans H-Statistik und 2D-PDPs für
   land_cover × rain und spatial_trend × land_cover nicht berechnet.
4. **Bootstrap-CI für Importance:** Stabilitätstest der Rangfolge zwischen
   spatial_trend und land_cover nicht durchgeführt (Laufzeit: ~13h für 50 Bootstrap-Runs).

## Fazit

Das Modell erklärt **36.5% der SHI-Varianz** auf räumlich ungesehenen
Testblöcken (Spatial CV). Nach Kontrolle des räumlichen Hintergrundtrends
sind **Landbedeckung, Niederschlag und Höhenlage** die stärksten messbaren
Umweltfaktoren für den Soil Health Index in Europa.

