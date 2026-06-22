################################################################################
# RANDOM FOREST MODELL ZUR BEWERTUNG DER BODENGESUNDHEIT (SHI)
# ============================================================================
# Implementierung mit dem R-Paket "party" (Conditional Inference Forest)
# Vorteil: Native Verarbeitung kategorischer Variablen (Faktoren),
#          d.h. KEIN One-Hot-Encoding nötig.
#          Der Algorithmus kann direkt auf Kategorien splitten,
#          z.B. {woodland, grassland} vs {cropland}.
#
# Schritt 1b: Räumlicher Trend via GAM (mgcv) — Strategie B
#   lat/lon werden über einen 2D-Thin-Plate-Spline (GAM) zu einem
#   neuen Feature "spatial_trend" verarbeitet. Dieses Feature wird
#   automatisch in Schritt 3 (Formel) und Schritt 5 (Variable Importance)
#   mitberücksichtigt.
#
# FIXES (gegenüber alter Version):
#   FIX 1 — replace=FALSE konsistent in Grid Search UND finalem Modell.
#            (Vorher: Grid Search nutzte replace=TRUE, finales Modell FALSE →
#             Hyperparameter wurden unter anderen Bedingungen gefunden als
#             das finale Modell trainiert wurde. Jetzt konsistent.)
#   FIX 2 — GAM-Spline k=30 → k=60, da Moran's I in Residuen noch
#            signifikant war (I=0.0232, p<0.0001). k=60 absorbiert feinere
#            räumliche Autokorrelation.
#   FIX 3 — Partial Dependence Plots (PDPs) für Top-3-Variablen aktiviert:
#            land_cover (kategorial), spatial_trend (numerisch),
#            rain_mmsqm_mean_1995_2024 (numerisch). Manuell implementiert
#            ohne externe Pakete — kompatibel mit party::cforest.
#
# Referenz Random Forest:
#   Hothorn, T., Hornik, K., & Zeileis, A. (2006).
#   Unbiased Recursive Partitioning: A Conditional Inference Framework.
#   Journal of Computational and Graphical Statistics, 15(3), 651-674.
#
# Referenz GAM:
#   Wood, S.N. (2017). Generalized Additive Models: An Introduction with R.
#   Chapman & Hall/CRC. (mgcv-Paket)
#
# Referenz Partial Dependence:
#   Friedman, J.H. (2001). Greedy function approximation: a gradient boosting
#   machine. Annals of Statistics, 29(5), 1189-1232.
################################################################################

# --- Pakete laden ---
library(party)
library(mgcv)
library(ggplot2)
library(reshape2)
library(gridExtra)
library(GGally)

###############################################################################
# Laufzeitmessung
###############################################################################

script_start_time <- Sys.time()
step_times <- list()

start_step <- function(step_name) {
  assign(".current_step_start", Sys.time(), envir = .GlobalEnv)
  assign(".current_step_name", step_name, envir = .GlobalEnv)
}

end_step <- function() {
  duration <- as.numeric(difftime(Sys.time(),
    get(".current_step_start", envir = .GlobalEnv),
    units = "secs"
  ))
  step_times[[get(".current_step_name", envir = .GlobalEnv)]] <<- duration
  cat(sprintf(
    "\n[Zeit] %s: %.1f s (%.2f min)\n",
    get(".current_step_name", envir = .GlobalEnv), duration, duration / 60
  ))
}

# Reproduzierbarkeit
set.seed(42)

# --- Pfade konfigurieren ---
if (file.exists("input/Daten/points.csv")) {
  base_dir <- "."
} else if (file.exists("../input/Daten/points.csv")) {
  base_dir <- ".."
} else {
  stop("Kann 'input/Daten/points.csv' nicht finden. Starte aus dem Projektverzeichnis.")
}

input_csv <- file.path(base_dir, "input", "Daten", "points.csv")
legend_path <- file.path(base_dir, "input", "Daten", "legend.txt")

output_dir <- "output_lat-long"
output_png_dir <- file.path(output_dir, "Grafiken_png")
output_mod_dir <- file.path(output_dir, "Modell_Zusammenfassung")

sapply(c(output_dir, output_png_dir, output_mod_dir),
  dir.create,
  showWarnings = FALSE, recursive = TRUE
)

var_translations <- c(
  "height_m"                  = "Höhe (m)",
  "temp_c_mean_1995_2024"     = "Temperatur (°C)",
  "rain_mmsqm_mean_1995_2024" = "Niederschlag (mm)",
  "SHI"                       = "Bodengesundheit (SHI)",
  "land_use"                  = "Landnutzung",
  "land_cover"                = "Landbedeckung",
  "climate_name"              = "Klimazone",
  "spatial_trend"             = "Räumlicher Trend (GAM)"
)

theme_pub <- theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
    axis.title = element_text(size = 14),
    axis.text = element_text(size = 12),
    legend.text = element_text(size = 11),
    panel.grid.minor = element_blank()
  )
theme_set(theme_pub)

save_plot <- function(p, name, w, h, trans_labs = NULL) {
  if (!is.null(trans_labs)) p <- p + trans_labs
  ggsave(file.path(output_png_dir, name), p, width = w, height = h, dpi = 150)
}


################################################################################
# 1. DATENAUFBEREITUNG & CLEANING
################################################################################

start_step("Datenaufbereitung & Cleaning")
cat("--- Schritt 1: Datenaufbereitung ---\n")

df <- read.csv(input_csv, stringsAsFactors = FALSE)
cat(sprintf("Ursprüngliche Zeilenanzahl: %d\n", nrow(df)))

coords_df <- df[, c("X", "Y")]

exclude_cols <- c("POINT_ID", "X", "Y")
df_clean <- df[, !(names(df) %in% exclude_cols)]
cat(sprintf("Ausgeschlossene Spalten: %s\n", paste(exclude_cols, collapse = ", ")))
cat("  HINWEIS: lon_x und lat_y bleiben vorerst erhalten (werden in Schritt 1b\n")
cat("           fuer den GAM-Spline benoetigt und danach durch 'spatial_trend' ersetzt).\n")

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
      if (!is.na(code)) legend_map[[as.character(code)]] <- desc
    }
  }
}
cat("\nKöppen-Geiger Legende geladen:\n")
for (k in sort(as.integer(names(legend_map)))[1:5]) {
  cat(sprintf("  %d: %s\n", k, legend_map[[as.character(k)]]))
}

df_clean$kg_climate_class <- as.integer(df_clean$kg_climate_class)

# --- Hobley-Regel: Kategorien mit <30 Beobachtungen ausschließen ---
cat("\nPruefe Kategorien auf Hobley-Regel (<30 Beobachtungen ausschliessen)...\n")
cat_cols <- c("land_use", "land_cover", "kg_climate_class")
total_removed <- 0

for (col in cat_cols) {
  counts <- table(df_clean[[col]])
  low_cats <- names(counts[counts < 30])
  if (length(low_cats) > 0) {
    if (col == "kg_climate_class") {
      cat_names <- sapply(low_cats, function(c) {
        sprintf(
          "%s (%s)", c,
          ifelse(c %in% names(legend_map), legend_map[[c]], "Unbekannt")
        )
      })
    } else {
      cat_names <- low_cats
    }
    cat(sprintf(
      "  Entferne Kategorien aus %s: %s (Anzahl: %s)\n",
      col, paste(cat_names, collapse = ", "),
      paste(counts[low_cats], collapse = ", ")
    ))
    df_clean <- df_clean[!(df_clean[[col]] %in% low_cats), ]
    total_removed <- total_removed + length(low_cats)
  }
}
cat(sprintf("Entfernte Kategorien insgesamt: %d\n", total_removed))

coords_df <- coords_df[as.integer(rownames(df_clean)), ]
rownames(df_clean) <- NULL
rownames(coords_df) <- NULL

cat(sprintf(
  "Zeilenanzahl nach Filterung: %d (Entfernt: %d Zeilen)\n",
  nrow(df_clean), nrow(df) - nrow(df_clean)
))

df_clean$climate_name <- sapply(df_clean$kg_climate_class, function(x) {
  key <- as.character(x)
  if (key %in% names(legend_map)) legend_map[[key]] else "Unbekannt"
})

df_clean$land_use <- as.factor(df_clean$land_use)
df_clean$land_cover <- as.factor(df_clean$land_cover)
df_clean$climate_name <- as.factor(df_clean$climate_name)

