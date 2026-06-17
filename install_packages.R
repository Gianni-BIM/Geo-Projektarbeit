# Dieses Skript installiert alle für das Projekt benötigten R-Pakete
# Führe dieses Skript einmalig aus, bevor du das Hauptskript startest.

required_packages <- c(
  "party", # Für Conditional Inference Forest (ctree, cforest)
  "mgcv", # Für GAM (Räumlicher Trend)
  "ggplot2", # Für Diagramme und Plots
  "reshape2", # Für Datenumformung (z.B. Korrelationsmatrix)
  "spdep", # Für räumliche Autokorrelation (Moran's I)
  "sf", # Abhängigkeit von spdep
  "spData", # Abhängigkeit von spdep
  "GGally" # Für Korrelationsmatrix
)

# Prüfen, welche Pakete noch fehlen
new_packages <- required_packages[!(required_packages %in% installed.packages()[, "Package"])]

if (length(new_packages) > 0) {
  cat("Installiere fehlende Pakete:", paste(new_packages, collapse = ", "), "\n")
  install.packages(new_packages, dependencies = TRUE, repos = "https://cloud.r-project.org")
} else {
  cat("Alle benötigten Pakete sind bereits installiert!\n")
}
