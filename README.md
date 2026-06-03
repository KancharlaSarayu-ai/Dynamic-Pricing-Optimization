# Dynamic Pricing Optimization

**CS520 Data Mining | City University of Seattle**  
**Authors:** Sarayu Kancharla

## Overview

This project builds a dynamic pricing model for ride-sharing services that goes beyond simple ride-duration-based fares. By incorporating supply/demand signals and customer context, the model predicts a fairer, more accurate price for each ride.

## Features Used

| Feature | Effect on Price |
|---|---|
| Number of Riders | Higher demand → higher price |
| Number of Drivers | More supply → lower price |
| Location Category | Rural → higher price |
| Vehicle Type | Premium → higher price |
| Customer Loyalty Status | Gold = discount |
| Number of Past Rides | Frequent rider = small discount |

## Results

| Metric | Value |
|---|---|
| R² | 0.99 |
| RMSE | 19.18 |
| MAE | 14.36 |

## Dataset

[Dynamic Pricing Dataset](https://www.kaggle.com/datasets/arashnic/dynamic-pricing-dataset) from Kaggle.