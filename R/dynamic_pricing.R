#1. Load Libraries 
library(caret)       # model training and evaluation
library(ggplot2)     # plots
library(dplyr)       # data manipulation
library(tidyr)       # data cleaning

#2. Load Dataset 
# Dataset: "Dynamic Pricing Dataset" from Kaggle


data_path <- "data/dynamic_pricing.csv"

if (!file.exists(data_path)) {
  stop(paste(
    "Dataset not found at:", data_path,
    "\nDownload from: https://www.kaggle.com/datasets/arashnic/dynamic-pricing-dataset",
    "\nRename the CSV to 'dynamic_pricing.csv' and place it in the data/ folder."
  ))
}

# Expected CSV columns:
#   Number_of_Riders, Number_of_Drivers, Location_Category,
#   Customer_Loyalty_Status, Number_of_Past_Rides, Average_Ratings,
#   Time_of_Booking, Vehicle_Type, Expected_Ride_Duration,
#   Historical_Cost_of_Ride


df <- read.csv(data_path, stringsAsFactors = FALSE)
cat("Dataset loaded:", nrow(df), "rows,", ncol(df), "columns\n")
cat("Columns:", paste(names(df), collapse = ", "), "\n\n")

#  3. Data Exploration 
cat("=== Summary Statistics ===\n")
print(summary(df))

cat("\n=== Missing Values ===\n")
print(colSums(is.na(df)))

# Plot 1: Ride Duration vs Historical Cost (no regression line)
# This reveals the scatter — duration alone doesn't fully explain cost
p1 <- ggplot(df, aes(x = Expected_Ride_Duration, y = Historical_Cost_of_Ride)) +
  geom_point(alpha = 0.5, size = 1.2) +
  labs(
    title = "Ride Duration vs. Historical Cost",
    x     = "Ride Duration",
    y     = "Cost"
  ) +
  theme_minimal()

ggsave("plots/01_duration_vs_cost_scatter.png", p1, width = 8, height = 5, dpi = 150)
cat("Saved: plots/01_duration_vs_cost_scatter.png\n")

# 4. Feature Engineering 

#Infer "predicted cost for expected ride duration" via simple linear regression
#     and add it as a new feature
base_model <- lm(Historical_Cost_of_Ride ~ Expected_Ride_Duration, data = df)
cat("\n=== Base Model (Duration Only) ===\n")
print(summary(base_model))

df$Predicted_Cost_For_Duration <- predict(base_model, df)

# Plot 2: Same scatter with regression line overlaid
p2 <- ggplot(df, aes(x = Expected_Ride_Duration, y = Historical_Cost_of_Ride)) +
  geom_point(alpha = 0.5, size = 1.2) +
  geom_line(aes(y = Predicted_Cost_For_Duration), colour = "blue", linewidth = 1) +
  labs(
    title = "Ride Duration vs. Historical Cost",
    x     = "Expected Ride Duration",
    y     = "Cost"
  ) +
  theme_minimal()

ggsave("plots/02_duration_vs_cost_with_regression.png", p2, width = 8, height = 5, dpi = 150)
cat("Saved: plots/02_duration_vs_cost_with_regression.png\n")

#Encode categorical features as 0 / 1
df$Location_Category       <- ifelse(df$Location_Category == "Urban", 0, 1)
df$Customer_Loyalty_Status <- ifelse(df$Customer_Loyalty_Status == "Gold", 1, 0)
df$Vehicle_Type            <- ifelse(df$Vehicle_Type == "Premium", 1, 0)

# 4c. Min-max normalize all numeric features to [0, 1]
min_max_norm <- function(x) {
  rng <- range(x, na.rm = TRUE)
  if (diff(rng) == 0) return(rep(0, length(x)))
  (x - rng[1]) / diff(rng)
}

numeric_cols <- c(
  "Number_of_Riders", "Number_of_Drivers",
  "Number_of_Past_Rides", "Average_Ratings",
  "Expected_Ride_Duration", "Predicted_Cost_For_Duration"
)

df_normalized <- df
df_normalized[numeric_cols] <- lapply(df[numeric_cols], min_max_norm)

#Apply subjective impact weights to each feature
weights <- list(
  Number_of_Riders       =  0.30,   # More riders → higher demand → price up
  Number_of_Drivers      = -0.25,   # More drivers → more supply → price down
  Location_Category      =  0.15,   # Rural → longer to reach → price up
  Customer_Loyalty_Status = -0.10,  # Gold loyalty → discount
  Number_of_Past_Rides   = -0.05,   # Frequent riders → small discount
  Vehicle_Type           =  0.10    # Premium vehicle → price up
)

# Compute weighted adjustment factor for each row
df_normalized$Adjustment_Factor <- with(df_normalized,
  weights$Number_of_Riders        * Number_of_Riders        +
  weights$Number_of_Drivers       * Number_of_Drivers       +
  weights$Location_Category       * Location_Category       +
  weights$Customer_Loyalty_Status * Customer_Loyalty_Status +
  weights$Number_of_Past_Rides    * Number_of_Past_Rides    +
  weights$Vehicle_Type            * Vehicle_Type
)

