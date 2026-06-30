################################################################################
# VISUALISIERUNG DER THIN PLATE SPLINE (TPS) ANPASSUNG (GAM)
# ============================================================================
# Dieses Skript fittet den 2D-Thin-Plate-Spline (GAM) über Europa neu
# und generiert hochauflösende 2D- und 3D-Diagramme der interpolierten
# Bodengesundheit (SHI).
################################################################################

# --- Pakete laden ---
cat("Lade benötigte Pakete...\n")
library(mgcv) # Für GAM / Thin-Plate-Spline
library(ggplot2) # Für 2D-Visualisierung
library(sf) # Für räumliche Maskierung (Projektion und Buffer)
library(plotly) # Für interaktive 3D-Visualisierung
library(htmlwidgets)

# Reproduzierbarkeit
set.seed(42)

# --- Pfade konfigurieren ---
if (file.exists("input/Daten/points.csv")) {
  base_dir <- "."
} else if (file.exists("../input/Daten/points.csv")) {
  base_dir <- ".."
} else {
  stop(
    "Kann die Eingabedatei 'input/Daten/points.csv' nicht finden. ",
    "Bitte starte das Skript aus dem Projektverzeichnis."
  )
}

input_csv <- file.path(base_dir, "input", "Daten", "points.csv")
output_dir <- file.path(base_dir, "output_lat-long", "tps_fitting_plot-Modell")
output_png_dir <- output_dir

dir.create(output_png_dir, showWarnings = FALSE, recursive = TRUE)

# --- ggplot2-Theme für Publikationen ---
theme_pub <- theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "grey30"),
    axis.title = element_text(size = 13),
    axis.text = element_text(size = 11),
    legend.title = element_text(size = 12, face = "bold"),
    legend.text = element_text(size = 10),
    panel.grid.minor = element_blank(),
    panel.background = element_rect(fill = "#f8f9fa", color = NA),
    plot.background = element_rect(fill = "white", color = NA)
  )
theme_set(theme_pub)

################################################################################
# 1. DATEN EINLESEN & BEREINIGEN (Analog zum Hauptmodell)
################################################################################
cat("Lese Daten ein...\n")
df <- read.csv(input_csv, stringsAsFactors = FALSE)

# Identifier-Spalten ausschließen (lon_x und lat_y bleiben erhalten)
exclude_cols <- c("POINT_ID", "X", "Y")
df_clean <- df[, !(names(df) %in% exclude_cols)]

# Hobley-Filterung (<30 Beobachtungen ausschließen)
cat_cols <- c("land_use", "land_cover", "kg_climate_class")
df_clean$kg_climate_class <- as.integer(df_clean$kg_climate_class)

for (col in cat_cols) {
  counts <- table(df_clean[[col]])
  low_cats <- names(counts[counts < 30])
  if (length(low_cats) > 0) {
    df_clean <- df_clean[!(df_clean[[col]] %in% low_cats), ]
  }
}
rownames(df_clean) <- NULL
cat(sprintf("Daten erfolgreich bereinigt. Verbleibende Zeilen: %d\n", nrow(df_clean)))

################################################################################
# 2. GAM (THIN PLATE SPLINE) FIT
################################################################################
cat("Fitte GAM mit Thin-Plate-Spline s(lon_x, lat_y, bs='tp', k=30)...\n")
gam_spatial <- mgcv::gam(
  SHI ~ s(lon_x, lat_y, bs = "tp", k = 30),
  data = df_clean,
  method = "REML"
)
cat("Spline-Fitting abgeschlossen.\n")

################################################################################
# 3. ERSTELLUNG DES REPRÄSENTATIVEN GITTERS & RÄUMLICHE MASKIERUNG
# ============================================================================
# Um eine Extrapolation in Gebieten ohne Daten (z.B. Atlantik) zu verhindern,
# maskieren wir das Gitter mit einem 150km Puffer um die tatsächlichen Datenpunkte.
################################################################################
cat("Erstelle Vorhersage-Gitter und maskiere räumliche Ausdehnung...\n")

# Gitter über die Bounding-Box der Daten erstellen
n_grid <- 250
lon_seq <- seq(min(df_clean$lon_x) - 0.5, max(df_clean$lon_x) + 0.5, length.out = n_grid)
lat_seq <- seq(min(df_clean$lat_y) - 0.5, max(df_clean$lat_y) + 0.5, length.out = n_grid)
grid_df <- expand.grid(lon_x = lon_seq, lat_y = lat_seq)

