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
Year	Segment	repeat_customers	total_customers	repeat_purchase_rate_pct
2010	Overall	2799	4208	66.52
2010	Domestic	2580	3871	66.65
2010	International	219	338	64.79
2011	Overall	2707	4203	64.41
2011	Domestic	2445	3804	64.27
2011	International	262	399	65.66


-- 2) Excluding customers who bought in BOTH markets in the year
Year	Segment	repeat_customers	total_customers	repeat_purchase_rate_pct
2010	Domestic	2579	3870	66.64
2010	International	219	337	64.99
2011	Domestic	2445	3804	64.27
2011	International	262	399	65.66
