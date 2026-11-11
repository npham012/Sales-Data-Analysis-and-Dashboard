-- =====================================================================
-- DATA VALIDATION (BigQuery)
-- Run after 3_Layer_Data_Processing_Script.sql. Sections 1-6 profile the raw data;
-- 7 checks duplicates; 8-11 check countries, products and outliers; 12-13 reconcile to cleaned_sales.
-- =====================================================================

-- 1) Cancelled invoices (Invoice starts with 'C')              
SELECT COUNT(*) AS canceled_lines
FROM `online_retail_2_dataset.raw_invoices`
WHERE STARTS_WITH(UPPER(CAST(Invoice AS STRING)), 'C');

-- 2) Negative quantities (returns)                             
SELECT COUNT(*) AS negative_quantity_lines
FROM `online_retail_2_dataset.raw_invoices`
WHERE Quantity < 0;

-- 3) Negative prices                                           
SELECT COUNT(*) AS negative_price_lines
FROM `online_retail_2_dataset.raw_invoices`
WHERE ROUND(CAST(Price AS NUMERIC), 2) < 0;

-- 4) Zero-price lines (giveaways)                              
SELECT COUNT(*) AS zero_price_lines
FROM `online_retail_2_dataset.raw_invoices`
WHERE ROUND(CAST(Price AS NUMERIC), 2) = 0;

-- 5) Null descriptions, and what they are                
SELECT
  COUNT(*)                                        AS null_description_lines,
  COUNTIF(Quantity < 0)                           AS of_which_negative_quantity,   -- previously 2,633
  COUNTIF(ROUND(CAST(Price AS NUMERIC), 2) = 0)   AS of_which_zero_price           -- previously 4,275
FROM `online_retail_2_dataset.raw_invoices`
WHERE Description IS NULL;

-- 6) Missing Customer IDs                          
SELECT
  COUNT(*)                                                         AS total_lines,
  COUNTIF(`Customer ID` IS NULL)                                   AS null_customer_id_lines,
  ROUND(COUNTIF(`Customer ID` IS NULL) * 100.0 / COUNT(*), 1)      AS pct_of_lines
FROM `online_retail_2_dataset.raw_invoices`;

-- 7) Duplicates (the pipeline combines the sheets with UNION DISTINCT, so checks on the
--    combined table can never find duplicates. These checks look at the SOURCE sheets.)
-- 7a) Rows identical in both sheets (the overlap that UNION DISTINCT collapses)
SELECT COUNT(*) AS distinct_rows_in_both_sheets
FROM (
  SELECT Invoice, StockCode, `Customer ID`, Description, Quantity, InvoiceDate, Price, Country
  FROM `online_retail_2_dataset.sheet1`
  INTERSECT DISTINCT
  SELECT Invoice, StockCode, `Customer ID`, Description, Quantity, InvoiceDate, Price, Country
  FROM `online_retail_2_dataset.sheet2`
);

-- 7b) Exact duplicate rows WITHIN each sheet. UNION DISTINCT also collapses these, so
--     this is the number to look at: if it is 0 (or tiny) the choice costs nothing;
--     if it is large, repeated lines on one invoice are being merged into one.
SELECT sheet, SUM(copies - 1) AS extra_copies, COUNT(*) AS duplicated_row_groups
FROM (
  SELECT 'sheet1' AS sheet, COUNT(*) AS copies
  FROM `online_retail_2_dataset.sheet1`
  GROUP BY Invoice, StockCode, `Customer ID`, Description, Quantity, InvoiceDate, Price, Country
  HAVING COUNT(*) > 1
  UNION ALL
  SELECT 'sheet2', COUNT(*)
  FROM `online_retail_2_dataset.sheet2`
  GROUP BY Invoice, StockCode, `Customer ID`, Description, Quantity, InvoiceDate, Price, Country
  HAVING COUNT(*) > 1
)
GROUP BY sheet;

-- 7c) Total rows removed by UNION DISTINCT (overlap + within-sheet duplicates)
SELECT
  (SELECT COUNT(*) FROM `online_retail_2_dataset.sheet1`)
  + (SELECT COUNT(*) FROM `online_retail_2_dataset.sheet2`)
  - (SELECT COUNT(*) FROM `online_retail_2_dataset.raw_invoices`) AS rows_removed_by_union_distinct;

-- 7d) Date range per sheet (shows the overlap window)
SELECT 'sheet1' AS sheet, MIN(DATE(InvoiceDate)) AS first_date, MAX(DATE(InvoiceDate)) AS last_date, COUNT(*) AS line_count
FROM `online_retail_2_dataset.sheet1`
UNION ALL
SELECT 'sheet2', MIN(DATE(InvoiceDate)), MAX(DATE(InvoiceDate)), COUNT(*)
FROM `online_retail_2_dataset.sheet2`;

-- 7e) Layer 2 must not add or remove rows: both counts should be equal
SELECT
  (SELECT COUNT(*) FROM `online_retail_2_dataset.raw_invoices`)      AS raw_rows,
  (SELECT COUNT(*) FROM `online_retail_2_dataset.cleaned_invoices`)  AS cleaned_invoice_rows;

-- 8) Countries
-- 8a) Null / blank country                                    
SELECT COUNT(*) AS null_or_blank_country
FROM `online_retail_2_dataset.raw_invoices`
WHERE Country IS NULL OR TRIM(Country) = '';

