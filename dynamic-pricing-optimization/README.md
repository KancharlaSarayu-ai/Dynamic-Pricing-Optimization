# Dynamic Pricing Optimization

**CS520 Data Mining | City University of Seattle**  
**Authors:** Benjamin Hurst · Michael Hsiu · Sarayu Kancharla

---

## Overview

This project builds a dynamic pricing model for ride-sharing services that goes beyond simple ride-duration-based fares. By incorporating supply/demand signals and customer context, the model predicts a fairer, more accurate price for each ride.

**Key idea:** The dataset description states that fares are currently based only on ride duration — but a scatter plot of duration vs. historical cost reveals significant spread, meaning other factors clearly influence price. This project identifies and quantifies those factors.

---

## Features Used

| Feature | Effect on Price | Weight |
|---|---|---|
| Number of Riders | ↑ Higher demand → higher price | +0.30 |
| Number of Drivers | ↑ More supply → lower price | −0.25 |
| Location Category | Rural = longer reach → higher price | +0.15 |
| Vehicle Type | Premium → higher price | +0.10 |
| Customer Loyalty Status | Gold = discount | −0.10 |
| Number of Past Rides | Frequent rider = small discount | −0.05 |
| Average Ratings | Context feature | — |
| Expected Ride Duration | Base cost driver | — |

---

## Methodology

1. **Data Exploration** — Scatter plot confirms duration alone doesn't fully explain cost
2. **Feature Engineering**
   - Fit a base linear regression on duration → generate `Predicted_Cost_For_Duration`
   - Encode categorical features (Location, Loyalty, Vehicle Type) as binary (0/1)
   - Min-max normalize all numeric features to [0, 1]
   - Apply subjective impact weights per feature → compute `Adjusted_Cost`
3. **Model Training** — Linear regression on the enriched feature set (80/20 train-test split)
4. **Evaluation** — RMSE, MAE, R² on test set; feature coefficient analysis

---

## Results

| Metric | Value |
|---|---|
| R² | 0.99 |
| RMSE | ~19.18 |
| MAE | ~14.36 |

The high R² indicates the multi-feature model explains ride cost variance far better than duration alone.

---

## Project Structure

```
dynamic-pricing-optimization/
├── R/
│   └── dynamic_pricing.R      # Main analysis script
├── data/
│   └── dynamic_pricing.csv    # Place Kaggle dataset here (see below)
├── plots/
│   ├── 01_duration_vs_cost_scatter.png
│   ├── 02_duration_vs_cost_with_regression.png
│   ├── 03_adjusted_vs_predicted_cost.png
│   ├── 04_predicted_vs_actual.png
│   └── 05_feature_coefficients.png
└── README.md
```

---

## Setup & Usage

### 1. Get the Dataset

Download the **Dynamic Pricing Dataset** from Kaggle:  
https://www.kaggle.com/datasets/arashnic/dynamic-pricing-dataset

Rename the CSV to `dynamic_pricing.csv` and place it in the `data/` folder.

### 2. Install R Dependencies

```r
install.packages(c("caret", "ggplot2", "dplyr", "tidyr"))
```

### 3. Run the Analysis

```r
setwd("path/to/dynamic-pricing-optimization")
source("R/dynamic_pricing.R")
```

All plots will be saved to the `plots/` directory.

---

## Dataset Source

Kaggle — [Dynamic Pricing Dataset](https://www.kaggle.com/datasets/arashnic/dynamic-pricing-dataset)

**Features in the dataset:**
- `Number_of_Riders`, `Number_of_Drivers`
- `Location_Category`, `Customer_Loyalty_Status`
- `Number_of_Past_Rides`, `Average_Ratings`
- `Time_of_Booking`, `Vehicle_Type`
- `Expected_Ride_Duration`, `Historical_Cost_of_Ride`