# Konvertiere Datenpunkte und Gitter zu sf-Objekten
points_sf <- st_as_sf(df_clean, coords = c("lon_x", "lat_y"), crs = 4326)
grid_sf <- st_as_sf(grid_df, coords = c("lon_x", "lat_y"), crs = 4326, remove = FALSE)

# Projektion in ein flächentreues europäisches Koordinatensystem (EPSG:3035 - LAEA Europe)
# Dies stellt sicher, dass Distanzen (Meter) über ganz Europa korrekt berechnet werden.
points_3035 <- st_transform(points_sf, 3035)
grid_3035 <- st_transform(grid_sf, 3035)

# 150 km Buffer um die Punkte legen und vereinigen
cat("  Berechne Puffer-Maske (150 km um Datenpunkte)...\n")
buffer_3035 <- st_union(st_buffer(points_3035, dist = 150000))

# Schnittmenge prüfen (welche Gitterpunkte liegen im Puffer?)
in_buffer <- st_intersects(grid_3035, buffer_3035, sparse = FALSE)

# Filtere das Gitter
grid_df_masked <- grid_df[as.vector(in_buffer), ]
cat(sprintf("  Gitterpunkte vor Maskierung: %d | nach Maskierung: %d\n", nrow(grid_df), nrow(grid_df_masked)))

# Vorhersage des räumlichen Trends (SHI) auf dem maskierten Gitter
grid_df_masked$predicted_SHI <- as.numeric(predict(gam_spatial, newdata = grid_df_masked))

################################################################################
# 4. GENERIERUNG DES ERSTKLASSIGEN 2D-PLOTS
# ============================================================================
# Zeigt die interpolierte Oberfläche mit feinen Konturlinien und den originalen
# Messpunkten als dezenter Hintergrund.
################################################################################
cat("Generiere 2D-Spline-Plot (ggplot2)...\n")

p_2d <- ggplot() +
  # Geglättete Rasterfläche des Splines
  geom_raster(data = grid_df_masked, aes(x = lon_x, y = lat_y, fill = predicted_SHI), interpolate = TRUE) +
  # Konturlinien des Fitted Splines
  geom_contour(data = grid_df_masked, aes(x = lon_x, y = lat_y, z = predicted_SHI), color = "white", alpha = 0.35, binwidth = 0.1) +
  # Originale Messpunkte zur räumlichen Orientierung
  geom_point(data = df_clean, aes(x = lon_x, y = lat_y), color = "black", size = 0.3, alpha = 0.15) +
  # Farbskala (Viridis option "viridis" oder "plasma")
  scale_fill_viridis_c(
    option = "viridis",
    name = "Vorhergesagter\nSHI Trend",
    limits = range(grid_df_masked$predicted_SHI),
    oob = scales::squish
  ) +
  coord_sf(crs = 4326, expand = FALSE) +
  labs(
    title = "Räumliches Spline-Fitting der Bodengesundheit (SHI)",
    subtitle = "2D-Thin-Plate-Spline GAM | s(lon_x, lat_y, bs='tp', k=30) mit 150-km-Datenmaske",
    x = "Längengrad (°E)",
    y = "Breitengrad (°N)",
    caption = "Schwarze Punkte markieren die tatsächlichen Messstationen. Weiß gestrichelte Linien zeigen SHI-Isolinien."
  )

# Plot speichern
plot_path_2d <- file.path(output_png_dir, "tps_spline_2d.png")
ggsave(plot_path_2d, p_2d, width = 11, height = 8, dpi = 200)
cat(sprintf("2D-Plot gespeichert unter: %s\n", plot_path_2d))

################################################################################
# 5. GENERIERUNG DES INTERAKTIVEN 3D-PLOTS
# ============================================================================
# Verwendet plotly, um eine dreidimensionale interaktive Oberfläche zu rendern.
# Unmaskierte Gebiete (z.B. Ozean) bleiben als NA erhalten, was in Plotly zu
# einer wunderschönen geformten Karte führt.
################################################################################
cat("Generiere interaktiven 3D-Plot (plotly)...\n")

