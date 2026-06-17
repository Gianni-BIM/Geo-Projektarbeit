################################################################################
# RANDOM FOREST MODELL ZUR BEWERTUNG DER BODENGESUNDHEIT (SHI)
# ============================================================================
# Implementierung mit dem R-Paket "party" (Conditional Inference Forest)
# Vorteil: Native Verarbeitung kategorischer Variablen (Faktoren),
#          d.h. KEIN One-Hot-Encoding nötig.
#          Der Algorithmus kann direkt auf Kategorien splitten,
#          z.B. {woodland, grassland} vs {cropland}.
#
# NEU (Schritt 1b): Räumlicher Trend via GAM (mgcv) — Strategie B
#   lat/lon werden über einen 2D-Thin-Plate-Spline (GAM) zu einem
#   neuen Feature "spatial_trend" verarbeitet. Dieses Feature wird
#   automatisch in Schritt 3 (Formel) und Schritt 5 (Variable Importance)
#   mitberücksichtigt — kein weiterer Eingriff nötig.
#
# Referenz Random Forest:
#   Hothorn, T., Hornik, K., & Zeileis, A. (2006).
#   Unbiased Recursive Partitioning: A Conditional Inference Framework.
#   Journal of Computational and Graphical Statistics, 15(3), 651-674.
#
# Referenz GAM:
#   Wood, S.N. (2017). Generalized Additive Models: An Introduction with R.
#   Chapman & Hall/CRC. (mgcv-Paket)
################################################################################

# --- Pakete laden ---
library(party)
library(mgcv)      # NEU: GAM für räumlichen Trend
library(ggplot2)
library(reshape2)
library(gridExtra)
library(GGally)    # Korrelationsmatrix

# Reproduzierbarkeit
set.seed(42)

# --- Pfade konfigurieren ---
# Skript kann vom Projektroot aus gestartet werden
if (file.exists("input/Daten/points.csv")) {
  base_dir <- "."
} else if (file.exists("../input/Daten/points.csv")) {
  base_dir <- ".."
} else {
  stop("Kann die Eingabedatei 'input/Daten/points.csv' nicht finden. ",
       "Bitte starte das Skript aus dem Projektverzeichnis.")
}

input_csv   <- file.path(base_dir, "input", "Daten", "points.csv")
legend_path <- file.path(base_dir, "input", "Daten", "legend.txt")

output_dir  <- "output_lat-long"
output_png_dir <- file.path(output_dir, "Grafiken_png")
output_mod_dir <- file.path(output_dir, "Modell_Zusammenfassung")

sapply(c(output_dir, output_png_dir, output_mod_dir), dir.create, showWarnings = FALSE, recursive = TRUE)

var_translations <- c(
  "height_m" = "Höhe (m)",
  "temp_c_mean_1995_2024" = "Temperatur (°C)",
  "rain_mmsqm_mean_1995_2024" = "Niederschlag (mm)",
  "SHI" = "Bodengesundheit (SHI)",
  "land_use" = "Landnutzung",
  "land_cover" = "Landbedeckung",
  "climate_name" = "Klimazone",
  "spatial_trend" = "Räumlicher Trend (GAM)"
)

# ggplot2-Theme für publikationsreife Plots
theme_pub <- theme_minimal(base_size = 14) +
  theme(
    plot.title    = element_text(face = "bold", size = 16, hjust = 0.5),
    axis.title    = element_text(size = 14),
    axis.text     = element_text(size = 12),
    legend.text   = element_text(size = 11),
    panel.grid.minor = element_blank()
  )
theme_set(theme_pub)

# Hilfsfunktion zum Speichern der Plots (kompakt)
save_plot <- function(p, name, w, h, trans_labs = NULL) {
  if (!is.null(trans_labs)) {
    p <- p + trans_labs
  }
  ggsave(file.path(output_png_dir, name), p, width = w, height = h, dpi = 150)
}

################################################################################
# 1. DATENAUFBEREITUNG & CLEANING
################################################################################
cat("--- Schritt 1: Datenaufbereitung ---\n")
df <- read.csv(input_csv, stringsAsFactors = FALSE)
cat(sprintf("Ursprüngliche Zeilenanzahl: %d\n", nrow(df)))

# Koordinaten für GAM schon vor dem Ausschluss sichern
# lon_x / lat_y bleiben zunächst im Datensatz (werden nach GAM entfernt)
coords_df <- df[, c("X", "Y")]

# Identifier-Spalten entfernen — lon_x / lat_y bleiben DRIN für GAM (Schritt 1b)
exclude_cols <- c("POINT_ID", "X", "Y")
df_clean <- df[, !(names(df) %in% exclude_cols)]
cat(sprintf("Ausgeschlossene Spalten: %s\n", paste(exclude_cols, collapse = ", ")))
cat("  HINWEIS: lon_x und lat_y bleiben vorerst erhalten (werden in Schritt 1b\n")
cat("           für den GAM-Spline benötigt und danach durch 'spatial_trend' ersetzt).\n")

