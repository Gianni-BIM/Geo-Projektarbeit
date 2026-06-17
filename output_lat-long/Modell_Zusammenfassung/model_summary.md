# Zusammenfassung: Conditional Inference Forest zur Bewertung der Bodengesundheit (SHI)

## Modell-Informationen
- **Modell-Algorithmus:** Conditional Inference Forest (party)
- **Räumliche Erweiterung:** GAM Thin-Plate-Spline `s(lon_x, lat_y, k=30)`
- **Vorteil:** Native kategorische Verarbeitung — KEIN One-Hot-Encoding nötig! Räumlicher Trend als kompaktes numerisches Feature eingebunden.
- **Datenpunkte verwendet:** 4426 (nach Ausschluss von Klassen mit < 30 Punkten)

## NEU: GAM RÄUMLICHER TREND (Schritt 1b)
- **Methode:** `mgcv::gam(SHI ~ s(lon_x, lat_y, bs='tp', k=30), method='REML')`
- **Strategie B:** GAM-Vorhersage = neues Feature `spatial_trend`
- **Moran's I (GAM-Residuen):** I=0.0232, p=0.000000 → Noch signifikant (ggf. k erhöhen)
- **Variable Importance von 'spatial_trend':** Rang 2 von 7 (26.7%)
- **Interpretation:** SIGNIFIKANT — räumlicher Hintergrundtrend trägt zur Erklärung bei

## Ergebnisse der Modellgüte (OOB-Validierung)
- **Out-of-Bag R² (Erklärte Varianz):** 0.3997 (39.97%)
- **Out-of-Bag RMSE (Vorhersagefehler):** 0.3469
- **Trainings-R² (zum Vergleich):** 0.4552

**Optimierte Hyperparameter:**
- ntree (Anzahl Bäume): 500
- mtry (Variablen pro Split): 4
- mincriterion (Signifikanzniveau): 0.900
- fraction (Bootstrap-Stichprobengröße): 0.632
- replace (mit Zurücklegen): FALSE

## Beantwortung der Forschungsfragen

### Frage 1: Welche Faktoren haben den größten Einfluss auf den SHI?
1. **land_cover** (32.0% Erklärungsbeitrag)
2. **spatial_trend** (26.7% Erklärungsbeitrag)
3. **rain_mmsqm_mean_1995_2024** (18.4% Erklärungsbeitrag)
4. **height_m** (8.9% Erklärungsbeitrag)
5. **temp_c_mean_1995_2024** (5.6% Erklärungsbeitrag)

### Frage 2: Welche Faktoren wirken positiv, welche negativ?
**POSITIVE Effekte (erhöhen den SHI):**
- Höherer Niederschlag → Mehr Wasser für Pflanzen & Bodenbiologie
- Wald/Grünland-Bedeckung → Stabile Bodenstruktur, Humusaufbau
- Temperate Klimazonen (mild, nicht zu trocken)
- Hoher spatial_trend → günstige geografische Lage (z.B. Atlantikküste)

**NEGATIVE Effekte (senken den SHI):**
- Hohe Temperaturen in Trockengebieten
- Niedriger Niederschlag / Trockenheit
- Intensive Ackerbau-Nutzung
- Niedriger spatial_trend → ungünstige geografische Lage (z.B. Mittelmeer)

### Frage 3: Gibt es Interaktionen zwischen den Einflussfaktoren?
JA! Der Entscheidungsbaum zeigt Interaktionen. Neu:
- **spatial_trend × Landnutzung:** In Regionen mit hohem räumlichen Trend kann selbst intensive Landnutzung noch moderate SHI-Werte erzielen.
- **spatial_trend × Niederschlag:** Der räumliche Trend codiert oft implizit Ozeanitäts- und Kontinentalitätsgradienten.

### Frage 4: Gibt es lokale/regionale/klimatische Unterschiede?
JA — jetzt explizit durch spatial_trend sichtbar:
- Die Karte `spatial_trend_gam.png` zeigt den räumlichen Trend direkt.
- Atlantische Westküsten: hoher spatial_trend (günstige Lage)
- Kontinentale / mediterrane Regionen: niedrigerer spatial_trend

## Fazit und Empfehlungen
- **Modellqualität:** ★★★★☆ (4/5)
  OOB R² = 0.3997 — für ökologische Komplexsysteme sehr gut. Mit 'spatial_trend' wird der räumliche Makrogradient explizit modelliert.
- **Zuverlässigkeit:** ★★★★★ (5/5)
  OOB-Validierung: kein Overfitting.
- **Interpretierbarkeit:** ★★★★☆ (4/5)
  Variable Importance und Decision Tree klar interpretierbar. spatial_trend ist zusätzlich über die GAM-Karte visualisierbar.