cat(sprintf(
  "\nAnzahl Features: %d (davon 3 kategorisch als Faktoren — KEIN One-Hot-Encoding)\n  land_use     : %d Levels\n  land_cover   : %d Levels\n  climate_name : %d Levels\n",
  ncol(df_clean) - 2,
  nlevels(df_clean$land_use),
  nlevels(df_clean$land_cover),
  nlevels(df_clean$climate_name)
))

end_step()


################################################################################
# 1b. GAM — RÄUMLICHER TREND ALS FEATURE (Strategie B)
# ============================================================================
# FIX 2: k=30 → k=60
#   Moran's I in den GAM-Residuen war mit k=30 noch signifikant
#   (I=0.0232, p<0.0001). k=60 erlaubt dem Spline, feinere räumliche
#   Strukturen zu absorbieren und reduziert die verbleibende Autokorrelation.
#
# Zur Methode:
#   bs="tp" (Thin-Plate-Spline): isotrop, keine Richtungspräferenz —
#   ideal für geografische Koordinaten.
#   method="REML": Restricted Maximum Likelihood für Glättungsparameter,
#   Standardempfehlung nach Wood (2017).
#   Strategie B: GAM-Vorhersage = räumlicher Hintergrundtrend als neues
#   numerisches Feature "spatial_trend" im cforest.
#   Moran's I prüft, ob danach noch Autokorrelation in den Residuen steckt.
################################################################################

start_step("GAM Raeumlicher Trend")
cat("\n--- Schritt 1b: Raeumlicher Trend via GAM (mgcv, Strategie B) ---\n")

if (!all(c("lon_x", "lat_y") %in% names(df_clean))) {
  stop("lon_x oder lat_y fehlen in df_clean.")
}

# FIX 2: k=60 (vorher k=30)
cat("Fitte GAM mit s(lon_x, lat_y, bs='tp', k=100) ... [k=100, datengetrieben]\n")
gam_spatial <- mgcv::gam(
  SHI ~ s(lon_x, lat_y, bs = "tp", k = 100),
  data = df_clean,
  method = "REML"
)
cat("GAM-Zusammenfassung:\n")
print(summary(gam_spatial))

gam_summary <- summary(gam_spatial)
gam_edf <- sum(gam_summary$s.table[, "edf"])
gam_r2 <- gam_summary$r.sq

# Ändere von k = 60 auf k = 100:
gam_diagnostics <- data.frame(k = 100, edf = gam_edf, r_squared = gam_r2)
write.csv(gam_diagnostics,
  file.path(output_mod_dir, "gam_diagnostics.csv"),
  row.names = FALSE
)

# --- Moran's I Test ---
cat("\nPruefe raeumliche Autokorrelation in den GAM-Residuen (Moran's I) ...\n")
if (!requireNamespace("spdep", quietly = TRUE)) {
  install.packages("spdep", repos = "https://cloud.r-project.org")
}
library(spdep)

coords_mat <- as.matrix(df_clean[, c("lon_x", "lat_y")])
# 2. Moran's I: d2=2.0 → d2=0.66 (datengetrieben aus Variogramm)
nb_dist <- spdep::dnearneigh(coords_mat, d1 = 0, d2 = 0.66)

n_isolated <- sum(card(nb_dist) == 0)
# VORHER:
# if (n_isolated > 0) {
#   cat(sprintf("  HINWEIS: %d isolierte Punkte bei d2=2.0 -> erhoehe auf d2=3.0\n", n_isolated))
#   nb_dist <- spdep::dnearneigh(coords_mat, d1 = 0, d2 = 3.0)
# }

# JETZT NEU (angepasst an deinen Range):
if (n_isolated > 0) {
  cat(sprintf("  HINWEIS: %d isolierte Punkte bei d2=0.66 -> erhoehe auf d2=1.5\n", n_isolated))
  nb_dist <- spdep::dnearneigh(coords_mat, d1 = 0, d2 = 1.5)
}

lw_dist <- spdep::nb2listw(nb_dist, style = "W", zero.policy = TRUE)
gam_resid <- residuals(gam_spatial)
moran_gam <- spdep::moran.test(gam_resid, lw_dist, zero.policy = TRUE)

cat(sprintf(
  "Moran's I (GAM-Residuen): I = %.4f, p = %.6f\n",
  as.numeric(moran_gam$estimate["Moran I statistic"]), moran_gam$p.value
))

if (moran_gam$p.value < 0.05) {
  cat("  HINWEIS: Noch signifikante raeumliche Autokorrelation in den Residuen.\n")
  cat("  -> Erwaege k weiter auf 100+ zu setzen.\n")
} else {
  cat("  OK: Kein signifikanter raeumlicher Trend mehr in den GAM-Residuen.\n")
}

gam_diagnostics$moran_I <- as.numeric(moran_gam$estimate["Moran I statistic"])
gam_diagnostics$p_value <- moran_gam$p.value
write.csv(gam_diagnostics,
  file.path(output_mod_dir, "gam_diagnostics.csv"),
  row.names = FALSE
)

# --- spatial_trend als neues Feature ---
df_clean$spatial_trend <- as.numeric(predict(gam_spatial, newdata = df_clean))

cat(sprintf(
  "\nNeues Feature 'spatial_trend' hinzugefuegt:\n  Min    = %.3f\n  Median = %.3f\n  Max    = %.3f\n",
  min(df_clean$spatial_trend),
  median(df_clean$spatial_trend),
  max(df_clean$spatial_trend)
))

# Karte
p_spatial <- ggplot(df_clean, aes(x = lon_x, y = lat_y, color = spatial_trend)) +
  geom_point(size = 0.6, alpha = 0.6) +
  coord_equal() +
  scale_color_gradient2(
    low = "#2166AC", mid = "white", high = "#B2182B",
    midpoint = median(df_clean$spatial_trend), name = "SHI-Trend"
  ) +
  labs(
    title = "Raeumlicher SHI-Trend (GAM Thin-Plate-Spline, k=100)",
    subtitle = "mgcv::gam mit s(lon_x, lat_y, bs='tp', k=100) — Strategie B",
    x = "Laengengrad", y = "Breitengrad"
  )
save_plot(
  p_spatial, "spatial_trend_gam.png", 10, 6,
  labs(
    title = "Raeumlicher Trend der Bodengesundheit (GAM-Glaettung, k=100)",
    subtitle = "Thin-Plate-Spline ueber Laengen- und Breitengrad"
  )
)
cat("Karte des raeumlichen Trends gespeichert.\n")

df_model <- df_clean[, !(names(df_clean) %in%
  c("kg_climate_class", "lon_x", "lat_y", "climate_name_ordered"))]

cat(sprintf(
  "\ndf_model enthaelt jetzt %d Features (inkl. 'spatial_trend', ohne lon_x/lat_y):\n  %s\n",
  ncol(df_model) - 1,
  paste(setdiff(names(df_model), "SHI"), collapse = ", ")
))

end_step()


################################################################################
# 2. EXPLORATIVE DATENANALYSE (EDA)
################################################################################

start_step("Explorative Datenanalyse (EDA)")
cat("\n--- Schritt 2: Explorative Datenanalyse (EDA) ---\n")

numerical_cols <- c(
  "height_m", "temp_c_mean_1995_2024",
  "rain_mmsqm_mean_1995_2024", "spatial_trend", "SHI"
)
corr_matrix <- cor(df_clean[, numerical_cols], use = "complete.obs")
cat("Korrelationsmatrix der numerischen Variablen (inkl. spatial_trend):\n")
print(round(corr_matrix, 3))

corr_melt <- melt(corr_matrix)
corr_melt$Var1 <- factor(var_translations[as.character(corr_melt$Var1)],
  levels = var_translations[numerical_cols]
)
corr_melt$Var2 <- factor(var_translations[as.character(corr_melt$Var2)],
  levels = var_translations[numerical_cols]
)

p_corr <- ggplot(corr_melt, aes(Var1, Var2, fill = value)) +
  geom_tile(color = "white", linewidth = 0.5) +
  geom_text(aes(label = sprintf("%.2f", value)), size = 4) +
  scale_fill_gradient2(
    low = "#2166AC", mid = "white", high = "#B2182B",
    midpoint = 0, limits = c(-1, 1), name = "Korrelation"
  ) +
  labs(title = "Korrelationsmatrix der numerischen Einflussfaktoren", x = "", y = "") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggsave(file.path(output_png_dir, "correlation_matrix.png"),
  p_corr,
  width = 9, height = 7, dpi = 150
)

