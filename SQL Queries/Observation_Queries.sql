-- =====================================================================
-- OBSERVATION QUERIES (BigQuery)
-- Reproduces every figure used in Observations.md and Analysis.md directly from
-- `cleaned_sales`, so nothing needs to be copied by hand from Tableau crosstabs.
--
--   Market   : 'Domestic' = United Kingdom, 'International' = every other country
--   Period   : 'All years', 2010 or 2011
--   Product views use merchandise only (IsMerchandise) and rank by StockCode.
--
-- Run the sections you need; each is self-contained.
--   1  Monthly sales and MoM % by market
--   2  Monthly sales summary (range / average) by market
--   3  KPIs by market and year
--   4  Top 5 products by sales, units and orders
--   5  International countries: top 5 by sales, orders and AOV
--   6  Year-over-year, Jan-Nov (like-for-like)
--   7  December 1-9 like-for-like
--   8  Customer concentration
--   9  Concentration inside each country
--  10  Order and customer profile
--  11  Seasonality
--  12  Non-merchandise lines still in cleaned_sales
-- Repeat purchase rate  -> Repeat_Purchase_Rate.sql
-- Customer retention    -> Customer_Retention.sql
-- =====================================================================

-- Minimum orders a country needs to appear in the AOV ranking (section 5).
-- (DECLARE must come first in a BigQuery script.)
DECLARE min_orders_for_aov INT64 DEFAULT 30;


-- ---------------------------------------------------------------------
-- 1) MONTHLY SALES AND MONTH-OVER-MONTH % CHANGE, by market and in total
--    (replaces the "MoM Sales" crosstabs; Jan 2010 has no MoM, Dec 2011 is Dec 1-9 only)
-- ---------------------------------------------------------------------
WITH monthly AS (
  SELECT
    DATE_TRUNC(InvoiceDate, MONTH) AS Month,
    IF(Country = 'United Kingdom', 'Domestic', 'International') AS Market,
    SUM(Sales) AS Sales
  FROM `online_retail_2_dataset.cleaned_sales`
  GROUP BY Month, Market
),

combined AS (
  SELECT Month, Market, Sales FROM monthly
  UNION ALL
  SELECT Month, 'Total' AS Market, SUM(Sales) AS Sales FROM monthly GROUP BY Month
)

SELECT
  Month,
  Market,
  ROUND(Sales, 2) AS Sales,
  ROUND(SAFE_DIVIDE(Sales - LAG(Sales) OVER w, LAG(Sales) OVER w) * 100, 3) AS mom_pct_change
FROM combined
WINDOW w AS (PARTITION BY Market ORDER BY Month)
ORDER BY Market, Month;


-- ---------------------------------------------------------------------
-- 2) MONTHLY SALES SUMMARY by market (min, max, average)
--    Excludes the partial month (Dec 2011). Add or remove months to match the
--    "excluding peak months" averages quoted in the analysis.
-- ---------------------------------------------------------------------
WITH monthly AS (
  SELECT
    DATE_TRUNC(InvoiceDate, MONTH) AS Month,
    IF(Country = 'United Kingdom', 'Domestic', 'International') AS Market,
    SUM(Sales) AS Sales
  FROM `online_retail_2_dataset.cleaned_sales`
  GROUP BY Month, Market
)

SELECT
  Market,
  ROUND(MIN(Sales), 0)                                         AS lowest_month,
  ARRAY_AGG(Month ORDER BY Sales ASC LIMIT 1)[OFFSET(0)]      AS lowest_month_is,
  ROUND(MAX(Sales), 0)                                         AS highest_month,
  ARRAY_AGG(Month ORDER BY Sales DESC LIMIT 1)[OFFSET(0)]     AS highest_month_is,
  ROUND(AVG(Sales), 0)                                         AS average_month,
  -- average excluding the Sep-Dec high season
  ROUND(AVG(IF(EXTRACT(MONTH FROM Month) <= 8, Sales, NULL)), 0) AS average_jan_to_aug
FROM monthly
WHERE Month < DATE '2011-12-01'
GROUP BY Market;


-- ---------------------------------------------------------------------
-- 3) KPIs by market and year (Sales, Orders, Customers, Items sold, AOV)
-- ---------------------------------------------------------------------
WITH base AS (
  SELECT
    EXTRACT(YEAR FROM InvoiceDate) AS yr,
    IF(Country = 'United Kingdom', 'Domestic', 'International') AS mkt,
    Invoice, CustomerID, Quantity, Sales
  FROM `online_retail_2_dataset.cleaned_sales`
)

