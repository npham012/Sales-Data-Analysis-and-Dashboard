-- =====================================================================
-- REPEAT PURCHASE RATE by year and market (from cleaned_sales)
-- Definition: customers with 2+ distinct invoices in the year / all customers in
-- that year, within the segment. This is a WITHIN-YEAR measure. For customers who
-- come back the following year, see Customer_Retention.sql.
--
-- 'Domestic' = United Kingdom. A customer who buys in both markets counts in each
-- market segment but once in 'Overall'.
-- =====================================================================

-- 1) All segments in one result
WITH base AS (
  SELECT
    EXTRACT(YEAR FROM InvoiceDate) AS Year,
    IF(Country = 'United Kingdom', 'Domestic', 'International') AS Market,
    CustomerID,
    Invoice
  FROM `online_retail_2_dataset.cleaned_sales`
),

by_market AS (
  SELECT Year, Market AS Segment, CustomerID, COUNT(DISTINCT Invoice) AS purchases
  FROM base
  GROUP BY Year, Segment, CustomerID
),

overall AS (
  SELECT Year, 'Overall' AS Segment, CustomerID, COUNT(DISTINCT Invoice) AS purchases
  FROM base
  GROUP BY Year, Segment, CustomerID
)

SELECT
  Year,
  Segment,
  COUNTIF(purchases >= 2) AS repeat_customers,
  COUNT(*)                AS total_customers,
  ROUND(SAFE_DIVIDE(COUNTIF(purchases >= 2) * 100.0, COUNT(*)), 2) AS repeat_purchase_rate_pct
FROM (SELECT * FROM by_market UNION ALL SELECT * FROM overall)
GROUP BY Year, Segment
ORDER BY Year, CASE Segment WHEN 'Overall' THEN 1 WHEN 'Domestic' THEN 2 ELSE 3 END;


-- 2) Excluding customers who bought in BOTH markets in the year
WITH base AS (
  SELECT
    EXTRACT(YEAR FROM InvoiceDate) AS Year,
    IF(Country = 'United Kingdom', 'Domestic', 'International') AS Market,
    CustomerID,
    Invoice
  FROM `online_retail_2_dataset.cleaned_sales`
),

single_market AS (
  SELECT Year, CustomerID
  FROM base
  GROUP BY Year, CustomerID
  HAVING COUNT(DISTINCT Market) = 1
),

customer_orders AS (
  SELECT b.Year, b.Market AS Segment, b.CustomerID, COUNT(DISTINCT b.Invoice) AS purchases
  FROM base AS b
  JOIN single_market AS s USING (Year, CustomerID)
  GROUP BY b.Year, Segment, b.CustomerID
)

SELECT
  Year,
  Segment,
  COUNTIF(purchases >= 2) AS repeat_customers,
  COUNT(*)                AS total_customers,
  ROUND(SAFE_DIVIDE(COUNTIF(purchases >= 2) * 100.0, COUNT(*)), 2) AS repeat_purchase_rate_pct
FROM customer_orders
GROUP BY Year, Segment
ORDER BY Year, Segment;