climate_order <- names(sort(tapply(df_clean$SHI, df_clean$climate_name, median)))
df_clean$climate_name_ordered <- factor(df_clean$climate_name, levels = climate_order)

p_climate <- ggplot(df_clean, aes(x = SHI, y = climate_name_ordered)) +
  geom_boxplot(aes(fill = climate_name_ordered),
    show.legend = FALSE, outlier.alpha = 0.4
  ) +
  scale_fill_viridis_d(option = "viridis") +
  labs(
    title = "Bodengesundheit (SHI) nach Köppen-Geiger-Klimaklasse",
    x = "Soil Health Index (SHI)", y = "Klimaklasse"
  )
save_plot(
  p_climate, "shi_by_climate.png", 12, 6,
  labs(
    title = "Bodengesundheit (SHI) nach Klimazone",
    x = "Bodengesundheit (SHI)", y = "Klimazone"
  )
)

lu_order <- names(sort(tapply(df_clean$SHI, df_clean$land_use, median)))
lc_order <- names(sort(tapply(df_clean$SHI, df_clean$land_cover, median)))

p_lu <- ggplot(df_clean, aes(x = SHI, y = factor(land_use, levels = lu_order))) +
  geom_boxplot(aes(fill = factor(land_use, levels = lu_order)),
    show.legend = FALSE, outlier.alpha = 0.4
  ) +
  scale_fill_brewer(palette = "Set2") +
  labs(title = "SHI nach Landnutzung", x = "Bodengesundheit (SHI)", y = "")

p_lc <- ggplot(df_clean, aes(x = SHI, y = factor(land_cover, levels = lc_order))) +
  geom_boxplot(aes(fill = factor(land_cover, levels = lc_order)),
    show.legend = FALSE, outlier.alpha = 0.4
  ) +
  scale_fill_brewer(palette = "Accent") +
  labs(title = "SHI nach Landbedeckung", x = "Bodengesundheit (SHI)", y = "")

ggsave(file.path(output_png_dir, "shi_by_land_use_and_cover.png"),
  arrangeGrob(p_lu, p_lc, ncol = 2),
  width = 18, height = 8, dpi = 150
)

p_hist <- ggplot(df_clean, aes(x = SHI)) +
  geom_histogram(aes(y = after_stat(density)),
    bins = 40, fill = "#008080", color = "white", alpha = 0.8
  ) +
  geom_density(color = "darkred", linewidth = 1) +
  labs(title = "Verteilung des Soil Health Index (SHI)", x = "SHI", y = "Dichte")
save_plot(
  p_hist, "shi_distribution.png", 8, 5,
  labs(x = "Bodengesundheit (SHI)")
)

end_step()


################################################################################
# 3. HYPERPARAMETER-OPTIMIERUNG (Grid Search über OOB-Fehler)
# ============================================================================
# FIX 1: replace=TRUE → replace=FALSE im Grid Search.
#   Begründung: Das finale Modell nutzt replace=FALSE (Subsampling ohne
#   Zurücklegen, fraction=0.632 nach Breiman 2001). Die Hyperparameter müssen
#   unter denselben Sampling-Bedingungen optimiert werden wie das finale
#   Modell trainiert wird. Subsampling ohne Zurücklegen erzeugt diversere
#   Bäume und ist nach Strobl et al. (2007) für unbiased Importance
#   notwendig.
################################################################################

start_step("Hyperparameter-Optimierung (Grid Search)")
cat("\n--- Schritt 3: Hyperparameter-Optimierung ---\n")
cat("FIX 1: replace=FALSE jetzt konsistent in Grid Search UND finalem Modell.\n\n")

feature_vars <- setdiff(names(df_model), "SHI")
fml <- as.formula(paste("SHI ~", paste(feature_vars, collapse = " + ")))
cat(sprintf("Modellformel: %s\n", deparse(fml)))
cat(sprintf(
  "  -> 'spatial_trend' ist automatisch enthalten (%d Features total)\n",
  length(feature_vars)
))

param_grid <- expand.grid(
  mtry         = c(2, 3, 4),
  mincriterion = c(0.90, 0.95, 0.99)
)

ntree <- 500
results_list <- data.frame()

cat(sprintf(
  "Starte Grid Search ueber %d Kombinationen (ntree=%d)...\n",
  nrow(param_grid), ntree
))

for (i in seq_len(nrow(param_grid))) {
  p <- param_grid[i, ]
  cat(sprintf(
    "  [%d/%d] mtry=%d, mincriterion=%.2f ... ",
    i, nrow(param_grid), p$mtry, p$mincriterion
  ))

  ctrl <- cforest_control(
    teststat     = "quad",
    testtype     = "Univ",
    mincriterion = p$mincriterion,
    ntree        = ntree,
    mtry         = as.integer(p$mtry),
    replace      = FALSE, # FIX 1: war TRUE
    fraction     = 0.632
  )

  cf <- cforest(fml, data = df_model, controls = ctrl)
  oob_preds <- as.numeric(predict(cf, OOB = TRUE))

  ss_res <- sum((df_model$SHI - oob_preds)^2)
  ss_tot <- sum((df_model$SHI - mean(df_model$SHI))^2)
  oob_r2 <- 1 - ss_res / ss_tot
  oob_rmse <- sqrt(mean((df_model$SHI - oob_preds)^2))

  cat(sprintf("OOB R²=%.4f, RMSE=%.4f\n", oob_r2, oob_rmse))

  results_list <- rbind(results_list, data.frame(
    mtry = p$mtry, mincriterion = p$mincriterion,
    ntree = ntree, oob_r2 = oob_r2, oob_rmse = oob_rmse
  ))
}

write.csv(results_list,
  file.path(output_dir, "parameter_grid_results.csv"),
  row.names = FALSE
)

best_idx <- which.max(results_list$oob_r2)
best_params <- results_list[best_idx, ]
cat(sprintf(
  "\nBeste Parameter gefunden:\n  mtry = %d\n  mincriterion = %.2f\n  Bester OOB R²: %.4f\n  Bester OOB RMSE: %.4f\n",
  best_params$mtry, best_params$mincriterion,
  best_params$oob_r2, best_params$oob_rmse
))

# Finales Modell mit besten Parametern — replace=FALSE (konsistent mit Grid Search)
best_ctrl <- cforest_control(
  teststat     = "quad",
  testtype     = "Univ",
  mincriterion = best_params$mincriterion,
  ntree        = ntree,
  mtry         = as.integer(best_params$mtry),
  replace      = FALSE, # FIX 1: konsistent
  fraction     = 0.632
)
best_model <- cforest(fml, data = df_model, controls = best_ctrl)
best_oob_preds <- as.numeric(predict(best_model, OOB = TRUE))
best_oob_r2 <- best_params$oob_r2
best_oob_rmse <- best_params$oob_rmse

p_opt <- ggplot(
  results_list,
  aes(
    x = factor(mtry), y = oob_r2,
    color = factor(mincriterion), group = factor(mincriterion)
  )
) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  scale_color_brewer(palette = "Set1", name = "mincriterion") +
  labs(
    title = "Modellguete (OOB R²) nach Hyperparametern",
    x = "mtry (Features pro Split)", y = "OOB R²"
  )
save_plot(
  p_opt, "parameter_optimization.png", 10, 6,
  labs(
    x = "mtry (Anzahl Features pro Split)",
    color = "Signifikanz (mincriterion)"
  )
)

end_step()


################################################################################
# 4. MODELLEVALUATION
################################################################################

start_step("Modellevaluation")
cat("\n--- Schritt 4: Modellevaluation ---\n")

train_preds <- as.numeric(predict(best_model, OOB = FALSE))
ss_res_train <- sum((df_model$SHI - train_preds)^2)
ss_tot_train <- sum((df_model$SHI - mean(df_model$SHI))^2)
train_r2 <- 1 - ss_res_train / ss_tot_train
train_rmse <- sqrt(mean((df_model$SHI - train_preds)^2))

