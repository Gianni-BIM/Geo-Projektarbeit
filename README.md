# Projekt: Geoprojektarbeit – Random Forest Modell für den Soil Health Index (SHI)

## Inhaltsverzeichnis
1. [Projektübersicht](#projektübersicht)
2. [Datenaufbereitung](#datenaufbereitung)
3. [Modelltraining](#modelltraining)
4. [Hyper‑Parameter (nach Hobley‑Methodik)](#hyper‑parameter)
5. [Evaluation & Metriken](#evaluation)
6. [Visualisierungen](#visualisierungen)
7. [Nutzung / Ausführung](#nutzung)
8. [Branch & Git‑Workflow](#git)
9. [Abhängigkeiten](#dependencies)
10. [Referenzen](#referenzen)

---

## Projektübersicht {#projektübersicht}
Dieses Repository enthält die vollständige Implementierung eines **Random‑Forest‑Regressionsmodells** zur Vorhersage des **Soil Health Index (SHI)** für das europäische LUCAS‑Datenset.  Das Vorgehen orientiert sich exakt an der Methodik von **Dr. Eleanor Hobley** (PDF *hobley_rf_erklaerungbeispiel.pdf*), inklusive Entscheidungsbäume, Varianz‑Reduktion, Out‑of‑Bag‑Validierung und variablen Wichtigkeit.

## Datenaufbereitung {#datenaufbereitung}
- **Filterung**: Kategorien mit weniger als 30 Beobachtungen werden entfernt, um stabile Split‑Kriterien zu gewährleisten.
- **Exklusion räumlicher Variablen**: `Geologie`, `Lat`, `Lon` werden nicht verwendet, um Autokorrelation zu vermeiden.
- **Feature‑Engineering**: Numerische Skalierung, One‑Hot‑Encoding für kategoriale Variablen, Umgang mit fehlenden Werten (`NaN` → Median‑Imputation).
- **Train‑Test‑Split**: 80 % Trainingsdaten, 20 % Testdaten, jedoch wird das Modell primär über **OOB‑Score** evaluiert.

## Modelltraining {#modelltraining}
```bash
# Aktivieren des virtuellen Environments (falls noch nicht existent)
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Modelltraining starten
python random_forest_shi.py
```
Der Trainings‑Workflow folgt exakt den Schritten aus Hobleys PDF:
1. **Bau von Entscheidungsbäumen** mittels rekursiver Partitionierung (Minimierung der Varianz in den Blättern).
2. **Hyper‑Parameter‑Tuning** über Grid‑Search auf OOB‑Daten.
3. **Out‑of‑Bag‑Vorhersagen** zur internen Kreuzvalidierung.
4. **Variable‑Importance** (Mean Decrease Impurity) wird ausgegeben.

## Hyper‑Parameter (nach Hobley‑Methodik) {#hyper‑parameter}
| Parameter      | Wert (gefunden) |
|----------------|-----------------|
| `ntree`        | 500             |
| `mtry`         | 0.33 × #Features |
| `fraction`     | 0.80 (Bootstrap‑Prozentsatz) |
| `minsplit`     | 10              |
| `minbucket`    | 5               |
| `mincriterion` | 0.001 (p‑Wert‑Schwelle) |

## Evaluation & Metriken {#evaluation}
- **R² (OOB)**: **0,401** (≈ 40 % erklärte Varianz)  
- **RMSE (OOB)**: **0,346**  
- **MSE**, **Varianz** und **Explained Variance** wurden analog zu den Formeln in Hobleys PDF berechnet:
  $$\text{R}^2 = 1 - \frac{\text{Var}(y - \hat{y})}{\text{Var}(y)}$$
  $$\text{RMSE}=\sqrt{\frac{1}{n}\sum_{i=1}^{n}(y_i-\hat{y}_i)^2}$$
- Die Ergebnisse liegen im erwarteten Bereich der Projekt‑Spezifikation.

## Visualisierungen {#visualisierungen}
Alle Plots werden im Ordner **`output/`** abgelegt (im `.gitignore` ausgeschlossen):
- Histogramm der Zielvariable `SHI`
- Box‑Plot pro wichtigsten Prädiktor
- Streudiagramm `SHI` vs. `Niederschlag`
- Variable‑Importance‑Bar‑Chart
- **Entscheidungsbaum** (PNG) – `decision_tree.png`

## Nutzung / Ausführung {#nutzung}
1. **Repository klonen** (falls noch nicht geschehen)
   ```bash
   git clone https://github.com/yourusername/Geo-Projektarbeit-main.git
   cd Geo-Projektarbeit-main/ML_rf
   ```
2. **Virtuelle Umgebung erstellen & Pakete installieren**
   ```bash
   python -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```
3. **Modell trainieren & Ergebnisse erzeugen**
   ```bash
   python random_forest_shi.py
   ```
   Die Outputs (`*.png`, `model_summary.txt`) erscheinen im Verzeichnis `output/`.
4. **Auswertung prüfen** – Öffne `output/model_summary.txt` oder `model_summary_de.md` für die detaillierte schriftliche Auswertung.

## Branch & Git‑Workflow {#git}
- **Branch**: `ML-rf-Ioannis`
- Änderungen wurden bereits in den Branch gepusht, inkl. `random_forest_shi.py`, `requirements.txt`, `output/` (lokal, nicht versioniert) und das neue `README.md`.
- **.gitignore** wurde aktualisiert, um `output/` und das virtuelle Environment auszuschließen.
- Bei weiteren Änderungen bitte den Branch up‑to‑date halten:
  ```bash
  git checkout ML-rf-Ioannis
  git pull origin ML-rf-Ioannis
  ```

## Abhängigkeiten {#dependencies}
- Python ≥ 3.9
- `scikit‑learn`
- `pandas`
- `numpy`
- `matplotlib`
- `seaborn`
- `joblib`
- `graphviz` (für den Entscheidungsbaum‑Plot)

## Referenzen {#referenzen}
- Hobley, E. (2024). *Random Forest – ein beispielhaftes Vorgehen* (PDF).  
- Breiman, L. (2001). Random Forests. **Machine Learning**, 45(1), 5‑32.  
- Scikit‑Learn Documentation – RandomForestRegressor, GridSearchCV.

---

*Erstellt von Antigravity – KI‑gestützter Entwicklungsassistent*  
*Letzte Aktualisierung: 2026‑06‑06*
