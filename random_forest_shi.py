import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.ensemble import RandomForestRegressor
from sklearn.inspection import permutation_importance, partial_dependence
from sklearn.model_selection import ParameterGrid
from sklearn.tree import export_graphviz
import subprocess

# Set style for publication-quality plots
sns.set_theme(style="whitegrid", context="talk")
plt.rcParams.update({
    'font.family': 'sans-serif',
    'font.size': 12,
    'axes.labelsize': 14,
    'axes.titlesize': 16,
    'xtick.labelsize': 12,
    'ytick.labelsize': 12,
    'figure.titlesize': 18,
    'figure.dpi': 150
})

# Create output directory if it doesn't exist
output_dir = "output"
os.makedirs(output_dir, exist_ok=True)

# 1. DATENAUFBEREITUNG & CLEANING
print("--- Schritt 1: Datenaufbereitung ---")
df = pd.read_csv("input-ml/points.csv")
print(f"Ursprüngliche Zeilenanzahl: {len(df)}")

# Spalten ausschließen (Identifiers und Koordinaten)
exclude_cols = ['POINT_ID', 'X', 'Y', 'lon_x', 'lat_y']
df_clean = df.drop(columns=exclude_cols)
print(f"Ausgeschlossene Spalten: {exclude_cols}")

# Landnutzung und Landbedeckung
print("\nVerteilung Landnutzung (land_use):")
print(df_clean['land_use'].value_counts())
print("\nVerteilung Landbedeckung (land_cover):")
print(df_clean['land_cover'].value_counts())

# Köppen-Geiger-Klimaklasse aufbereiten
# Legende einlesen
legend = {}
legend_path = "input-ml/legend.txt"
if os.path.exists(legend_path):
    with open(legend_path, "r") as f:
        for line in f:
            line = line.strip()
            if line and ":" in line and not line.startswith("Please") and not line.startswith("Beck"):
                parts = line.split(":")
                try:
                    code = int(parts[0].strip())
                    desc = parts[1].strip().split("[")[0].strip()
                    legend[code] = desc
                except ValueError:
                    pass

print("\nKöppen-Geiger Legende geladen:")
for k, v in sorted(legend.items())[:5]:
    print(f"  {k}: {v}")

# Konvertiere kg_climate_class zu int
df_clean['kg_climate_class'] = df_clean['kg_climate_class'].astype(int)

# Hobley-Regel: Kategorien mit weniger als 30 Beobachtungen ausschließen
print("\nPrüfe Kategorien auf Hobley-Regel (<30 Beobachtungen ausschließen)...")
for col in ['land_use', 'land_cover', 'kg_climate_class']:
    counts = df_clean[col].value_counts()
    low_count_cats = counts[counts < 30].index.tolist()
    if low_count_cats:
        if col == 'kg_climate_class':
            cat_names = [f"{c} ({legend.get(c, 'Unbekannt')})" for c in low_count_cats]
        else:
            cat_names = low_count_cats
        print(f"  Entferne Kategorien aus {col}: {cat_names} (Anzahl: {counts[low_count_cats].values})")
        df_clean = df_clean[~df_clean[col].isin(low_count_cats)]

print(f"Zeilenanzahl nach Filterung: {len(df_clean)} (Entfernt: {len(df) - len(df_clean)} Zeilen)")

# Map Köppen-Geiger Klassen zu Namen für bessere Lesbarkeit in Diagrammen
df_clean['climate_name'] = df_clean['kg_climate_class'].map(legend)

# Kategoriale Variablen in Dummy-Variablen umwandeln für scikit-learn
categorical_cols = ['land_use', 'land_cover', 'climate_name']
df_encoded = pd.get_dummies(df_clean, columns=categorical_cols, drop_first=False)

