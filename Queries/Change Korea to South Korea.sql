/* This update:
  - changes Korea to South Korea in the data table per the assumption that orders are not from North Korea
  - Processes 90.7 MB of data
*/
UPDATE `online_retail_2_dataset.retail2`
SET Country = 'South Korea'
WHERE Country = 'Korea';