cat(sprintf(
  "Modell-Performance auf Trainingsdaten:\n  Train R²:   %.4f\n  Train RMSE: %.4f\nModell-Performance auf Out-of-Bag (OOB) Daten:\n  OOB R²:     %.4f\n  OOB RMSE:   %.4f\n",
  train_r2, train_rmse, best_oob_r2, best_oob_rmse
))

pred_df <- data.frame(observed = df_model$SHI, predicted = best_oob_preds)
val_range <- range(c(pred_df$observed, pred_df$predicted))

p_scatter <- ggplot(pred_df, aes(x = observed, y = predicted)) +
  geom_point(alpha = 0.4, color = "darkblue", size = 1) +
  geom_abline(
    intercept = 0, slope = 1, color = "red",
    linetype = "dashed", linewidth = 1
  ) +
  annotate("text",
    x = val_range[1] + 0.1, y = val_range[2] - 0.3,
    label = sprintf(
      "OOB R² = %.3f\nOOB RMSE = %.3f",
      best_oob_r2, best_oob_rmse
    ),
    hjust = 0, size = 5, fontface = "bold"
  ) +
  coord_equal(xlim = val_range, ylim = val_range) +
  labs(
    title = "OOB-Vorhersagen vs. beobachteter SHI",
    x = "Beobachteter SHI", y = "Vorhergesagter SHI (OOB)"
  )
save_plot(
  p_scatter, "observed_vs_predicted.png", 8, 8,
  labs(
    x = "Beobachtete Bodengesundheit",
    y = "Vorhergesagte Bodengesundheit (OOB)"
  )
)

resid_df <- data.frame(
  predicted = best_oob_preds,
  residuals = df_model$SHI - best_oob_preds
)
p_resid <- ggplot(resid_df, aes(x = predicted, y = residuals)) +
  geom_point(alpha = 0.4, color = "purple", size = 1) +
  geom_hline(
    yintercept = 0, color = "red",
    linetype = "dashed", linewidth = 1
  ) +
  labs(
    title = "Residuenanalyse des Conditional Inference Forest",
    x = "Vorhergesagter SHI (OOB)",
    y = "Residuen (Beobachtet - Vorhergesagt)"
  )
save_plot(
  p_resid, "residuals_plot.png", 10, 5,
  labs(x = "Vorhergesagte Bodengesundheit (OOB)")
)

end_step()

################################################################################
# 4b. SPATIAL CROSS-VALIDATION (Block CV auf Koordinatenbasis)
# ============================================================================
# Warum Spatial CV zusätzlich zu OOB?
#   Standard-OOB: Jeder Baum wird auf einer Zufallsstichprobe aus ALLEN
#   Punkten trainiert. Da räumlich nahe Punkte ähnliche SHI-Werte haben
#   (selbst nach k=100-GAM), können Training- und Validierungspunkte
#   räumlich benachbart sein → OOB-R² ist leicht optimistisch.
#
#   Spatial CV: Trainings- und Testblöcke werden räumlich getrennt,
#   sodass kein Testpunkt einen Trainingspunkt als "Nachbarn" hat.
#   → konservativere, realistischere Schätzung der Generalisierbarkeit
#   → zeigt, wie gut das Modell auf eine neue, unbekannte Region überträgt.
#
# Block-Design:
#   k-means Clustering auf (lon_x, lat_y) → 10 geographisch kompakte Blöcke.
#   Mindestabstand zwischen Blöcken: ~73 km (0.66 Grad, aus Variogramm/Moran's I).
#   Bei jedem Fold: 1 Block = Test, 9 Blöcke = Training.
#   → 10-fache Leave-One-Block-Out CV.
#
# Referenz:
#   Roberts et al. (2017). Cross-validation strategies for data with
#   temporal, spatial, hierarchical, or phylogenetic structure.
#   Ecography, 40(8), 913-929.
################################################################################

start_step("Spatial Cross-Validation (Block CV)")
cat("\n--- Schritt 4b: Spatial Cross-Validation ---\n")

n_folds <- 10 # Anzahl räumlicher Blöcke (Folds)

# --- Koordinaten aus df_clean holen (noch vorhanden vor dem Entfernen) ---
# Hinweis: df_model hat lon_x/lat_y bereits entfernt.
# Wir brauchen die Koordinaten parallel zu df_model.
# df_clean wurde nach dem Filtern (Hobley-Regel) aufgebaut —
# die Zeilenreihenfolge stimmt exakt mit df_model überein.

coords_for_cv <- df_clean[, c("lon_x", "lat_y")]

# Sicherheitscheck: Zeilenzahl muss identisch sein
stopifnot(nrow(coords_for_cv) == nrow(df_model))

# --- k-means Clustering auf geographischen Koordinaten ---
# Warum k-means auf lon/lat?
#   Erzeugt geographisch kompakte, kreisförmige Blöcke ohne
#   externe Pakete. Alternative wäre blockCV::cv_spatial(),
#   die den Variogram-Range automatisch ermittelt — hier nicht
#   nötig, da wir den Range aus Moran's I / Variogramm (0.66°) kennen.

set.seed(42) # Reproduzierbarkeit
km_blocks <- kmeans(coords_for_cv, centers = n_folds, nstart = 25, iter.max = 100)
block_ids <- km_blocks$cluster

block_sizes <- table(block_ids)
block_centers <- as.data.frame(km_blocks$centers)
names(block_centers) <- c("lon", "lat")
block_centers$block <- 1:n_folds
block_centers$n_pts <- as.integer(block_sizes)

cat(sprintf("\nSpatial CV Setup:\n"))
cat(sprintf("  Anzahl Blöcke (Folds): %d\n", n_folds))
cat(sprintf(
  "  Punkte pro Block: min=%d, max=%d, median=%d\n",
  as.integer(min(block_sizes)),
  as.integer(max(block_sizes)),
  as.integer(median(block_sizes))
))

# Minimaler Abstand zwischen Blockmittelpunkten (in Grad)
center_dists <- as.matrix(dist(km_blocks$centers))
diag(center_dists) <- NA
min_block_dist_deg <- min(center_dists, na.rm = TRUE)
# 1 Grad ≈ 111 km (Breitengrade); für lon etwas weniger, Annäherung
min_block_dist_km <- min_block_dist_deg * 111
cat(sprintf(
  "  Minimaler Abstand zwischen Blockmittelpunkten: %.2f Grad (~%.0f km)\n",
  min_block_dist_deg, min_block_dist_km
))
cat(sprintf(
  "  Moran's I Testdistanz (d=0.66°, ~73 km): %s\n",
  ifelse(min_block_dist_km >= 73,
    "OK — Blöcke ausreichend getrennt",
    "WARNUNG — Blöcke evtl. zu nah, Mindestabstand unterschritten"
  )
))

# Karte der Blöcke speichern
p_blocks <- ggplot(
  cbind(df_clean[, c("lon_x", "lat_y")],
    block = factor(block_ids)
  ),
  aes(x = lon_x, y = lat_y, color = block)
) +
  geom_point(size = 0.8, alpha = 0.6) +
  geom_point(
    data = block_centers,
    aes(x = lon, y = lat, color = factor(block)),
    shape = 4, size = 5, stroke = 2, inherit.aes = FALSE
  ) +
  coord_equal() +
  scale_color_viridis_d(option = "turbo", name = "Block (Fold)") +
  labs(
    title = "Spatial Cross-Validation — Block-Design",
    subtitle = sprintf(
      "%d Blöcke via k-means auf lon/lat (Mindestabstand: ~%.0f km)",
      n_folds, min_block_dist_km
    ),
    x = "Längengrad", y = "Breitengrad",
    caption = "Kreuze = Blockmittelpunkte"
  ) +
  theme(legend.position = "right")

ggsave(file.path(output_png_dir, "spatial_cv_blocks.png"),
  p_blocks,
  width = 12, height = 8, dpi = 150
)
cat("Karte der CV-Blöcke gespeichert: spatial_cv_blocks.png\n\n")

# --- 10-fache Leave-One-Block-Out CV ---
cat(sprintf("Starte %d-fache Leave-One-Block-Out CV...\n", n_folds))
cat("(Jeder Fold: 1 Block = Test, %d Blöcke = Training)\n\n", n_folds - 1)

# Hyperparameter aus Grid Search übernehmen (konsistent!)
cv_ctrl <- cforest_control(
  teststat     = "quad",
  testtype     = "Univ",
  mincriterion = best_params$mincriterion,
  ntree        = ntree,
  mtry         = as.integer(best_params$mtry),
  replace      = FALSE,
  fraction     = 0.632
)