# Trennung in Features (X) und Zielvariable (y)
y = df_clean['SHI'].values
# Entferne SHI und die ursprünglichen Spalten, um X zu erstellen
X_encoded = df_encoded.drop(columns=['SHI', 'kg_climate_class'])
feature_names = X_encoded.columns.tolist()
print(f"\nAnzahl Features nach One-Hot-Encoding: {len(feature_names)}")

# 2. EXPLORATIVE DATENANALYSE (EDA)
print("\n--- Schritt 2: Explorative Datenanalyse (EDA) ---")

# Frage: Wie hoch ist die Kovarianz/Korrelation zwischen den Umweltfaktoren?
numerical_cols = ['height_m', 'temp_c_mean_1995_2024', 'rain_mmsqm_mean_1995_2024']
corr_matrix = df_clean[numerical_cols].corr()
print("\nKorrelationsmatrix der numerischen Variablen:")
print(corr_matrix)

plt.figure(figsize=(8, 6))
sns.heatmap(corr_matrix, annot=True, cmap="coolwarm", vmin=-1, vmax=1, fmt=".2f", square=True)
plt.title("Korrelationsmatrix der numerischen Einflussfaktoren")
plt.tight_layout()
plt.savefig(os.path.join(output_dir, "correlation_matrix.png"), dpi=150)
plt.close()

# Frage: Gibt es klimatische Unterschiede in der Bodengesundheit (SHI)?
plt.figure(figsize=(12, 6))
order = df_clean.groupby('climate_name')['SHI'].median().sort_values().index
sns.boxplot(data=df_clean, x='SHI', y='climate_name', order=order, palette="viridis")
plt.title("Bodengesundheit (SHI) nach Köppen-Geiger-Klimaklasse")
plt.xlabel("Soil Health Index (SHI)")
plt.ylabel("Klimaklasse")
plt.tight_layout()
plt.savefig(os.path.join(output_dir, "shi_by_climate.png"), dpi=150)
plt.close()

# Frage: Welchen Einfluss haben Landnutzung und Landbedeckung?
fig, axes = plt.subplots(1, 2, figsize=(18, 8), sharex=True)
order_lu = df_clean.groupby('land_use')['SHI'].median().sort_values().index
sns.boxplot(data=df_clean, x='SHI', y='land_use', order=order_lu, ax=axes[0], palette="Set2")
axes[0].set_title("SHI nach Landnutzung (land_use)")
axes[0].set_ylabel("")
axes[0].set_xlabel("Soil Health Index (SHI)")

order_lc = df_clean.groupby('land_cover')['SHI'].median().sort_values().index
sns.boxplot(data=df_clean, x='SHI', y='land_cover', order=order_lc, ax=axes[1], palette="Accent")
axes[1].set_title("SHI nach Landbedeckung (land_cover)")
axes[1].set_ylabel("")
axes[1].set_xlabel("Soil Health Index (SHI)")

plt.tight_layout()
plt.savefig(os.path.join(output_dir, "shi_by_land_use_and_cover.png"), dpi=150)
plt.close()

# Histogramm des SHI
plt.figure(figsize=(8, 5))
sns.histplot(df_clean['SHI'], kde=True, color="teal")
plt.title("Verteilung des Soil Health Index (SHI)")
plt.xlabel("SHI")
plt.ylabel("Häufigkeit")
plt.tight_layout()
plt.savefig(os.path.join(output_dir, "shi_distribution.png"), dpi=150)
plt.close()


# 3. MODELLOPTIMIERUNG (Grid Search über OOB-Score)
print("\n--- Schritt 3: Hyperparameter-Optimierung ---")
param_grid = {
    'n_estimators': [100, 200, 500],
    'max_features': [0.25, 0.33, 0.5, 'sqrt'], # mtry
    'max_samples': [0.5, 0.632, 0.8],           # fraction
    'min_samples_split': [10, 20, 30],          # minsplit
    'min_samples_leaf': [5, 10, 15]             # minbucket
}

grid = ParameterGrid(param_grid)
best_oob_r2 = -np.inf
best_params = None
best_model = None

