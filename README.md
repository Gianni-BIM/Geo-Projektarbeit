# Analyse der Einflussfaktoren auf den Soil Health Index mittels Conditional Inference Forest

---

## Inhaltsverzeichnis

* [Projektübersicht](#projektübersicht)
* [Projektziele](#projektziele)
* [Projektstruktur](#projektstruktur)
* [Datengrundlage](#datengrundlage)
* [Datenaufbereitung](#datenaufbereitung)
* [Machine-Learning-Ansatz](#machine-learning-ansatz)
* [Modellierung](#modellierung)
* [Modellbewertung](#modellbewertung)
* [Ergebnisse](#ergebnisse)
* [Ergebnisse und Abbildungen](#ergebnisse-und-abbildungen)
* [Workflow](#workflow)
* [Einschränkungen](#einschränkungen)
* [Verwendete Technologien](#verwendete-technologien)
* [Autorinnen und Autoren](#autorinnen-und-autoren)

---

# Projektübersicht

Die Bodengesundheit ist ein zentraler Indikator für die Funktionsfähigkeit von Ökosystemen, die landwirtschaftliche Produktivität und die nachhaltige Nutzung natürlicher Ressourcen. Ziel dieses Projekts ist die Analyse von Umweltfaktoren, die den **Soil Health Index (SHI)** beeinflussen.

Zur Untersuchung der Zusammenhänge wird ein **Conditional Inference Forest (cForest)** eingesetzt, eine erweiterte Form des Random-Forest-Algorithmus. Das Modell ermöglicht die Identifikation wichtiger Einflussgrößen sowie die Analyse komplexer, nichtlinearer Beziehungen zwischen Umweltvariablen und Bodengesundheit.

### Forschungsfrage

> Welche Umweltfaktoren beeinflussen den Soil Health Index (SHI), wie stark wirken sie und welche Wechselwirkungen bestehen zwischen ihnen?

---

# Projektziele

* Identifikation der wichtigsten Einflussfaktoren auf die Bodengesundheit
* Quantifizierung des Einflusses von Klima-, Landnutzungs- und Topographievariablen
* Untersuchung nichtlinearer Zusammenhänge und Interaktionen
* Bewertung der Vorhersageleistung von Machine-Learning-Modellen
* Interpretation der Ergebnisse im Kontext räumlicher Umweltprozesse

---

# Projektstruktur

```text
Geo-Projektarbeit/
│
├── finalize_data_prep/      # Datenaufbereitung
├── ML-rf-Ioannis/           # Skripte für Modellierung und Auswertung
├── WebAnwendung/            # Ergebnisse, Abbildungen und Karte
└── README.md
```

---

# Datengrundlage

Für die Analyse wurden verschiedene Umwelt- und Geodatenquellen zusammengeführt.

## Zielvariable

| Variable | Beschreibung      |
| -------- | ----------------- |
| SHI      | Soil Health Index |

## Einflussvariablen

| Variable                  | Beschreibung                |
| ------------------------- | --------------------------- |
| rain_mmsqm_mean_1995_2024 | Mittlerer Niederschlag      |
| temp_c_mean               | Mittlere Temperatur         |
| height_m                  | Höhe über dem Meeresspiegel |
| land_use                  | Landnutzung                 |
| land_cover                | Landbedeckung               |
| climate_name              | Klimazone                   |

---

# Datenaufbereitung

Die Datenaufbereitung bildet die Grundlage der Analyse und umfasst folgende Arbeitsschritte:

* Zusammenführung verschiedener Datensätze
* Entfernung von Identifikations- und Koordinatenfeldern
* Behandlung fehlender Werte
* Erkennung und Bereinigung von Ausreißern
* Filterung seltener Kategorien (weniger als 30 Beobachtungen)
* Umwandlung kategorialer Variablen in Faktoren
* Erstellung eines konsistenten Datensatzes für das Machine Learning

### Ergebnis

> Ein bereinigter und modellfähiger Datensatz für die weitere Analyse.

---

# Machine-Learning-Ansatz

Für die Modellierung wird ein **Conditional Inference Forest (cForest)** verwendet.

Im Vergleich zu klassischen Random-Forest-Modellen bietet dieser Ansatz mehrere Vorteile:

* Reduzierung von Verzerrungen bei der Variablenauswahl
* Nutzung statistisch signifikanter Splits
* Erkennung komplexer und nichtlinearer Zusammenhänge
* Berücksichtigung von Interaktionen zwischen Variablen
* Interpretation der Bedeutung einzelner Einflussgrößen

---

# Modellierung

## Ziel des Modells

Das Modell beschreibt den Zusammenhang zwischen Bodengesundheit und Umweltbedingungen:

```text
SHI = f(Klima, Landnutzung, Landbedeckung, Höhe, ...)
```

> Das Ziel des Modells ist nicht die Identifikation der „besten Böden“, sondern die Erklärung von Unterschieden im Soil Health Index.

## Hyperparameter

| Parameter    | Beschreibung                       |
| ------------ | ---------------------------------- |
| ntree        | Anzahl der Bäume                   |
| mtry         | Anzahl der Variablen pro Split     |
| mincriterion | Signifikanzniveau für Aufteilungen |

## Optimierung

Zur Verbesserung der Modellleistung wurde eine Grid Search über verschiedene Parameterkombinationen durchgeführt.

Die Ergebnisse werden gespeichert unter:

```text
output/parameter_grid_results.csv
```

---

# Modellbewertung

Die Bewertung erfolgt mithilfe folgender Kennzahlen:

## Out-of-Bag R² (OOB-R²)

Maß für die erklärte Varianz des Modells.

## Root Mean Squared Error (RMSE)

Maß für den durchschnittlichen Vorhersagefehler.

## Observed vs. Predicted

Vergleich zwischen beobachteten und vorhergesagten SHI-Werten zur Beurteilung der Modellgüte.

---

# Ergebnisse

Das Modell liefert Informationen zu:

* der Bedeutung einzelner Einflussfaktoren
* Zusammenhängen zwischen Umweltvariablen
* Interaktionen zwischen Klima und Landnutzung
* Verteilungsmustern des Soil Health Index

## Zentrale Erkenntnisse

* Der Niederschlag stellt den stärksten Einflussfaktor auf den SHI dar.
* Landnutzungsformen beeinflussen die Bodengesundheit auf lokaler Ebene.
* Klimatische Bedingungen erklären einen großen Teil der SHI-Variation.
* Die Wechselwirkungen mehrerer Umweltfaktoren sind entscheidend für die Ausprägung der Bodengesundheit.

---

# Ergebnisse und Abbildungen

Im Verzeichnis `output/` werden die wichtigsten Resultate gespeichert:

```text
feature_importance.png
correlation_matrix.png
shi_by_climate.png
observed_vs_predicted.png
decision_tree.png
model_summary.txt
parameter_grid_results.csv
```

---

# Workflow

```text
Rohdaten
    │
    ▼
Datenaufbereitung
    │
    ▼
Explorative Analyse (EDA)
    │
    ▼
Training des cForest-Modells
    │
    ▼
Hyperparameter-Optimierung
    │
    ▼
Modellbewertung
    │
    ▼
Interpretation der Ergebnisse
```

---

# Einschränkungen

* Das Modell beschreibt statistische Zusammenhänge, keine Kausalitäten.
* Relevante Bodenparameter wie Bodenchemie oder Bodenstruktur sind nicht enthalten.
* Räumliche Autokorrelation wird nicht explizit berücksichtigt.
* Die Aussagekraft hängt von Qualität und Vollständigkeit der Eingangsdaten ab.

---

# Verwendete Technologien

* R
* tidyverse
* ggplot2
* partykit
* cForest
* GIS-basierte Umwelt- und Geodaten

---

# Autorinnen und Autoren

* Ivonne Giske
* Nora König
* Sina Philipowski
* Yannick Trog
* Ioannis Svolos

---

**Berliner Hochschule für Technik (BHT)**

Geo-Projektarbeit
