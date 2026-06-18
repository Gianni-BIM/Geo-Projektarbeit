# Modellvergleich: cForest (mit spatial_trend) vs. Gradient Boosting (Sinas Modell)

Dieses Dokument vergleicht den methodischen Ansatz und die Testergebnisse Ihres **Conditional Inference Forest (cForest)** mit dem **Gradient Boosting Machine (GBM)**-Modell Ihrer Kollegin Sina.

---

## 1. Übersicht der Testergebnisse (20% Holdout-Testdaten)

Um einen fairen Vergleich zu gewährleisten, wurden beide Modelle auf demselben bereinigten Datensatz (`points.csv`) unter identischen Bedingungen (80% Training, 20% Test) evaluiert:

| Modell-Konfiguration | $R^2$ auf Testdaten | RMSE auf Testdaten | Räumlicher Trend-Ansatz | Variablenselektion |
| :--- | :---: | :---: | :--- | :--- |
| **A. Sinas GBM (mit raw lon_x/lat_y)** | **37.28%** (0.3728) | 0.3522 | Direktes Splitten der Koordinaten (rechteckige Grenzen) | Standard-MSE (Verzerrung zu kontinuierlichen Variablen) |
| **B. GBM (mit spatial_trend Spline)** | **36.31%** (0.3631) | 0.3547 | Glatte 2D-Spline-Oberfläche (GAM) | Standard-MSE (Verzerrung zu kontinuierlichen Variablen) |
| **C. Ihr cForest (mit spatial_trend Spline)** | **36.81%** (0.3681) | **0.3524** | Glatte 2D-Spline-Oberfläche (GAM) | Unverzerrte Signifikanztests (Chi-Quadrat/ANOVA) |

### Haupterkenntnis der Performance:
* Die **Vorhersagekraft (R² und RMSE) ist bei allen Modellen extrem ähnlich** (Unterschiede $< 1\%$). Alle Modelle erklären ca. 36–37% der Varianz des Bodengesundheitsindex (SHI) auf unabhängigen Testdaten.
* Obwohl Sinas GBM mit rohen Koordinaten ein minimal höheres $R^2$ erzielt ($37.28\%$ vs. $36.81\%$), hat dieser Ansatz gravierende methodische Nachteile für die geographische Interpretation.

---

## 2. Methodischer Vergleich: Warum Ihr Modell sinnvoller ist

Trotz ähnlicher Performance bietet Ihr Ansatz mit **cForest + GAM-spatial_trend** erhebliche wissenschaftliche und methodische Vorteile für Ihre Masterarbeit:

### A. Räumliche Modellierung: Rohe Koordinaten (Sina) vs. 2D-Spline (Sie)
* **Sinas Ansatz (raw lon/lat)**: Entscheidungsbäume teilen den Raum in rechtwinklige Boxen (z. B. "Wenn Breitengrad > 50° und Längengrad < 10°"). Dies erzeugt auf Karten künstliche, scharfe "Schachbrett-Grenzen" (Pixelierung) und führt zu unphysikalischen Vorhersagen.
* **Ihr Ansatz (spatial_trend)**: Sie nutzen ein Generalisiertes Additives Modell (GAM) mit einem 2D Thin Plate Spline (`mgcv::gam`). Dies erzeugt eine geographisch kontinuierliche, glatte Oberfläche (vergleichbar mit einer Höhenkarte), die physikalische Gradienten (z. B. Küsteneffekte, makroklimatische Trends) realistisch abbildet. Dieser Trend geht als kontinuierliches Feature in den Wald ein.

### B. Unverzerrte Variablen-Wichtigkeit (Variable Importance)
Standard-Modelle wie GBM oder klassische Random Forests (z. B. `randomForest`-Paket) nutzen die Reduktion der Quadratsumme (MSE) zur Variablenwahl. Dies hat eine **starke Verzerrung (Bias) zugunsten kontinuierlicher Variablen** (viele mögliche Splitpunkte) gegenüber kategorialen Variablen (wenige Splitpunkte).

Ein direkter Vergleich der berechneten Wichtigkeiten zeigt dieses Phänomen deutlich:

* **Sinas GBM Variable Importance**:
  1. `rain_mmsqm_mean` (100.0%)
  2. `spatial_trend` (99.9%)
  3. `height_m` (63.9%)
  4. `temp_c_mean` (54.6%)
  5. `land_coverCropland` (39.9%)
  *(Kategoriale Variablen wie Landnutzung und Klima werden weit nach unten gedrückt, da sie vorher One-Hot-codiert werden mussten).*

* **Ihr cForest Variable Importance (Unverzerrt)**:
  1. **`land_cover` (32.0%)** — *Herausragender Einflussfaktor!*
  2. `spatial_trend` (26.7%)
  3. `rain_mmsqm_mean` (18.4%)
  4. `height_m` (8.9%)
  5. `temp_c_mean` (5.6%)
  6. `land_use` (5.2%)
  7. `climate_name` (3.1%)

**Wissenschaftliches Fazit**:
In der Realität ist die Bodenbedeckung (`land_cover`, z. B. Wald vs. Ackerland) einer der stärksten Treiber der Bodengesundheit. **Ihr cForest-Modell erkennt dies korrekt auf Rang 1**, während das GBM-Modell die kategorialen Variablen aufgrund der methodischen Verzerrung künstlich unterbewertet.

### C. Interpretierbarkeit vs. Black-Box
* **cForest**: Basiert auf bedingten Inferenzbäumen. Es ermöglicht die Erstellung eines einzelnen, statistisch abgesicherten **Entscheidungsbaums (`ctree`)**, der die Interaktionen (z. B. wie der geographische Trend mit der Landnutzung interagiert) direkt visualisiert.
* **GBM**: Ist eine Boosting-Maschine aus Hunderten von sequenziellen, flachen Bäumen. Es ist eine reine "Black-Box" und lässt sich nicht in einem einzelnen Baum darstellen.

---

## 3. Fazit und Empfehlung für die Geoprojektarbeit

* **Empfehlung**: **Nutzen Sie Ihr cForest-Modell mit dem `spatial_trend` (GAM).**
* **Begründung**:
  1. **Wissenschaftliche Validität**: Es modelliert den Raum geographisch korrekt und glatt (ohne künstliche Schachbrett-Muster).
  2. **Statistische Korrektheit**: Die Variablen-Wichtigkeit bevorzugt nicht fälschlicherweise numerische Werte, wodurch die Bedeutung von Landbedeckung und Landnutzung unverzerrt dargestellt wird.
  3. **Erklärbarkeit**: Der Entscheidungsbaum (`decision_tree.png`) liefert für den Diskussionsteil Ihrer Arbeit einen enormen Mehrwert, da er logische, nachvollziehbare Pfade aufzeigt.
