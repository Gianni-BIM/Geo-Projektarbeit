# Random Forest zur Bewertung der Bodengesundheit (SHI)

Analyse des Soil Health Index (SHI) in Europa mithilfe eines Conditional Inference Forest (`party`). Das Modell untersucht den Einfluss von Klima, Topografie, Landnutzung und Landbedeckung.

---

## 1. Quickstart

```bash
git clone https://github.com/Gianni-BIM/Geo-Projektarbeit.git
cd Geo-Projektarbeit
git checkout ML-rf-Ioannis
cd RandomForest_R

# Pakete installieren & Modell ausführen
cd Modell 
Rscript install_packages.R
Rscript cforest_shi.rmd 
cd ..
```

---

## 2. Daten & Methodik

**Eingabedaten:** Höhe (m), Temperatur (°C), Niederschlag (mm), Landnutzung, Landbedeckung und Klimazone.
**Ziel:** Vorhersage des SHI und Analyse der wichtigsten Einflussfaktoren.
**Methodik:** Conditional Inference Forest (`party::cforest`) nach Datenbereinigung (Ausschluss von Klassen < 30 Beobachtungen) und Hyperparameter-Tuning.

---

## 3. Ergebnisse

| Metrik | Wert |
|---|---|
| **OOB R²** | 0.3727 (37.27%) |
| **OOB RMSE** | 0.3546 |

**Top-Einflussfaktoren:**
1. Niederschlag (34.0%)
2. Landbedeckung (30.9%)
3. Temperatur (12.6%)

**Kernaussagen:**
- **Positive Effekte:** Höherer Niederschlag, Wald-/Grünlandbedeckung und milde Klimazonen (z.B. atlantische Westküsten) fördern den SHI.
- **Negative Effekte:** Hohe Temperaturen, Trockenheit und intensive Ackerbaunutzung senken den SHI.
- **Interaktionen:** Die Relevanz der Landbedeckung variiert je nach Feuchtigkeit; Temperatur und Niederschlag definieren gemeinsam die wirksamen Klimazonen.

---

## 4. Projektstruktur & Ergebnisse

- **`Modell/`**: R-Skript, Ergebnisse und Diagramme
- **`Modell/output/Modell_Zusammenfassung/modell_zusammenfassung.md`**: Die automatisch generierte Modell Zusammenfassung mit der Beantwortung der Forschungsfragen.
- **`Modell/output/Modell_Zusammenfassung/variablen_legende.md`**: Legende und Erklärung aller vom Modell verwendeten Variablen.