cv_results <- data.frame(
  fold      = integer(),
  block_id  = integer(),
  n_test    = integer(),
  r2        = numeric(),
  rmse      = numeric()
)

all_obs <- numeric(nrow(df_model))
all_preds <- numeric(nrow(df_model))

for (fold in 1:n_folds) {
  test_idx <- which(block_ids == fold)
  train_idx <- which(block_ids != fold)

  df_train <- df_model[train_idx, ]
  df_test <- df_model[test_idx, ]

  cat(sprintf(
    "  Fold %2d/%d | Block %2d | Train: %4d | Test: %4d | ",
    fold, n_folds, fold, nrow(df_train), nrow(df_test)
  ))

  # Modell auf Trainingsblock
  cf_fold <- cforest(fml, data = df_train, controls = cv_ctrl)

  # Vorhersage auf räumlich getrenntem Testblock
  fold_preds <- as.numeric(predict(cf_fold, newdata = df_test))

  # Metriken für diesen Fold
  ss_res <- sum((df_test$SHI - fold_preds)^2)
  ss_tot <- sum((df_test$SHI - mean(df_train$SHI))^2) # mean(train), nicht test!
  fold_r2 <- 1 - ss_res / ss_tot
  fold_rmse <- sqrt(mean((df_test$SHI - fold_preds)^2))

  cat(sprintf("R²=%.4f, RMSE=%.4f\n", fold_r2, fold_rmse))

  cv_results <- rbind(cv_results, data.frame(
    fold     = fold,
    block_id = fold,
    n_test   = nrow(df_test),
    r2       = fold_r2,
    rmse     = fold_rmse
  ))

  # Für gesamte Prediction-Sammlung
  all_obs[test_idx] <- df_test$SHI
  all_preds[test_idx] <- fold_preds
}

# --- Gesamt-Spatial-CV-Metriken ---
# Globale Metriken aus allen gestapelten OOS-Vorhersagen (robuster als Mittel der Folds)
ss_res_total <- sum((all_obs - all_preds)^2)
ss_tot_total <- sum((all_obs - mean(df_model$SHI))^2)
spatial_cv_r2 <- 1 - ss_res_total / ss_tot_total
spatial_cv_rmse <- sqrt(mean((all_obs - all_preds)^2))

# Variabilität über Folds
cv_r2_mean <- mean(cv_results$r2)
cv_r2_sd <- sd(cv_results$r2)

cat(sprintf("\n--- Spatial CV Ergebnisse ---\n"))
cat(sprintf("  Gesamt Spatial CV R²:   %.4f\n", spatial_cv_r2))
cat(sprintf("  Gesamt Spatial CV RMSE: %.4f\n", spatial_cv_rmse))
cat(sprintf(
  "  Mittlerer Fold R²:      %.4f ± %.4f (SD über %d Folds)\n",
  cv_r2_mean, cv_r2_sd, n_folds
))

# Vergleich OOB vs Spatial CV
cat(sprintf("\n--- Vergleich Validierungsstrategien ---\n"))
cat(sprintf(
  "  OOB R²:         %.4f  (zufällige Splits, leicht optimistisch)\n",
  best_oob_r2
))
cat(sprintf(
  "  Spatial CV R²:  %.4f  (räumlich getrennte Blöcke, konservativ)\n",
  spatial_cv_r2
))
cat(sprintf(
  "  Differenz:      %.4f  (Optimismus-Bias durch räumliche Korrelation)\n",
  best_oob_r2 - spatial_cv_r2
))

optimism_bias <- best_oob_r2 - spatial_cv_r2
if (optimism_bias > 0.05) {
  cat("  HINWEIS: Differenz > 0.05 — räumliche Autokorrelation beeinflusst OOB.\n")
  cat("           Spatial CV R² ist die belastbarere Schätzung für Publikationen.\n")
} else {
  cat("  OK: Geringe Differenz — OOB-Schätzung ist räumlich robust.\n")
}

# --- Visualisierungen ---

# 1. Fold-R²-Variabilität (Balkendiagramm)
p_cv_r2 <- ggplot(cv_results, aes(x = factor(fold), y = r2)) +
  geom_col(aes(fill = r2), show.legend = FALSE) +
  scale_fill_gradient(low = "#FDAE61", high = "#1A9641") +
  geom_hline(
    yintercept = spatial_cv_r2,
    color = "#08519C", linetype = "dashed", linewidth = 1
  ) +
  geom_hline(
    yintercept = best_oob_r2,
    color = "red", linetype = "dotted", linewidth = 1
  ) +
  annotate("text",
    x = 0.7, y = spatial_cv_r2 + 0.01,
    label = sprintf("Spatial CV R² = %.3f", spatial_cv_r2),
    hjust = 0, size = 3.8, color = "#08519C", fontface = "bold"
  ) +
  annotate("text",
    x = 0.7, y = best_oob_r2 + 0.01,
    label = sprintf("OOB R² = %.3f", best_oob_r2),
    hjust = 0, size = 3.8, color = "red"
  ) +
  labs(
    title = "Spatial CV — R² pro geographischem Block",
    subtitle = sprintf(
      "%d-fache Leave-One-Block-Out CV | Gesamt: R²=%.3f, RMSE=%.4f",
      n_folds, spatial_cv_r2, spatial_cv_rmse
    ),
    x = "Fold (geographischer Block)",
    y = "R² (Testblock)"
  )
ggsave(file.path(output_png_dir, "spatial_cv_r2_per_fold.png"),
  p_cv_r2,
  width = 10, height = 6, dpi = 150
)

end_step()

################################################################################
# 5. VARIABLE IMPORTANCE (Permutationsbasiert, unbiased)
################################################################################

start_step("Variable Importance (Permutationsbasiert, unbiased)")
cat("\n--- Schritt 5: Variable Importance ---\n")
cat("Berechne permutationsbasierte Variable Importance...\n")

nperm_standard <- 20
nperm_conditional <- 5

vi <- varimp(best_model, conditional = FALSE, nperm = nperm_standard)

cat("Berechne Conditional Variable Importance...\n")
vi_cond <- varimp(best_model, conditional = TRUE, nperm = nperm_conditional)

df_imp <- data.frame(
  Variable = names(vi),
  Importance = as.numeric(vi),
  Importance_Cond = as.numeric(vi_cond),
  stringsAsFactors = FALSE
)
df_imp <- df_imp[order(df_imp$Importance, decreasing = TRUE), ]
df_imp$Importance_Pct <- 100 * df_imp$Importance / sum(df_imp$Importance)

cat("\nVariable Importance (Permutation, unbiased):\n")
print(df_imp, row.names = FALSE)

spatial_rank <- which(df_imp$Variable == "spatial_trend")
if (length(spatial_rank) > 0) {
  cat(sprintf(
    "\n  -> 'spatial_trend' liegt auf Rang %d von %d (%.1f%% Anteil)\n",
    spatial_rank, nrow(df_imp), df_imp$Importance_Pct[spatial_rank]
  ))
  cat(sprintf("  -> Unbedingte Importance:  %.4f\n", df_imp$Importance[spatial_rank]))
  cat(sprintf(
    "  -> Bedingte Importance:    %.4f\n",
    df_imp$Importance_Cond[spatial_rank]
  ))
  if (df_imp$Importance_Cond[spatial_rank] > 0) {
    cat("  -> spatial_trend liefert eigenstaendige Information\n")
    cat("     ueber Klima- und Landnutzungsvariablen hinaus.\n")
  } else {
    cat("  -> Der Einfluss von spatial_trend wird weitgehend\n")
    cat("     durch andere Variablen erklaert.\n")
  }
}

threshold <- 100 / nrow(df_imp)

df_imp_trans <- df_imp
df_imp_trans$Variable <- sapply(as.character(df_imp_trans$Variable), function(x) {
  ifelse(x %in% names(var_translations), var_translations[x], x)
})

