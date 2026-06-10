# Dokumentation der Eingabedaten

Dieses Dokument beschreibt die Datengrundlage, die für das Random-Forest-Modell zur Bewertung der Bodengesundheit (SHI) im Projekt genutzt wird.

## 1. Was sind das für Daten und warum brauchen wir sie?
Die Daten bestehen aus räumlichen Stichproben (Punkten in Europa), für die verschiedene Umwelt-, Landnutzungs- und Klimaparameter sowie der "Soil Health Index" (SHI) erfasst wurden.
Wir benötigen diese Daten, um ein maschinelles Lernmodell (Random Forest) zu trainieren. Das Modell soll herausfinden, welche Umweltfaktoren die Bodengesundheit am stärksten beeinflussen und wie diese zusammenhängen.

## 2. Woher haben wir die Daten?
Die Rohdaten stammen typischerweise aus Geodaten-Quellen und globalen Klimamodellen (unter anderem Köppen-Geiger-Klimaklassifikationen und Wetterdaten für den Zeitraum 1995–2024). Diese Werte wurden in Vorverarbeitungsschritten (meist über GIS-Software) exakt an den Stichprobenkoordinaten (Points) extrahiert und in einer Tabelle zusammengeführt.

## 3. Wie sehen die Daten aus und wie sind sie aufgebaut?
Die Hauptdaten liegen in einer klassischen Tabelle im CSV-Format vor (`input/Daten/points.csv`). Jeder Datensatz (jede Zeile) repräsentiert einen spezifischen geografischen Punkt und enthält Spalten für Koordinaten, die Umweltfaktoren und die zugehörige Zielgröße. 

Zusätzlich gibt es eine Datei `input/Daten/legend.txt`, die als Übersetzungsdatei dient. Sie wird genutzt, um die rein numerischen Klima-Codes der Köppen-Geiger-Klassifikation in lesbare Text-Kategorien (z. B. "Tropical, rainforest") umzuwandeln.

## 4. Welche Attribute sind für uns wichtig?
Das Skript nutzt nicht pauschal alle Felder der CSV-Datei. Die Variablen werden in drei Gruppen unterteilt:

**1. Ausgeschlossene (irrelevante) Felder:**
- `POINT_ID`, `X`, `Y`, `lon_x`, `lat_y`: Identifikatoren und reine Koordinaten. Diese werden explizit entfernt, damit das Modell nicht anfängt, die simplen "Orte" auswendig zu lernen, anstatt die echten physikalischen und ökologischen Parameter für seine Regeln zu nutzen.

**2. Wichtige Eingabefeatures (Einflussfaktoren):**
- `land_use`: Die Art der Landnutzung (z. B. Forestry, Agriculture, Fallow land).
- `land_cover`: Die Art der physischen Landbedeckung (z. B. Woodland, Cropland, Grassland).
- `kg_climate_class` (wird per Legend-Datei in `climate_name` übersetzt): Die Köppen-Geiger-Klimazone des jeweiligen Punktes.
- `height_m`: Die topografische Höhe in Metern.
- `temp_c_mean_1995_2024`: Die mittlere Temperatur in °C (für den Zeitraum 1995 bis 2024).
- `rain_mmsqm_mean_1995_2024`: Der mittlere Niederschlag in mm/m² (für den Zeitraum 1995 bis 2024).

**3. Zielvariable (Target):**
- `SHI`: Der Soil Health Index (Bodengesundheits-Index). Dies ist der Wert, den wir analysieren und den das Modell vorhersagen soll.

## 5. Was muss mit den Daten gemacht werden? (Vorverarbeitung)
Bevor das Modell effektiv trainiert werden kann, führt das Skript folgende Schritte automatisch aus:
1. **Spalten-Bereinigung**: Die oben genannten reinen Koordinaten- und ID-Spalten werden aus den Trainingsdaten gestrichen.
2. **Klimaklassen-Mapping**: Die numerischen IDs für `kg_climate_class` werden mithilfe der `legend.txt` in verständliche Textbeschreibungen übersetzt.
3. **Kategorien filtern (Hobley-Regel)**: Kategorien von Landnutzung, Landbedeckung oder Klimazonen, die für weniger als 30 Punkte im Datensatz vorkommen, werden komplett ausgeschlossen. Dies ist wichtig, da das Modell für extrem seltene Kategorien (Ausreißer) keine statistisch belastbaren Regeln ableiten kann.
4. **Faktorisierung**: Kategorische Variablen (Texte/Namen) werden in R direkt als sogenannte "Faktoren" gekennzeichnet. Das erspart uns mühsames One-Hot-Encoding. Das verwendete R-Paket `party` kann nativ mit diesen kategorialen Gruppen umgehen, wodurch die natürliche Struktur der Daten erhalten bleibt.