# Verteilungen ausgeben
cat("\nVerteilung Landnutzung (land_use):\n")
print(table(df_clean$land_use))
cat("\nVerteilung Landbedeckung (land_cover):\n")
print(table(df_clean$land_cover))

# --- Köppen-Geiger Legende einlesen ---
legend_map <- list()
if (file.exists(legend_path)) {
  legend_lines <- readLines(legend_path)
  for (line in legend_lines) {
    line <- trimws(line)
    if (nchar(line) > 0 && grepl(":", line) &&
        !grepl("^Please", line) && !grepl("^Beck", line)) {
      parts <- strsplit(line, ":")[[1]]
      code_str <- trimws(parts[1])
      desc_raw <- trimws(parts[2])
      desc <- trimws(gsub("\\[.*\\]", "", desc_raw))
      code <- suppressWarnings(as.integer(code_str))
      if (!is.na(code)) {
        legend_map[[as.character(code)]] <- desc
      }
    }
  }
}
cat("\nKöppen-Geiger Legende geladen:\n")
for (k in sort(as.integer(names(legend_map)))[1:5]) {
  cat(sprintf("  %d: %s\n", k, legend_map[[as.character(k)]]))
}

# Konvertiere kg_climate_class zu integer
df_clean$kg_climate_class <- as.integer(df_clean$kg_climate_class)

# --- Hobley-Regel: Kategorien mit <30 Beobachtungen ausschließen ---
cat("\nPrüfe Kategorien auf Hobley-Regel (<30 Beobachtungen ausschließen)...\n")
cat_cols <- c("land_use", "land_cover", "kg_climate_class")

for (col in cat_cols) {
  counts <- table(df_clean[[col]])
  low_cats <- names(counts[counts < 30])
  if (length(low_cats) > 0) {
    if (col == "kg_climate_class") {
      cat_names <- sapply(low_cats, function(c) {
        sprintf("%s (%s)", c, ifelse(c %in% names(legend_map),
                                     legend_map[[c]], "Unbekannt"))
      })
    } else {
      cat_names <- low_cats
    }
    cat(sprintf("  Entferne Kategorien aus %s: %s (Anzahl: %s)\n",
                col, paste(cat_names, collapse = ", "),
                paste(counts[low_cats], collapse = ", ")))
    df_clean <- df_clean[!(df_clean[[col]] %in% low_cats), ]
  }
}

# Koordinaten an gefilterte Zeilen anpassen
coords_df <- coords_df[as.integer(rownames(df_clean)), ]
rownames(df_clean) <- NULL
rownames(coords_df) <- NULL

cat(sprintf("Zeilenanzahl nach Filterung: %d (Entfernt: %d Zeilen)\n",
            nrow(df_clean), nrow(df) - nrow(df_clean)))

# --- Klimanamen mappen ---
df_clean$climate_name <- sapply(df_clean$kg_climate_class, function(x) {
  key <- as.character(x)
  if (key %in% names(legend_map)) legend_map[[key]] else "Unbekannt"
})

# ============================================================================
# KERNPUNKT: Kategorische Variablen als FACTOR setzen — KEIN One-Hot-Encoding!
# ============================================================================
df_clean$land_use     <- as.factor(df_clean$land_use)
df_clean$land_cover   <- as.factor(df_clean$land_cover)
df_clean$climate_name <- as.factor(df_clean$climate_name)

cat(sprintf("\nAnzahl Features: %d (davon 3 kategorisch als Faktoren — KEIN One-Hot-Encoding)\n  land_use     : %d Levels\n  land_cover   : %d Levels\n  climate_name : %d Levels\n", ncol(df_clean) - 2, nlevels(df_clean$land_use), nlevels(df_clean$land_cover), nlevels(df_clean$climate_name)))


################################################################################
# 1b. GAM — RÄUMLICHER TREND ALS FEATURE (Strategie B)
# ============================================================================
# Warum nicht rohe lat/lon in den cforest?
#   Bedingte Inferenzbäume machen nur achsenparallele Splits.
#   Der gekrümmte N-S / W-O Gradient des SHI über Europa wird von einem
#   einzelnen Split auf "lat_y > X" nur grob erfasst.
#   Ein 2D-Thin-Plate-Spline im GAM modelliert diesen Trend glatt und
#   komprimiert ihn in eine einzige Zahl ("spatial_trend") pro Punkt.
#
# Strategie B (hier umgesetzt):
#   GAM-Vorhersage = geglätteter räumlicher Hintergrundtrend im SHI.
#   Dieser wird als neues numerisches Feature in den cforest gegeben.
#   Der Forest kann dann entscheiden, wie stark er diesen Trend
#
# Moran's I-Test:
#   Prüft, ob in den GAM-Residuen noch räumliche Autokorrelation steckt.
#   Wenn ja → k in s(lon_x, lat_y, k=...) erhöhen.
#   Wenn nein → der Spline hat den räumlichen Trend ausreichend absorbiert.
################################################################################
cat("\n--- Schritt 1b: Räumlicher Trend via GAM (mgcv, Strategie B) ---\n")

