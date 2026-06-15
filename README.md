# Machine-Learning-Ansatz (Gradient Boosting)

Für die Modellierung wurde ein Gradient Boosting Machine (GBM) verwendet. Im Gegensatz zu Random Forest oder Conditional Inference Forest basiert GBM auf einem sequenziellen Lernansatz, bei dem viele schwache Entscheidungsbäume schrittweise zu einem starken Modell kombiniert werden. Jeder neue Baum wird dabei so trainiert, dass er die Fehler der vorherigen Bäume reduziert.

## Methodische Idee

Das Modell approximiert den Zusammenhang:

SHI = f(Klima, Landnutzung, Landbedeckung, Topographie, ...)

durch eine additive Funktion vieler kleiner Entscheidungsbäume:

f(x) = Σ (learning rate × Baum_i(x))

## Vorteile des GBM-Ansatzes

- Sehr gute Vorhersageleistung bei nichtlinearen Daten.
- Flexible Modellierung komplexer Zusammenhänge.
- Automatische Berücksichtigung von Interaktionen.
- Gute Performance auch bei gemischten Datentypen.

## Hyperparameter

Die Modellleistung hängt stark von folgenden Parametern ab:

| Parameter | Bedeutung |
|---|---|
| `n.trees` | Anzahl der Boosting-Iterationen |
| `interaction.depth` | Maximale Tiefe der einzelnen Bäume |
| `shrinkage` | Lernrate; kleinere Werte führen zu stabilerem Lernen |
| `n.minobsinnode` | Minimale Beobachtungen pro Terminalknoten |

Zur Optimierung wurde eine Grid Search mittels `caret` durchgeführt. Die wichtigsten GBM-Hyperparameter sind genau diese Größen, und `shrinkage` sowie `interaction.depth` werden typischerweise gemeinsam mit `n.trees` getunt. 

## Modellierung

Das GBM-Modell wurde mit der `caret::train()`-Funktion trainiert und mittels 5-facher Cross-Validation validiert. `caret` unterstützt dafür standardisierte Resampling- und Performance-Metriken wie RMSE. 

Der Datensatz wurde zuvor:

- bereinigt (Missing Values, Ausreißer).
- kategoriale Variablen als Faktoren kodiert.
- in Trainings- (80%) und Testdaten (20%) aufgeteilt.

## Ziel

Das Ziel ist die möglichst präzise Vorhersage des Soil Health Index (SHI) auf Basis von Umweltvariablen.

## Modellbewertung

Die Modellgüte wurde anhand folgender Kennzahlen bewertet:

- RMSE (Root Mean Squared Error): Misst die durchschnittliche Abweichung zwischen beobachteten und vorhergesagten SHI-Werten.
- R² / `postResample()`: Bewertet die erklärte Varianz im Testdatensatz.

### Observed-vs-Predicted-Plot

Der Vergleich zeigt:

- Nähe zur 1:1-Linie: gute Vorhersagequalität.
- Systematische Abweichungen: Bias im Modell.

## Variable Importance

Die Variable-Importance-Analyse zeigt, welche Prädiktoren vom GBM-Modell am stärksten genutzt werden, um Vorhersagen zu verbessern. Wichtig ist dabei: Importance beschreibt keine Kausalität, sondern nur die Bedeutung für die Vorhersageleistung des Modells.

## Sensitivitätsanalyse (Leave-One-Variable-Out)

Zur robusteren Interpretation wurde eine Analyse durchgeführt, bei der jeweils eine Variable entfernt wurde.

### Ziel

- Einfluss einzelner Variablen auf den RMSE messen.
- Stabilität des Modells prüfen.

### Ergebnis

- Variablen mit starkem Einfluss führen zu deutlicher Verschlechterung des RMSE.
- Redundante Variablen zeigen kaum Effekt.

## Ergebnisse

Das GBM-Modell zeigt:

- Hohe Vorhersagegüte für den Soil Health Index.
- Starke Bedeutung von Klima- und Landnutzungsvariablen.
- Nichtlineare Zusammenhänge zwischen Umweltfaktoren und SHI.
- Robuste Modellleistung bei Cross-Validation.

## Vergleich zum Random Forest / cForest-Ansatz

Im Vergleich zum vorherigen cForest-Modell zeigt GBM:

- oft bessere Vorhersageleistung (niedriger RMSE),
- stärkere Sensitivität gegenüber Hyperparametern,
- weniger „statistische Strenge“, dafür höhere Flexibilität,
- stärkere Tendenz zur Optimierung auf Vorhersagefehler.

## Einschränkungen

- GBM ist empfindlich gegenüber der Hyperparameterwahl.
- Höhere Gefahr von Overfitting ohne Tuning.
- Interpretierbarkeit geringer als bei cForest.
- Keine kausalen Aussagen möglich.
- Räumliche Autokorrelation wird weiterhin nicht explizit modelliert.

## Verwendete Technologien

- R
- `caret`
- `gbm`
- `ggplot2`
- `sf`
- `tidyverse`
