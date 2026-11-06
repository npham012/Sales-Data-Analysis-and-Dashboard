# Online Retail Sales Analysis & Dashboard

End-to-end sales analysis of a UK-based giftware retailer: data cleaning in **SQL (Google BigQuery)**, an interactive **Tableau** dashboard, and a written analysis with actionable business recommendations.

**Live dashboard:** 
https://public.tableau.com/shared/2TMCWW8RW?:display_count=n&:origin=viz_share_link

**Full analysis:** [Analysis.md](./Analysis.md)

![Dashboard preview](<./Tableau Dashboard/Online Retail Sales Dashboard.png>)

---

## Project overview

The dataset covers roughly two years of transactions (2010–2011) from a wholesale-oriented online giftware retailer. The goal was to turn messy transaction lines into a trustworthy sales view, then answer practical questions:

- How are sales trending, and how do UK and international markets differ?
- Which products and countries drive revenue?
- How loyal are customers, and where is the business exposed?

## Key findings

| | |
|---|---|
| **Sales** | £16.1M across 35,188 orders and 5,762 identified customers (average order £458.61) |
| **UK vs international** | UK is 82.6% of sales; international is 17.4% but has an average order about twice as large (£863 vs £417) |
| **Trend** | Like-for-like (Jan–Nov) sales were flat YoY (-0.13%). Orders -3.1%, average order value +3.0% |
| **UK** | Sales -3.2% Jan–Nov: about the same number of customers placing 5% fewer orders |
| **International growth** | +15.6% YoY with 21% more customers, but 55% of the £ growth is a single Australian account; excluding Australia, +7% |
| **Concentration** | Top 10% of customers = 63% of sales. One customer is 95% of Netherlands sales; two customers are 98% of EIRE sales |
| **Retention** | 63% of 2010 customers bought again in 2011; the lapsed 37% had spent £1.19M. Customers who stayed spent about 8% less |
| **Seasonality** | Sep–Nov = 36% of full-year sales, with a +37% to +47% jump every September |

