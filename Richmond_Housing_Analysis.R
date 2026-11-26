# Richmond Housing Market Intelligence | Reproducible analysis
# Source: City of Richmond Assessor public datasets, September 23, 2026
# Scope: selected single-family property codes; qualified transfers; 2015–2025
# Run in RStudio. Place both source Excel files in the same folder.

library(readxl)
library(dplyr)
library(readr)
library(ggplot2)

# 1. Set the source folder (change only this line if needed).
data_dir <- "C:/Users/thrhn/Downloads"
output_dir <- file.path(data_dir, "Richmond_Portfolio_Output")
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# 2. Import. Treat STORIES as text (some records contain values like '1.5+1').
transfer_file <- file.path(data_dir, "Assessor_Transfers_2026-09-23.xlsx")
property_file <- file.path(data_dir, "Assessor_Public_Data_Set_2026-09-23.xlsx")
stopifnot(file.exists(transfer_file), file.exists(property_file))
transfers <- read_excel(transfer_file, col_types = replace(rep("guess", 28), 26, "text"))
properties <- read_excel(property_file, col_types = replace(rep("guess", 80), 26, "text"))
stopifnot(!anyNA(transfers$PID), !anyNA(properties$PID), !anyDuplicated(properties$PID))

# 3. Join property characteristics to qualified transfer records.
# Avoid including owner/grantor/grantee or mailing details in published exports.
property_info <- properties %>%
  select(PID, BED_COUNT, BATH_COUNT, HALF_BATH_COUNT,
         CONDITION, STYLE, PARCEL_LOCATION_ZIP, ASSSESS_TOTAL_VALUE_1)
housing <- transfers %>%
  filter(QUALIFIED == "Q", !is.na(CONSIDERATION), CONSIDERATION > 0) %>%
  left_join(property_info, by = "PID", relationship = "many-to-one") %>%
  select(PID, NBHD, PRIMARY_USE, PROP_TYPE, TRANSFER_DATE, SALE_TYPE,
         CONSIDERATION, QUALIFIED, YEAR_BUILT, LIVING_AREA,
         BED_COUNT, BATH_COUNT, HALF_BATH_COUNT, CONDITION, STYLE,
         PARCEL_LOCATION_ZIP, ASSSESS_TOTAL_VALUE_1)

# 4. Select five single-family building classes and complete years.
# These are screening criteria, not a guarantee of arm's-length transactions.
housing_clean <- housing %>%
  mutate(sale_date = as.Date(TRANSFER_DATE),
         sale_year = as.integer(format(sale_date, "%Y")),
         sale_price = as.numeric(CONSIDERATION),
         living_sqft = as.numeric(LIVING_AREA),
         property_code = substr(PRIMARY_USE, 1, 3)) %>%
  filter(property_code %in% c("110", "115", "120", "130", "150"),
         between(sale_year, 2015, 2025), sale_price > 10000,
         !is.na(living_sqft), living_sqft > 300) %>%
  mutate(price_per_sqft = sale_price / living_sqft) %>%
  distinct(PID, TRANSFER_DATE, CONSIDERATION, .keep_all = TRUE)

# Export an analysis-ready file without individual property identifiers.
write_csv(housing_clean %>% select(-PID),
          file.path(output_dir, "Richmond_Single_Family_Analysis.csv"))

# 5. Descriptive trends.
annual_trends <- housing_clean %>%
  group_by(sale_year) %>%
  summarise(sales = n(), median_price = median(sale_price),
            median_price_sqft = median(price_per_sqft), .groups = "drop")
write_csv(annual_trends, file.path(output_dir, "Annual_Trends.csv"))
p1 <- ggplot(annual_trends, aes(sale_year, median_price)) +
  geom_line(color = "#176B87", linewidth = 1.2) +
  geom_point(color = "#176B87", size = 2.5) +
  scale_y_continuous(labels = scales::label_dollar()) +
  scale_x_continuous(breaks = 2015:2025) +
  labs(title = "Richmond Single-Family Housing Market",
       subtitle = "Median sale price | 2015–2025", x = "Year",
       y = "Median sale price",
       caption = "Source: City of Richmond Assessor | Qualified transfers; selected property classes") +
  theme_minimal(base_size = 12) + theme(plot.title = element_text(size = 16))