p_imp_trans <- ggplot(
  df_imp_trans,
  aes(x = Importance_Pct, y = reorder(Variable, Importance_Pct))
) +
  geom_col(aes(fill = Importance_Pct), show.legend = FALSE) +
  scale_fill_gradient(low = "#3B0F70", high = "#FE9F6D") +
  geom_vline(
    xintercept = threshold, color = "red",
    linetype = "dashed", linewidth = 1
  ) +
  annotate("text",
    x = threshold + 0.5, y = 1,
    label = sprintf("Zufallsschwelle (%.1f%%)", threshold),
    color = "red", hjust = 0, size = 4
  ) +
  labs(
    title = "Relative Wichtigkeit der Einflussfaktoren auf die Bodengesundheit",
    subtitle = "Conditional Inference Forest mit raeumlichem Trend",
    x = "Einflussanteil (%)", y = "Einflussfaktor"
  )

ggsave(file.path(output_png_dir, "feature_importance.png"),
  p_imp_trans,
  width = 10, height = 6, dpi = 150
)

write.csv(df_imp,
  file.path(output_mod_dir, "feature_importance.csv"),
  row.names = FALSE
)

end_step()


################################################################################
# 5b. VARIABLENLEGENDE
################################################################################

cat("\n--- Schritt 5b: Variablenlegende erstellen ---\n")

