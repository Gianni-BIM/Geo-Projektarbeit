# Random Forest zur Bodengesundheit (SHI)

Dieses Repository enthält ein R-Skript zur Modellierung und Analyse des Soil Health Index (SHI) mithilfe eines Random-Forest-Modells (Conditional Inference Forest). Das Projekt analysiert den Einfluss verschiedener Umweltfaktoren (wie Niederschlag, Temperatur und Landnutzung) auf die Bodengesundheit in Europa.

## 1. Setup & Ausführung

Diese Anleitung erklärt Schritt für Schritt, wie das R-Skript zur Auswertung der Bodengesundheitsdaten ausgeführt wird.

### Voraussetzungen
- Ein Code-Editor (z. B. **VS Code**, **Antigravity** oder RStudio) ist installiert.
- **R** ist auf dem System installiert.
- (Optional, aber empfohlen) **Git** ist installiert.

### Projekt vorbereiten
1. Öffne ein Terminal (oder die integrierte Konsole in deinem Editor).
2. Klone das Repository mit dem korrekten GitHub-Link auf deinen Computer:
   ```bash
   git clone https://github.com/Gianni-BIM/Geo-Projektarbeit.git
   ```
3. Wechsle in den Projektordner und aktiviere den Entwicklungs-Branch `ML-rf-Ioannis`:
   ```bash
   cd Geo-Projektarbeit
   git checkout ML-rf-Ioannis
   ```
4. Wechsle nun in das spezifische Unterverzeichnis für dieses R-Modell:
   ```bash
   cd RandomForest_R
   ```
5. Öffne dieses Verzeichnis in deinem Editor (z. B. VS Code).

### R-Pakete installieren
Das Skript benötigt einige externe R-Pakete. Öffne R (oder die R-Konsole in deinem Editor) und führe folgenden Befehl aus, falls die Pakete noch nicht installiert sind:
```R
install.packages(c("party", "ggplot2", "reshape2", "gridExtra", "partykit"))
```

### Skript ausführen
Führe das Hauptskript `random_forest_shi.R` aus. Das geht entweder direkt im Terminal:
```bash
Rscript random_forest_shi.R
```
Oder indem du das Skript in RStudio/VS Code öffnest und ausführen lässt (via "Run" oder "Source").

### Ergebnisse ansehen
Sobald das Skript durchgelaufen ist, findest du alle generierten Auswertungen im Ordner `output`:
- **`output/Grafiken_png/`**: Originalgrafiken mit englischen Datenbank-Bezeichnern.
- **`output/Grafiken_png/Grafik_mit_Beschriftung/`**: Grafiken mit verständlicheren, deutschen Achsenbeschriftungen.
- **`output/Modell_Zusammenfassung/`**: Text- und CSV-Dateien (z. B. detaillierte `model_summary.txt` und `parameter_grid_results.csv`).

---

## 2. Projektzusammenfassung

Das Projekt nutzt einen **Conditional Inference Forest (cforest)**, um die Bodengesundheit (SHI) anhand von sechs Hauptfaktoren vorherzusagen: Niederschlag, Temperatur, topografische Höhe, Landnutzung, Landbedeckung und Klimazone. Das Modell erklärt im Schnitt rund 37-40 % der Varianz im SHI, was für stark verrauschte ökologische Daten ein sehr guter und robuster Wert ist (geprüft über Out-of-Bag Validierung).

**Wichtigste Erkenntnisse (Feature Importance):**
1. **Niederschlag (~34 %)** und **Landbedeckung (~31 %)** sind die absolut dominierenden Einflussfaktoren für den Soil Health Index.
2. **Temperatur (~13 %)** spielt ebenfalls eine signifikante Rolle.
3. Klimazone und Höhe haben zwar einen messbaren, aber deutlich geringeren isolierten Einfluss.

Das Modell zeigt auf Datenbasis klar, dass feuchte Klimate in Kombination mit naturnaher Wald- oder Grünlandbedeckung die höchsten SHI-Werte fördern, während intensive landwirtschaftliche Nutzung oder extreme Trockenheit die Bodengesundheit reduzieren. Topografie allein spielt nur eine untergeordnete Rolle, weil klimabedingte Interaktionen überwiegen.

Weitere Details finden sich in der `output/Modell_Zusammenfassung/model_summary.txt` und in der `Dokumentation/DATEN_DOKUMENTATION.md`.

---

## 3. Workflow des Modells

Das Random-Forest-Modell zielt darauf ab, die Einflussfaktoren auf den SHI zu identifizieren und deren komplexe Interaktionen zu verstehen (Data Mining). Es geht nicht nur darum, Vorhersagen zu treffen, sondern die kausalen Zusammenhänge zu erklären. Der Workflow umfasst folgende Schritte:

1. **Datenvorbereitung (Cleaning):**
   Ausschluss von reinen Koordinaten/IDs sowie Filterung seltener Kategorien (Hobley-Regel: Gruppen mit < 30 Beobachtungen werden komplett entfernt).
2. **Explorative Datenanalyse (EDA):**
   Sichtprüfung der Datenverteilung mittels Korrelationsmatrizen, Boxplots und Histogrammen.
3. **Random Forest Training (Conditional Inference):**
   Einsatz von rekursiver Partitionierung und Bootstrapping. Ein großer Vorteil dieses Modells: Kategorische Variablen (Text) werden nativ (ohne One-Hot-Encoding) verarbeitet, wodurch Verzerrungen (Bias) vermieden werden.
4. **Hyperparameter-Optimierung:**
   Mittels Grid Search (für `ntree`, `mtry`, `mincriterion`) wird das verlässlichste Modell anhand des Out-of-Bag (OOB) R² ermittelt.
5. **Modellevaluation:**
   Validierung der Ergebnisse über OOB-Vorhersagefehler (RMSE) und Residuenanalysen zur Sicherstellung, dass das Modell keine systematischen Fehler macht.
6. **Interpretation & Data Mining:**
   Abschließende Ableitung der wichtigsten Faktoren durch Permutations-Wichtigkeit (Feature Importance) und Analyse ökologischer Interaktionen (z. B. wie sich Niederschlag in Abhängigkeit von Landnutzung verhält).
