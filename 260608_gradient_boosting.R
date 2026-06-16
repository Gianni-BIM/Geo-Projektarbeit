#############################
#                           #
#    sina philipowski       #
#    04.06.2026             #
#    script ML              #
#    bodengesundheit        #
#    gradient boosting      #
#                           #
#############################


# hyperparameter
#   | Parameter           | Bedeutung                             | Typischer Bereich |
#   | ------------------- | ------------------------------------- | ----------------- |
#   | `n.trees`           | Anzahl der Bäume                      | 100–5000          |
#   | `interaction.depth` | Maximale Tiefe der Bäume              | 1–10              |
#   | `shrinkage`         | Lernrate                              | 0.001–0.1         |
#   | `n.minobsinnode`    | Mindestanzahl Beobachtungen pro Blatt | 5–30              |

# user directory
#getwd()
#setwd("C:/Users/sphil/Documents/Studium/02_master/03_Semester_2/02_Geo_Projektarbeit/R")

library(caret)
library(gbm)
library(readxl)
library(datasets)
library(caret)
library(party)
library(sf)
library(ggplot2)

# daten einlesen
daten <- st_read("points.gpkg")

# geometrie rausschmeißen
daten_df <- st_drop_geometry(daten)

# alle spalten bei denen es sich um kategorien handelt- faktorisieren
daten_df$land_use <- as.factor(daten_df$land_use)
daten_df$land_cover <- as.factor(daten_df$land_cover)
daten_df$kg_climate_class <- as.factor(daten_df$kg_climate_class)

# subset erstellen (ausgeschlossen werden point ID und lon/lat)
# lon und lat könnte überlegt werden, ob man diese miteinbeziehen will
#daten_df <- subset(daten_df, select = -c(POINT_ID, lon_x, lat_y))
# wenn dieser teil auskommenteirt ist, dann werden lon und lat mit einbezogen

### "daten_df" wird in zufällige trainings- und testdaten aufgeteilt

# setzt den startpunkt für die zufallszahlen, damit die stichprobe bei jedem lauf gleich ist
set.seed(123)

# zieht zufällig 80% der zeilenindizes aus "daten_df"
idx <- sample(seq_len(nrow(daten_df)), size = 0.8 * nrow(daten_df))
# nimmt genau diese ausgewählten zeilen als trainingsdaten
train <- daten_df[idx, ]
# nimmt alle übrigen zeilen als testdaten
test  <- daten_df[-idx, ]


# gbm-modell mit caret::train, trainiert es auf "train" mit 5 facher cross-validierung

gbm_grid <- expand.grid(
  n.trees = c(500, 1000, 2000),
  interaction.depth = c(2, 4, 6),
  shrinkage = c(0.01, 0.05, 0.1),
  n.minobsinnode = c(5, 10)
)

gbm_mod <- train(
  SHI ~ .,
  data = train,
  method = "gbm",
  trControl = trainControl(method = "cv", number = 5),
  tuneGrid = gbm_grid,
  verbose = FALSE
)

# vorhersagen für testdaten erzeugen
# predict() funktion für vorhersagen in r
pred <- predict(gbm_mod, newdata = test)
# in pred ist nun enthalten - regression (vektor von numerischen vorhersagen)

# durchschnittliche abweichung zwischen meinen vorhersagen und echten werten berechnen
# durchschnittliche vorhersageabweichung
rmse <- sqrt(mean((pred - test$SHI)^2))

# ausgabe rmse, r2 und mae
postResample(pred, test$SHI)
rmse

# variable importance
# ordnet die prädikatoren nach ihrem einfluss auf das modell
# keine kausalität
# es zeigt nur, wie stark das trainierte modell diese Variable für gute vorhersagen verwendet
varImp(gbm_mod)

################################################################################
# auswertung anwendung der hyperparameter
p1 <- ggplot(gbm_mod$results, aes(x = factor(n.trees), y = RMSE)) +
  geom_boxplot() +
  labs(x = "n.trees", y = "RMSE")
p1

p2 <- ggplot(gbm_mod$results, aes(x = factor(interaction.depth), y = RMSE)) +
  geom_boxplot() +
  labs(x = "interaction.depth", y = "RMSE")
p2

p3 <- ggplot(gbm_mod$results, aes(x = factor(shrinkage), y = RMSE)) +
  geom_boxplot() +
  labs(x = "shrinkage", y = "RMSE")
p3

p4 <- ggplot(gbm_mod$results, aes(x = factor(n.minobsinnode), y = RMSE)) +
  geom_boxplot() +
  labs(x = "n.minobsinnode", y = "RMSE")
p4

################################################################################
# streudiagramm, dass die vorhergesagten shi-werten mit den tatsächlichen shi-werten vergleicht
# wenn punkt nahe an der roten linie liegen sind vorhersage und ist-werte ähnlich
# schwarze linie zeigt, ob modell eher zu hoch oder zu niedrig schätzt
# Vorhersage vs. Istwerte für SHI
library(ggplot2)
plot_pred_ist <- ggplot(
  data = data.frame(pred = pred, SHI = test$SHI), # baut kleine tabelle mit zwei spalten
  # pred = modellvorhersage
  # shi = die echten werte
  aes(x = SHI, y = pred)
) +
  geom_point(color = "steelblue", size = 2) +
  geom_abline(intercept = 0, slope = 1, color = "red", linetype = "dashed") +
  geom_smooth(method = "lm", se = FALSE, color = "black") +
  labs(
    title = "Vorhersage vs. Istwerte für SHI (GBM)",
    x = "Istwerte SHI",
    y = "Vorhersagen SHI"
  ) +
  theme_minimal()