SELECT
  COALESCE(CAST(yr AS STRING), 'All years') AS Period,
  COALESCE(mkt, 'All markets')              AS Market,
  ROUND(SUM(Sales), 2)                      AS Sales,
  COUNT(DISTINCT Invoice)                   AS Orders,
  COUNT(DISTINCT CustomerID)                AS Customers,
  SUM(Quantity)                             AS Items_Sold,
  ROUND(SAFE_DIVIDE(SUM(Sales), COUNT(DISTINCT Invoice)), 2) AS Avg_Order_Value
FROM base
GROUP BY GROUPING SETS ((), (yr), (mkt), (yr, mkt))
ORDER BY Period, Market;
-- Note: customers are distinct per row of output, so Domestic + International
-- can exceed 'All markets' by the number of customers who bought in both.


-- ---------------------------------------------------------------------
-- 4) TOP 5 PRODUCTS by sales, units and number of orders containing the item
--    Merchandise only, ranked by StockCode (one canonical description each).
--    Each ranking is returned for every Period x Market combination.
-- ---------------------------------------------------------------------
WITH base AS (
  SELECT
    EXTRACT(YEAR FROM InvoiceDate) AS yr,
    IF(Country = 'United Kingdom', 'Domestic', 'International') AS mkt,
    StockCode, Description, Invoice, Quantity, Sales
  FROM `online_retail_2_dataset.cleaned_sales`
  WHERE IsMerchandise
),

agg AS (
  SELECT
    COALESCE(CAST(yr AS STRING), 'All years') AS Period,
    COALESCE(mkt, 'All markets')              AS Market,
    StockCode,
    ANY_VALUE(Description)                    AS Description,
    ROUND(SUM(Sales), 2)                      AS Sales,
    SUM(Quantity)                             AS Units,
    COUNT(DISTINCT Invoice)                   AS Orders
  FROM base
  GROUP BY GROUPING SETS ((StockCode), (yr, StockCode), (mkt, StockCode), (yr, mkt, StockCode))
),

ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY Period, Market ORDER BY Sales DESC, StockCode) AS rank_sales,
    ROW_NUMBER() OVER (PARTITION BY Period, Market ORDER BY Units  DESC, StockCode) AS rank_units,
    ROW_NUMBER() OVER (PARTITION BY Period, Market ORDER BY Orders DESC, StockCode) AS rank_orders
  FROM agg
)

SELECT 'Top by sales' AS ranking, Period, Market, rank_sales AS rnk, StockCode, Description, Sales, Units, Orders
FROM ranked WHERE rank_sales <= 5
UNION ALL
SELECT 'Top by units', Period, Market, rank_units, StockCode, Description, Sales, Units, Orders
FROM ranked WHERE rank_units <= 5
UNION ALL
SELECT 'Top by orders', Period, Market, rank_orders, StockCode, Description, Sales, Units, Orders
FROM ranked WHERE rank_orders <= 5
ORDER BY ranking, Period, Market, rnk;


-- ---------------------------------------------------------------------
-- 5) INTERNATIONAL COUNTRIES: top 5 by sales, by order count, and by AOV
--    AOV ranking requires at least 30 orders so one-order countries cannot top it.
--    Change min_orders_for_aov to adjust.
-- ---------------------------------------------------------------------
WITH base AS (
  SELECT
    EXTRACT(YEAR FROM InvoiceDate) AS yr,
    Country, Invoice, CustomerID, Sales
  FROM `online_retail_2_dataset.cleaned_sales`
  WHERE Country != 'United Kingdom'
),

agg AS (
  SELECT
    COALESCE(CAST(yr AS STRING), 'All years') AS Period,
    Country,
    ROUND(SUM(Sales), 2)                      AS Sales,
    COUNT(DISTINCT Invoice)                   AS Orders,
    COUNT(DISTINCT CustomerID)                AS Customers,
    ROUND(SAFE_DIVIDE(SUM(Sales), COUNT(DISTINCT Invoice)), 2) AS Avg_Order_Value
  FROM base
  GROUP BY GROUPING SETS ((Country), (yr, Country))
),

ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY Period ORDER BY Sales DESC, Country)  AS rank_sales,
    ROW_NUMBER() OVER (PARTITION BY Period ORDER BY Orders DESC, Country) AS rank_orders,
    ROW_NUMBER() OVER (PARTITION BY Period, Orders >= min_orders_for_aov
                       ORDER BY Avg_Order_Value DESC, Country)             AS rank_aov
  FROM agg
)