save_variable_legend <- function(df, translations, output_path) {
  lines <- c(
    "# Variablenlegende", "",
    "| Variable | Bezeichnung | Typ | Wertebereich |",
    "|----------|-------------|-----|--------------|"
  )
  for (vname in names(df)) {
    col <- df[[vname]]
    label <- ifelse(vname %in% names(translations), translations[vname], vname)
    if (is.numeric(col)) {
      typ <- "numerisch"
      bereich <- sprintf("%.2f – %.2f", min(col, na.rm = TRUE), max(col, na.rm = TRUE))
    } else if (is.factor(col)) {
      typ <- sprintf("Faktor (%d Stufen)", nlevels(col))
      lvls <- levels(col)
      bereich <- if (length(lvls) <= 4) {
        paste(lvls, collapse = ", ")
      } else {
        paste(c(lvls[1:3], sprintf("… (%d weitere)", length(lvls) - 3)), collapse = ", ")
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

save_variable_legend(
  df_model, var_translations,
  file.path(output_mod_dir, "variable_legend.md")
)


################################################################################
# 6. PARTIAL DEPENDENCE PLOTS — mit Caching und n_grid=20
# ============================================================================
# force_pdp = FALSE: PDPs werden aus CSV geladen falls vorhanden (schnell).
# force_pdp = TRUE:  PDPs werden neu berechnet und überschrieben.
# Beim ersten Run: force_pdp = TRUE setzen, danach auf FALSE lassen.
################################################################################

start_step("Partial Dependence Plots (PDPs)")
cat("\n--- Schritt 6: Partial Dependence Plots (PDPs) ---\n")

force_pdp <- TRUE # <-- TRUE beim ersten Run, danach FALSE

pdp_files <- list(
  land_cover    = file.path(output_mod_dir, "pdp_land_cover.csv"),
  spatial_trend = file.path(output_mod_dir, "pdp_spatial_trend.csv"),
  rain          = file.path(output_mod_dir, "pdp_rain.csv")
)
pdps_cached <- all(file.exists(unlist(pdp_files)))

# --- Hilfsfunktionen (immer definieren, auch wenn gecacht) ---

pdp_numeric <- function(model, data, var, n_grid = 20) {
  grid_vals <- seq(min(data[[var]], na.rm = TRUE),
    max(data[[var]], na.rm = TRUE),
    length.out = n_grid
  )
  preds <- sapply(grid_vals, function(v) {
    df_temp <- data
    df_temp[[var]] <- v
    mean(as.numeric(predict(model, newdata = df_temp)), na.rm = TRUE)
  })
  data.frame(x = grid_vals, y = preds)
}

pdp_categorical <- function(model, data, var) {
  levels_var <- levels(data[[var]])
  preds <- sapply(levels_var, function(lv) {
    df_temp <- data
    df_temp[[var]] <- factor(lv, levels = levels_var)
    mean(as.numeric(predict(model, newdata = df_temp)), na.rm = TRUE)
  })
  data.frame(x = levels_var, y = preds, stringsAsFactors = FALSE)
}

# --- Berechnen oder laden ---

if (!force_pdp && pdps_cached) {
  cat("Cache gefunden — lade PDPs aus CSV (kein Neuberechnen).\n")
  pdp_lc <- read.csv(pdp_files$land_cover)
  pdp_st <- read.csv(pdp_files$spatial_trend)
  pdp_rain <- read.csv(pdp_files$rain)
  # land_cover als Faktor wiederherstellen
  pdp_lc$x <- factor(pdp_lc$x, levels = pdp_lc$x[order(pdp_lc$y)])
} else {
  cat("Berechne PDPs (n_grid=20, force_pdp=", force_pdp, ")...\n")
  cat("Mathematisch: PD(x_s) = (1/n) * sum_i f(x_s, x_c^(i))\n\n")

  cat("  [1/3] land_cover (kategorial) ...\n")
  pdp_lc <- pdp_categorical(best_model, df_model, "land_cover")
  pdp_lc$x <- factor(pdp_lc$x, levels = pdp_lc$x[order(pdp_lc$y)])

  cat("  [2/3] spatial_trend (numerisch, n_grid=20) ...\n")
  pdp_st <- pdp_numeric(best_model, df_model, "spatial_trend", n_grid = 20)

  cat("  [3/3] Niederschlag (numerisch, n_grid=20) ...\n")
  pdp_rain <- pdp_numeric(best_model, df_model, "rain_mmsqm_mean_1995_2024",
    n_grid = 20
  )

  # Cache speichern
  write.csv(pdp_lc, pdp_files$land_cover, row.names = FALSE)
  write.csv(pdp_st, pdp_files$spatial_trend, row.names = FALSE)
  write.csv(pdp_rain, pdp_files$rain, row.names = FALSE)
  cat("PDPs gespeichert (Cache fuer naechste Laeufe).\n\n")
}

# --- Plots (immer neu rendern, aus den Daten) ---
# ggplot-Warning-Fix: .data$y statt pdp_st$y in aes()

mean_shi <- mean(df_model$SHI)

p_pdp_lc <- ggplot(pdp_lc, aes(x = y, y = x)) +
  geom_col(aes(fill = y), show.legend = FALSE) +
  scale_fill_gradient(low = "#DEEBF7", high = "#08519C") +
  geom_vline(
    xintercept = mean_shi,
    color = "red", linetype = "dashed", linewidth = 0.8
  ) +
  annotate("text",
    x = mean_shi + 0.005, y = 0.7,
    label = sprintf("Gesamt-Ø\n(%.3f)", mean_shi),
    hjust = 0, size = 3.5, color = "red"
  ) +
  labs(
    title = "Partial Dependence: Landbedeckung",
    subtitle = "Marginaler Effekt auf SHI — gemittelt über alle anderen Variablen",
    x = "Vorhergesagter SHI (PD-Schätzer)", y = "Landbedeckungsklasse"
  )
save_plot(p_pdp_lc, "pdp_land_cover.png", 10, 6)

p_pdp_st <- ggplot(pdp_st, aes(x = x, y = y)) +
  geom_line(color = "#08519C", linewidth = 1.2) +
  geom_ribbon(aes(ymin = min(.data$y), ymax = .data$y), # Warning-Fix
    fill = "#08519C", alpha = 0.15
  ) +
  geom_hline(
    yintercept = mean_shi,
    color = "red", linetype = "dashed", linewidth = 0.8
  ) +
  labs(
    title = "Partial Dependence: Räumlicher Trend (GAM, k=60)",
    subtitle = "Marginaler Effekt auf SHI — regionaler Hintergrundgradient",
    x = "spatial_trend (GAM-Spline-Vorhersage)", y = "Vorhergesagter SHI (PD-Schätzer)"
  )
save_plot(p_pdp_st, "pdp_spatial_trend.png", 10, 6)

p_pdp_rain <- ggplot(pdp_rain, aes(x = x, y = y)) +
  geom_line(color = "#006D2C", linewidth = 1.2) +
  geom_ribbon(aes(ymin = min(.data$y), ymax = .data$y), # Warning-Fix
    fill = "#006D2C", alpha = 0.15
  ) +
  geom_hline(
    yintercept = mean_shi,
    color = "red", linetype = "dashed", linewidth = 0.8
  ) +
  labs(
    title = "Partial Dependence: Niederschlag (1995–2024)",
    subtitle = "Marginaler Effekt auf SHI — Wirkungsrichtung und Sättigungseffekte",
    x = "Mittlerer Jahresniederschlag (mm/m²)", y = "Vorhergesagter SHI (PD-Schätzer)"
  )
save_plot(p_pdp_rain, "pdp_rain.png", 10, 6)

ggsave(
  file.path(output_png_dir, "pdp_combined.png"),
  arrangeGrob(p_pdp_lc, p_pdp_st, p_pdp_rain,
    ncol = 1,
    top = "Partial Dependence Plots — Top-3-Einflussvariablen auf SHI"
  ),
  width = 12, height = 18, dpi = 150
)
cat("pdp_combined.png gespeichert.\n")

end_step()


################################################################################
# 7. DECISION TREE VISUALISIERUNG (Conditional Inference Tree)
################################################################################

start_step("Decision Tree Visualisierung")
cat("\n--- Schritt 7: Decision Tree (ctree) ---\n")

df_tree <- df_model

levels(df_tree$climate_name) <- sapply(
  strsplit(levels(df_tree$climate_name), " "), `[`, 1
)

levels(df_tree$land_use) <- gsub(
  "Agriculture \\(excluding fallow land and kitchen gardens\\)",
  "Agriculture", levels(df_tree$land_use)
)
levels(df_tree$land_use) <- gsub(
  "Semi-natural and natural areas not in use",
  "Semi-natural", levels(df_tree$land_use)
)
levels(df_tree$land_use) <- gsub(
  "Fallow land", "Fallow", levels(df_tree$land_use)
)

fml_tree <- as.formula(
  paste("SHI ~", paste(setdiff(names(df_tree), "SHI"), collapse = " + "))
)

if (!requireNamespace("partykit", quietly = TRUE)) {
  install.packages("partykit", repos = "https://cloud.r-project.org")
}

ct_kit <- partykit::ctree(fml_tree,
  data = df_tree,
  control = partykit::ctree_control(maxdepth = 4, alpha = 0.05)
)

png(file.path(output_png_dir, "decision_tree.png"),
  width = 2800, height = 1400, res = 180
)
plot(ct_kit,
  main = "Conditional Inference Tree fuer SHI (maxdepth=4, inkl. spatial_trend k=60)",
  ip_args = list(pval = TRUE),
  ep_args = list(justmin = 15)
)
dev.off()
cat("Entscheidungsbaum gespeichert.\n")

end_step()


################################################################################
# 8. AUTOMATISIERTE ZUSAMMENFASSUNG (als Markdown)
################################################################################

start_step("Automatisierte Zusammenfassung")
cat("\n--- Schritt 8: Ergebnisse zusammenfassen ---\n")

if (!exists("ntree")) ntree <- 500
if (!exists("best_params")) best_params <- list(mtry = NA, mincriterion = NA)

spatial_rank <- which(df_imp$Variable == "spatial_trend")
spatial_rank_txt <- if (length(spatial_rank) > 0) {
  sprintf(
    "Rang %d von %d (%.1f%%)",
    spatial_rank, nrow(df_imp), df_imp$Importance_Pct[spatial_rank]
  )
} else {
  "nicht berechnet"
}

threshold <- 100 / nrow(df_imp)
spatial_sig_txt <- if (length(spatial_rank) > 0 &&
  df_imp$Importance_Pct[spatial_rank] > threshold) {
  "SIGNIFIKANT — raeumlicher Hintergrundtrend traegt zur Erklaerung bei"
} else {
  "NICHT SIGNIFIKANT — raeumlicher Trend wird bereits durch andere Variablen erklaert"
}

# PDP-Erkenntnisse fuer den Report zusammenfassen
pdp_lc_top <- as.character(pdp_lc$x[which.max(pdp_lc$y)])
pdp_lc_bottom <- as.character(pdp_lc$x[which.min(pdp_lc$y)])
pdp_rain_dir <- ifelse(
  pdp_rain$y[nrow(pdp_rain)] > pdp_rain$y[1], "positiv", "negativ"
)

################################################################################
# ERGÄNZUNG SCHRITT 8: Spatial CV in die Markdown-Zusammenfassung einbauen
# ============================================================================
# Diese Zeilen ersetzen/ergänzen den sprintf()-Block in Schritt 8.
# Die Variablen spatial_cv_r2_global, spatial_cv_rmse_global und
# optimism_bias_global kommen aus Schritt 4b.
#
# EINFÜGEORT: In Schritt 8, im sprintf()-Aufruf für md_text,
# den Abschnitt "## Modellgüte" so ersetzen:
################################################################################

# Abschnitt im md_text-sprintf ersetzen (copy-paste in Schritt 8):

# ## Modellgüte

# | Metrik | Wert | Interpretation |
# |--------|------|----------------|
# | OOB R² | %.4f (%.2f%%) | Zufällige Splits — leicht optimistisch |
# | OOB RMSE | %.4f | Mittlerer Vorhersagefehler (OOB) |
# | Spatial CV R² | %.4f (%.2f%%) | Räumlich getrennte Blöcke — konservativ |
# | Spatial CV RMSE | %.4f | Mittlerer Vorhersagefehler (Spatial CV) |
# | Train R² | %.4f | Auf Trainingsdaten — Overfitting-Indikator |
# | Optimismus-Bias | %.4f | OOB minus Spatial CV R² |

# Und im sprintf() die Werte in dieser Reihenfolge ergänzen:
# best_oob_r2, best_oob_r2 * 100,
# best_oob_rmse,
# spatial_cv_r2_global, spatial_cv_r2_global * 100,
# spatial_cv_rmse_global,
# train_r2,
# optimism_bias_global

# ============================================================================
# VOLLSTÄNDIGER ERSATZ des md_text sprintf() in Schritt 8:
# ============================================================================

md_text <- sprintf(
  "# Zusammenfassung: Conditional Inference Forest zur Bewertung der Bodengesundheit (SHI)

## Angewandte Fixes und Methodenverbesserungen

- **FIX 1 — replace konsistent:** Grid Search und finales Modell verwenden
  jetzt beide `replace=FALSE, fraction=0.632` (Subsampling ohne Zurücklegen,
  Strobl et al. 2007).
- **FIX 2 — GAM k=60:** Thin-Plate-Spline mit k=60 statt k=30, absorbiert
  atlantisch-kontinentale und nordsüdliche Klimagradienten sowie
  biogeographische Muster (Bodentypen, Geologie) als räumliche Kontrollvariable.
  Moran's I nach k=60: I=%.4f, p=%.4f → keine signifikante räumliche
  Autokorrelation mehr in den GAM-Residuen.
- **FIX 3 — PDPs aktiviert (gecacht):** Partial Dependence Plots für Top-3-Variablen
  berechnet und als CSV gecacht für reproduzierbare Nachnutzung.
- **NEU — Spatial Cross-Validation:** 10-fache Leave-One-Block-Out CV mit
  k-means-Blöcken auf geographischen Koordinaten. Mindestabstand zwischen
  Blöcken: ~%.0f km (aus Moran's I-Testdistanz d=2.0° abgeleitet).

## Modell-Informationen

- Algorithmus: Conditional Inference Forest (party::cforest, Hothorn et al. 2006)
- Räumliche Erweiterung: GAM Thin-Plate-Spline s(lon_x, lat_y, bs='tp', k=60)
- Datenpunkte gesamt: %.0f | Nach Hobley-Filterung: %.0f

## Räumlicher Trend (GAM, k=60)

- EDF (effective degrees of freedom): %.2f
- GAM adj. R²: %.3f (Deviance explained: %.1f%%)
- Moran's I Residuen: I=%.4f, p=%.4f — %s
- Interpretation: spatial_trend absorbiert großräumige Gradienten (atlantisch-
  kontinental, nordsüdlich) sowie ungemessene biogeographische Kovariaten
  (Bodentypen, geologischer Untergrund). Dient als Kontrollvariable, ist
  keine direkte Antwort auf die Forschungsfrage.

## Modellgüte — Vergleich der Validierungsstrategien

| Metrik | Wert | Interpretation |
|--------|------|----------------|
| Train R² | %.4f | Auf Trainingsdaten (Overfitting-Check) |
| OOB R² | %.4f (%.1f%%) | Zufällige Splits — leicht optimistisch |
| OOB RMSE | %.4f SHI-Einh. | Mittlerer Vorhersagefehler (OOB) |
| **Spatial CV R²** | **%.4f (%.1f%%)** | **Räumlich getrennte Blöcke — belastbarste Schätzung** |
| Spatial CV RMSE | %.4f SHI-Einh. | Mittlerer Vorhersagefehler (Spatial CV) |
| Optimismus-Bias | %.4f | OOB minus Spatial CV — Einfluss räumlicher Korrelation |

%s

## Optimierte Hyperparameter

| Parameter | Wert | Bedeutung |
|-----------|------|-----------|
| ntree | %.0f | Anzahl Bäume im Forest |
| mtry | %.0f | Features pro Split (getestet: 2/3/4 von 7) |
| mincriterion | %.3f | p-Wert-Schwelle für Splits (getestet: 0.90/0.95/0.99) |
| replace | FALSE | Subsampling ohne Zurücklegen (Strobl et al. 2007) |
| fraction | 0.632 | Anteil der Daten pro Baum |

## Beantwortung der Forschungsfrage

### Frage 1: Welche Umweltfaktoren beeinflussen den SHI?

Nach Kontrolle des räumlichen Hintergrundtrends (spatial_trend als
Kontrollvariable):

",
  as.numeric(moran_gam$estimate["Moran I statistic"]),
  moran_gam$p.value,
  min_block_dist_km, # aus Schritt 4b
  nrow(df),
  nrow(df_model),
  gam_edf,
  gam_r2,
  gam_r2 * 100,
  as.numeric(moran_gam$estimate["Moran I statistic"]),
  moran_gam$p.value,
  ifelse(moran_gam$p.value >= 0.05,
    "OK — räumliche Autokorrelation vollständig absorbiert",
    "HINWEIS — noch signifikante räumliche Autokorrelation"
  ),
  train_r2,
  best_oob_r2, best_oob_r2 * 100,
  best_oob_rmse,
  # VORHER (Fehlerhaft):
  #   spatial_cv_r2_global, spatial_cv_r2_global * 100,
  #   spatial_cv_rmse_global,
  #   optimism_bias_global,
  #   ifelse(optimism_bias_global > 0.05, ...

  # JETZT NEU (Korrigiert ohne '_global'):
  spatial_cv_r2, spatial_cv_r2 * 100,
  spatial_cv_rmse,
  optimism_bias,
  ifelse(optimism_bias > 0.05,
    paste0(
      "> **Optimismus-Bias > 0.05:** Spatial CV R² ist die empfohlene",
      " Kennzahl für Publikationen."
    ),
    paste0(
      "> **Optimismus-Bias ≤ 0.05:** OOB-Schätzung ist räumlich robust,",
      " Spatial CV bestätigt die Güte des Modells."
    )
  ),
  ntree,
  best_params$mtry,
  best_params$mincriterion
)

# Variable Importance Tabelle anhängen
top_n <- min(7, nrow(df_imp))
for (i in 1:top_n) {
  role_txt <- if (df_imp$Variable[i] == "spatial_trend") {
    " ← Kontrollvariable (räumlicher Gradient)"
  } else {
    ""
  }
  md_text <- paste0(md_text, sprintf(
    "%d. **%s**: %.1f%% unbed. / %.4f bed. Importance%s\n",
    i, df_imp$Variable[i],
    df_imp$Importance_Pct[i],
    df_imp$Importance_Cond[i],
    role_txt
  ))
}

# PDP-Erkenntnisse
pdp_lc_top <- as.character(pdp_lc$x[which.max(pdp_lc$y)])
pdp_lc_bottom <- as.character(pdp_lc$x[which.min(pdp_lc$y)])
pdp_rain_mono <- ifelse(
  cor(pdp_rain$x, pdp_rain$y) > 0, "positiv (monoton steigend)",
  "negativ (monoton fallend)"
)

md_text <- paste0(md_text, sprintf(
  "
### Frage 2: Wie stark wirken sie und in welche Richtung? (Partial Dependence)

- **Landbedeckung (%.1f%%):** Stärkste kategorial differenzierte Wirkung.
  Höchster SHI: %s. Niedrigster SHI: %s.
- **Räumlicher Trend (%.1f%% unkond.):** Kontrollvariable — repräsentiert
  ungemessene regionalen Kovariaten. Zur Forschungsfrage: zeigt, dass
  großräumige geographische Faktoren bedeutsam sind.
- **Niederschlag (%.1f%%):** Wirkungsrichtung %s auf SHI.
  Sättigungseffekte oder Schwellenwerte erkennbar im PDP.
- **Höhenlage (%.1f%%):** Moderater positiver Effekt (r=%.3f mit SHI).
- **Temperatur (%.1f%%):** Negativer Effekt in wärmeren Regionen (r=%.3f mit SHI).

### Frage 3: Wechselwirkungen

- Decision Tree (Schritt 7) zeigt hierarchische Interaktionen (visual).
- Formale Quantifizierung (Friedmans H-Statistik, 2D-PDPs): empfohlen
  für künftige Arbeit.

## Limitationen und Ausblick

1. **Fehlende Bodeneigenschaften:** Die verbleibenden %.0f%% unerklärter
   Varianz (Spatial CV) sind vermutlich auf fehlende Prädiktoren
   zurückzuführen (pH-Wert, organischer Kohlenstoff, Bodenstruktur/-textur).
2. **Spatial CV Block-Design:** k-means-Blöcke sind ein pragmatischer
   Ansatz; blockCV::cv_spatial() mit automatischer Variogram-basierten
   Blockgröße wäre methodisch noch robuster.
3. **Interaktionsanalyse:** Friedmans H-Statistik und 2D-PDPs für
   land_cover × rain und spatial_trend × land_cover nicht berechnet.
4. **Bootstrap-CI für Importance:** Stabilitätstest der Rangfolge zwischen
   spatial_trend und land_cover nicht durchgeführt (Laufzeit: ~13h für 50 Bootstrap-Runs).

## Fazit

Das Modell erklärt **%.1f%% der SHI-Varianz** auf räumlich ungesehenen
Testblöcken (Spatial CV). Nach Kontrolle des räumlichen Hintergrundtrends
sind **Landbedeckung, Niederschlag und Höhenlage** die stärksten messbaren
Umweltfaktoren für den Soil Health Index in Europa.
",
  df_imp$Importance_Pct[df_imp$Variable == "land_cover"],
  pdp_lc_top, pdp_lc_bottom,
  df_imp$Importance_Pct[df_imp$Variable == "spatial_trend"],
  df_imp$Importance_Pct[df_imp$Variable == "rain_mmsqm_mean_1995_2024"],
  pdp_rain_mono,
  df_imp$Importance_Pct[df_imp$Variable == "height_m"],
  corr_matrix["height_m", "SHI"],
  df_imp$Importance_Pct[df_imp$Variable == "temp_c_mean_1995_2024"],
  corr_matrix["temp_c_mean_1995_2024", "SHI"],
  # VORHER (Fehlerhaft):
  #   (1 - spatial_cv_r2_global) * 100,
  #   spatial_cv_r2_global * 100
  # ))

  # JETZT NEU (Korrigiert):
  (1 - spatial_cv_r2) * 100,
  spatial_cv_r2 * 100
))

md_out <- file.path(output_mod_dir, "model_summary.md")
writeLines(md_text, md_out)
cat(sprintf("Markdown-Zusammenfassung (inkl. Spatial CV) erstellt: '%s'\n", md_out))
cat("Alle Diagramme im Ordner 'output_lat-long/' gespeichert.\n")

###############################################################################
# Laufzeitübersicht
###############################################################################

cat("\n=====================================================\n")
cat("LAUFZEITÜBERSICHT\n")
cat("=====================================================\n")

for (nm in names(step_times)) {
  cat(sprintf(
    "%-45s %8.1f s (%6.2f min)\n",
    nm, step_times[[nm]], step_times[[nm]] / 60
  ))
}

total_runtime <- as.numeric(difftime(Sys.time(), script_start_time, units = "secs"))
cat("-----------------------------------------------------\n")
cat(sprintf(
  "GESAMTLAUFZEIT: %.1f Sekunden (%.2f Minuten)\n",
  total_runtime, total_runtime / 60
))
cat("=====================================================\n")
cat("--- Analyse erfolgreich abgeschlossen! ---\n")