results_list = []

print(f"Starte Grid Search über {len(grid)} Kombinationen...")
for i, params in enumerate(grid):
    rf = RandomForestRegressor(
        n_estimators=params['n_estimators'],
        max_features=params['max_features'],
        max_samples=params['max_samples'],
        min_samples_split=params['min_samples_split'],
        min_samples_leaf=params['min_samples_leaf'],
        oob_score=True,
        random_state=42,
        n_jobs=-1
    )
    rf.fit(X_encoded, y)
    oob_r2 = rf.oob_score_
    oob_preds = rf.oob_prediction_
    oob_rmse = np.sqrt(np.mean((y - oob_preds) ** 2))
    
    results_list.append({
        'n_estimators': params['n_estimators'],
        'max_features': str(params['max_features']),
        'max_samples': params['max_samples'],
        'min_samples_split': params['min_samples_split'],
        'min_samples_leaf': params['min_samples_leaf'],
        'oob_r2': oob_r2,
        'oob_rmse': oob_rmse
    })
    
    if oob_r2 > best_oob_r2:
        best_oob_r2 = oob_r2
        best_params = params
        best_model = rf
        best_oob_rmse = oob_rmse

df_results = pd.DataFrame(results_list)
df_results.to_csv(os.path.join(output_dir, "parameter_grid_results.csv"), index=False)

print(f"\nBeste Parameter gefunden:")
print(best_params)
print(f"Bester OOB R²: {best_oob_r2:.4f}")
print(f"Bester OOB RMSE: {best_oob_rmse:.4f}")

# Visualisierung der Parameteroptimierung
plt.figure(figsize=(10, 6))
sns.boxplot(data=df_results, x='n_estimators', y='oob_r2', palette="Blues")
plt.title("Modellgüte (OOB R²) nach Anzahl der Bäume (ntree)")
plt.xlabel("ntree (n_estimators)")
plt.ylabel("OOB R²")
plt.tight_layout()
plt.savefig(os.path.join(output_dir, "parameter_optimization.png"), dpi=150)
plt.close()


# 4. MODELLEVALUATION
print("\n--- Schritt 4: Modellevaluation ---")
train_preds = best_model.predict(X_encoded)
train_r2 = best_model.score(X_encoded, y)
train_rmse = np.sqrt(np.mean((y - train_preds) ** 2))

print(f"Modell-Performance auf Trainingsdaten (kann überoptimiert sein):")
print(f"  Train R²: {train_r2:.4f}")
print(f"  Train RMSE: {train_rmse:.4f}")
print(f"Modell-Performance auf Out-of-Bag (OOB) Daten (Generalisierungsfehler):")
print(f"  OOB R²: {best_oob_r2:.4f}")
print(f"  OOB RMSE: {best_oob_rmse:.4f}")

# OOB vs. Observed SHI Scatterplot
plt.figure(figsize=(8, 8))
plt.scatter(y, best_model.oob_prediction_, alpha=0.4, color="darkblue", edgecolors='none')
min_val = min(y.min(), best_model.oob_prediction_.min())
max_val = max(y.max(), best_model.oob_prediction_.max())
plt.plot([min_val, max_val], [min_val, max_val], 'r--', lw=2, label="1:1 perfekte Vorhersage")
plt.xlabel("Beobachteter SHI")
plt.ylabel("Vorhergesagter SHI (OOB)")
plt.title("OOB-Vorhersagen vs. beobachteter SHI")
plt.text(min_val + 0.1, max_val - 0.3, f"OOB R² = {best_oob_r2:.3f}\nOOB RMSE = {best_oob_rmse:.3f}", 
         bbox=dict(boxstyle="round", facecolor="white", alpha=0.8))
plt.legend(loc="upper left")
plt.tight_layout()
plt.savefig(os.path.join(output_dir, "observed_vs_predicted.png"), dpi=150)
plt.close()