SELECT 'Top by sales' AS ranking, Period, rank_sales AS rnk, Country, Sales, Orders, Customers, Avg_Order_Value
FROM ranked WHERE rank_sales <= 5
UNION ALL
SELECT 'Top by orders', Period, rank_orders, Country, Sales, Orders, Customers, Avg_Order_Value
FROM ranked WHERE rank_orders <= 5
UNION ALL
SELECT 'Top by AOV (min orders)', Period, rank_aov, Country, Sales, Orders, Customers, Avg_Order_Value
FROM ranked WHERE Orders >= min_orders_for_aov AND rank_aov <= 5
ORDER BY ranking, Period, rnk;


-- ---------------------------------------------------------------------
-- 6) YEAR-OVER-YEAR, JAN-NOV (like-for-like; Dec 2011 is incomplete)
--    Sales, orders, customers, items and AOV for 2010 vs 2011, by market.
-- ---------------------------------------------------------------------
WITH base AS (
  SELECT
    EXTRACT(YEAR FROM InvoiceDate) AS yr,
    IF(Country = 'United Kingdom', 'Domestic', 'International') AS mkt,
    Country, Invoice, CustomerID, Quantity, Sales
  FROM `online_retail_2_dataset.cleaned_sales`
  WHERE EXTRACT(MONTH FROM InvoiceDate) <= 11
)

SELECT
  COALESCE(mkt, 'All markets') AS Market,
  ROUND(SUM(IF(yr = 2010, Sales, 0)), 2)                    AS sales_2010,
  ROUND(SUM(IF(yr = 2011, Sales, 0)), 2)                    AS sales_2011,
  ROUND(SAFE_DIVIDE(SUM(IF(yr = 2011, Sales, 0)), SUM(IF(yr = 2010, Sales, 0))) * 100 - 100, 3) AS sales_yoy_pct,
  COUNT(DISTINCT IF(yr = 2010, Invoice, NULL))              AS orders_2010,
  COUNT(DISTINCT IF(yr = 2011, Invoice, NULL))              AS orders_2011,
  ROUND(SAFE_DIVIDE(COUNT(DISTINCT IF(yr = 2011, Invoice, NULL)),
                    COUNT(DISTINCT IF(yr = 2010, Invoice, NULL))) * 100 - 100, 2) AS orders_yoy_pct,
  COUNT(DISTINCT IF(yr = 2010, CustomerID, NULL))           AS customers_2010,
  COUNT(DISTINCT IF(yr = 2011, CustomerID, NULL))           AS customers_2011,
  SUM(IF(yr = 2010, Quantity, 0))                           AS items_2010,
  SUM(IF(yr = 2011, Quantity, 0))                           AS items_2011,
  ROUND(SAFE_DIVIDE(SUM(IF(yr = 2011, Quantity, 0)), SUM(IF(yr = 2010, Quantity, 0))) * 100 - 100, 2) AS items_yoy_pct,
  ROUND(SAFE_DIVIDE(SUM(IF(yr = 2010, Sales, 0)), COUNT(DISTINCT IF(yr = 2010, Invoice, NULL))), 2) AS aov_2010,
  ROUND(SAFE_DIVIDE(SUM(IF(yr = 2011, Sales, 0)), COUNT(DISTINCT IF(yr = 2011, Invoice, NULL))), 2) AS aov_2011
FROM base
GROUP BY GROUPING SETS ((), (mkt))
ORDER BY Market;

-- 6b) International growth by country, Jan-Nov (who drove the +x%?)
SELECT
  Country,
  ROUND(SUM(IF(EXTRACT(YEAR FROM InvoiceDate) = 2010, Sales, 0)), 0) AS sales_2010,
  ROUND(SUM(IF(EXTRACT(YEAR FROM InvoiceDate) = 2011, Sales, 0)), 0) AS sales_2011,
  ROUND(SUM(IF(EXTRACT(YEAR FROM InvoiceDate) = 2011, Sales, 0))
      - SUM(IF(EXTRACT(YEAR FROM InvoiceDate) = 2010, Sales, 0)), 0) AS change_gbp,
  ROUND(SAFE_DIVIDE(SUM(IF(EXTRACT(YEAR FROM InvoiceDate) = 2011, Sales, 0)),
                    SUM(IF(EXTRACT(YEAR FROM InvoiceDate) = 2010, Sales, 0))) * 100 - 100, 1) AS change_pct
