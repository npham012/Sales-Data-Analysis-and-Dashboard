/*
This query:
- Converts Price to a numerical data type
- Computes Sales by taking the product of Price and Quantity
- Processes 69.22 MB of data
*/

CREATE OR REPLACE TABLE
  `online_retail_2_dataset.retail2` AS
SELECT
  *,
  ROUND(UnitPrice * Quantity, 2) AS Sales
FROM (
  SELECT
    *,
    ROUND(SAFE_CAST(REGEXP_REPLACE(Price, r'^GBP\s*', '') AS FLOAT64), 2) AS UnitPrice
  FROM
    `online_retail_2_dataset.retail2`);