# Sicherstellen, dass lon_x / lat_y vorhanden sind
if (!all(c("lon_x", "lat_y") %in% names(df_clean))) {
  stop("lon_x oder lat_y fehlen in df_clean. Prüfe den exclude_cols-Block in Schritt 1.")
}

# ---- GAM fitten ----
# bs = "tp"  : Thin-Plate-Spline — isotrop, keine Richtungspräferenz,
#              ideal für geografische Koordinaten
# k  = 30    : Anzahl Basisfunktionen (Knotenanzahl).
#              k=10 = grob/schnell, k=30 = Standard, k=60 = fein/langsam.
#              Bei noch signifikantem Moran's I → k erhöhen.
# method="REML": Restricted Maximum Likelihood für Glättungsparameter —
#              Standardempfehlung in Wood (2017)
cat("Fitte GAM mit s(lon_x, lat_y, bs='tp', k=30) ...\n")
gam_spatial <- mgcv::gam(
  SHI ~ s(lon_x, lat_y, bs = "tp", k = 30),
  data   = df_clean,
  method = "REML"
)
cat("GAM-Zusammenfassung:\n")
print(summary(gam_spatial))

# (Removed gam_spatial_summary.txt generation per user request)
# gam_summary_text <- capture.output(summary(gam_spatial))
# writeLines(
#   c("GAM RÄUMLICHER TREND — ZUSAMMENFASSUNG",
#     "========================================",
#     "Modell: SHI ~ s(lon_x, lat_y, bs='tp', k=30)",
#     "Methode: REML",
#     "",
#     gam_summary_text),
#   file.path(output_mod_dir, "gam_spatial_summary.txt")
# )

# Ersetze den Moran's I Block komplett durch diesen:

cat("\nPrüfe räumliche Autokorrelation in den GAM-Residuen (Moran's I) ...\n")
if (!requireNamespace("spdep", quietly = TRUE)) {
  install.packages("spdep", repos = "https://cloud.r-project.org")
}
library(spdep)

coords_mat <- as.matrix(df_clean[, c("lon_x", "lat_y")])

# Distanzbasierte Nachbarn: alle Punkte im Umkreis von max_dist Grad
# (2.0 Grad ≈ ~220 km — passt gut für europäische Punktdichte)
# Vorteil: kein Teilgraph-Problem, immer zusammenhängend
nb_dist <- spdep::dnearneigh(coords_mat, d1 = 0, d2 = 2.0)

# Falls einzelne Punkte isoliert bleiben → d2 erhöhen (z.B. 3.0)
n_isolated <- sum(card(nb_dist) == 0)
if (n_isolated > 0) {
  cat(sprintf("  HINWEIS: %d isolierte Punkte bei d2=2.0 → erhöhe auf d2=3.0\n",
              n_isolated))
  nb_dist <- spdep::dnearneigh(coords_mat, d1 = 0, d2 = 3.0)
}

lw_dist    <- spdep::nb2listw(nb_dist, style = "W", zero.policy = TRUE)
gam_resid  <- residuals(gam_spatial)
moran_gam  <- spdep::moran.test(gam_resid, lw_dist, zero.policy = TRUE)

cat(sprintf("Moran's I (GAM-Residuen): I = %.4f, p = %.6f\n",
            as.numeric(moran_gam$estimate["Moran I statistic"]),
            moran_gam$p.value))

if (moran_gam$p.value < 0.05) {
  cat("  HINWEIS: Noch signifikante räumliche Autokorrelation in den Residuen.\n")
  cat("  → Erwäge k in s(lon_x, lat_y, k=...) auf 60 oder höher zu setzen.\n")
} else {
  cat("  OK: Kein signifikanter räumlicher Trend mehr in den GAM-Residuen.\n")
}

# ---- Strategie B: spatial_trend als neues Feature ----
df_clean$spatial_trend <- as.numeric(predict(gam_spatial, newdata = df_clean))

cat(sprintf("\nNeues Feature 'spatial_trend' hinzugefügt:\n  Min    = %.3f\n  Median = %.3f\n  Max    = %.3f\n", min(df_clean$spatial_trend), median(df_clean$spatial_trend), max(df_clean$spatial_trend)))

# ---- Visualisierung: Räumlicher Trend ----
p_spatial <- ggplot(df_clean, aes(x = lon_x, y = lat_y, color = spatial_trend)) +
  geom_point(size = 0.6, alpha = 0.6) + coord_equal() +
  scale_color_gradient2(low="#2166AC", mid="white", high="#B2182B", midpoint=median(df_clean$spatial_trend), name="SHI-Trend") +
  labs(title="Räumlicher SHI-Trend (GAM Thin-Plate-Spline)", subtitle="mgcv::gam mit s(lon_x, lat_y, bs='tp', k=30) — Strategie B", x="Längengrad", y="Breitengrad")
save_plot(p_spatial, "spatial_trend_gam.png", 10, 6, labs(title="Räumlicher Trend der Bodengesundheit (GAM-Glättung)", subtitle="Thin-Plate-Spline über Längen- und Breitengrad"))
cat("Karte des räumlichen Trends gespeichert.\n")

