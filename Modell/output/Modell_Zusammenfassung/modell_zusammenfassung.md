# Zusammenfassung: Conditional Inference Forest zur Bewertung der Bodengesundheit (SHI)

## Modell-Informationen
- **Modell-Algorithmus:** Conditional Inference Forest (party)
- **Vorteil:** Integrierte Verarbeitung kategorischer Variablen, wodurch kein One-Hot-Encoding nötig ist.
- **Datenpunkte verwendet:** 4426 (nach Ausschluss von seltenen Klassen mit weniger als 30 Beobachtungen)

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
1. **rain_mmsqm_mean_1995_2024** (34.1% Erklärungsbeitrag)
2. **land_cover** (30.9% Erklärungsbeitrag)
3. **temp_c_mean_1995_2024** (12.5% Erklärungsbeitrag)
4. **climate_name** (8.2% Erklärungsbeitrag)
5. **height_m** (8.0% Erklärungsbeitrag)

### Frage 2: Welche Faktoren wirken positiv, welche negativ?
**POSITIVE Effekte die den SHI erhöhen:**
- Höherer Niederschlag → Mehr Wasser für Pflanzen und Bodenbiologie
- Wald und Grünlandbedeckung → Stabile Bodenstruktur, Humusaufbau
- Milde und nicht zu trockene Klimazonen

**NEGATIVE Effekte die den SHI senken:**
- Hohe Temperaturen und Trockenheit
- Niedriger Niederschlag und Trockenheit
- Intensive Ackerbaunutzung

### Frage 3: Gibt es Interaktionen zwischen den Einflussfaktoren?
Ja und zwar zeigt der Entscheidungsbaum Interaktionen. Zum Beispiel ist bei Niederschlag die Relevanz der Landbedeckung in feuchten Gebieten eine andere als in trockenen. Des Weiteren definieren Temperatur und Niederschlag zusammen die wirksamen Klimazonen.

### Frage 4: Gibt es lokale oder regionale Unterschiede?
Ja und zwar sehr deutlich in den Boxplots nach Klimazone.
- Atlantische Westküsten (Cfb) weisen die höchsten SHI-Werte auf.
- Mediterrane & trockene Regionen haben deutlich geringere SHI-Werte.