**Top recommendations:** Prioritise win-back and retention of lapsed customers, manage the largest accounts individually, keep growing international through Germany and France rather than a few big buyers, address the decline in UK order frequency, and plan stock and promotions around the September–November peak. See [Analysis.md](./Analysis.md#recommendations) for the full reasoning and caveats.

## Tools

| Tool | Used for |
|---|---|
| Google BigQuery (SQL) | Combining sheets, cleaning, flagging, validation, KPI and customer analysis |
| Tableau | Interactive dashboard |
| Excel | Consolidating the source workbook |

## Repository structure

```
.
├── README.md
├── Analysis.md                              # Full analysis and recommendations
├── SQL Queries/
│   ├── 3_Layer_Data_Processing_Script.sql   # Raw → clean invoice → sales layers
│   ├── Data_Validation.sql                  # Data-quality checks and reconciliation
│   ├── Observation_Queries.sql              # Every figure used in the analysis
│   ├── Repeat_Purchase_Rate.sql             # Repeat purchase rate by year and market
│   └── Customer_Retention.sql               # 2010 → 2011 retention and lapsed revenue
├── Query Results/                           # Saved query outputs
│   ├── Validation_Results.md
│   ├── Observation_Results.md
│   ├── Repeat_Purchase_Rate.md
│   └── Customer_Retention.md
├── Tableau Dashboard/
│   ├── Online Retail Sales Dashboard.twb    # Tableau Dashboard Workbook
│   └── Online Retail Sales Dashboard.png    # Tableau Dashboard Preview Image
└── Figures/
│   ├── customer_concentration.png
│   ├── monthly_sales_by_market.png
│   └── yoy_jan_nov.png
```

## Data pipeline

The source is a workbook with two yearly sheets, loaded into BigQuery as two tables.

| Layer | Table | What it does |
|---|---|---|
| 1. Raw | `raw_invoices` | Combines both sheets with `UNION DISTINCT` (one copy of any identical row) |
| 2. Clean invoice | `cleaned_invoices` | Casts `Price` to numeric and `Customer ID` to string; standardises descriptions (trim, collapse whitespace, title case) and assigns one canonical name per stock code; computes `Sales`; adds flags `Canceled`, `Returned`, `NegativePrice`, `Giveaway`, `IsMerchandise`. Adds and removes no rows |
| 3. Sales analysis | `cleaned_sales` | Keeps positive quantity and price, non-cancelled invoices, known customer, known country, 2010–2011, and drops orders cancelled in full within 30 days |

### Data-quality decisions

| Issue | Lines | Treatment |
|---|---:|---|
| Rows identical in both sheets (sheets overlap in early Dec 2010) | 22,202 | Kept once |
| Identical repeat lines within a sheet | 12,133 | Collapsed, assumed to be duplicate entries |
| Cancelled invoices (`C…`) | 19,104 | Excluded from sales |
| Negative quantities not on a cancellation invoice | 3,393 | Excluded from sales |
| Zero or negative unit price (gifts, samples, corrections) | 2,644 | Excluded |
| Missing Customer ID | 228,488 | Excluded, so figures cover identified customers only (22.8% of all raw lines have no ID) |
| `Unspecified` country | 518 | Excluded |
| Dec 2009 (only month of 2009) | 30,272 | Excluded |
| Orders cancelled in full within 30 days (same customer, product and quantity) | 3,831 | Excluded (£545k, 3.3% of sales; includes two single-line orders worth £246k) |
| Non-product lines (postage, manual, carriage, adjustments, bank charges, discounts, test items) | | Kept in sales totals, flagged `IsMerchandise = FALSE` and left out of product rankings |

Every exclusion is reconciled from 1,067,371 source lines to 744,786 sales lines in Section 12 of [`Data_Validation.sql`](<./SQL%20Queries/Data_Validation.sql>) and explained in [Analysis.md](./Analysis.md#data-and-methodology).

## Dashboard

**KPIs:** Customers, Orders, Items sold, Sales, Average order value.

**Views:** month-over-month sales highlight table; monthly sales line chart (domestic vs international); sales map; top 5 products by sales; most ordered products; international country tables.

**Filters:** Year, Month, Market type (Domestic / International), with a reset button.

**Definitions**

| Measure | Definition |
|---|---|
| Sales | `UnitPrice × Quantity` (in £, after the exclusions above) |
| Orders | `COUNTD(Invoice)` |
| Customers | `COUNTD(CustomerID)` |
| AOV | Sales ÷ Orders |
| Domestic | Country = United Kingdom |
| Repeat purchase rate | Customers with 2+ invoices in the period ÷ all customers in the period (per market) |

## How to reproduce

1. Download the Online Retail II dataset (link below) and load each sheet into BigQuery as `online_retail_2_dataset.sheet1` and `sheet2`.
2. Run `SQL Queries/3_Layer_Data_Processing_Script.sql` to create `raw_invoices`, `cleaned_invoices` and `cleaned_sales`. Set `exclude_reversed_orders` to `FALSE` at the top of the script to keep orders that were later cancelled.
3. Run `SQL Queries/Data_Validation.sql` to check the data and reconcile the exclusions.
4. Run `SQL Queries/Observation_Queries.sql`, `SQL Queries/Repeat_Purchase_Rate.sql` and `SQL Queries/Customer_Retention.sql` to reproduce every number in the analysis.
5. Export `cleaned_sales` to CSV
6. Visit the live dashboard at: https://public.tableau.com/shared/2TMCWW8RW?:display_count=n&:origin=viz_share_link
7. Download a copy of the dashboard, `Online Retail Sales Dashboard.twbx`
8. Open `Online Retail Sales Dashboard.twbx` and re-point the data source to `cleaned_sales.csv` by creating or editing a connection.

## Limitations

- No cost or profit data, so profitability by product or market is unknown.
- Sales exclude orders cancelled in full within 30 days but are not net of partial or later returns.
- Customers without an ID are excluded, so totals are not total company revenue.
- Only two years of data (and a partial final month), so trends can't be separated from one-offs.
- No acquisition-cost or churn data.

More detail is in [Analysis.md](./Analysis.md#limitations).

## Data source

**Online Retail II** by Daqing Chen, UCI Machine Learning Repository, licensed [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
Chen, D. (2012). *Online Retail II* [Dataset]. https://doi.org/10.24432/C5CG6D
