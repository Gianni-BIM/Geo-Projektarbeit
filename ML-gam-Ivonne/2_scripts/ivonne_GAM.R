library(caret)
library(readxl)
library(sf)
library(mgcv)
library(dplyr)
library(readr)
library(gratia)
library(ggplot2)


# Prepare Data
##############

# Daten einlesen
daten <- st_read("1_data/points_1.gpkg")
colnames(daten)
summary(daten)

# Geometrie entfernen
daten_df <- st_drop_geometry(daten)

# Climate Class simplifizieren:
daten_df$climate_class_simple <- substr(daten_df$kg_climate_class_label, 1, 1)

# alle Spalten bei denen es sich um Kategorien handelt- faktorisieren
daten_df$land_use <- as.factor(daten_df$land_use)
daten_df$land_cover <- as.factor(daten_df$land_cover)
daten_df$climate_class_simple <- as.factor(daten_df$climate_class_simple)

# subset erstellen (ohne POINT_ID, kg_climate_class_label)
daten_clean <- daten_df |> 
  dplyr::select(-c(POINT_ID, kg_climate_class_label))

# check
colnames(daten_clean)
sapply(daten_clean, class)

# TRAIN TEST
############

set.seed(13)

dataset_size <- nrow(daten_clean)
train_index <- sample(seq_len(dataset_size), size = 0.8 * dataset_size)

train <- daten_clean[train_index, ]
test  <- daten_clean[-train_index, ]

# Definition of baseline categories for model interpretation
############################################################
# Die Wahl der Referenzkategorien definiert die Basissituation, gegenüber der alle kategorialen Effekte interpretiert werden. Modellgüte und Vorhersagen bleiben davon unverändert: häufigste Kategorie → Referenzkategorie → Effekte der übrigen Kategorien relativ zu dieser Basissituation interpretieren

# Agriculture, Cropland, C -> coherent baseline system
train$land_use <- relevel(train$land_use, ref = "Agriculture")
train$land_cover <- relevel(train$land_cover, ref = "Cropland")
train$climate_class_simple <- relevel(train$climate_class_simple, ref = "C")


# Jetzt GAM
###########
# keep in mind: A GAM is a mathematical equation made of several additive terms, where some terms are smooth functions learned from the data rather than fixed linear effects.
# Niederschlag, Höhenlage und räumliche Lage zeigten sich nichtlineare Zusammenhänge, von daher im GAM mittels glatter Funktionen modelliert s(...)

# FIT THE MODEL
gam_mod <- gam(SHI ~ s(lon_x, lat_y, k = 250) +
                  s(rain_mmsqm_mean_1995_2024) +
                  s(height_m) +
                  temp_c_mean_1995_2024 + 
                  land_use + 
                  land_cover + 
                  climate_class_simple,
                 data = train,
                 method = "REML"
)


# MODEL SUMMARY
###############
# Basic model sanity: is the smooth structure reasonable?
summary(gam_mod)

# MODEL DIAGNOSTICS
###################
gam.check(gam_mod)

# PREDICTION PERFORMANCE (WITH TEST DATA) global
################################################
pred <- predict(gam_mod, newdata = test)
postResample(pred, test$SHI)

# PLOTS - VISUALIZATION
#######################

# Histogramm der Residuen - Verteilung (~ Normalverteilung, ähnlich Glockenkurve)
# Residuen = die Differenz zwischen wahrem SHI von test und predicted SHI

test$resid <- test$SHI - pred
summary(test$resid)
hist(test$resid,
     breaks = 30,
     col = "grey",
     main = "Residuals distribution",
     xlab = "Residuals (observed - predicted)")



# Plot der Residuen als Karte
#Die Residuen werden vereinfachend nach ihrem Vorzeichen (positiv/negativ/nahe Null) klassifiziert, um eventuelle räumliche Muster der Über- und Unterschätzung zu erkennen.

