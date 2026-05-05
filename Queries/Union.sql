/*
This query:
- Combines the 2 sheets from the Excel file (uploaded to the cloud as 2 different data tables) using UNION DISTINCT (since there are some duplicates).
- Processes 92.97 MB of data
The resulting dataset was then saved as a table, retail2
*/

CREATE OR REPLACE TABLE
  `online_retail_2_dataset.retail2` AS
SELECT
  *
FROM
  `online_retail_2_dataset.sheet1`
UNION DISTINCT
SELECT
  *
FROM
  `online_retail_2_dataset.sheet2`