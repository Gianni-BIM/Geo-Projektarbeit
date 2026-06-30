# Dokumentation der Eingabedaten für das lat‑long‑Skript

Dieses Dokument beschreibt die Datengrundlage, die für das Random‑Forest‑Modell zur Bewertung der Bodengesundheit (SHI) im Projekt **`cforest_shi_latlong.rmd`** genutzt wird.

## 1. Was sind das für Daten und warum brauchen wir sie?
Die Daten bestehen aus räumlichen Stichproben (Punkten in Europa), für die verschiedene Umwelt‑, Landnutzungs‑ und Klimaparameter sowie der "Soil Health Index" (SHI) erfasst wurden. Wir benötigen diese Daten, um ein maschinelles Lernmodell (Random Forest) zu trainieren. Das Modell soll herausfinden, welche Umweltfaktoren die Bodengesundheit am stärksten beeinflussen und wie diese zusammenhängen.

## 2. Woher haben wir die Daten?
Die Rohdaten stammen typischerweise aus Geodaten‑Quellen und globalen Klimamodellen (unter anderem Köppen‑Geiger‑Klimaklassifikationen und Wetterdaten für den Zeitraum 1995–2024). Diese Werte wurden in Vorverarbeitungsschritten (meist über GIS‑Software) exakt an den Stichprobenkoordinaten (Points) extrahiert und in einer Tabelle zusammengeführt.

## 3. Wie sehen die Daten aus und wie sind sie aufgebaut?
Die Hauptdaten liegen in einer klassischen Tabelle im CSV‑Format vor (`input/Daten/points.csv`). Jeder Datensatz (jede Zeile) repräsentiert einen spezifischen geografischen Punkt und enthält Spalten für Koordinaten, die Umweltfaktoren und die zugehörige Zielgröße.

Zusätzlich gibt es eine Datei `input/Daten/legend.txt`, die als Übersetzungsdatei dient. Sie wird genutzt, um die rein numerischen Klima‑Codes der Köppen‑Geiger‑Klassifikation in lesbare Text‑Kategorien (z. B. "Tropical, rainforest") umzuwandeln.

## 4. Welche Attribute sind für uns wichtig?
Das Skript nutzt nicht pauschal alle Felder der CSV‑Datei. Die Variablen werden in drei Gruppen unterteilt:

**1. Ausgeschlossene (irrelevante) Felder:**
- `POINT_ID`, `X`, `Y`, `lon_x`, `lat_y` – reine Identifikatoren und Koordinaten, die das Modell nicht lernen soll.

**2. Wichtige Eingabefeatures (Einflussfaktoren):**
- `land_use` – Art der Landnutzung (z. B. Forestry, Agriculture, Fallow land).
- `land_cover` – Physische Landbedeckung (Woodland, Cropland, Grassland …).
- `kg_climate_class` (übersetzt zu `climate_name`) – Köppen‑Geiger‑Klimazone.
- `height_m` – Topografische Höhe in Metern.
- `temp_c_mean_1995_2024` – Mittlere Temperatur (°C) für 1995‑2024.
- `rain_mmsqm_mean_1995_2024` – Mittlerer Niederschlag (mm/m²) für 1995‑2024.

**3. Zielvariable (Target):**
- `SHI` – Soil Health Index, das zu prognostizierende Ergebnis.

## 5. Gegeben
- Koordinaten der Stichproben (für den räumlichen GAM‑Trend, erzeugt das Feature `spatial_trend`).
- Topografische Höhe (`height_m`).
- Mittlere Temperatur (`temp_c_mean_1995_2024`).
- Mittlerer Niederschlag (`rain_mmsqm_mean_1995_2024`).
- Landnutzung & Landbedeckung (`land_use`, `land_cover`).
- Klimaklassifikation (`kg_climate_class` → `climate_name`).
- `spatial_trend` – numerisches Feature aus dem GAM‑Modell, das räumliche Muster im SHI codiert.

## 6. Gesucht
- Vorhersage des **Soil Health Index (SHI)**.
- Quantitative Einschätzung, welche Parameter den größten Einfluss haben (Variable Importance).
- Datengetriebenes Regelwerk (Entscheidungsbaum/Random Forest), das nicht‑lineare Wechselwirkungen zwischen Klima, Geografie und Landnutzung aufdeckt.

## 7. Variablenlegende (Wertebereiche)

| Variable | Bezeichnung | Typ | Wertebereich |
|----------|-------------|-----|--------------|
| `SHI` | Bodengesundheit (SHI) | numerisch | ca. 1.5 – 4.5 |
| `height_m` | Höhe (m) | numerisch | 0 – ca. 2800 |
| `temp_c_mean_1995_2024` | Temperatur (°C) | numerisch | ca. -2.0 – 20.0 |
| `rain_mmsqm_mean_1995_2024` | Niederschlag (mm) | numerisch | ca. 200 – 2500 |
| `land_use` | Landnutzung | Faktor (4 Stufen) | Agriculture, Fallow land, Forestry, Semi-natural |
| `land_cover` | Landbedeckung | Faktor (5 Stufen) | Bareland, Cropland, Grassland, Shrubland, Woodland |
| `climate_name` | Klimazone | Faktor (7 Stufen) | z. B. Cfb, Cfa, Dfb, Dfa, Csb, Csa, BSk |
| `spatial_trend` | Räumlicher Trend (GAM) | numerisch | ca. 2.6 – 3.9 |

> **Hinweis:** `spatial_trend` wird zur Laufzeit durch ein GAM‑Modell (`mgcv::gam(SHI ~ s(lon_x, lat_y, bs='tp', k=30))`) erzeugt und ist nicht in der CSV‑Datei enthalten. Die exakten Wertebereiche können je nach Datensatz leicht variieren.

## 8. Was muss mit den Daten gemacht werden? (Vorverarbeitung)
1. **Spalten‑Bereinigung** – Entfernen der reinen Koordinaten‑ und ID‑Spalten.
2. **Klimaklassen‑Mapping** – Numerische IDs (`kg_climate_class`) werden mittels `legend.txt` in lesbare Textbeschreibungen übersetzt.
3. **GAM‑Feature‑Engineering** – Koordinaten (lon/lat) werden über einen 2D‑Thin‑Plate‑Spline zu `spatial_trend` verarbeitet.
4. **Kategorien filtern (Hobley‑Regel)** – Kategorien mit weniger als 30 Beobachtungen werden ausgeschlossen, um statistisch belastbare Modelle zu gewährleisten.
5. **Faktorisierung** – Kategorische Variablen werden in R als `factor` gekennzeichnet, sodass das `party`‑Paket sie nativ verarbeiten kann.

---

*Dieses Dokument liegt im Ordner `Dokumentation/` und wird zusammen mit den erzeugten PNG‑Grafiken und der Markdown‑Modell‑Zusammenfassung (`model_summary.md`) in das Git‑Repository gepusht.*