# schwarze linie verläuft etwas flacher als die rote linie
# deutet darauf hin, dass das modell bei kleineren shi werten eher überschätzt und große eher unterschätzt
plot_pred_ist

################################################################################
# welcher Prädiktor hat welchen einfluss? (ausgabe in der Konsole)
# alle Prädiktoren außer Zielvariable
vars <- setdiff(names(train), "SHI")

ergebnis <- data.frame(
  Variable_entfernt = character(),
  RMSE = numeric(),
  stringsAsFactors = FALSE
)

for(v in vars){
  
  train_tmp <- train[, !(names(train) %in% v)]
  test_tmp  <- test[, !(names(test) %in% v)]
  
  mod_tmp <- train(
    SHI ~ .,
    data = train_tmp,
    method = "gbm",
    trControl = trainControl(method = "cv", number = 5),
    verbose = FALSE
  )
  
  pred_tmp <- predict(mod_tmp, newdata = test_tmp)
  
  rmse_tmp <- sqrt(mean((pred_tmp - test$SHI)^2))
  
  ergebnis <- rbind(
    ergebnis,
    data.frame(
      Variable_entfernt = v,
      RMSE = rmse_tmp
    )
  )
}

ergebnis[order(ergebnis$RMSE), ]


###############################################################################
# korrelationsmatrix

# nur numerische Spalten auswählen
num_df <- daten_df %>%
  select(where(is.numeric))

# Korrelationsmatrix berechnen
cor_mat <- cor(num_df, use = "complete.obs")

# in langes Format für ggplot umwandeln
cor_long <- as.data.frame(cor_mat) %>%
  tibble::rownames_to_column("Var1") %>%
  pivot_longer(-Var1, names_to = "Var2", values_to = "Correlation")

# Plot
ggplot(cor_long, aes(x = Var1, y = Var2, fill = Correlation)) +
  geom_tile(color = "white") +
  geom_text(aes(label = round(Correlation, 2)), size = 4) +
  scale_fill_gradient2(low = "blue", mid = "white", high = "red", midpoint = 0, limits = c(-1, 1)) +
  coord_equal() +
  labs(title = "Korrelationsmatrix der numerischen Einflussfaktoren",
       x = NULL, y = NULL, fill = "Korrelation") +
  theme_minimal(base_size = 14) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    plot.title = element_text(face = "bold", size = 18, hjust = 0.5)
  )

################################################################################
# decision tree

tree_mod <- ctree(SHI ~ ., data = train)
plot(tree_mod)

library(partykit)

tree_mod <- ctree(SHI ~ ., data = train)
plot(tree_mod, terminal_panel = node_boxplot, drop_terminal = TRUE)

################################################################################
# wichtigkeit der einflussfaktoren
# Variable Importance extrahieren
vi <- varImp(gbm_mod)$importance

# Spaltennamen als Variable übernehmen
vi$variable <- rownames(vi)

# Prozentwerte berechnen
vi$percent <- 100 * vi$Overall / sum(vi$Overall)

# Nach Wichtigkeit sortieren
vi <- vi[order(vi$percent, decreasing = TRUE), ]

print(vi)

# Reihenfolge der Variablen für den Plot festlegen
vi$variable <- factor(
  vi$variable,
  levels = rev(vi$variable)
)

zufall <- 100 / nrow(vi)

ggplot(vi,
       aes(x = percent,
           y = variable,
           fill = percent)) +
  geom_col() +
  geom_vline(
    xintercept = zufall,
    colour = "red",
    linetype = "dashed",
    linewidth = 1
  ) +
  annotate(
    "text",
    x = zufall + 0.5,
    y = 1,
    label = paste0(
      "Zufallsschwelle (",
      round(zufall, 1),
      "%)"
    ),
    colour = "red",
    hjust = 0
  ) +
  labs(
    title = "Relative Wichtigkeit der Einflussfaktoren auf den SHI",
    subtitle = "Gradient Boosting",
    x = "Einflussanteil (%)",
    y = "Einflussfaktor"
  ) +
  theme_minimal(base_size = 14)

################################################################################
# residuen analyse histogramm

# Vorhersagen auf den Trainingsdaten
pred <- predict(tree_mod, newdata = train)

# Residuen: beobachtet - vorhergesagt
res <- train$SHI - pred

# Residuen vs. vorhergesagte Werte (Heteroskedastizität prüfen)
plot(pred, res,
     xlab = "Vorhergesagte Werte",
     ylab = "Residuen",
     main = "Residuen vs. Vorhersage")
abline(h = 0, col = "red")

# Histogramm der Residuen
hist(res, breaks = 20, main = "Histogramm der Residuen", xlab = "Residuen")

# Q-Q-Plot (Normalverteilung prüfen)
qqnorm(res, main = "Q-Q-Plot der Residuen")
qqline(res, col = "red")
