# Geo-Projektarbeit – Soil Health Index (SHI) & Machine Learning

## Projektübersicht

In diesem Projekt wird der **Soil Health Index (SHI)** mithilfe von
**Machine Learning (Random Forest)** modelliert und analysiert.

Ziel ist es, zu untersuchen:

> **Welche Umweltfaktoren beeinflussen die Bodengesundheit (SHI), wie stark und auf welche Weise?**

Dabei werden verschiedene Einflussgrößen wie **Klima, Landnutzung und Topographie**
kombiniert, um komplexe Zusammenhänge zu identifizieren.

---

## Projektstruktur

Geo-Projektarbeit/
│
├── data-prep/        # Aufbereitung der Rohdaten
├── src/              # Machine Learning (Random Forest)
├── output/           # Ergebnisse & Plots
├── input-ml/         # Eingabedaten für ML
├── README.md

---

## 1. Data Preparation (data-prep)

Die Datenaufbereitung ist der **erste und entscheidende Schritt** im Projekt.

### Aufgaben:
- Zusammenführen verschiedener Datensätze (SHI, Klima, Landnutzung etc.)
- Entfernen irrelevanter Variablen (IDs, Koordinaten)
- Bereinigung von Daten (fehlende Werte, Ausreißer)
- Filterung kleiner Kategorien (<30 Beobachtungen, Hobley-Regel)
- Umwandlung von Variablen in geeignete Formate (Faktoren)

### Ergebnis:
→ Ein konsistenter Datensatz für das Machine Learning Modell  

---

## 2. Machine Learning (src)

Der Machine Learning Teil basiert auf einem:

> **Conditional Inference Forest (cforest)**

### Warum dieser Algorithmus?

- basiert auf Random Forest
- vermeidet Bias bei Variablen
- nutzt statistisch signifikante Splits
- erkennt **nichtlineare Zusammenhänge und Interaktionen**

---

## Modellziel

Das Modell beschreibt:
SHI = f(Klima, Landnutzung, Höhe, etc.)

-  Zielvariable:
  - `SHI` (Soil Health Index)

-  Einflussvariablen:
  - Niederschlag (`rain_mmsqm_mean_1995_2024`)
  - Temperatur (`temp_c_mean`)
  - Höhe (`height_m`)
  - Landnutzung (`land_use`)
  - Landbedeckung (`land_cover`)
  - Klimazone (`climate_name`)

---

##  Modellansatz

Der Random Forest:

- erstellt viele Entscheidungsbäume
- nutzt **Bootstrapping (zufällige Stichproben)**
- wählt zufällig Variablen pro Split (`mtry`)
- minimiert Varianz innerhalb von Gruppen

 WICHTIG:
> Das Modell sucht **nicht die besten Böden**,  
> sondern erklärt Unterschiede im SHI.

---

##  Modelltraining & Optimierung

### Hyperparameter:
- `ntree` → Anzahl der Bäume (z. B. 500)
- `mtry` → Anzahl Variablen pro Split
- `mincriterion` → Signifikanzniveau

### Optimierung:
→ Grid Search über verschiedene Parameterkombinationen

Ergebnisse gespeichert in:
output/parameter_grid_results.csv

---

##  Modellbewertung

Zur Bewertung werden verwendet:

-  **Out-of-Bag (OOB) R²**
  → erklärte Varianz

-  **RMSE**
  → Vorhersagefehler

-  **Observed vs Predicted Plot**
  → Vergleich Modell vs Realität

---

##  Ergebnisse

Das Modell liefert:

-  Feature Importance (wichtigste Faktoren)
-  Entscheidungsbaum (Interpretation)
-  Verteilungsanalysen (Boxplots)
-  Interaktionen zwischen Variablen

### Beispiel:

- Niederschlag = stärkster Einflussfaktor
- Landnutzung beeinflusst SHI lokal
- Kombinationen (z. B. Regen + Nutzung) sind entscheidend

---

##  Output

Im Ordner `output/` befinden sich:

-  `feature_importance.png`
-  `correlation_matrix.png`
-  `shi_by_climate.png`
-  `observed_vs_predicted.png`
-  `decision_tree.png`
-  `model_summary.txt`

---

##  Workflow

1. Datenaufbereitung (`data-prep`)
2. Explorative Analyse (EDA)
3. Modelltraining (Random Forest)
4. Hyperparameter-Optimierung
5. Evaluation (OOB)
6. Interpretation & Data Mining

---

##  Einschränkungen

- Modell zeigt **keine Kausalität**, sondern statistische Zusammenhänge
- wichtige Variablen (z. B. Bodenchemie) fehlen
- räumliche Effekte sind nicht direkt modelliert

---

##  Fazit

Das Projekt zeigt:

- Klima ist der wichtigste Einflussfaktor für SHI
- Landnutzung beeinflusst Bodenqualität lokal
- Random Forest ist geeignet, um komplexe Umweltzusammenhänge zu analysieren

---

##  Autoren

Ivonne Giske, Nora König, Sina Philipowski, Yannick Trog & Ioannis Svolos
Projekt im Rahmen der Geo-Projektarbeit  
Berliner Hochschule für Technik Berlin



