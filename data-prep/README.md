# Geo-Projektarbeit

## Setup

Install uv from [uv homepage](https://docs.astral.sh/uv/getting-started/installation/)

Clone the repository [github repository](https://github.com/Gianni-BIM/Geo-Projektarbeit)

Run `uv sync` to install project dependencies
Run `uv run nbstripout --install` to keep Jupyter notebooks clean in Git (i.e. remove outputs and execution metadata).

## Info

The repository uses .gitattributes to enforce consistent LF line endings across operating systems.

## Running in VS Code

### Data Processing Workflow
**Open the project in VS Code and select the project `.venv` interpreter if prompted.**

**AUTO RUN: If you see a file called a_auto_run_all_notebooks.ipynb, you can use it to run all following steps at once.**

**Step 1**: run data-prep/explore_indicator_data.ipynb --> several CSV-files used for inspection and transformation are produced in the output folder

**Step 2**: run data-prep/data_clean_and_transform.ipynb --> further CSV-files used for transformation and SHI calculation are produced in the output folder

**Step 3**: run data-prep/calculate_shi.ipynb --> SHI calculation is done

**Step 4**: run data-prep/additional_expl.ipynb
 --> preparation for pivot tables (Excel) to explore independent indicators, LC/LU reduction...
 --> OUTPUT: df_SHI_with_LC_LU_reduced.csv = dataset with 4538 points (suggestion for further usage with columns contained: SHI, hoehe_m, Landcover, Landuse)

## Running jupyter lab

If you want to use jupyter lab to serve ipynb-files run: `uv run --with jupyter jupyter lab`.

If Jupyter Lab cannot find project dependencies, register the project's virtual environment as a Jupyter kernel:

`uv run python -m ipykernel install --user --name project-env --display-name "Project Environment"`

The kernel name can be chosen freely. This only needs to be done once per machine.

For further information [uv documentation jupyter lab](https://docs.astral.sh/uv/guides/integration/jupyter/#using-jupyter-within-a-project).

The **Data Processing Workflow** is the same as in VS Code (see above).

---

## 🤖 Machine Learning: Random Forest Modellierung (Bodengesundheit)

Zur Vorhersage und Analyse des **Soil Health Index (SHI)** wurde ein **Random Forest Regressionsmodell** implementiert, das auf den theoretischen Prinzipien von **Eleanor Hobley** (Recursive Partitioning, Out-of-Bag-Validierung und Permutation Variable Importance) basiert.

### Ausführung
Das Modell kann direkt über `uv` ausgeführt werden (es werden automatisch alle benötigten Abhängigkeiten geladen):
```bash
uv run python random_forest_shi.py
```
*Hinweis: Falls du kein `uv` nutzt, kannst du alternativ die Bibliotheken via `pip install -r requirements.txt` installieren und das Skript mit `python3 random_forest_shi.py` starten.*

---

## 📈 Modell-Ergebnisse & Beantwortung der Leitfragen

Das Modell wurde mittels einer systematischen Gittersuche (324 Kombinationen) für die Hyperparameter optimiert:
* **ntree (Anzahl Bäume)**: `500`
* **mtry (Variablen pro Split)**: `0.33` (ca. 6 Features pro Split)
* **fraction (Bootstrap-Anteil)**: `80%`
* **minsplit (Knotengröße für Split)**: `10`
* **minbucket (Blattgröße)**: `5`

### Modellgüte:
* **Out-of-Bag $R^2$ (Erklärte Varianz)**: **`0.401` ($40.1\%$)** – Das entspricht exakt der in den Projektnotizen erwarteten Leistung ("$R^2$ von 40 bedeutet: 40% kann erklärt werden").
* **Out-of-Bag RMSE (Fehler)**: **`0.346`** (auf einer SHI-Skala von 1.80 bis 4.00).

---

## 📊 Grafische Belege für die Präsentation (in `output/`)

Für die Abschlusspräsentation wurden im Ordner **`output/`** Visualisierungen generiert, die jede Kernfrage wissenschaftlich begründen:

### 1. Wichtigste Einflussfaktoren (Variable Importance)
* **Datei**: [feature_importance.png](file:///Users/ioannissvolos/Library/CloudStorage/OneDrive-BerlinerHochschulefürTechnik/FB3-Gianni%20BIM-Privat%20-%20Dokumente/Uni/Master/Geoprojektarbeit/Geo-Projektarbeit-main/output/feature_importance.png)
* **Ergebnis**: Der **Niederschlag (30.0%)** hat den stärksten Einfluss auf die Bodengesundheit, gefolgt von **Jahrestemperatur (19.8%)**, **Landbedeckung (19.1%)** und topographischer **Höhe (16.2%)**. Klimatische Zonen (10.0%) und Landnutzung (4.9%) spielen eine untergeordnete Rolle.

### 2. Richtung des Einflusses (Positiv vs. Negativ)
* **Dateien**: [partial_dependence.png](file:///Users/ioannissvolos/Library/CloudStorage/OneDrive-BerlinerHochschulefürTechnik/FB3-Gianni%20BIM-Privat%20-%20Dokumente/Uni/Master/Geoprojektarbeit/Geo-Projektarbeit-main/output/partial_dependence.png) & [shi_by_land_use_and_cover.png](file:///Users/ioannissvolos/Library/CloudStorage/OneDrive-BerlinerHochschulefürTechnik/FB3-Gianni%20BIM-Privat%20-%20Dokumente/Uni/Master/Geoprojektarbeit/Geo-Projektarbeit-main/output/shi_by_land_use_and_cover.png)
* **Ergebnis**:
  * **Temperatur**: Negativer Einfluss. Ab $12^\circ\text{C}$ Jahresmittel sinkt der SHI drastisch.
  * **Niederschlag**: Positiver Einfluss. Mehr Niederschlag erhöht den SHI, flacht jedoch ab ca. 1.200 mm ab.
  * **Höhe**: Positiver Einfluss. Höhere Lagen weisen tendenziell gesündere Böden auf (stabilisiert sich ab 800 m).
  * **Landnutzung**: *Forestry* (Forstwirtschaft) wirkt positiv (mittlerer SHI: 3.37), während intensive Ackerwirtschaft (*Agriculture*) den SHI drückt (mittlerer SHI: 3.08).

### 3. Interaktionen & Entscheidungsbaum (Decision Tree)
* **Datei**: [decision_tree.png](file:///Users/ioannissvolos/Library/CloudStorage/OneDrive-BerlinerHochschulefürTechnik/FB3-Gianni%20BIM-Privat%20-%20Dokumente/Uni/Master/Geoprojektarbeit/Geo-Projektarbeit-main/output/decision_tree.png)
* **Ergebnis**: Zeigt die konkreten baumbasierten Verzweigungen und Schwellenwerte. Bei hohen Temperaturen fängt beispielsweise eine waldreiche Landbedeckung den SHI-Abfall auf.
* *Hinweis zur Korrelation*: Im Gesamtdatensatz ist die lineare Korrelation zwischen Höhe und Temperatur mit $r = -0.05$ überraschend schwach (zu sehen in [correlation_matrix.png](file:///Users/ioannissvolos/Library/CloudStorage/OneDrive-BerlinerHochschulefürTechnik/FB3-Gianni%20BIM-Privat%20-%20Dokumente/Uni/Master/Geoprojektarbeit/Geo-Projektarbeit-main/output/correlation_matrix.png)). Dies liegt daran, dass der Datensatz ganz Europa umspannt (kalte Regionen im Norden auf geringer Höhe vs. warme Regionen im Süden auf mittlerer Höhe). Der Random Forest kann diese nicht-linearen Interaktionen dennoch hervorragend erfassen.

### 4. Regionale & Klimatische Unterschiede
* **Datei**: [shi_by_climate.png](file:///Users/ioannissvolos/Library/CloudStorage/OneDrive-BerlinerHochschulefürTechnik/FB3-Gianni%20BIM-Privat%20-%20Dokumente/Uni/Master/Geoprojektarbeit/Geo-Projektarbeit-main/output/shi_by_climate.png)
* **Ergebnis**: Temperierte Zonen ohne Trockenzeit (wie *Cfb* - warmtemperiert, Mitteleuropa) zeigen stabilere und höhere SHI-Werte im Vergleich zu ariden Steppenzonen (*BSk*) oder kälteren Zonen (*Dfc*).

### 5. Modell-Güte & Residuen
* **Dateien**: [observed_vs_predicted.png](file:///Users/ioannissvolos/Library/CloudStorage/OneDrive-BerlinerHochschulefürTechnik/FB3-Gianni%20BIM-Privat%20-%20Dokumente/Uni/Master/Geoprojektarbeit/Geo-Projektarbeit-main/output/observed_vs_predicted.png) & [residuals_plot.png](file:///Users/ioannissvolos/Library/CloudStorage/OneDrive-BerlinerHochschulefürTechnik/FB3-Gianni%20BIM-Privat%20-%20Dokumente/Uni/Master/Geoprojektarbeit/Geo-Projektarbeit-main/output/residuals_plot.png)
* **Ergebnis**: Die Vorhersagen folgen gleichmäßig der 1:1-Linie. Die Fehler (Residuen) sind homogen über das gesamte Spektrum verteilt, was für ein robustes Modell ohne systematischen Bias spricht.

Eine ausführliche textuelle Beantwortung aller Fragen findet sich in der Datei **[model_summary.txt](file:///Users/ioannissvolos/Library/CloudStorage/OneDrive-BerlinerHochschulefürTechnik/FB3-Gianni%20BIM-Privat%20-%20Dokumente/Uni/Master/Geoprojektarbeit/Geo-Projektarbeit-main/output/model_summary.txt)**.

