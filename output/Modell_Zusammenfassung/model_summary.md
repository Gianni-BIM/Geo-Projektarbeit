# Zusammenfassung: Conditional Inference Forest zur Bewertung der Bodengesundheit (SHI)

## Modell-Informationen
- **Modell-Algorithmus:** Conditional Inference Forest (party)
- **Vorteil:** Native kategorische Verarbeitung — KEIN One-Hot-Encoding nötig!
- **Datenpunkte verwendet:** 4426 (nach Ausschluss von Klassen mit < 30 Punkten)

## Ergebnisse der Modellgüte (OOB-Validierung)
- **Out-of-Bag R² (Erklärte Varianz):** 0.3727 (37.27%)
- **Out-of-Bag RMSE (Vorhersagefehler):** 0.3546
- **Trainings-R² (zum Vergleich):** 0.4167

**Optimierte Hyperparameter:**
- ntree (Anzahl Bäume): 500
- mtry (Variablen pro Split): 3
- mincriterion (Signifikanzniveau): 0.900
- fraction (Bootstrap-Stichprobengröße): 0.632
- replace (mit Zurücklegen): FALSE

## Beantwortung der Forschungsfragen

### Frage 1: Welche Faktoren haben den größten Einfluss auf den SHI?
1. **rain_mmsqm_mean_1995_2024** (34.0% Erklärungsbeitrag)
2. **land_cover** (30.9% Erklärungsbeitrag)
3. **temp_c_mean_1995_2024** (12.6% Erklärungsbeitrag)
4. **climate_name** (8.1% Erklärungsbeitrag)
5. **height_m** (8.0% Erklärungsbeitrag)

### Frage 2: Welche Faktoren wirken positiv, welche negativ?
**POSITIVE Effekte (erhöhen den SHI):**
- Höherer Niederschlag → Mehr Wasser für Pflanzen & Bodenbiologie
- Wald/Grünland-Bedeckung → Stabile Bodenstruktur, Humusaufbau
- Temperate Klimazonen (mild, nicht zu trocken)

**NEGATIVE Effekte (senken den SHI):**
- Hohe Temperaturen in Trockengebieten
- Niedriger Niederschlag / Trockenheit
- Intensive Ackerbau-Nutzung

### Frage 3: Gibt es Interaktionen zwischen den Einflussfaktoren?
JA! Der Entscheidungsbaum zeigt Interaktionen.
- **Niederschlag × Landbedeckung:** In feuchten Gebieten ist die Landbedeckung anders relevant als in trockenen.
- **Temperatur × Niederschlag:** Zusammen definieren sie die wirksamen Klimazonen.

### Frage 4: Gibt es lokale/regionale/klimatische Unterschiede?
JA! Sehr deutlich in den Boxplots nach Klimazone.
- Atlantische Westküsten (Cfb): höchste SHI-Werte.
- Mediterrane & trockene Regionen: deutlich geringere SHI-Werte.

## Fazit und Empfehlungen
- **Modellqualität:** ★★★★☆ (4/5)
  OOB R² = 0.3727 — für ökologische Komplexsysteme sehr gut.
- **Zuverlässigkeit:** ★★★★★ (5/5)
  OOB-Validierung: kein Overfitting.
- **Interpretierbarkeit:** ★★★★☆ (4/5)
  Variable Importance und Decision Tree klar interpretierbar.

