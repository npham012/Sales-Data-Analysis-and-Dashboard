-- =====================================================================
-- 3-LAYER DATA PROCESSING PIPELINE (BigQuery)
--   Layer 1  raw_invoices      the two sheets combined (UNION DISTINCT)
--   Layer 2  cleaned_invoices  typed + standardised + flagged (no business filters)
--   Layer 3  cleaned_sales     rows appropriate for the sales dashboard
--
-- =====================================================================

-- Set to FALSE to reproduce the old behaviour (reversed orders kept in sales).
DECLARE exclude_reversed_orders BOOL DEFAULT TRUE;


-- ---------------------------------------------------------------------
-- LAYER 1: combine the two source sheets. UNION DISTINCT keeps one copy of any
-- row that is identical in both sheets.
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE `online_retail_2_dataset.raw_invoices` AS
SELECT * FROM `online_retail_2_dataset.sheet1`
UNION DISTINCT
SELECT * FROM `online_retail_2_dataset.sheet2`;


-- ---------------------------------------------------------------------
-- LAYER 2: type, standardise and flag. No business filters and no row removal.
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE `online_retail_2_dataset.cleaned_invoices` AS
WITH typed AS (
  SELECT
    CAST(Invoice AS STRING)                              AS Invoice,
    UPPER(TRIM(CAST(StockCode AS STRING)))               AS StockCode,
    NULLIF(TRIM(CAST(`Customer ID` AS STRING)), '')      AS CustomerID,
    -- trim, collapse whitespace, title case
    INITCAP(TRIM(REGEXP_REPLACE(Description, r'\s+', ' '))) AS Description_Cleaned,
    DATE(InvoiceDate)                                    AS InvoiceDate,
    FORMAT_DATETIME('%F %T', DATETIME(InvoiceDate))      AS InvoiceDateTime,
    ROUND(CAST(Price AS NUMERIC), 2)                     AS UnitPrice,
    Quantity,
    TRIM(Country)                                        AS Country
  FROM `online_retail_2_dataset.raw_invoices`
),

canonical AS (
  -- Most frequent cleaned description per StockCode (ties broken alphabetically)
  SELECT StockCode, Description_Cleaned AS Description
  FROM typed
  WHERE Description_Cleaned IS NOT NULL AND Description_Cleaned != ''
  GROUP BY StockCode, Description_Cleaned
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY StockCode
    ORDER BY COUNT(*) DESC, Description_Cleaned
  ) = 1
)

SELECT
  t.Invoice,
  t.StockCode,
  t.CustomerID,
  COALESCE(c.Description, t.Description_Cleaned) AS Description,
  t.InvoiceDate,
  t.InvoiceDateTime,
  t.UnitPrice,
  t.Quantity,
  t.Country,
  ROUND(t.UnitPrice * t.Quantity, 2)                  AS Sales,
  t.UnitPrice = 0                                     AS Giveaway,
  t.UnitPrice < 0                                     AS NegativePrice,
  STARTS_WITH(UPPER(t.Invoice), 'C')                  AS Canceled,
  t.Quantity < 0                                      AS Returned,
  REGEXP_CONTAINS(t.StockCode, r'^\d{5}')             AS IsMerchandise
FROM typed AS t
LEFT JOIN canonical AS c
  ON t.StockCode = c.StockCode;


-- ---------------------------------------------------------------------
-- LAYER 3: rows appropriate for the sales dashboard.
--   * Quantity > 0, UnitPrice > 0, not a cancellation invoice
--   * known customer, known country, 2010 onwards (Dec 2009 excluded)
--   * orders later cancelled in full are excluded (if exclude_reversed_orders)
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE `online_retail_2_dataset.cleaned_sales` AS
WITH sales_lines AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY CustomerID, StockCode, Quantity
      ORDER BY InvoiceDateTime, Invoice
    ) AS pair_no
  FROM `online_retail_2_dataset.cleaned_invoices`
  WHERE Quantity > 0
    AND UnitPrice > 0
    AND NOT Canceled
    AND CustomerID IS NOT NULL
    AND Country != 'Unspecified'
    AND InvoiceDate >= DATE '2010-01-01'
),

cancel_lines AS (
  SELECT
    CustomerID,
    StockCode,
    -Quantity AS Quantity,
    InvoiceDate AS CancelDate,
    ROW_NUMBER() OVER (
      PARTITION BY CustomerID, StockCode, -Quantity
      ORDER BY InvoiceDateTime, Invoice
    ) AS pair_no
  FROM `online_retail_2_dataset.cleaned_invoices`
  WHERE Canceled
    AND Quantity < 0
    AND CustomerID IS NOT NULL
)

SELECT
  s.* EXCEPT (pair_no),
  c.CancelDate IS NOT NULL AS ReversedByCancellation
FROM sales_lines AS s
LEFT JOIN cancel_lines AS c
  ON  s.CustomerID = c.CustomerID
  AND s.StockCode  = c.StockCode
  AND s.Quantity   = c.Quantity
  AND s.pair_no    = c.pair_no
  AND c.CancelDate BETWEEN s.InvoiceDate AND DATE_ADD(s.InvoiceDate, INTERVAL 30 DAY)
WHERE NOT (exclude_reversed_orders AND c.CancelDate IS NOT NULL);