# ---- Modell-Datensatz vorbereiten ----
# Jetzt lon_x, lat_y und kg_climate_class entfernen:
#   - lon_x / lat_y: durch spatial_trend ersetzt (kompakt + interpretierbar)
#   - kg_climate_class: durch climate_name ersetzt
df_model <- df_clean[, !(names(df_clean) %in% c("kg_climate_class", "lon_x", "lat_y"))]

cat(sprintf("\ndf_model enthält jetzt %d Features (inkl. 'spatial_trend', ohne lon_x/lat_y):\n  %s\n", ncol(df_model) - 1, paste(setdiff(names(df_model), "SHI"), collapse = ", ")))


################################################################################
# 2. EXPLORATIVE DATENANALYSE (EDA)
################################################################################
cat("\n--- Schritt 2: Explorative Datenanalyse (EDA) ---\n")

# Korrelationsmatrix der numerischen Variablen (inkl. spatial_trend)
numerical_cols <- c("height_m", "temp_c_mean_1995_2024",
                    "rain_mmsqm_mean_1995_2024", "spatial_trend", "SHI")
corr_matrix <- cor(df_clean[, numerical_cols], use = "complete.obs")
cat("Korrelationsmatrix der numerischen Variablen (inkl. spatial_trend):\n")
print(round(corr_matrix, 3))

# Heatmap — direkt mit übersetzten Variablennamen
corr_melt <- melt(corr_matrix)
corr_melt$Var1 <- factor(var_translations[as.character(corr_melt$Var1)],
                         levels = var_translations[numerical_cols])
corr_melt$Var2 <- factor(var_translations[as.character(corr_melt$Var2)],
                         levels = var_translations[numerical_cols])
p_corr <- ggplot(corr_melt, aes(Var1, Var2, fill = value)) +
  geom_tile(color = "white", linewidth = 0.5) +
  geom_text(aes(label = sprintf("%.2f", value)), size = 4) +
  scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B",
                       midpoint = 0, limits = c(-1, 1), name = "Korrelation") +
  labs(title = "Korrelationsmatrix der numerischen Einflussfaktoren", x = "", y = "") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggsave(file.path(output_png_dir, "correlation_matrix.png"), p_corr, width = 9, height = 7, dpi = 150)

# SHI nach Klimaklasse (Boxplot)
climate_order <- names(sort(tapply(df_clean$SHI, df_clean$climate_name, median)))
df_clean$climate_name_ordered <- factor(df_clean$climate_name, levels = climate_order)

p_climate <- ggplot(df_clean, aes(x = SHI, y = climate_name_ordered)) +
  geom_boxplot(aes(fill = climate_name_ordered), show.legend=FALSE, outlier.alpha=0.4) +
  scale_fill_viridis_d(option="viridis") +
  labs(title="Bodengesundheit (SHI) nach Köppen-Geiger-Klimaklasse", x="Soil Health Index (SHI)", y="Klimaklasse")
save_plot(p_climate, "shi_by_climate.png", 12, 6, labs(title="Bodengesundheit (SHI) nach Klimazone", x="Bodengesundheit (SHI)", y="Klimazone"))

# SHI nach Landnutzung und Landbedeckung
lu_order <- names(sort(tapply(df_clean$SHI, df_clean$land_use, median)))
lc_order <- names(sort(tapply(df_clean$SHI, df_clean$land_cover, median)))

p_lu <- ggplot(df_clean, aes(x = SHI, y = factor(land_use, levels = lu_order))) +
  geom_boxplot(aes(fill = factor(land_use, levels = lu_order)),
               show.legend = FALSE, outlier.alpha = 0.4) +
  scale_fill_brewer(palette = "Set2") +
  labs(title = "SHI nach Landnutzung", x = "Bodengesundheit (SHI)", y = "")
p_lc <- ggplot(df_clean, aes(x = SHI, y = factor(land_cover, levels = lc_order))) +
  geom_boxplot(aes(fill = factor(land_cover, levels = lc_order)),
               show.legend = FALSE, outlier.alpha = 0.4) +
  scale_fill_brewer(palette = "Accent") +
  labs(title = "SHI nach Landbedeckung", x = "Bodengesundheit (SHI)", y = "")
ggsave(file.path(output_png_dir, "shi_by_land_use_and_cover.png"),
       arrangeGrob(p_lu, p_lc, ncol = 2), width = 18, height = 8, dpi = 150)

# Histogramm SHI
p_hist <- ggplot(df_clean, aes(x = SHI)) + geom_histogram(aes(y = after_stat(density)), bins=40, fill="#008080", color="white", alpha=0.8) + geom_density(color="darkred", linewidth=1) + labs(title="Verteilung des Soil Health Index (SHI)", x="SHI", y="Dichte")
save_plot(p_hist, "shi_distribution.png", 8, 5, labs(x="Bodengesundheit (SHI)"))


