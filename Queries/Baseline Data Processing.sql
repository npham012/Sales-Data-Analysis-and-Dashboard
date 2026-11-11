/*
This query:
  - Drops the existing table for benchmarking and because a new table needs to be created for partitioning and clustering in BigQuery.
  - Combines data from two Excel sheets (saved as CSV files and loaded into BigQuery as separate tables) using UNION ALL.
  - Defines the result as a Common Table Expression (CTE) for further processing.
  - Removes currency and converts Price into a numerical column, UnitPrice.
  - Calculates total Sales per row (Unit_Price × Quantity).
  - Removes duplicates using SELECT DISTINCT.
  - Creates an InvoiceDate_UTC column.
  - Removes UTC suffix from all invoice dates and renames column to InvoiceTimeStamp_UTC.
  - Removes rows with non-positive Quantities, nulls, invalid Countries, and canceled orders (where Invoice starts with 'C').
  - Creates a new table that contains the resulting dataset.
  - Updates instances of 'Korea' in the Country column to 'South Korea' per the assumption that orders in 'Korea' are not from 'North Korea'.
  - Processes 92.97 MB of data.
*/

DROP TABLE IF EXISTS `online_retail_2_dataset.cleaned_retail_2`;
CREATE OR REPLACE TABLE
  `online_retail_2_dataset.cleaned_retail_2`
AS
WITH
  retail_union AS (
  SELECT
    *
  FROM
    `online_retail_2_dataset.sheet1`
  UNION DISTINCT
  SELECT
    *
  FROM
    `online_retail_2_dataset.sheet2`)

SELECT
  DISTINCT Invoice,
  StockCode,
  `Customer ID`,
  Description,
  Quantity,
  DATE(InvoiceDate) AS InvoiceDate_UTC,
  FORMAT_TIMESTAMP('%F %T', InvoiceDate) AS InvoiceTimeStamp_UTC,
  UnitPrice,
  Sales,
  Country
FROM (
  SELECT
    *,
    ROUND(SAFE_CAST(REGEXP_REPLACE(Price, r'^GBP\s*', '') AS FLOAT64), 2) AS UnitPrice,
    ROUND(SAFE_CAST(REGEXP_REPLACE(Price, r'^GBP\s*', '') AS FLOAT64) * Quantity, 2) AS Sales
  FROM
    retail_union )
WHERE
  Quantity > 0
  AND `Customer ID` IS NOT NULL
  AND Description IS NOT NULL
  AND Invoice NOT LIKE "C%"
  AND Country NOT IN ('Unspecified', 'European Community', 'West Indies');

UPDATE 
  `online_retail_2_dataset.cleaned_retail_2`
SET Country = 'South Korea'
WHERE Country = 'Korea';