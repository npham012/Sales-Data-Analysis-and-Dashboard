-- =====================================================================
-- YEAR-OVER-YEAR CUSTOMER RETENTION, 2010 -> 2011 (from cleaned_sales)
-- Retained  = bought in both years
-- Lapsed    = bought in 2010, not in 2011 (note: 2011 data stops on 9 Dec)
-- New       = bought in 2011, not in 2010
-- =====================================================================
WITH y10 AS (
  SELECT CustomerID, SUM(Sales) AS s10
  FROM `online_retail_2_dataset.cleaned_sales`
  WHERE EXTRACT(YEAR FROM InvoiceDate) = 2010
  GROUP BY CustomerID
),

y11 AS (
  SELECT CustomerID, SUM(Sales) AS s11
  FROM `online_retail_2_dataset.cleaned_sales`
  WHERE EXTRACT(YEAR FROM InvoiceDate) = 2011
  GROUP BY CustomerID
),

joined AS (
  SELECT CustomerID, s10, s11
  FROM y10
  FULL OUTER JOIN y11 USING (CustomerID)
)

SELECT
  COUNTIF(s10 IS NOT NULL)                                   AS customers_2010,
  COUNTIF(s10 IS NOT NULL AND s11 IS NOT NULL)               AS retained_customers,
  ROUND(SAFE_DIVIDE(COUNTIF(s10 IS NOT NULL AND s11 IS NOT NULL) * 100.0,
                    COUNTIF(s10 IS NOT NULL)), 1)            AS retention_rate_pct,
  COUNTIF(s10 IS NOT NULL AND s11 IS NULL)                   AS lapsed_customers,
  COUNTIF(s10 IS NULL)                                       AS new_customers_2011,
  COUNTIF(s11 IS NOT NULL)                                   AS customers_2011,
  ROUND(SUM(IF(s11 IS NULL, s10, 0)), 2)                     AS lapsed_2010_sales,
  ROUND(SUM(IF(s10 IS NULL, s11, 0)), 2)                     AS new_customer_2011_sales,
  ROUND(SUM(IF(s10 IS NOT NULL, s11, 0)), 2)                 AS retained_customer_2011_sales,
  ROUND(SUM(s10), 2)                                         AS total_2010_sales,
  ROUND(SUM(s11), 2)                                         AS total_2011_sales
FROM joined;