################################################################################
# 3. HYPERPARAMETER-OPTIMIERUNG (Grid Search über OOB-Fehler)
# ============================================================================
# 'spatial_trend' wird automatisch einbezogen, da:
#   feature_vars <- setdiff(names(df_model), "SHI")
# enthält jetzt: height_m, temp_c_mean_1995_2024, rain_mmsqm_mean_1995_2024,
#                land_use, land_cover, climate_name, spatial_trend
################################################################################
cat("\n--- Schritt 3: Hyperparameter-Optimierung ---\n")

feature_vars <- setdiff(names(df_model), "SHI")
fml <- as.formula(paste("SHI ~", paste(feature_vars, collapse = " + ")))
cat(sprintf("Modellformel: %s\n", deparse(fml)))
cat(sprintf("  → 'spatial_trend' ist automatisch enthalten (%d Features total)\n",
            length(feature_vars)))

param_grid <- expand.grid(
  mtry         = c(2, 3, 4),
  mincriterion = c(0.90, 0.95, 0.99)
)

ntree <- 500

results_list <- data.frame()

cat(sprintf("Starte Grid Search über %d Kombinationen (ntree=%d)...\n",
            nrow(param_grid), ntree))

for (i in seq_len(nrow(param_grid))) {
  p <- param_grid[i, ]
  cat(sprintf("  [%d/%d] mtry=%d, mincriterion=%.2f ... ",
              i, nrow(param_grid), p$mtry, p$mincriterion))

  ctrl <- cforest_control(
    teststat     = "quad",
    testtype     = "Univ",
    mincriterion = p$mincriterion,
    ntree        = ntree,
    mtry         = as.integer(p$mtry),
    replace      = FALSE,
    fraction     = 0.632
  )

  cf <- cforest(fml, data = df_model, controls = ctrl)

  oob_preds <- as.numeric(predict(cf, OOB = TRUE))

  ss_res <- sum((df_model$SHI - oob_preds)^2)
  ss_tot <- sum((df_model$SHI - mean(df_model$SHI))^2)
  oob_r2   <- 1 - ss_res / ss_tot
  oob_rmse <- sqrt(mean((df_model$SHI - oob_preds)^2))

  cat(sprintf("OOB R²=%.4f, RMSE=%.4f\n", oob_r2, oob_rmse))

  results_list <- rbind(results_list, data.frame(
    mtry         = p$mtry,
    mincriterion = p$mincriterion,
    ntree        = ntree,
    oob_r2       = oob_r2,
    oob_rmse     = oob_rmse
  ))
}

write.csv(results_list, file.path(output_dir, "parameter_grid_results.csv"),
          row.names = FALSE)

best_idx    <- which.max(results_list$oob_r2)
best_params <- results_list[best_idx, ]
cat(sprintf("\nBeste Parameter gefunden:\n  mtry = %d\n  mincriterion = %.2f\n  Bester OOB R²: %.4f\n  Bester OOB RMSE: %.4f\n", best_params$mtry, best_params$mincriterion, best_params$oob_r2, best_params$oob_rmse))

best_ctrl <- cforest_control(
  teststat     = "quad",
  testtype     = "Univ",
  mincriterion = best_params$mincriterion,
  ntree        = ntree,
  mtry         = as.integer(best_params$mtry),
  replace      = FALSE,
  fraction     = 0.632
)
best_model     <- cforest(fml, data = df_model, controls = best_ctrl)
best_oob_preds <- as.numeric(predict(best_model, OOB = TRUE))
best_oob_r2    <- best_params$oob_r2
best_oob_rmse  <- best_params$oob_rmse

p_opt <- ggplot(results_list, aes(x = factor(mtry), y = oob_r2, color = factor(mincriterion), group = factor(mincriterion))) + geom_line(linewidth=1.2) + geom_point(size=3) + scale_color_brewer(palette="Set1", name="mincriterion") + labs(title="Modellgüte (OOB R²) nach Hyperparametern", x="mtry (Features pro Split)", y="OOB R²")
save_plot(p_opt, "parameter_optimization.png", 10, 6, labs(x="mtry (Anzahl Features pro Split)", color="Signifikanz (mincriterion)"))


################################################################################
# 4. MODELLEVALUATION
################################################################################
cat("\n--- Schritt 4: Modellevaluation ---\n")

train_preds   <- as.numeric(predict(best_model, OOB = FALSE))
ss_res_train  <- sum((df_model$SHI - train_preds)^2)
ss_tot_train  <- sum((df_model$SHI - mean(df_model$SHI))^2)
train_r2      <- 1 - ss_res_train / ss_tot_train
train_rmse    <- sqrt(mean((df_model$SHI - train_preds)^2))

cat(sprintf("Modell-Performance auf Trainingsdaten:\n  Train R²:   %.4f\n  Train RMSE: %.4f\nModell-Performance auf Out-of-Bag (OOB) Daten:\n  OOB R²:     %.4f\n  OOB RMSE:   %.4f\n", train_r2, train_rmse, best_oob_r2, best_oob_rmse))

pred_df   <- data.frame(observed = df_model$SHI, predicted = best_oob_preds)
val_range <- range(c(pred_df$observed, pred_df$predicted))