FROM `online_retail_2_dataset.cleaned_sales`
WHERE Country != 'United Kingdom'
  AND EXTRACT(MONTH FROM InvoiceDate) <= 11
GROUP BY Country
ORDER BY change_gbp DESC;


-- ---------------------------------------------------------------------
-- 7) DECEMBER 1-9 LIKE-FOR-LIKE (the only December days present in both years)
-- ---------------------------------------------------------------------
SELECT
  EXTRACT(YEAR FROM InvoiceDate)       AS Year,
  ROUND(SUM(Sales), 2)                 AS sales_dec_1_to_9,
  COUNT(DISTINCT Invoice)              AS orders,
  ROUND(MAX(Sales), 2)                 AS largest_single_line
FROM `online_retail_2_dataset.cleaned_sales`
WHERE EXTRACT(MONTH FROM InvoiceDate) = 12
  AND EXTRACT(DAY FROM InvoiceDate) <= 9
GROUP BY Year
ORDER BY Year;


-- ---------------------------------------------------------------------
-- 8) CUSTOMER CONCENTRATION: share of sales from top customer tiers
-- ---------------------------------------------------------------------
WITH cust AS (
  SELECT CustomerID, SUM(Sales) AS Sales
  FROM `online_retail_2_dataset.cleaned_sales`
  GROUP BY CustomerID
),

ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (ORDER BY Sales DESC) AS rn,
    COUNT(*) OVER ()                        AS n,
    SUM(Sales) OVER ()                      AS total
  FROM cust
),

tiers AS (
  SELECT 'Top 1% of customers'  AS tier, 0.01 AS p UNION ALL
  SELECT 'Top 5% of customers',  0.05 UNION ALL
  SELECT 'Top 10% of customers', 0.10 UNION ALL
  SELECT 'Top 20% of customers', 0.20
)

SELECT
  t.tier,
  COUNT(*)                                          AS customers,
  ROUND(SUM(r.Sales), 2)                            AS sales,
  ROUND(SUM(r.Sales) / ANY_VALUE(r.total) * 100, 1) AS pct_of_total_sales
FROM ranked AS r
JOIN tiers  AS t ON r.rn <= ROUND(r.n * t.p)
GROUP BY t.tier

UNION ALL

SELECT 'Top 10 customers', COUNT(*), ROUND(SUM(Sales), 2), ROUND(SUM(Sales) / ANY_VALUE(total) * 100, 1)
FROM ranked WHERE rn <= 10

ORDER BY pct_of_total_sales;

-- 8b) The 10 largest customers
SELECT
  CustomerID,
  ANY_VALUE(Country)        AS Country,
  ROUND(SUM(Sales), 2)      AS Sales,
  COUNT(DISTINCT Invoice)   AS Orders
FROM `online_retail_2_dataset.cleaned_sales`
GROUP BY CustomerID
ORDER BY Sales DESC
LIMIT 10;

-- 8c) International concentration: share of international sales from the top 5 / top 10 customers
WITH cust AS (
  SELECT CustomerID, SUM(Sales) AS Sales
  FROM `online_retail_2_dataset.cleaned_sales`
  WHERE Country != 'United Kingdom'
  GROUP BY CustomerID
),

ranked AS (
  SELECT *, ROW_NUMBER() OVER (ORDER BY Sales DESC) AS rn, SUM(Sales) OVER () AS total
  FROM cust
)

SELECT
  ROUND(SUM(IF(rn <= 5,  Sales, 0)) / ANY_VALUE(total) * 100, 1) AS top5_pct,
  ROUND(SUM(IF(rn <= 10, Sales, 0)) / ANY_VALUE(total) * 100, 1) AS top10_pct,
  COUNT(*)                                                       AS international_customers
FROM ranked;


-- ---------------------------------------------------------------------
-- 9) CONCENTRATION INSIDE EACH COUNTRY: how much does the biggest customer
--    (or the biggest two) drive a country's sales? Read this before comparing
--    country AOVs.
-- ---------------------------------------------------------------------
WITH cc AS (
  SELECT Country, CustomerID, SUM(Sales) AS s
  FROM `online_retail_2_dataset.cleaned_sales`
  GROUP BY Country, CustomerID
),

ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY Country ORDER BY s DESC) AS rn
  FROM cc
)

