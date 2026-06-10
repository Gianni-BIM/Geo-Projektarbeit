# Setup & Ausführung: Random Forest zur Bodengesundheit (SHI)

Diese Anleitung erklärt Schritt für Schritt, wie das R-Skript zur Auswertung der Bodengesundheitsdaten ausgeführt wird.

## 1. Voraussetzungen
- Ein Code-Editor (z. B. **VS Code**, **Antigravity** oder RStudio) ist installiert.
- **R** ist auf dem System installiert.
- (Optional, aber empfohlen) **Git** ist installiert.

## 2. Projekt vorbereiten
1. Öffne ein Terminal (oder die integrierte Konsole in deinem Editor).
2. Klone das Repository (falls noch nicht geschehen) oder aktualisiere es auf den neuesten Stand:
   ```bash
   git pull
   ```
3. Öffne den Projektordner `RandomForest_R` in deinem Editor.

## 3. R-Pakete installieren
Das Skript benötigt einige externe R-Pakete. Öffne R (oder die R-Konsole in deinem Editor) und führe folgenden Befehl aus, falls die Pakete noch nicht installiert sind:
```R
install.packages(c("party", "ggplot2", "reshape2", "gridExtra", "partykit"))
```

## 4. Skript ausführen
Führe das Hauptskript `random_forest_shi.R` aus. Das geht entweder direkt im Terminal:
```bash
Rscript random_forest_shi.R
```
Oder indem du das Skript in RStudio/VS Code öffnest und ausführen lässt (via "Run" oder "Source").

## 5. Ergebnisse ansehen
Sobald das Skript durchgelaufen ist, findest du alle generierten Auswertungen im Ordner `output`:
- **`output/Grafiken_png/`**: Originalgrafiken mit englischen Datenbank-Bezeichnern.
- **`output/Grafiken_png/Grafik_mit_Beschriftung/`**: Grafiken mit verständlicheren, deutschen Achsenbeschriftungen.
- **`output/Modell_Zusammenfassung/`**: Text- und CSV-Dateien (z. B. detaillierte `model_summary.txt` und `parameter_grid_results.csv`).
