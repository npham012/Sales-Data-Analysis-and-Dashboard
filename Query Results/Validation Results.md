-- =====================================================================
-- DATA VALIDATION (BigQuery)
-- Run after 3_Layer_Data_Processing_Script.sql. Sections 1-6 profile the raw data;
-- 7 checks duplicates; 8-11 check countries, products and outliers; 12-13 reconcile to cleaned_sales.
-- =====================================================================

-- 1) Cancelled invoices (Invoice starts with 'C')              
canceled_lines
19104

-- 2) Negative quantities (returns)                            
negative_quantity_lines
22496

-- 3) Negative prices                                       
negative_price_lines
5

-- 4) Zero-price lines (giveaways)                             
zero_price_lines
6032

-- 5) Null descriptions, and what they are                     
null_description_lines	of_which_negative_quantity	of_which_zero_price
4275	2633	4275

-- 6) Missing Customer IDs                 
total_lines	null_customer_id_lines	pct_of_lines
1033036	235151	22.8

-- 7) Duplicates (the pipeline combines the sheets with UNION DISTINCT, so checks on the
--    combined table can never find duplicates. These checks look at the SOURCE sheets.)
-- 7a) Rows identical in both sheets (the overlap that UNION DISTINCT collapses)
distinct_rows_in_both_sheets
22202

-- 7b) Exact duplicate rows WITHIN each sheet. UNION DISTINCT also collapses these, so
--     this is the number to look at: if it is 0 (or tiny) the choice costs nothing;
--     if it is large, repeated lines on one invoice are being merged into one.
sheet	extra_copies	duplicated_row_groups
sheet1	6865	6418
sheet2	5268	4879

-- 7c) Total rows removed by UNION DISTINCT (overlap + within-sheet duplicates)
rows_removed_by_union_distinct
34335

-- 7d) Date range per sheet (shows the overlap window)
sheet	first_date	last_date	line_count
sheet1	2009-12-01	2010-12-09	525461
sheet2	2010-12-01	2011-12-09	541910

-- 7e) Layer 2 must not add or remove rows: both counts should be equal
raw_rows	cleaned_invoice_rows
1033036	1033036

-- 8) Countries
-- 8a) Null / blank country 
null_or_blank_country
0

-- 8b) Lines by country (look for 'Unspecified' and spelling variants)
Country	lines
United Kingdom	948321
EIRE	17667
Germany	17339
France	14025
Netherlands	5137
Spain	3754
Switzerland	3175
Belgium	3110
Portugal	2528
Australia	1890
Channel Islands	1646
Italy	1507
Sweden	1362
Norway	1308
Cyprus	1157
Finland	1049
Austria	938
Denmark	797
Unspecified	752
Greece	663
Japan	565
USA	535
Poland	527
United Arab Emirates	500
Israel	368
Hong Kong	360
Singapore	346
Malta	299
Canada	228
Iceland	222
RSA	169
Lithuania	154
Bahrain	126
Brazil	94
Thailand	76
Korea	63
European Community	61
Lebanon	58
West Indies	54
Bermuda	34
Nigeria	32
Czech Republic	30
Saudi Arabia	10

-- 9) Product data quality
-- 9a) Non-merchandise stock codes (Manual, Postage, Carriage, adjustments, ...)
StockCode	Description	lines	sales
POST	Postage	1748	112541.26
M	Manual	576	67807.79
C2	Carriage	238	12046
DOT	Dotcom Postage	16	11906.36
ADJUST	Adjustment By John On 26/01/2010 16	31	3533.95
ADJUST2	Adjustment By Peter On Jun 25 2010	3	731.05
BANK CHARGES	Bank Charges	28	420
D	Discount	4	205.89
TEST001	This Is A Test Product.	5	112.5
SP1002	Kid's Chalkboard/Easel	2	14.75

-- 9b) Stock codes with more than one description in the RAW data (fixed by the canonical-name step)
stock_codes_with_multiple_descriptions
1188

-- 9c) Every StockCode in cleaned_sales should have exactly one description (expect 0 rows)
There is no data to display

-- 10) Outlier orders and cancellations
-- 10a) Largest single order lines
Invoice	CustomerID	StockCode	Description	Quantity	UnitPrice	Sales	InvoiceDate
581483	16446	23843	"Paper Craft , Little Birdie"	80995	2.08	168469.6	2011-12-09
541431	12346	23166	Medium Ceramic Top Storage Jar	74215	1.04	77183.6	2011-01-18
556444	15098	22502	Picnic Basket Wicker Small	60	649.5	38970	2011-06-10
512771		M	Manual	1	25111.09	25111.09	2010-06-17
530715	15838	84347	Rotating Silver Angels T-Light Hldr	9360	1.69	15818.4	2010-11-04
537632		AMAZONFEE	Amazon Fee	1	13541.33	13541.33	2010-12-07
A563185		B	Adjust Bad Debt	1	11062.06	11062.06	2011-08-12
502265		M	Manual	1	10953.5	10953.5	2010-03-23
502263	12918	M	Manual	1	10953.5	10953.5	2010-03-23
525399		M	Manual	1	10468.8	10468.8	2010-10-05

-- 10b) Were invoices 581483 and 541431 reversed? (cancellation lines for the same customers)
Invoice	CustomerID	StockCode	Quantity	Price	InvoiceDate
541431	12346	23166	74215	1.04	2011-01-18
C541433	12346	23166	-74215	1.04	2011-01-18
581483	16446	23843	80995	2.08	2011-12-09
C581484	16446	23843	-80995	2.08	2011-12-09

-- 11) Impact of the cancellation-matching rule (orders cancelled in full within 30 days)
--     Run with exclude_reversed_orders = FALSE in the pipeline to see the flagged rows,
--     or compare against the figures below.
-- (If the pipeline was run with exclude_reversed_orders = TRUE this returns 0 reversed lines.)
reversed_order_lines	reversed_sales	total_sales_in_table
0	0	16137511.78

-- 12) Reconciliation: raw rows -> cleaned_sales rows
-- Any remaining gap between the sum of the exclusions and cleaned_sales_rows is the
-- reversed-order rule (rows excluded because they were cancelled in full).
cleaned_invoice_rows	cancellation_lines	non_positive_qty_not_cancelled	zero_or_negative_price	missing_customer_id	unspecified_country	before_2010	cleaned_sales_rows
1033036	19104	3393	2644	228488	518	30272	744786

-- 13) Headline KPIs from cleaned_sales.
--     Previous pipeline: sales 16,682,692.89 | orders 35,441 | customers 5,783 | items 10,110,161
--     Expect small differences now (cross-sheet de-duplication, reversed orders).
sales	orders	customers	items_sold	avg_order_value
16137511.78	35188	5762	9843273	458.61