SELECT
  Country,
  ROUND(SUM(s), 0)                                   AS sales,
  COUNT(*)                                           AS customers,
  ROUND(SUM(IF(rn = 1, s, 0)) / SUM(s) * 100, 1)     AS top_customer_pct,
  ROUND(SUM(IF(rn <= 2, s, 0)) / SUM(s) * 100, 1)    AS top2_customers_pct
FROM ranked
GROUP BY Country
ORDER BY sales DESC
LIMIT 15;


-- ---------------------------------------------------------------------
-- 10) ORDER AND CUSTOMER PROFILE
-- ---------------------------------------------------------------------
-- 10a) Median vs mean order value
WITH orders AS (
  SELECT Invoice, SUM(Sales) AS order_value
  FROM `online_retail_2_dataset.cleaned_sales`
  GROUP BY Invoice
)

SELECT DISTINCT
  ROUND(PERCENTILE_CONT(order_value, 0.5) OVER (), 2) AS median_order_value,
  ROUND(AVG(order_value) OVER (), 2)                   AS mean_order_value
FROM orders;

-- 10b) Orders per customer, and share of one-order customers
WITH per_customer AS (
  SELECT CustomerID, COUNT(DISTINCT Invoice) AS orders
  FROM `online_retail_2_dataset.cleaned_sales`
  GROUP BY CustomerID
)

SELECT
  COUNT(*)                                                AS customers,
  ROUND(COUNTIF(orders = 1) * 100.0 / COUNT(*), 1)        AS pct_one_order_customers,
  APPROX_QUANTILES(orders, 2)[OFFSET(1)]                  AS median_orders_per_customer
FROM per_customer;


-- ---------------------------------------------------------------------
-- 11) SEASONALITY
-- ---------------------------------------------------------------------
-- 11a) Share of each year's sales in Sep-Nov.
--      sep_nov_pct_of_year is NOT like-for-like for 2011 (the data ends on 9 Dec);
--      use sep_nov_pct_of_jan_nov to compare the two years.
SELECT
  EXTRACT(YEAR FROM InvoiceDate) AS Year,
  ROUND(SUM(IF(EXTRACT(MONTH FROM InvoiceDate) IN (9, 10, 11), Sales, 0)), 0) AS sep_nov_sales,
  ROUND(SUM(IF(EXTRACT(MONTH FROM InvoiceDate) IN (9, 10, 11), Sales, 0)) / SUM(Sales) * 100, 1) AS sep_nov_pct_of_year,
  ROUND(SUM(IF(EXTRACT(MONTH FROM InvoiceDate) IN (9, 10, 11), Sales, 0))
        / SUM(IF(EXTRACT(MONTH FROM InvoiceDate) <= 11, Sales, 0)) * 100, 1) AS sep_nov_pct_of_jan_nov
FROM `online_retail_2_dataset.cleaned_sales`
GROUP BY Year
ORDER BY Year;

-- 11b) Sales by day of week (are there Saturday sales?)
SELECT
  FORMAT_DATE('%A', InvoiceDate)             AS weekday,
  ROUND(SUM(Sales) / SUM(SUM(Sales)) OVER () * 100, 1) AS pct_of_sales
FROM `online_retail_2_dataset.cleaned_sales`
GROUP BY weekday
ORDER BY pct_of_sales DESC;

-- 11c) Last trading date in each December (Dec 2010 ends before Christmas)
SELECT EXTRACT(YEAR FROM InvoiceDate) AS Year, MIN(InvoiceDate) AS first_date, MAX(InvoiceDate) AS last_date
FROM `online_retail_2_dataset.cleaned_sales`
WHERE EXTRACT(MONTH FROM InvoiceDate) = 12
GROUP BY Year;


-- ---------------------------------------------------------------------
-- 12) NON-MERCHANDISE LINES still present in cleaned_sales (Manual, Postage, ...)
--     They count towards Sales/Orders KPIs but are excluded from product rankings above.
-- ---------------------------------------------------------------------
SELECT
  ROUND(SUM(IF(NOT IsMerchandise, Sales, 0)), 2)                    AS non_merchandise_sales,
  ROUND(SUM(IF(NOT IsMerchandise, Sales, 0)) / SUM(Sales) * 100, 2) AS pct_of_total_sales
FROM `online_retail_2_dataset.cleaned_sales`;