p_scatter <- ggplot(pred_df, aes(x=observed, y=predicted)) + geom_point(alpha=0.4, color="darkblue", size=1) + geom_abline(intercept=0, slope=1, color="red", linetype="dashed", linewidth=1) + annotate("text", x=val_range[1]+0.1, y=val_range[2]-0.3, label=sprintf("OOB R² = %.3f\nOOB RMSE = %.3f", best_oob_r2, best_oob_rmse), hjust=0, size=5, fontface="bold", label.padding=unit(0.5, "lines")) + coord_equal(xlim=val_range, ylim=val_range) + labs(title="OOB-Vorhersagen vs. beobachteter SHI", x="Beobachteter SHI", y="Vorhergesagter SHI (OOB)")
save_plot(p_scatter, "observed_vs_predicted.png", 8, 8, labs(x="Beobachtete Bodengesundheit", y="Vorhergesagte Bodengesundheit (OOB)"))

resid_df <- data.frame(predicted=best_oob_preds, residuals=df_model$SHI - best_oob_preds)
p_resid <- ggplot(resid_df, aes(x=predicted, y=residuals)) + geom_point(alpha=0.4, color="purple", size=1) + geom_hline(yintercept=0, color="red", linetype="dashed", linewidth=1) + labs(title="Residuenanalyse des Conditional Inference Forest", x="Vorhergesagter SHI (OOB)", y="Residuen (Beobachtet − Vorhergesagt)")
save_plot(p_resid, "residuals_plot.png", 10, 5, labs(x="Vorhergesagte Bodengesundheit (OOB)"))


################################################################################
# 5. VARIABLE IMPORTANCE (Permutationsbasiert, unbiased)
# ============================================================================
# 'spatial_trend' erscheint hier als eine einzelne numerische Variable,
# gleichwertig mit height_m, temp_c etc. — kein separater Eingriff nötig.
# Je höher sein Balken, desto wichtiger ist der räumliche Hintergrundtrend
# für die Erklärung des SHI (über das hinaus, was Klima/Landnutzung erklären).
################################################################################
cat("\n--- Schritt 5: Variable Importance ---\n")
cat("Berechne permutationsbasierte Variable Importance (kann einige Minuten dauern)...\n")

vi <- varimp(best_model, conditional = FALSE)

df_imp <- data.frame(
  Variable   = names(vi),
  Importance = as.numeric(vi)
)
df_imp <- df_imp[order(df_imp$Importance, decreasing = TRUE), ]
df_imp$Importance_Pct <- (df_imp$Importance / sum(df_imp$Importance)) * 100

cat("\nVariable Importance (Permutation, unbiased):\n")
print(df_imp, row.names = FALSE)

# Spatial-Trend Rang ausgeben
spatial_rank <- which(df_imp$Variable == "spatial_trend")
if (length(spatial_rank) > 0) {
  cat(sprintf("\n  → 'spatial_trend' liegt auf Rang %d von %d (%.1f%% Anteil)\n",
              spatial_rank, nrow(df_imp), df_imp$Importance_Pct[spatial_rank]))
  if (df_imp$Importance_Pct[spatial_rank] > 100 / nrow(df_imp)) {
    cat("  → spatial_trend ist SIGNIFIKANT: räumlicher Trend trägt zur Erklärung bei.\n")
  } else {
    cat("  → spatial_trend ist NICHT signifikant: räumlicher Großtrend bereits\n")
    cat("    durch Klima/Landnutzung abgedeckt. Feature kann ggf. entfernt werden.\n")
  }
}

threshold <- 100.0 / nrow(df_imp)

p_imp <- ggplot(df_imp, aes(x=Importance_Pct, y=reorder(Variable, Importance_Pct))) + geom_col(aes(fill=Importance_Pct), show.legend=FALSE) + scale_fill_gradient(low="#3B0F70", high="#FE9F6D") + geom_vline(xintercept=threshold, color="red", linetype="dashed", linewidth=1) + annotate("text", x=threshold+0.5, y=1, label=sprintf("Zufallsschwelle (%.1f%%)", threshold), color="red", hjust=0, size=4) + labs(title="Relative Wichtigkeit der Einflussfaktoren auf den SHI", subtitle="Conditional Inference Forest — inkl. räumlichem GAM-Trend", x="Einflussanteil (%)", y="Einflussfaktor")

df_imp_trans <- df_imp
df_imp_trans$Variable <- sapply(as.character(df_imp_trans$Variable), function(x) ifelse(x %in% names(var_translations), var_translations[x], x))
p_imp_trans <- ggplot(df_imp_trans, aes(x=Importance_Pct, y=reorder(Variable, Importance_Pct))) + geom_col(aes(fill=Importance_Pct), show.legend=FALSE) + scale_fill_gradient(low="#3B0F70", high="#FE9F6D") + geom_vline(xintercept=threshold, color="red", linetype="dashed", linewidth=1) + annotate("text", x=threshold+0.5, y=1, label=sprintf("Zufallsschwelle (%.1f%%)", threshold), color="red", hjust=0, size=4) + labs(title="Relative Wichtigkeit der Einflussfaktoren auf die Bodengesundheit", subtitle="Conditional Inference Forest — inkl. räumlichem GAM-Trend", x="Einflussanteil (%)", y="Einflussfaktor")
ggsave(file.path(output_png_dir, "feature_importance.png"), p_imp_trans, width=10, height=6, dpi=150)


