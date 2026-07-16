# Geoprojektarbeit: Bewertung der Bodengesundheit mittels Machine Learning

## Projektbeschreibung

Dieses Repository enthält die Ergebnisse, Datengrundlagen und Machine-Learning-Modelle unserer Geoprojektarbeit zur Bewertung der **Bodengesundheit (Soil Health Index, SHI)** in Europa.

Ziel der Arbeit ist die Untersuchung des Einflusses verschiedener Umweltfaktoren auf die Bodengesundheit. Dabei werden insbesondere folgende Einflussgrößen betrachtet:

- Klima
- Topografie
- Landnutzung und Landbedeckung

---

## Forschungsfrage

> **Wie beeinflussen Klima, Topografie, Landnutzung und -bedeckung sowie die räumliche Lage ein Set komplementärer Bodengesundheitsindikatoren, abgebildet über den Soil Health Index (SHI), in Europa, und welche Wechselwirkungen zwischen diesen Einflussfaktoren prägen die Bodengesundheit am stärksten?**

---

## Projektstruktur

Das Projekt ist in drei Hauptbereiche gegliedert, die jeweils in eigenen Branches entwickelt wurden.

| Branch / Ordner | Inhalt |
|-----------------|--------|
|  **`finalize_data_prep/`** | Finale Datenaufbereitung, Bereinigung und Vorverarbeitung der Datensätze |
|  **`ML-rf-Ioannis/`** | Modellierung mittels **Random Forest** bzw. **Conditional Inference Forest** einschließlich Skripten, Ergebnissen und Modellzusammenfassungen |
|  **`ML-gbm-Sina/`** | Modellierung mittels **Gradient Boosting Machines (GBM)** einschließlich Code, Auswertungen und Visualisierungen |

---

##  Workflow

```text
Rohdaten
    │
    ▼
Datenaufbereitung
    │
    ├──────────────┐
    ▼              ▼
Random Forest     GBM
    │              │
    └──────┬───────┘
           ▼
  Modellvergleich &
 Interpretation des
 Soil Health Index
```

---

## Ziel

Die entwickelten Modelle sollen

- den **Soil Health Index (SHI)** vorhersagen
- die wichtigsten Einflussfaktoren identifizieren
- Wechselwirkungen zwischen Umweltvariablen aufzeigen und
- zu einem besseren Verständnis der Bodengesundheit in Europa beitragen.

---

## Projektteam

- **Ioannis Svolos**
- **Sina Philipowski**
- **Ivonne Giske**
- **Nora König**
- **Yannick Trog**

---
