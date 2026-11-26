Richmond Housing Market Intelligence
An R-based analysis of Richmond, Virginia single-family housing transactions (2015–2025)

This portfolio project examines changes in nominal home sale prices, compares neighborhood-level markets, and evaluates a hedonic regression model using a chronological holdout. It uses public City of Richmond Assessor datasets extracted September 23, 2026.
Key findings
- 32,739 qualified, selected single-family transaction records after screening and deduplication.
- Median sale price increased from $225,500 in 2015 to $410,000 in 2025, an 81.8% nominal increase. This is a comparison of annual transaction medians, not a repeat-sales appreciation estimate.
- Among neighborhoods with at least 30 selected sales in 2025, Fan District had the highest median sale price ($914,650; 90 sales). Neighborhood medians are descriptive and not adjusted for differences in property characteristics.
- The full-sample hedonic regression used 30,471 observations and achieved adjusted R² = 0.779 in-sample.
- In a 2024–2025 chronological test set of 4,650 transactions, the regression achieved MAE $86,621, RMSE $128,331, and MAPE 21.54%. The training-period median-price baseline had MAE $227,146, RMSE $350,580, and MAPE 40.30%. The baseline is deliberately simple, so these improvements should not be interpreted as superiority to sophisticated valuation models.
Visualizations
Annual median sale price

2025 neighborhood comparison

Methodology
1. Import the City of Richmond Assessor transfer and property datasets.
2. Join records by parcel identifier (PID), retain qualified transfers with positive consideration, and select five residential PRIMARY_USE codes: 110, 115, 120, 130, 150.
3. Restrict analysis to 2015–2025, sale price above $10,000, and living area above 300 square feet; remove duplicate combinations of parcel identifier, transfer date, and consideration.
4. Calculate annual transaction counts, median sale prices, and median price per square foot; compare 2025 neighborhoods with at least 30 qualifying sales.
5. For modeling, restrict price to $50,000–$2 million, living area to 500–6,000 square feet, and require valid bedroom, bathroom, construction-year, and neighborhood values.
6. Fit a log-price hedonic linear regression using log living area, bedrooms, bathrooms, property age, neighborhood effects, and sale-year effects for in-sample description.
7. Separately fit a training model on sales through 2023, with numeric sale year for extrapolation, and evaluate predictions on eligible 2024–2025 sales. Compare against a constant training-period median baseline.
Reproduce the analysis
Requirements: R with readxl, dplyr, readr, ggplot2, and scales installed.
1. Obtain the original City of Richmond Assessor datasets and place these files in a local folder:
   - Assessor_Transfers_2026-09-23.xlsx
   - Assessor_Public_Data_Set_2026-09-23.xlsx
2. Open Richmond_Housing_Analysis.R in RStudio.
3. Change the data_dir variable near the top of the script to the folder containing the Excel files.
4. Run the script using Source or source("Richmond_Housing_Analysis.R").
5. Find the generated charts, aggregate tables, and model metrics in Richmond_Portfolio_Output/.
The source Excel files are not included in this repository. The script currently relies on the column layout of the specified September 2026 extracts. Import warnings can arise from nonnumeric values in Excel fields; users should review these against the source schema when adapting the workflow.
Repository contents
File	Description
Richmond_Housing_Analysis.R	Reproducible data preparation, visualization, modeling, and validation
Richmond_Price_Trend.png	Annual median sale price visualization
Richmond_Neighborhood_Comparison.png	Top ten neighborhoods by 2025 median sale price
Richmond_Model_Performance.csv	Chronological holdout metrics for baseline and regression
Richmond_Annual_Trends.csv	Annual sales counts and median prices
README.md	Project overview, methodology, findings, and limitations


The script also produces other output tables. Raw property-level records are not required for the published portfolio.
Limitations and interpretation
- Historical attribute mismatch: The 2026 property extract may reflect current characteristics rather than the characteristics at each historical sale, potentially introducing measurement error or temporal leakage.
- Transaction selection: Qualified transfers and selected residential codes are screening criteria, not proof that all observations are arm's-length single-family sales.
- Price trend interpretation: Annual medians reflect the mix of properties sold and are not inflation-adjusted or repeat-sales indices.
- Model validation: The test set excludes neighborhoods absent from training; observations may include multiple sales of the same property. The model extrapolates a linear year trend and back-transforms log predictions without a smearing correction.
- Benchmark strength: The constant training-median baseline is intentionally weak; stronger temporal and neighborhood-specific benchmarks would be needed before drawing claims of predictive superiority.
- Scope: Results are exploratory and descriptive, not causal effects, professional appraisals, or investment recommendations.
Tools and skills demonstrated
R · dplyr · readxl · ggplot2 · Data cleaning · Data joins · Exploratory analysis · Hedonic regression · Chronological validation · Model evaluation · Reproducible reporting

Data source: City of Richmond Assessor public transfer and property data, extract dated September 23, 2026.