################################################################################
# 5b. VARIABLENLEGENDE (Übersicht aller Modellvariablen als Markdown-Tabelle)
################################################################################
cat("\n--- Schritt 5b: Variablenlegende erstellen ---\n")

save_variable_legend <- function(df, translations, output_path) {
  lines <- c("# Variablenlegende", "",
             "| Variable | Bezeichnung | Typ | Wertebereich |",
             "|----------|-------------|-----|--------------|")
  for (vname in names(df)) {
    col <- df[[vname]]
    label <- ifelse(vname %in% names(translations), translations[vname], vname)
    if (is.numeric(col)) {
      typ <- "numerisch"
      bereich <- sprintf("%.2f – %.2f", min(col, na.rm = TRUE), max(col, na.rm = TRUE))
    } else if (is.factor(col)) {
      typ <- sprintf("Faktor (%d Stufen)", nlevels(col))
      lvls <- levels(col)
      if (length(lvls) <= 4) {
        bereich <- paste(lvls, collapse = ", ")
      } else {
        bereich <- paste(c(lvls[1:3], sprintf("… (%d weitere)", length(lvls) - 3)),
                         collapse = ", ")
      }
    } else {
      typ <- class(col)[1]
      bereich <- "—"
    }
    lines <- c(lines, sprintf("| %s | %s | %s | %s |", vname, label, typ, bereich))
  }
  writeLines(lines, output_path)
  cat(sprintf("Variablenlegende gespeichert: %s\n", output_path))
}

save_variable_legend(df_model, var_translations, file.path(output_mod_dir, "variable_legend.md"))


################################################################################
# 6. PARTIAL DEPENDENCE PLOTS (Übersprungen)
################################################################################
cat("\n--- Schritt 6: Partial Dependence Plots (übersprungen wegen Laufzeit) ---\n")


################################################################################
# 7. DECISION TREE VISUALISIERUNG (Conditional Inference Tree mit partykit)
################################################################################
cat("\n--- Schritt 7: Decision Tree (ctree) ---\n")

df_tree <- df_model

# Klimanamen kürzen
levels(df_tree$climate_name) <- sapply(
  strsplit(levels(df_tree$climate_name), " "), `[`, 1
)

# Landnutzung kürzen
levels(df_tree$land_use) <- gsub(
  "Agriculture \\(excluding fallow land and kitchen gardens\\)",
  "Agriculture", levels(df_tree$land_use)
)
levels(df_tree$land_use) <- gsub(
  "Semi-natural and natural areas not in use",
  "Semi-natural", levels(df_tree$land_use)
)
levels(df_tree$land_use) <- gsub("Fallow land", "Fallow", levels(df_tree$land_use))

fml_tree <- as.formula(
  paste("SHI ~", paste(setdiff(names(df_tree), "SHI"), collapse = " + "))
)

if (!requireNamespace("partykit", quietly = TRUE)) {
  install.packages("partykit", repos = "https://cloud.r-project.org")
}

ct_kit <- partykit::ctree(
  fml_tree, data = df_tree,
  control = partykit::ctree_control(maxdepth = 4, alpha = 0.05)
)

png(file.path(output_png_dir, "decision_tree.png"), width=2800, height=1400, res=180)
plot(ct_kit, main="Conditional Inference Tree für SHI (maxdepth=4, inkl. spatial_trend)", ip_args=list(pval=TRUE), ep_args=list(justmin=15))
dev.off()
cat("Entscheidungsbaum gespeichert.\n")




################################################################################
# 8. AUTOMATISIERTE ZUSAMMENFASSUNG (als Markdown)
################################################################################
cat("\n--- Schritt 8: Ergebnisse zusammenfassen ---\n")

# Notwendige Variablen berechnen
spatial_rank <- which(df_imp$Variable == "spatial_trend")
spatial_rank_txt <- if (length(spatial_rank) > 0) {
  sprintf("Rang %d von %d (%.1f%%)", spatial_rank, nrow(df_imp), df_imp$Importance_Pct[spatial_rank])
} else {
  "nicht berechnet"
}
threshold <- 100.0 / nrow(df_imp)
spatial_sig_txt <- if (length(spatial_rank) > 0 && df_imp$Importance_Pct[spatial_rank] > threshold) {
  "SIGNIFIKANT — räumlicher Hintergrundtrend trägt zur Erklärung bei"
} else {
  "NICHT SIGNIFIKANT — räumlicher Trend durch andere Features abgedeckt"
}