-- 8b) Lines by country (look for 'Unspecified' and spelling variants)
SELECT TRIM(Country) AS Country, COUNT(*) AS lines
FROM `online_retail_2_dataset.raw_invoices`
GROUP BY Country
ORDER BY lines DESC;

-- 9) Product data quality
-- 9a) Non-merchandise stock codes (Manual, Postage, Carriage, adjustments, ...)
SELECT StockCode, ANY_VALUE(Description) AS Description, COUNT(*) AS lines, ROUND(SUM(Sales), 2) AS sales
FROM `online_retail_2_dataset.cleaned_sales`
WHERE NOT IsMerchandise
GROUP BY StockCode
ORDER BY sales DESC;

-- 9b) Stock codes with more than one description in the RAW data (fixed by the canonical-name step)
SELECT COUNT(*) AS stock_codes_with_multiple_descriptions
FROM (
  SELECT UPPER(TRIM(CAST(StockCode AS STRING))) AS StockCode
  FROM `online_retail_2_dataset.raw_invoices`
  WHERE Description IS NOT NULL
  GROUP BY 1
  HAVING COUNT(DISTINCT INITCAP(TRIM(REGEXP_REPLACE(Description, r'\s+', ' ')))) > 1
);

-- 9c) Every StockCode in cleaned_sales should have exactly one description (expect 0 rows)
SELECT StockCode, COUNT(DISTINCT Description) AS descriptions
FROM `online_retail_2_dataset.cleaned_sales`
GROUP BY StockCode
HAVING COUNT(DISTINCT Description) > 1;

-- 10) Outlier orders and cancellations
-- 10a) Largest single order lines
SELECT Invoice, CustomerID, StockCode, Description, Quantity, UnitPrice, Sales, InvoiceDate
FROM `online_retail_2_dataset.cleaned_invoices`
WHERE NOT Canceled AND Quantity > 0
ORDER BY Sales DESC
LIMIT 10;

-- 10b) Were invoices 581483 and 541431 reversed? (cancellation lines for the same customers)
SELECT Invoice, CAST(`Customer ID` AS STRING) AS CustomerID, StockCode, Quantity, Price, DATE(InvoiceDate) AS InvoiceDate
FROM `online_retail_2_dataset.raw_invoices`
WHERE CAST(`Customer ID` AS STRING) IN ('16446', '12346')
  AND ABS(Quantity) IN (80995, 74215)
ORDER BY InvoiceDate, Invoice;

-- 11) Impact of the cancellation-matching rule (orders cancelled in full within 30 days)
--     Run with exclude_reversed_orders = FALSE in the pipeline to see the flagged rows,
--     or compare against the figures below.
SELECT
  COUNTIF(ReversedByCancellation)                                   AS reversed_order_lines,
  ROUND(SUM(IF(ReversedByCancellation, Sales, 0)), 2)               AS reversed_sales,
  ROUND(SUM(Sales), 2)                                              AS total_sales_in_table
FROM `online_retail_2_dataset.cleaned_sales`;
-- (If the pipeline was run with exclude_reversed_orders = TRUE this returns 0 reversed lines.)

-- 12) Reconciliation: raw rows -> cleaned_sales rows
SELECT
  COUNT(*)                                                                         AS cleaned_invoice_rows,
  COUNTIF(Canceled)                                                                AS cancellation_lines,
  COUNTIF(NOT Canceled AND Quantity <= 0)                                          AS non_positive_qty_not_cancelled,
  COUNTIF(NOT Canceled AND Quantity > 0 AND UnitPrice <= 0)                        AS zero_or_negative_price,
  COUNTIF(NOT Canceled AND Quantity > 0 AND UnitPrice > 0 AND CustomerID IS NULL)  AS missing_customer_id,
  COUNTIF(NOT Canceled AND Quantity > 0 AND UnitPrice > 0 AND CustomerID IS NOT NULL
          AND Country = 'Unspecified')                                             AS unspecified_country,
  COUNTIF(NOT Canceled AND Quantity > 0 AND UnitPrice > 0 AND CustomerID IS NOT NULL
          AND Country != 'Unspecified' AND InvoiceDate < DATE '2010-01-01')        AS before_2010,
  (SELECT COUNT(*) FROM `online_retail_2_dataset.cleaned_sales`)                   AS cleaned_sales_rows
FROM `online_retail_2_dataset.cleaned_invoices`;
-- Any remaining gap between the sum of the exclusions and cleaned_sales_rows is the
-- reversed-order rule (rows excluded because they were cancelled in full).

-- 13) Headline KPIs from cleaned_sales.
--     Previous pipeline: sales 16,682,692.89 | orders 35,441 | customers 5,783 | items 10,110,161
--     Expect small differences now (cross-sheet de-duplication, reversed orders).
SELECT
  ROUND(SUM(Sales), 2)        AS sales,
  COUNT(DISTINCT Invoice)     AS orders,
  COUNT(DISTINCT CustomerID)  AS customers,
  SUM(Quantity)               AS items_sold,
  ROUND(SUM(Sales) / COUNT(DISTINCT Invoice), 2) AS avg_order_value
FROM `online_retail_2_dataset.cleaned_sales`;