# Adjusted Cost = base predicted cost + weighted adjustment scaled back to cost range
cost_range  <- diff(range(df$Historical_Cost_of_Ride, na.rm = TRUE))
df_normalized$Adjusted_Cost <-
  df_normalized$Predicted_Cost_For_Duration * cost_range +
  min(df$Historical_Cost_of_Ride, na.rm = TRUE) +
  df_normalized$Adjustment_Factor * cost_range

# Plot 3: Adjusted Cost vs Predicted Cost — shows multi-factor separation
p3 <- ggplot(df_normalized,
             aes(x = Predicted_Cost_For_Duration * cost_range +
                       min(df$Historical_Cost_of_Ride),
                 y = Adjusted_Cost)) +
  geom_point(alpha = 0.4, size = 1.2) +
  geom_abline(slope = 1, intercept = 0, colour = "red", linetype = "dashed") +
  labs(
    title = "Adjusted Cost vs. Predicted Cost",
    x     = "Predicted Cost For Expected Ride Duration",
    y     = "Adjusted Cost"
  ) +
  theme_minimal()

ggsave("plots/03_adjusted_vs_predicted_cost.png", p3, width = 8, height = 5, dpi = 150)
cat("Saved: plots/03_adjusted_vs_predicted_cost.png\n")

#5. Model Training 
set.seed(123)  # reproducibility

split_index <- createDataPartition(df_normalized$Adjusted_Cost, p = 0.80,
                                   list = FALSE, times = 1)
train_data  <- df_normalized[ split_index, ]
test_data   <- df_normalized[-split_index, ]

cat("\nTraining set size:", nrow(train_data), "rows\n")
cat("Test set size    :", nrow(test_data),  "rows\n")

model_fit <- train(
  Adjusted_Cost ~ Number_of_Riders + Number_of_Drivers +
    Location_Category + Customer_Loyalty_Status +
    Number_of_Past_Rides + Average_Ratings +
    Vehicle_Type + Expected_Ride_Duration + Predicted_Cost_For_Duration,
  data   = train_data,
  method = "lm"
)

cat("\n=== Final Linear Regression Model ===\n")
print(summary(model_fit$finalModel))

# 6. Model Evaluation
train_preds <- predict(model_fit, train_data)
test_preds  <- predict(model_fit, test_data)

rmse_train <- RMSE(train_preds, train_data$Adjusted_Cost)
rmse_test  <- RMSE(test_preds,  test_data$Adjusted_Cost)
mae_test   <- MAE(test_preds,   test_data$Adjusted_Cost)
r2_test    <- cor(test_preds,   test_data$Adjusted_Cost)^2

cat("\n=== Model Evaluation Metrics ===\n")
cat(sprintf("Train RMSE : %.2f\n", rmse_train))
cat(sprintf("Test  RMSE : %.2f\n", rmse_test))
cat(sprintf("Test  MAE  : %.2f\n", mae_test))
cat(sprintf("Test  R²   : %.4f\n", r2_test))

# Plot 4: Predicted vs Actual on test set
results_df <- data.frame(
  Actual    = test_data$Adjusted_Cost,
  Predicted = test_preds
)

p4 <- ggplot(results_df, aes(x = Actual, y = Predicted)) +
  geom_point(alpha = 0.5, size = 1.5) +
  geom_abline(slope = 1, intercept = 0, colour = "red", linetype = "dashed") +
  labs(
    title = "Predicted vs. Actual Adjusted Cost (Test Set)",
    x     = "Actual Adjusted Cost",
    y     = "Predicted Adjusted Cost"
  ) +
  theme_minimal()

ggsave("plots/04_predicted_vs_actual.png", p4, width = 8, height = 5, dpi = 150)
cat("Saved: plots/04_predicted_vs_actual.png\n")

# Plot 5: Feature importance (absolute coefficients)
coef_df <- as.data.frame(coef(model_fit$finalModel))
coef_df$Feature     <- rownames(coef_df)
names(coef_df)[1]   <- "Coefficient"
coef_df             <- coef_df[coef_df$Feature != "(Intercept)", ]
coef_df$Importance  <- abs(coef_df$Coefficient)
coef_df             <- coef_df[order(coef_df$Importance, decreasing = TRUE), ]

p5 <- ggplot(coef_df, aes(x = reorder(Feature, Importance), y = Coefficient,
                           fill = Coefficient > 0)) +
  geom_col() +
  coord_flip() +
  scale_fill_manual(values = c("TRUE" = "#2E86AB", "FALSE" = "#E84855"),
                    labels = c("TRUE" = "Positive", "FALSE" = "Negative"),
                    name   = "Direction") +
  labs(
    title = "Feature Coefficients — Dynamic Pricing Model",
    x     = "Feature",
    y     = "Coefficient Value"
  ) +
  theme_minimal()

ggsave("plots/05_feature_coefficients.png", p5, width = 9, height = 5, dpi = 150)
cat("Saved: plots/05_feature_coefficients.png\n")

cat("\n✓ Analysis complete. All plots saved to plots/\n")