# Für Plotly benötigen wir eine vollständige Matrix z.
# Wir erstellen eine Matrix der Größe n_grid x n_grid und füllen sie mit NAs.
z_matrix <- matrix(NA, nrow = n_grid, ncol = n_grid)

# Zuordnung der maskierten Punkte in die Matrix
# Finde die Indices der Sequenzen
grid_df$idx_x <- match(grid_df$lon_x, lon_seq)
grid_df$idx_y <- match(grid_df$lat_y, lat_seq)

# Füge die Vorhersagen hinzu
grid_df$predicted_SHI <- NA
# Maske auf das unfiltrierte Gitter übertragen
grid_df$predicted_SHI[as.vector(in_buffer)] <- grid_df_masked$predicted_SHI

# Befülle die Matrix
for (i in 1:nrow(grid_df)) {
  z_matrix[grid_df$idx_x[i], grid_df$idx_y[i]] <- grid_df$predicted_SHI[i]
}

# Transponieren für die korrekte Achsenbeziehung in plotly
z_matrix <- t(z_matrix)

# 3D-Plotly Oberfläche
p_3d <- plot_ly(
  x = ~lon_seq,
  y = ~lat_seq,
  z = ~z_matrix,
  type = "surface",
  colorscale = "Viridis",
  colorbar = list(title = "SHI Trend")
) %>%
  layout(
    title = list(
      text = "3D-Oberfläche des räumlichen SHI-Trends (Thin Plate Spline)",
      y = 0.95
    ),
    scene = list(
      xaxis = list(title = "Längengrad (°E)"),
      yaxis = list(title = "Breitengrad (°N)"),
      zaxis = list(title = "SHI Trend"),
      camera = list(
        eye = list(x = 1.3, y = -1.3, z = 1.0) # Standard-Kamerawinkel
      )
    )
  )

# Speichere den interaktiven Plot als HTML
plot_path_3d_html <- file.path(output_png_dir, "tps_spline_3d.html")
saveWidget(p_3d, plot_path_3d_html, selfcontained = FALSE)
cat(sprintf("Interaktiver 3D-Plot gespeichert unter: %s\n", plot_path_3d_html))

################################################################################
# 6. GENERIERUNG EINES STATISCHEN 3D-PLOTS (Für Berichte)
# ============================================================================
# Erstellt eine statische 3D-Perspektive mit persp() und speichert sie als PNG.
################################################################################
cat("Generiere statischen 3D-Perspektiv-Plot (persp)...\n")

plot_path_3d_static <- file.path(output_png_dir, "tps_spline_3d_static.png")

png(plot_path_3d_static, width = 1800, height = 1400, res = 180)

# Farbmatrix für persp berechnen basierend auf z_matrix Werten
# Wir interpolieren eine Palette für die Facetten
nbcol <- 100
color_palette <- viridisLite::viridis(nbcol)
# Berechne z-Mittelwerte der Facetten
z_facet <- (z_matrix[-1, -1] + z_matrix[-1, -ncol(z_matrix)] +
  z_matrix[-nrow(z_matrix), -1] + z_matrix[-nrow(z_matrix), -ncol(z_matrix)]) / 4
facet_colors <- color_palette[cut(z_facet, breaks = nbcol)]
# Facetten ohne Werte (NA) weiß färben
facet_colors[is.na(facet_colors)] <- "#ffffff"

op <- par(mar = c(2, 2, 4, 2))
persp_res <- persp(
  x = lon_seq,
  y = lat_seq,
  z = z_matrix,
  theta = 35, # Drehung im Uhrzeigersinn
  phi = 30, # Neigungswinkel
  expand = 0.5, # Skalierung der Z-Achse
  col = facet_colors,
  border = NA, # Keine störenden Gitternetzlinien auf der Oberfläche
  shade = 0.15, # Subtile Schattierung für 3D-Wirkung
  ltheta = 120, # Lichtrichtung
  xlab = "Längengrad (°E)",
  ylab = "Breitengrad (°N)",
  zlab = "SHI Trend",
  main = "Fitted Thin Plate Spline 3D-Oberfläche (SHI)"
)

dev.off()
cat(sprintf("Statischer 3D-Plot gespeichert unter: %s\n", plot_path_3d_static))
cat("--- Alle TPS-Fitting-Diagramme wurden erfolgreich erstellt! ---\n")