ggsave(file.path(output_dir, "Richmond_Price_Trend.png"), p1,
       width = 11, height = 6, dpi = 300)

# 6. Neighborhood comparisons: require >=30 sales in 2025.
neighborhood_analysis <- housing_clean %>%
  filter(sale_year == 2025, !is.na(NBHD)) %>%
  group_by(NBHD) %>%
  summarise(sales = n(), median_price = median(sale_price),
            median_price_sqft = median(price_per_sqft), .groups = "drop") %>%
  filter(sales >= 30) %>% arrange(desc(median_price))
write_csv(neighborhood_analysis,
          file.path(output_dir, "Neighborhood_2025.csv"))
top_neighborhoods <- head(neighborhood_analysis, 10)
p2 <- ggplot(top_neighborhoods,
             aes(reorder(NBHD, median_price), median_price)) +
  geom_col(fill = "#176B87", width = 0.7) + coord_flip() +
  scale_y_continuous(labels = scales::label_dollar()) +
  labs(title = "Richmond Neighborhood Price Comparison",
       subtitle = "Median single-family sale price | 2025 | At least 30 sales",
       x = NULL, y = "Median sale price",
       caption = "Source: City of Richmond Assessor | Descriptive, not quality-adjusted") +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(size = 14),
        axis.text.y = element_text(size = 9))
ggsave(file.path(output_dir, "Richmond_Neighborhood_Comparison.png"), p2,
       width = 13, height = 8, dpi = 300)

# 7. Hedonic regression: transparent, preliminary modeling restrictions.
model_data <- housing_clean %>%
  filter(between(sale_price, 50000, 2000000),
         between(living_sqft, 500, 6000),
         !is.na(BED_COUNT), BED_COUNT >= 1,
         !is.na(BATH_COUNT), BATH_COUNT >= 1,
         !is.na(YEAR_BUILT), YEAR_BUILT >= 1800,
         YEAR_BUILT <= sale_year, !is.na(NBHD)) %>%
  mutate(log_price = log(sale_price), log_sqft = log(living_sqft),
         property_age = sale_year - YEAR_BUILT,
         neighborhood = factor(NBHD), year = factor(sale_year))
full_model <- lm(log_price ~ log_sqft + BED_COUNT + BATH_COUNT +
                   property_age + neighborhood + year, data = model_data)
cat("In-sample observations:", nobs(full_model), "\n")
cat("Adjusted R-squared:", round(summary(full_model)$adj.r.squared, 3), "\n")

# 8. Chronological holdout: train through 2023, evaluate on 2024–2025.
train <- filter(model_data, sale_year <= 2023)
test <- filter(model_data, sale_year >= 2024,
               NBHD %in% unique(train$NBHD))
train_model <- lm(log_price ~ log_sqft + BED_COUNT + BATH_COUNT +
                    property_age + neighborhood + sale_year, data = train)
actual <- test$sale_price
predicted <- exp(predict(train_model, newdata = test))
baseline_pred <- rep(median(train$sale_price), nrow(test))
metrics <- function(pred) c(MAE = mean(abs(actual - pred)),
                           RMSE = sqrt(mean((actual - pred)^2)),
                           MAPE = 100 * mean(abs(actual - pred) / actual))
comparison <- data.frame(Model = c("Training Median Baseline", "Hedonic Regression"),
                         rbind(metrics(baseline_pred), metrics(predicted)),
                         row.names = NULL)
write_csv(comparison, file.path(output_dir, "Richmond_Model_Performance.csv"))
print(annual_trends)
print(comparison)
cat("Test observations:", length(actual), "\n")
cat("Outputs saved to:", output_dir, "\n")

# Limitations: 2026 assessor extract; historical property attributes may be
# current rather than contemporaneous with each sale. No inflation adjustment,
# geographic spillovers, repeat-sale clustering, or sensitivity checks yet.
# Out-of-sample performance is compared with a weak constant-median baseline.
# Do not describe this model as an appraisal or causal estimate.
