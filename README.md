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
├── ML-rf-Ioannis/           # Skripte für Modellierung und Auswertung mit Random Forest
├── ML-gdb-Sina/             # Skripte für Modellierung und Auswertung mit Gradient Boosting
├── WebAnwendung/            # Ergebnisse, Abbildungen und Karte
└── README.md
```

---

# Datengrundlage

Für die Analyse wurden verschiedene Umwelt- und Geodatenquellen in ganz Europa zusammengeführt.

## Zielvariable

| Variable | Beschreibung      |
| -------- | ----------------- |
| SHI      | Soil Health Index |

## Einflussvariablen

| Variable                  | Beschreibung                                              |
| ------------------------- | --------------------------------------------------------- |
| rain_mmsqm_mean_1995_2024 | Mittlerer Niederschlag (mm)                               |
| temp_c_mean_1995_2024     | Mittlere Temperatur (°C)                                  |
| height_m                  | Topografische Höhe über dem Meeresspiegel (m)             |
| land_use                  | Landnutzung (kategorisch)                                 |
| land_cover                | Landbedeckung (kategorisch)                               |
| climate_name              | Köppen-Geiger Klimazone (kategorisch)                     |
| spatial_trend             | Räumlicher Hintergrundtrend (per GAM aus Koordinaten)     |

---

# Datenaufbereitung

Die Datenaufbereitung bildet die Grundlage der Analyse und umfasst folgende Arbeitsschritte:

* Zusammenführung verschiedener Datensätze
* Entfernung von reinen Identifikationsfeldern
* Umwandlung der numerischen Klima-Klassen-IDs in lesbare Textbeschreibungen (`climate_name`)
* **Feature Engineering:** Berechnung des neuen Features `spatial_trend` aus den Geokoordinaten (Längen- und Breitengrad) mittels eines verallgemeinerten additiven Modells (GAM Thin-Plate-Spline)
* Filterung seltener Kategorien nach der Hobley-Regel (weniger als 30 Beobachtungen werden ausgeschlossen)
* Umwandlung kategorialer Variablen in R-Faktoren (native Verarbeitung ohne One-Hot-Encoding!)

### Ergebnis

> Ein bereinigter, um räumliche Trends angereicherter und modellfähiger Datensatz für die weitere Analyse.

---

# Machine-Learning-Ansatz

Für die Modellierung wird ein **Conditional Inference Forest (cForest)** aus dem R-Paket `party` verwendet.

Im Vergleich zu klassischen Random-Forest-Modellen bietet dieser Ansatz entscheidende Vorteile:

* Unvoreingenommene Auswahl von Split-Variablen (keine Bevorzugung von Faktoren mit vielen Stufen)
* Nutzung statistisch signifikanter Hypothesentests (p-Werte) für das Splitting
* **Native Verarbeitung kategorialer Daten:** Der Algorithmus kann Gruppen direkt spalten (z.B. `{Wald, Grasland}` vs. `{Ackerbau, Urban}`), ohne dass Kategorien aufwendig in binäre Dummy-Variablen übersetzt werden müssen
* Erkennung komplexer, nichtlinearer Zusammenhänge und Interaktionen
* Zuverlässige, permutationsbasierte Interpretation der Variable Importance

---

# Modellierung

## Ziel des Modells

Das Modell beschreibt den komplexen Zusammenhang zwischen Bodengesundheit und Umweltbedingungen:

```text
SHI = f(Klima, Landnutzung, Landbedeckung, Topografie, Räumlicher Trend)
```

> Das Ziel des Modells ist nicht die Identifikation der „besten Böden“, sondern die Erklärung von Unterschieden im Soil Health Index.

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

Das Modell liefert konkrete, datengetriebene Informationen zu:

* der prozentualen Wichtigkeit einzelner Einflussfaktoren auf die Bodengesundheit (Variable Importance)
* komplexen Interaktionen zwischen geografischer Lage, Klima und Landnutzung
* den spezifischen Mustern, unter denen der Soil Health Index (SHI) steigt oder fällt
* dem Einfluss großräumiger Hintergrundtrends, isoliert von lokalen Gegebenheiten

## Zentrale Erkenntnisse 

* **Der räumliche Makrotrend und die Landbedeckung sind die stärksten Treiber:** Im erweiterten Modell erklären die geografische Lage (`spatial_trend`, ~27%) und die direkte Form der Landbedeckung (~32%) die meiste Variation im SHI, noch vor dem reinen Niederschlag.
* **Positive Effekte durch Feuchtigkeit und Naturbelassenheit:** Dauerhaft waldbedeckte Flächen (Forstwirtschaft) und naturnahes Grasland in gemäßigten, feuchten Klimazonen (z.B. Atlantikküste) maximieren die Bodengesundheit.
* **Negative Effekte durch Intensivnutzung und Trockenheit:** Intensive Ackerbaunutzung sowie trockene, heiße Bedingungen senken den SHI nachweislich. Der SHI verringert sich drastisch in mediterranen und kontinental trockenen Gebieten.
* **Starke Wechselwirkungen (Interaktionen):** Die Entscheidungsbäume beweisen, dass die Faktoren nicht isoliert wirken. So mildert beispielsweise eine allgemein günstige (feuchte) geografische Lage die negativen Effekte intensiver Landwirtschaft zum Teil spürbar ab, während Ackerbau in Trockengebieten extrem bodenschädigend wirkt.
* **Gute Modellgüte:** Das Modell erklärt ca. 40 % der realen Varianz des SHI. Für komplexe ökologische Daten (bei denen Aspekte wie Bodenbiologie oder Geologie im Datensatz fehlen) ist dies ein ausgezeichneter und hochsignifikanter Wert.


---

# Workflow

```text
Rohdaten (inkl. Koordinaten Lat/Long)
    │
    ▼
Datenaufbereitung (Filtern, Faktoren bilden)
    │
    ▼
Feature Engineering (GAM-Modell berechnet räumlichen Trend "spatial_trend")
    │
    ▼
Explorative Analyse (EDA) (Prüfung von Korrelationen inkl. spatial_trend)
    │
    ▼
Hyperparameter-Optimierung (Grid Search für mtry & mincriterion)
    │
    ▼
Training des cForest-Modells (Umweltfaktoren + spatial_trend)
    │
    ▼
Modellbewertung (OOB R², RMSE, Vorhersagegüte & Residuen)
    │
    ▼
Interpretation der Ergebnisse (Variable Importance, Entscheidungsbaum)

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