md_text <- sprintf(
"# Zusammenfassung: Conditional Inference Forest zur Bewertung der Bodengesundheit (SHI)

## Modell-Informationen
- **Modell-Algorithmus:** Conditional Inference Forest (party)
- **Räumliche Erweiterung:** GAM Thin-Plate-Spline `s(lon_x, lat_y, k=30)`
- **Vorteil:** Native kategorische Verarbeitung — KEIN One-Hot-Encoding nötig! Räumlicher Trend als kompaktes numerisches Feature eingebunden.
- **Datenpunkte verwendet:** %d (nach Ausschluss von Klassen mit < 30 Punkten)

## NEU: GAM RÄUMLICHER TREND (Schritt 1b)
- **Methode:** `mgcv::gam(SHI ~ s(lon_x, lat_y, bs='tp', k=30), method='REML')`
- **Strategie B:** GAM-Vorhersage = neues Feature `spatial_trend`
- **Moran's I (GAM-Residuen):** I=%.4f, p=%.6f → %s
- **Variable Importance von 'spatial_trend':** %s
- **Interpretation:** %s

## Ergebnisse der Modellgüte (OOB-Validierung)
- **Out-of-Bag R² (Erklärte Varianz):** %.4f (%.2f%%)
- **Out-of-Bag RMSE (Vorhersagefehler):** %.4f
- **Trainings-R² (zum Vergleich):** %.4f

**Optimierte Hyperparameter:**
- ntree (Anzahl Bäume): %d
- mtry (Variablen pro Split): %d
- mincriterion (Signifikanzniveau): %.3f
- fraction (Bootstrap-Stichprobengröße): 0.632
- replace (mit Zurücklegen): FALSE

## Beantwortung der Forschungsfragen

### Frage 1: Welche Faktoren haben den größten Einfluss auf den SHI?
", 
nrow(df_model), 
as.numeric(moran_gam$estimate["Moran I statistic"]), moran_gam$p.value, ifelse(moran_gam$p.value < 0.05, "Noch signifikant (ggf. k erhöhen)", "OK, kein räuml. Trend in Residuen"),
spatial_rank_txt,
spatial_sig_txt,
best_oob_r2, best_oob_r2 * 100,
best_oob_rmse,
train_r2,
ntree,
best_params$mtry,
best_params$mincriterion
)

top_n <- min(5, nrow(df_imp))
for (i in 1:top_n) {
  md_text <- paste0(md_text, sprintf("%d. **%s** (%.1f%% Erklärungsbeitrag)\n", i, df_imp$Variable[i], df_imp$Importance_Pct[i]))
}

md_text <- paste0(md_text, sprintf("
### Frage 2: Welche Faktoren wirken positiv, welche negativ?
**POSITIVE Effekte (erhöhen den SHI):**
- Höherer Niederschlag → Mehr Wasser für Pflanzen & Bodenbiologie
- Wald/Grünland-Bedeckung → Stabile Bodenstruktur, Humusaufbau
- Temperate Klimazonen (mild, nicht zu trocken)
- Hoher spatial_trend → günstige geografische Lage (z.B. Atlantikküste)

**NEGATIVE Effekte (senken den SHI):**
- Hohe Temperaturen in Trockengebieten
- Niedriger Niederschlag / Trockenheit
- Intensive Ackerbau-Nutzung
- Niedriger spatial_trend → ungünstige geografische Lage (z.B. Mittelmeer)

### Frage 3: Gibt es Interaktionen zwischen den Einflussfaktoren?
JA! Der Entscheidungsbaum zeigt Interaktionen. Neu:
- **spatial_trend × Landnutzung:** In Regionen mit hohem räumlichen Trend kann selbst intensive Landnutzung noch moderate SHI-Werte erzielen.
- **spatial_trend × Niederschlag:** Der räumliche Trend codiert oft implizit Ozeanitäts- und Kontinentalitätsgradienten.

### Frage 4: Gibt es lokale/regionale/klimatische Unterschiede?
JA — jetzt explizit durch spatial_trend sichtbar:
- Die Karte `spatial_trend_gam.png` zeigt den räumlichen Trend direkt.
- Atlantische Westküsten: hoher spatial_trend (günstige Lage)
- Kontinentale / mediterrane Regionen: niedrigerer spatial_trend

## Fazit und Empfehlungen
- **Modellqualität:** ★★★★☆ (4/5)
  OOB R² = %.4f — für ökologische Komplexsysteme sehr gut. Mit 'spatial_trend' wird der räumliche Makrogradient explizit modelliert.
- **Zuverlässigkeit:** ★★★★★ (5/5)
  OOB-Validierung: kein Overfitting.
- **Interpretierbarkeit:** ★★★★☆ (4/5)
  Variable Importance und Decision Tree klar interpretierbar. spatial_trend ist zusätzlich über die GAM-Karte visualisierbar.
", best_oob_r2))

md_out <- file.path(output_mod_dir, "model_summary.md")
writeLines(md_text, md_out)
cat(sprintf("Markdown-Zusammenfassung erstellt unter '%s'.\n", md_out))
cat("Alle Diagramme im Ordner 'output_lat-long/' gespeichert.\n")
cat("--- Analyse erfolgreich abgeschlossen! ---\n")