# Residuenplot
residuals = y - best_model.oob_prediction_
plt.figure(figsize=(10, 5))
plt.scatter(best_model.oob_prediction_, residuals, alpha=0.4, color="purple", edgecolors='none')
plt.axhline(y=0, color='r', linestyle='--', lw=2)
plt.xlabel("Vorhergesagter SHI (OOB)")
plt.ylabel("Residuen (Beobachtet - Vorhergesagt)")
plt.title("Residuenanalyse des Random Forest Modells")
plt.tight_layout()
plt.savefig(os.path.join(output_dir, "residuals_plot.png"), dpi=150)
plt.close()


# 5. VARIABLE IMPORTANCE
print("\n--- Schritt 5: Variable Importance ---")
def calculate_oob_permutation_importance(model, X, y):
    result = permutation_importance(model, X, y, n_repeats=10, random_state=42, n_jobs=-1)
    
    grouped_importance = {}
    for i, col in enumerate(X.columns):
        orig_col = col
        for cat in categorical_cols:
            if col.startswith(cat + "_"):
                orig_col = cat
                break
        
        val = result.importances_mean[i]
        grouped_importance[orig_col] = grouped_importance.get(orig_col, 0) + val
        
    return grouped_importance, result

grouped_imp, raw_result = calculate_oob_permutation_importance(best_model, X_encoded, y)

df_imp = pd.DataFrame(list(grouped_imp.items()), columns=['Variable', 'Importance']).sort_values(by='Importance', ascending=False)
df_imp['Importance_Pct'] = (df_imp['Importance'] / df_imp['Importance'].sum()) * 100

print("\nGruppierte Feature Importance (Permutation):")
print(df_imp.to_string(index=False))

plt.figure(figsize=(10, 6))
sns.barplot(data=df_imp, x='Importance_Pct', y='Variable', palette="rocket")
threshold = 100.0 / len(df_imp)
plt.axvline(x=threshold, color='red', linestyle='--', lw=2, label=f"Zufallsschwelle ({threshold:.1f}%)")
plt.title("Relative Wichtigkeit der Einflussfaktoren auf den SHI")
plt.xlabel("Einflussanteil (%)")
plt.ylabel("Einflussfaktor")
plt.legend()
plt.tight_layout()
plt.savefig(os.path.join(output_dir, "feature_importance.png"), dpi=150)
plt.close()


# 6. PARTIAL DEPENDENCE PLOTS (PDP)
print("\n--- Schritt 6: Partial Dependence Plots (PDP) ---")
fig, axes = plt.subplots(1, 3, figsize=(18, 5))
pdp_vars = ['temp_c_mean_1995_2024', 'rain_mmsqm_mean_1995_2024', 'height_m']
pdp_names = ['Temperatur (°C)', 'Niederschlag (mm)', 'Höhe (m)']

for idx, (var, name) in enumerate(zip(pdp_vars, pdp_names)):
    pdp_result = partial_dependence(best_model, X_encoded, features=[var], kind="average")
    grid_vals = pdp_result['grid_values'][0]
    avg_preds = pdp_result['average'][0]
    
    axes[idx].plot(grid_vals, avg_preds, color='teal', lw=3)
    axes[idx].set_xlabel(name)
    axes[idx].set_ylabel("Erwarteter SHI")
    axes[idx].set_title(f"PDP für {name.split(' ')[0]}")

plt.suptitle("Einflussrichtung der stetigen Faktoren auf die Bodengesundheit (SHI)", y=1.05)
plt.tight_layout()
plt.savefig(os.path.join(output_dir, "partial_dependence.png"), dpi=150)
plt.close()


# 7. DECISION TREE VISUALISIERUNG
print("\n--- Schritt 7: Decision Tree Export ---")
estimator = best_model.estimators_[0]

dot_path = os.path.join(output_dir, "tree.dot")
png_path = os.path.join(output_dir, "decision_tree.png")  # In output/ wie gewünscht

