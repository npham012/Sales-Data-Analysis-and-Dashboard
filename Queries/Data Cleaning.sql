/*
This query:
- Removes duplicates using SELECT DISTINCT
- Removes UTC suffix from all InvoiceDate values
- Converts InvoiceDates to Dates and DateTimes in MST, my current local timezone (for Tableau ingestion).
- Filters out canceled orders (where Invoice starts with 'C'), nulls, and rows with non-positive quantities
- Orders data by InvoiceDate
- Processes 89.96 MB of data.
The resulting data was then used to replace retail2
*/

SELECT
  DISTINCT Invoice,
  StockCode,
  Description,
  Quantity,
  DATE(InvoiceDate) AS InvoiceDate_UTC,
  FORMAT_TIMESTAMP('%F %T', InvoiceDate) AS InvoiceTimeStamp_UTC,
  Price,
  `Customer ID`,
  Country
FROM
  `online_retail_2_dataset.retail2`
WHERE
  Quantity > 0
  AND `Customer ID` IS NOT NULL
  AND Description IS NOT NULL
  AND Invoice NOT LIKE "C%"
  AND Country NOT IN ('Unspecified', 'European Community', 'West Indies');