z <- test$resid
cols <- colorRampPalette(c("navy", "greenyellow", "firebrick"))(3)
breaks <- quantile(z, probs = seq(0, 1, length.out = 4))
plot(test$lon_x, test$lat_y,
     col = cols[cut(z, breaks = breaks)],
     pch = 16, cex = 0.6)

legend("topleft",
       legend = c("Neg. residual (overprediction)", "Near 0", "Pos. residual (underprediction)"),
       col = c("navy", "greenyellow", "firebrick"),
       pch = 16,
       bty = "n")


# Plot der geschätzten nichtlinearen Effekte auf SHI
# GAM smooth terms: 1: s(lat,lon), 2: s(rain), and 3: s(height)
plot(gam_mod, select = 1)
plot(gam_mod, select = 2)
plot(gam_mod, select = 3)

# alternative Darstellung für den räumlichen Term
# s(lat,lon) = Eine glatte Funktion, die den räumlichen Beitrag (Effekt) der Lage auf den erwarteten Wert von SHI beschreibt.

# heat-map-like
vis.gam(gam_mod,
        view = c("lon_x", "lat_y"),
        plot.type = "contour",
        color = "heat")

# 3D
vis.gam(gam_mod,
        view = c("lon_x", "lat_y"),
        plot.type = "persp")


# # ======================
# # PERMUTATION IMPORTANCE
# # ======================
# # Um wie viel verschlechtert sich die Modellleistung (Veränderung des rmse) bei bisher unbekannten Daten, wenn ich die Informationen je einer Variable durchmische (shuffle)?

# Funktion bauen
perm_importance <- function(model, data, y, nperm, seed) {
  set.seed(seed)

  features <- setdiff(names(data), c(y, "lon_x", "lat_y"))

  base_pred <- predict(model, newdata = data)
  baseline_rmse <- sqrt(mean((data[[y]] - base_pred)^2))

  results <- data.frame(
    variable = features,
    baseline_rmse = baseline_rmse,
    perm_rmse = NA_real_,
    rmse_increase = NA_real_,
    perm_sd = NA_real_
  )

  for (f in features) {
    rmse_perm <- numeric(nperm)

    for (i in seq_len(nperm)) {
      data_perm <- data
      data_perm[[f]] <- sample(data_perm[[f]])

      pred <- predict(model, newdata = data_perm)
      rmse_perm[i] <- sqrt(mean((data[[y]] - pred)^2))
    }

    results$perm_rmse[results$variable == f] <- mean(rmse_perm)
    results$rmse_increase[results$variable == f] <- mean(rmse_perm) - baseline_rmse
    results$perm_sd[results$variable == f] <- sd(rmse_perm)
  }

  results[order(results$rmse_increase, decreasing = TRUE), ]
}

# Funktionsaufruf
importance <- perm_importance(
  model = gam_mod,
  data = test,
  y = "SHI",
  nperm = 10,
  seed = 13
)

# Resultate
importance
capture.output(importance,
               file = "4_output/permutation_importance.txt")


# GAM OHNE LOCATION/SPACE
#########################
gam_no_space <- gam(SHI ~ s(rain_mmsqm_mean_1995_2024) +
                      s(height_m) +
                      temp_c_mean_1995_2024 +
                      land_use +
                      land_cover +
                      climate_class_simple,
                    data = train,
                    method = "REML")

pred_no_space <- predict(gam_no_space, newdata = test)

#VERGLEICH BEIDER GAMS
######################

postResample(pred, test$SHI) # nach gam_mod
postResample(pred_no_space, test$SHI) # nach gam_no_space

AIC(gam_mod, gam_no_space)

# check Permutation importance with the gam_no_space
importance_no_space <- perm_importance(
  model = gam_no_space,
  data = test,
  y = "SHI",
  nperm = 10,
  seed = 13
)

importance_no_space
capture.output(importance_no_space,
               file = "4_output/permutation_importance_no_space.txt")

###############
# Ende