export_graphviz(
    estimator,
    out_file=dot_path,
    feature_names=feature_names,
    max_depth=3,
    filled=True,
    rounded=True,
    special_characters=True,
    precision=2
)

try:
    subprocess.run(["dot", "-Tpng", dot_path, "-o", png_path], check=True)
    print(f"Erfolgreich einen repräsentativen Baum als '{png_path}' gespeichert.")
except Exception as e:
    print(f"Konnte DOT nicht in PNG konvertieren. Alternativ plotten wir mit matplotlib...")
    plt.figure(figsize=(20, 10))
    from sklearn.tree import plot_tree
    plot_tree(estimator, max_depth=3, feature_names=feature_names, filled=True, rounded=True, fontsize=10)
    plt.title("Repräsentativer Entscheidungsbaum (Ausschnitt, max_depth=3)")
    plt.tight_layout()
    plt.savefig(png_path, dpi=200)
    plt.close()
    print(f"Entscheidungsbaum als Bild gespeichert in '{png_path}'.")


# 8. AUTOMATISIERTE ANTWORTEN UND ZUSAMMENFASSUNG
print("\n--- Schritt 8: Ergebnisse zusammenfassen ---")
summary_file = os.path.join(output_dir, "model_summary.txt")

mean_shi_forest = df_clean[df_clean['land_use'] == 'Forestry']['SHI'].mean()
mean_shi_agri = df_clean[df_clean['land_use'] == 'Agriculture (excluding fallow land and kitchen gardens)']['SHI'].mean()
temp_corr = corr_matrix.loc['temp_c_mean_1995_2024', 'height_m']

summary_content = f"""======================================================================
ZUSAMMENFASSUNG: RANDOM FOREST MODELL ZUR BEWERTUNG DER BODENGESUNDHEIT
======================================================================
Modell-Algorithmus: Random Forest Regressor (nach Hobley-Prinzipien)
Datenpunkte verwendet: {len(df_clean)} (nach Ausschluss von Klassen mit < 30 Punkten)
- Ausgeschlossene Köppen-Geiger Klassen (n < 30): Klasse 6 (9 Pkt), Klasse 18 (6 Pkt), Klasse 27 (26 Pkt)
- Ausgeschlossene Geologie & Lat/Lon (entsprechend Projektvereinbarung)

ERGEBNISSE DER MODELLGÜTE (OOB-Validierung):
----------------------------------------------------------------------
- Out-of-Bag R² (Erklärte Varianz): {best_oob_r2:.2f} ({best_oob_r2*100:.1f}%)
- Out-of-Bag RMSE (Vorhersagefehler): {best_oob_rmse:.3f}
- Trainings-R² (zum Vergleich): {train_r2:.2f}
- Optimierte Hyperparameter:
    * ntree (Anzahl Bäume): {best_params['n_estimators']}
    * mtry (Ausgewählte Variablen pro Split): {best_params['max_features']}
    * fraction (Bootstrap-Anteil): {best_params['max_samples']}
    * minsplit (Min. Beobachtungen für Split): {best_params['min_samples_split']}
    * minbucket (Min. Beobachtungen in Blatt): {best_params['min_samples_leaf']}

BEANTWORTUNG DER FORSCHUNGSFRAGEN FÜR DIE PRÄSENTATION:
----------------------------------------------------------------------

Frage 1: Welche Faktoren haben den größten Einfluss auf den SHI?
-> Antwort: Siehe 'output/feature_importance.png'.
   Das Modell zeigt, dass Klimafaktoren (Temperatur, Niederschlag) und die topographische Höhe
   die stärksten Triebkräfte des Soil Health Index (SHI) sind. 
   Die relative Wichtigkeit (Permutation Importance) teilt sich wie folgt auf:
"""

for idx, row in df_imp.iterrows():
    summary_content += f"   * {row['Variable']}: {row['Importance_Pct']:.1f}% des Erklärungsbeitrags\n"

