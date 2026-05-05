# Table of Contents
- [Project Background](#project-background)
- [Executive Summary](#executive-summary)
- [Data Pipeline](#data-pipeline)
- [Query Benchmarks](#query-benchmarks)
- [Tableau Dashboard](#tableau-dashboard)
- [Appendix](#appendix)

---

# Project Background
This project leverages Google BigQuery to prepare data before loading it into Tableau to build a dashboard. Queries were later consolidated into a single query, then optimized to improve performance and reduce costs. 

## Business Objective
Provide stakeholders with an interactive view of sales performance to monitor trends, identify revenue drivers, and support inventory and marketing planning.

## Primary Use Cases
- Monitor monthly and seasonal sales performance.
- Identify top-performing products and geographies.
- Compare domestic vs international sales behavior.
- Support inventory and promotion planning.

--- 

# Executive Summary
## Insights
- International customers (customers outside of the United Kingdom) represent a smaller share of total customers but generate 33% higher average unit prices.
- Sales have slightly declined year-over-year in 2011, driven by both fewer customers and lower total items sold.
- March and September consistently show peak sales activity.

## Recommendations
- Analyze customer churn between 2010 and 2011 by product and geography to identify whether revenue loss was driven by customer attrition or reduced order size.
- Expand international sales for top-performing products, particularly those with strong foreign demand and higher unit prices, while monitoring margin impact.
- Use seasonal peaks (March and September) to plan targeted promotions and inventory allocation for top-selling products.
- Track repeat purchase behavior for top products, identifying whether demand is driven by repeat buyers or one-time purchases.

## Proposed Success Metrics
- Total revenue and revenue growth
- Average order value
- Sales by product and geography
- Repeat customer rate

## Next Steps
- Explore sales trends by country and product category.
- Examine order volume and revenue patterns for different customer segments.
- Identify opportunities to expand international sales.

---

# Data Pipeline
1. **Data Preparation**
   - Converted Excel files to CSV and loaded into BigQuery.
2. **Query Pipeline**
   - Consolidated multiple queries to combine datasets and clean the data into a single optimized query pipeline.
   - Applied SQL best practices, clustering, and partitioning to improve performance and reduce cost.
3. **Benchmarking & Optimization**
   - Measured elapsed time, slot time, and bytes processed.
   - Consolidation reduced resource use by ~50% and lowered query costs by ~43%.
   - Please refer to the appendix for full benchmarking results.
4. **Dashboarding**
   - Extracted processed data into Tableau.
   - Built interactive dashboard with filters and colorblind-friendly palettes.
   - Published to Tableau Public for stakeholder access.

---
# Query Benchmarks
<details>
<summary><b>
Click to see the query benchmarks.</b></summary>
<br></br>

# Query Benchmarking and Optimization
- Metrics: Elapsed Time, Slot Time Consumed, Bytes Shuffled, Bytes Processed.
- Optimization focuses on reducing bytes processed under On-Demand Pricing.
- Queries run on the same servers back-to-back, with cached results disabled.
- Guidelines minimized variability from server differences or cloud throttling.

## Performance Metrics
- **Elapsed Time**: Query run time
- **Slot Time Consumed**: Computational capacity used
- **Bytes Shuffled**: Data moved between query stages
- **Bytes Processed**: Data processed by the query

## Individual Query Performance
| Query Steps         | Elapsed Time     | Slot Time Consumed | Bytes Shuffled | Bytes Processed |
|--------------------|------------------|--------------------|----------------|-----------------|
| **Union**          | 7 seconds        | 30 seconds         | 311.57 MB      | 92.97 MB        |
| **Data Cleaning**  | 5 seconds        | 16 seconds         | 281.76 MB      | 89.96 MB        |
| **Computing Sales**| 6 seconds        | 19 seconds         | 208.14 MB      | 84.76 MB        |
| **Update Table**   | 5 seconds        | 21 seconds         | 225.97 MB      | 96.64 MB        |
| **Total**          | 23 seconds       | 86 seconds         | 1027.44 MB     | 364.33 MB       |

## Individual Queries vs Baseline Pipeline
| Metric                | Individual Queries | Baseline Pipeline | Performance Difference (Individual − Baseline) | % Reduction |
|-----------------------|--------------------|-------------------|------------------------------------------------|-------------|
| **Elapsed Time**      | 23 seconds         | 11 seconds        | 12 seconds                                     | 52.17%      |
| **Slot Time Consumed**| 86 seconds         | 38 seconds        | 48 seconds                                     | 55.81%      |
| **Bytes Shuffled**    | 1027.44 MB         | 501.29 MB         | 526.15 MB                                      | 51.21%      |
| **Bytes Processed**   | 364.33 MB          | 182.16 MB         | 182.17 MB                                      | 50%         |


## Optimized Pipeline vs Baseline Pipeline
| Metric                | Baseline Pipeline | Optimized Pipeline | Performance Difference (Baseline − Optimized) | % Reduction |
|-----------------------|-------------------|--------------------|-----------------------------------------------|-------------|
| **Elapsed Time**      | 11 seconds        | 12 seconds         | -1 second                                     | -9.09%      |
| **Slot Time Consumed**| 38 seconds        | 1340 seconds       | -1328 seconds                                 | -11066.67%  |
| **Bytes Shuffled**    | 501.29 MB         | 307.01 MB          | 194.28 MB                                     | 38.76%      |
| **Bytes Processed**   | 182.16 MB         | 103.97 MB          | 78.19 MB                                      | 42.92%      |
</details>

---

# Tableau Dashboard
<img width="1799" height="1199" alt="Dashboard(1)" src="https://github.com/user-attachments/assets/9d2c4f27-d11a-4505-a2a6-6e4c87b0c722" />

---

# Appendix
<details>
<summary><b>
Click to see links, tools used, and data source.
</b></summary>
<br></br>

# Links

## Data
- [Cleaned Data](./Data/cleaned_online_retail_II.csv)
- [Raw Data](./Data/online_retail_II.xlsx)
- [Date Scaffold](./Data/retail_II_date_scaffold.xlsx)

## Queries
- [SQL Queries](./Queries/)

## Dashboard
- [Tableau Dashboard](https://public.tableau.com/views/RetailSalesDashboard_17604811253120/Dashboard?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)


# Tools & Technologies
- **Microsoft Excel**: File conversion, date scaffold creation
- **Google BigQuery**: SQL querying, data cleaning, and data extraction
- **Tableau**: Interactive dashboarding

# Data
- The dataset contains sales from 2009–2011 for a UK-based giftware company.
- The dataset includes invoices, stock codes, descriptions, quantities, prices, customer IDs, timestamps, and countries.
- The data contains 778,863 rows and 8 columns.

# Data Source and License
Dataset: Online Retail II

Creator: Daqing Chen

License: Creative Commons Attribution 4.0 International (CC BY 4.0)

Reference: Chen, D. (2012). Online Retail II [Dataset]. UCI Machine Learning Repository. https://doi.org/10.24432/C5CG6D
</details>