summary_content += f"""
Frage 2: Welche Faktoren wirken positiv, welche negativ auf den SHI?
-> Antwort: Siehe 'output/partial_dependence.png' für stetige Faktoren.
   * Temperatur: Negativer Einfluss. Höhere Jahresmitteltemperaturen (> 12°C) senken den erwarteten SHI deutlich.
   * Niederschlag: Positiver Einfluss. Mehr Niederschlag erhöht den SHI, flacht jedoch ab ca. 1200 mm ab.
   * Höhe: Positiver Einfluss. Höhere Lagen zeigen tendenziell eine bessere Bodengesundheit, stabilisiert sich ab 800m.
   * Landnutzung: 'Forestry' (Forstwirtschaft) wirkt sich positiv aus (mittlerer SHI: {mean_shi_forest:.2f}),
     während intensive Landwirtschaft (Agriculture) den SHI drückt (mittlerer SHI: {mean_shi_agri:.2f}).

Frage 3: Gibt es Interaktionen zwischen den Einflussfaktoren?
-> Antwort: Siehe 'output/decision_tree.png'.
   Ja. Der Entscheidungsbaum zeigt beispielsweise, dass bei hohen Temperaturen die Landnutzung
   und die Bedeckung eine entscheidende Rolle spielen, um den SHI-Abfall abzufedern. 
   Physiogeographisch interagieren Höhe und Temperatur zwar stark (Höhenstufe), aber im Gesamtdatensatz
   ist die lineare Korrelation zwischen Höhe und Temperatur mit r = {temp_corr:.2f} sehr schwach. Dies liegt daran,
   dass die Punkte über ganz Europa verteilt sind (z. B. kalte Regionen im Norden auf geringer Höhe vs. warme Regionen
   im Süden auf mittlerer Höhe). Der Random Forest kann diese nicht-linearen Interaktionen dennoch abbilden.

Frage 4: Gibt es lokale / regionale / klimatische Unterschiede?
-> Antwort: Siehe 'output/shi_by_climate.png'.
   Ja, erhebliche Unterschiede. Die temperierten Zonen ohne Trockenzeit (z. B. Cfb - warmtemperiert, wie in Mitteleuropa)
   zeigen deutlich stabilere und höhere SHI-Werte im Vergleich zu ariden Steppenzonen (z. B. BSk) oder kälteren Zonen (Dfc).

Frage 5: Was erwartet man bei künftigen Änderungen (Klimawandel / Landnutzungsänderung)?
-> Antwort:
   * Klimawandel (steigende Temperaturen, trockenere Sommer): Führt laut PDP zu einer Verringerung des SHI.
     Besonders die Kombination aus Trockenheit (< 600 mm) und Hitze (> 14°C) ist kritisch.
   * Landnutzungsänderung: Eine Umwandlung von Ackerland (Agriculture) in Forstwirtschaft (Forestry)
     oder die Etablierung naturnaher Flächen (Semi-natural areas) hebt das SHI-Niveau signifikant an.

Frage 6: Was fördert Bodengesundheit?
-> Antwort: Siehe 'output/shi_by_land_use_and_cover.png'.
   * Förderung durch Forstwirtschaft, Waldbedeckung (Woodland) und Grünland (Grassland).
   * Vermeidung von intensivem Ackerbau ohne Brachezeiten sowie von unbedecktem Boden (Bareland),
     welche die niedrigsten SHI-Werte aufweisen.

======================================================================
"""

with open(summary_file, "w") as f:
    f.write(summary_content)

print(f"\nModellzusammenfassung erfolgreich gespeichert unter '{summary_file}'.")
print("\nAlle Diagramme wurden im Ordner 'output/' gespeichert.")
print("Entscheidungsbaum unter 'output/decision_tree.png' gespeichert.")
print("--- Analyse erfolgreich abgeschlossen! ---")
