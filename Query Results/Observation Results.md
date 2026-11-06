-- =====================================================================
-- OBSERVATION QUERIES (BigQuery)
--
--   Market   : 'Domestic' = United Kingdom, 'International' = every other country
--   Period   : 'All years', 2010 or 2011
--   Product views use merchandise only (IsMerchandise) and rank by StockCode.
--
-- Run the sections you need; each is self-contained.
--   1  Monthly sales and MoM % by market
--   2  Monthly sales summary (range / average) by market
--   3  KPIs by market and year
--   4  Top 5 products by sales, units and orders
--   5  International countries: top 5 by sales, orders and AOV
--   6  Year-over-year, Jan-Nov (like-for-like)
--   7  December 1-9 like-for-like
--   8  Customer concentration
--   9  Concentration inside each country
--  10  Order and customer profile
--  11  Seasonality
--  12  Non-merchandise lines still in cleaned_sales
-- Repeat purchase rate  -> Repeat_Purchase_Rate.sql
-- Customer retention    -> Customer_Retention.sql
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1) MONTHLY SALES AND MONTH-OVER-MONTH % CHANGE, by market and in total
--    (replaces the "MoM Sales" crosstabs; Jan 2010 has no MoM, Dec 2011 is Dec 1-9 only)
-- ---------------------------------------------------------------------
Month	Market	Sales	mom_pct_change
2010-01-01	Domestic	403219.39	
2010-02-01	Domestic	406219.78	0.744
2010-03-01	Domestic	572365.17	40.9
2010-04-01	Domestic	494216.7	-13.654
2010-05-01	Domestic	485004.06	-1.864
2010-06-01	Domestic	527568.58	8.776
2010-07-01	Domestic	492911.08	-6.569
2010-08-01	Domestic	501292.29	1.7
2010-09-01	Domestic	674711.15	34.594
2010-10-01	Domestic	860210.95	27.493
2010-11-01	Domestic	950806.06	10.532
2010-12-01	Domestic	492409.92	-48.211
2011-01-01	Domestic	359275.97	-27.037
2011-02-01	Domestic	353543.06	-1.596
2011-03-01	Domestic	461106.94	30.425
2011-04-01	Domestic	406164.31	-11.915
2011-05-01	Domestic	537494.8	32.334
2011-06-01	Domestic	519496	-3.349
2011-07-01	Domestic	479686.21	-7.663
2011-08-01	Domestic	494550.86	3.099
2011-09-01	Domestic	786796.65	59.093
2011-10-01	Domestic	799077.41	1.561
2011-11-01	Domestic	966458.96	20.947
2011-12-01	Domestic	302593.67	-68.69
2010-01-01	International	134397.7	
2010-02-01	International	88491.73	-34.157
2010-03-01	International	94410.53	6.689
2010-04-01	International	88667.15	-6.083
2010-05-01	International	94542.41	6.626
2010-06-01	International	97080.19	2.684
2010-07-01	International	82516.82	-15.001
2010-08-01	International	93263.1	13.023
2010-09-01	International	140022.58	50.137
2010-10-01	International	147263.06	5.171
2010-11-01	International	187576.87	27.375
2010-12-01	International	73145.88	-61.005
2011-01-01	International	126991.73	73.614
2011-02-01	International	90953.28	-28.379
2011-03-01	International	125551.97	38.04
2011-04-01	International	51515.38	-58.969
2011-05-01	International	122094.97	137.007
2011-06-01	International	135818.4	11.24
2011-07-01	International	109173.23	-19.618
2011-08-01	International	146035.63	33.765
2011-09-01	International	154941.76	6.099
2011-10-01	International	201715.37	30.188
2011-11-01	International	178605.41	-11.457
2011-12-01	International	45556.66	-74.493
2010-01-01	Total	537617.09	
2010-02-01	Total	494711.51	-7.981
2010-03-01	Total	666775.7	34.781
2010-04-01	Total	582883.85	-12.582
2010-05-01	Total	579546.47	-0.573
2010-06-01	Total	624648.77	7.782
2010-07-01	Total	575427.9	-7.88
2010-08-01	Total	594555.39	3.324
2010-09-01	Total	814733.73	37.032
2010-10-01	Total	1007474.01	23.657
2010-11-01	Total	1138382.93	12.994
2010-12-01	Total	565555.8	-50.319
2011-01-01	Total	486267.7	-14.02
2011-02-01	Total	444496.34	-8.59
2011-03-01	Total	586658.91	31.983
2011-04-01	Total	457679.69	-21.985
2011-05-01	Total	659589.77	44.116
2011-06-01	Total	655314.4	-0.648
2011-07-01	Total	588859.44	-10.141
2011-08-01	Total	640586.49	8.784
2011-09-01	Total	941738.41	47.012
2011-10-01	Total	1000792.78	6.271
2011-11-01	Total	1145064.37	14.416
2011-12-01	Total	348150.33	-69.596


-- ---------------------------------------------------------------------
-- 2) MONTHLY SALES SUMMARY by market (min, max, average)
--    Excludes the partial month (Dec 2011). Add or remove months to match the
--    "excluding peak months" averages quoted in the analysis.
-- ---------------------------------------------------------------------
Market	lowest_month	lowest_month_is	highest_month	highest_month_is	average_month	average_jan_to_aug
International	51515	2011-04-01	201715	2011-10-01	120208	105094
Domestic	353543	2011-02-01	966459	2011-11-01	566286	468382


-- ---------------------------------------------------------------------
-- 3) KPIs by market and year (Sales, Orders, Customers, Items sold, AOV)
-- ---------------------------------------------------------------------
Period	Market	Sales	Orders	Customers	Items_Sold	Avg_Order_Value
2010	All markets	8182313.15	18159	4208	5199413	450.59
2010	Domestic	6860935.13	16644	3871	4139909	412.22
2010	International	1321378.02	1515	338	1059504	872.2
2011	All markets	7955198.63	17029	4203	4643860	467.16
2011	Domestic	6466244.84	15288	3804	3785673	422.96
2011	International	1488953.79	1741	399	858187	855.23
All years	All markets	16137511.78	35188	5762	9843273	458.61
All years	Domestic	13327179.97	31932	5249	7925582	417.36
All years	International	2810331.81	3256	514	1917691	863.12

-- ---------------------------------------------------------------------
-- 4) TOP 5 PRODUCTS by sales, units and number of orders containing the item
--    Merchandise only, ranked by StockCode (one canonical description each).
--    Each ranking is returned for every Period x Market combination.
--    Sales column as rounded sum of Sales to 2nd decimal
--    Units as sum of Quantity
--    Orders as Count Distinct of Invoice
-- ---------------------------------------------------------------------
ranking	Period	Market	rnk	StockCode	Description	Sales	Units	Orders
Top by orders	2010	All markets	1	85123A	White Hanging Heart T-Light Holder	138638.9	51994	2833
Top by orders	2010	All markets	2	22423	Regency Cakestand 3 Tier	150975.45	13127	1727
Top by orders	2010	All markets	3	85099B	Jumbo Bag Red Retrospot	79937.85	45663	1623
Top by orders	2010	All markets	4	21212	Pack Of 72 Retrospot Cake Cases	26260.61	54782	1436
Top by orders	2010	All markets	5	20725	Lunch Bag Red Retrospot	30560.3	19534	1268
Top by orders	2010	Domestic	1	85123A	White Hanging Heart T-Light Holder	126172.35	47217	2739
Top by orders	2010	Domestic	2	22423	Regency Cakestand 3 Tier	129082.95	11201	1548
Top by orders	2010	Domestic	3	85099B	Jumbo Bag Red Retrospot	71437.5	40770	1502
Top by orders	2010	Domestic	4	21212	Pack Of 72 Retrospot Cake Cases	20170.86	42141	1227
Top by orders	2010	Domestic	5	84879	Assorted Colour Bird Ornament	58906.78	37126	1197
Top by orders	2010	International	1	22326	Round Snack Boxes Set Of4 Woodland	13953.4	5140	223
Top by orders	2010	International	2	21212	Pack Of 72 Retrospot Cake Cases	6089.75	12641	209
Top by orders	2010	International	3	21731	Red Toadstool Led Night Light	11813.7	7666	193
Top by orders	2010	International	4	22423	Regency Cakestand 3 Tier	21892.5	1926	179
Top by orders	2010	International	5	20719	Woodland Charlotte Bag	3846.3	4938	164
Top by orders	2011	All markets	1	85123A	White Hanging Heart T-Light Holder	90833.3	33114	1773
Top by orders	2011	All markets	2	22423	Regency Cakestand 3 Tier	122857.6	10661	1546
Top by orders	2011	All markets	3	85099B	Jumbo Bag Red Retrospot	80982.86	43771	1513
Top by orders	2011	All markets	4	47566	Party Bunting	67438.13	14961	1351
Top by orders	2011	All markets	5	84879	Assorted Colour Bird Ornament	52701.29	32969	1279
Top by orders	2011	Domestic	1	85123A	White Hanging Heart T-Light Holder	85572.15	31157	1691
Top by orders	2011	Domestic	2	85099B	Jumbo Bag Red Retrospot	73332.03	39672	1369
Top by orders	2011	Domestic	3	22423	Regency Cakestand 3 Tier	93963.1	8135	1276
Top by orders	2011	Domestic	4	47566	Party Bunting	61828.73	13689	1266
Top by orders	2011	Domestic	5	84879	Assorted Colour Bird Ornament	48838.04	30524	1211
Top by orders	2011	International	1	22326	Round Snack Boxes Set Of4 Woodland	16939.75	6289	283
Top by orders	2011	International	2	22423	Regency Cakestand 3 Tier	28894.5	2526	270
Top by orders	2011	International	3	22554	Plasters In Tin Woodland Animals	7652.7	4894	199
Top by orders	2011	International	4	22629	Spaceboy Lunch Box	14070.45	8151	193
Top by orders	2011	International	5	22556	Plasters In Tin Circus Parade	6003.3	3778	188
Top by orders	All years	All markets	1	85123A	White Hanging Heart T-Light Holder	229472.2	85108	4606
Top by orders	All years	All markets	2	22423	Regency Cakestand 3 Tier	273833.05	23788	3273
Top by orders	All years	All markets	3	85099B	Jumbo Bag Red Retrospot	160920.71	89434	3136
Top by orders	All years	All markets	4	84879	Assorted Colour Bird Ornament	116398.85	73157	2546
Top by orders	All years	All markets	5	20725	Lunch Bag Red Retrospot	57371.9	36462	2500
Top by orders	All years	Domestic	1	85123A	White Hanging Heart T-Light Holder	211744.5	78374	4430
Top by orders	All years	Domestic	2	85099B	Jumbo Bag Red Retrospot	144769.53	80442	2871
Top by orders	All years	Domestic	3	22423	Regency Cakestand 3 Tier	223046.05	19336	2824
Top by orders	All years	Domestic	4	84879	Assorted Colour Bird Ornament	107744.82	67650	2408
Top by orders	All years	Domestic	5	20725	Lunch Bag Red Retrospot	45396.15	28707	2214
Top by orders	All years	International	1	22326	Round Snack Boxes Set Of4 Woodland	30893.15	11429	506
Top by orders	All years	International	2	22423	Regency Cakestand 3 Tier	50787	4452	449
Top by orders	All years	International	3	21212	Pack Of 72 Retrospot Cake Cases	11040.43	22981	380
Top by orders	All years	International	4	21731	Red Toadstool Led Night Light	21214.65	13765	363
Top by orders	All years	International	5	22554	Plasters In Tin Woodland Animals	13284.3	8470	346
Top by sales	2010	All markets	1	22423	Regency Cakestand 3 Tier	150975.45	13127	1727
Top by sales	2010	All markets	2	85123A	White Hanging Heart T-Light Holder	138638.9	51994	2833
Top by sales	2010	All markets	3	85099B	Jumbo Bag Red Retrospot	79937.85	45663	1623
Top by sales	2010	All markets	4	84879	Assorted Colour Bird Ornament	63697.56	40188	1267
Top by sales	2010	All markets	5	48138	Doormat Union Flag	42098.11	6465	1039
Top by sales	2010	Domestic	1	22423	Regency Cakestand 3 Tier	129082.95	11201	1548
Top by sales	2010	Domestic	2	85123A	White Hanging Heart T-Light Holder	126172.35	47217	2739
Top by sales	2010	Domestic	3	85099B	Jumbo Bag Red Retrospot	71437.5	40770	1502
Top by sales	2010	Domestic	4	84879	Assorted Colour Bird Ornament	58906.78	37126	1197
Top by sales	2010	Domestic	5	48138	Doormat Union Flag	40012.45	6159	999
Top by sales	2010	International	1	22423	Regency Cakestand 3 Tier	21892.5	1926	179
Top by sales	2010	International	2	22326	Round Snack Boxes Set Of4 Woodland	13953.4	5140	223
Top by sales	2010	International	3	85123A	White Hanging Heart T-Light Holder	12466.55	4777	94
Top by sales	2010	International	4	22328	Round Snack Boxes Set Of 4 Fruits	12326	4664	149
Top by sales	2010	International	5	21731	Red Toadstool Led Night Light	11813.7	7666	193
Top by sales	2011	All markets	1	22423	Regency Cakestand 3 Tier	122857.6	10661	1546
Top by sales	2011	All markets	2	85123A	White Hanging Heart T-Light Holder	90833.3	33114	1773
Top by sales	2011	All markets	3	85099B	Jumbo Bag Red Retrospot	80982.86	43771	1513
Top by sales	2011	All markets	4	47566	Party Bunting	67438.13	14961	1351
Top by sales	2011	All markets	5	84879	Assorted Colour Bird Ornament	52701.29	32969	1279
Top by sales	2011	Domestic	1	22423	Regency Cakestand 3 Tier	93963.1	8135	1276
Top by sales	2011	Domestic	2	85123A	White Hanging Heart T-Light Holder	85572.15	31157	1691
Top by sales	2011	Domestic	3	85099B	Jumbo Bag Red Retrospot	73332.03	39672	1369
Top by sales	2011	Domestic	4	47566	Party Bunting	61828.73	13689	1266
Top by sales	2011	Domestic	5	84879	Assorted Colour Bird Ornament	48838.04	30524	1211
Top by sales	2011	International	1	22423	Regency Cakestand 3 Tier	28894.5	2526	270
Top by sales	2011	International	2	23084	Rabbit Night Light	28782.08	15437	157
Top by sales	2011	International	3	22326	Round Snack Boxes Set Of4 Woodland	16939.75	6289	283
Top by sales	2011	International	4	22629	Spaceboy Lunch Box	14070.45	8151	193
Top by sales	2011	International	5	22630	Dolly Girl Lunch Box	12484.2	7308	146
Top by sales	All years	All markets	1	22423	Regency Cakestand 3 Tier	273833.05	23788	3273
Top by sales	All years	All markets	2	85123A	White Hanging Heart T-Light Holder	229472.2	85108	4606
Top by sales	All years	All markets	3	85099B	Jumbo Bag Red Retrospot	160920.71	89434	3136
Top by sales	All years	All markets	4	84879	Assorted Colour Bird Ornament	116398.85	73157	2546
Top by sales	All years	All markets	5	47566	Party Bunting	102204.33	23219	2050
Top by sales	All years	Domestic	1	22423	Regency Cakestand 3 Tier	223046.05	19336	2824
Top by sales	All years	Domestic	2	85123A	White Hanging Heart T-Light Holder	211744.5	78374	4430
Top by sales	All years	Domestic	3	85099B	Jumbo Bag Red Retrospot	144769.53	80442	2871
Top by sales	All years	Domestic	4	84879	Assorted Colour Bird Ornament	107744.82	67650	2408
Top by sales	All years	Domestic	5	47566	Party Bunting	93469.23	21197	1915
Top by sales	All years	International	1	22423	Regency Cakestand 3 Tier	50787	4452	449
Top by sales	All years	International	2	22326	Round Snack Boxes Set Of4 Woodland	30893.15	11429	506
Top by sales	All years	International	3	23084	Rabbit Night Light	28782.08	15437	157
Top by sales	All years	International	4	21731	Red Toadstool Led Night Light	21214.65	13765	363
Top by sales	All years	International	5	22629	Spaceboy Lunch Box	20867.4	12012	313
Top by units	2010	All markets	1	21212	Pack Of 72 Retrospot Cake Cases	26260.61	54782	1436
Top by units	2010	All markets	2	84077	World War 2 Gliders Asstd Designs	11099.42	53110	440
Top by units	2010	All markets	3	85123A	White Hanging Heart T-Light Holder	138638.9	51994	2833
Top by units	2010	All markets	4	17003	Brocade Ring Purse	8549.67	46747	172
Top by units	2010	All markets	5	85099B	Jumbo Bag Red Retrospot	79937.85	45663	1623
Top by units	2010	Domestic	1	84077	World War 2 Gliders Asstd Designs	10228.7	49366	413
Top by units	2010	Domestic	2	85123A	White Hanging Heart T-Light Holder	126172.35	47217	2739
Top by units	2010	Domestic	3	17003	Brocade Ring Purse	8525.31	46631	168
Top by units	2010	Domestic	4	21212	Pack Of 72 Retrospot Cake Cases	20170.86	42141	1227
Top by units	2010	Domestic	5	85099B	Jumbo Bag Red Retrospot	71437.5	40770	1502
Top by units	2010	International	1	37410	Black And White Paisley Flower Mug	2516.4	25164	2
Top by units	2010	International	2	21091	Set/6 Woodland Paper Plates	1694.76	13524	15
Top by units	2010	International	3	21085	Set/6 Woodland Paper Cups	1658.52	13428	16
Top by units	2010	International	4	21099	Set/6 Strawberry Paper Cups	1327.2	13008	4
Top by units	2010	International	5	21212	Pack Of 72 Retrospot Cake Cases	6089.75	12641	209
Top by units	2011	All markets	1	84077	World War 2 Gliders Asstd Designs	12366.18	49036	441
Top by units	2011	All markets	2	22197	Small Popcorn Holder	35409.41	46841	957
Top by units	2011	All markets	3	85099B	Jumbo Bag Red Retrospot	80982.86	43771	1513
Top by units	2011	All markets	4	85123A	White Hanging Heart T-Light Holder	90833.3	33114	1773
Top by units	2011	All markets	5	84879	Assorted Colour Bird Ornament	52701.29	32969	1279
Top by units	2011	Domestic	1	84077	World War 2 Gliders Asstd Designs	11098.69	44427	395
Top by units	2011	Domestic	2	22197	Small Popcorn Holder	32836.46	43554	870
Top by units	2011	Domestic	3	85099B	Jumbo Bag Red Retrospot	73332.03	39672	1369
Top by units	2011	Domestic	4	85123A	White Hanging Heart T-Light Holder	85572.15	31157	1691
Top by units	2011	Domestic	5	84879	Assorted Colour Bird Ornament	48838.04	30524	1211
Top by units	2011	International	1	23084	Rabbit Night Light	28782.08	15437	157
Top by units	2011	International	2	22492	Mini Paint Set Vintage	7414.85	12205	97
Top by units	2011	International	3	21212	Pack Of 72 Retrospot Cake Cases	4950.68	10340	171
Top by units	2011	International	4	22629	Spaceboy Lunch Box	14070.45	8151	193
Top by units	2011	International	5	22630	Dolly Girl Lunch Box	12484.2	7308	146
Top by units	All years	All markets	1	84077	World War 2 Gliders Asstd Designs	23465.6	102146	881
Top by units	All years	All markets	2	85099B	Jumbo Bag Red Retrospot	160920.71	89434	3136
Top by units	All years	All markets	3	85123A	White Hanging Heart T-Light Holder	229472.2	85108	4606
Top by units	All years	All markets	4	21212	Pack Of 72 Retrospot Cake Cases	40960.13	84808	2390
Top by units	All years	All markets	5	22197	Small Popcorn Holder	57002.14	75296	1712
Top by units	All years	Domestic	1	84077	World War 2 Gliders Asstd Designs	21327.39	93793	808
Top by units	All years	Domestic	2	85099B	Jumbo Bag Red Retrospot	144769.53	80442	2871
Top by units	All years	Domestic	3	85123A	White Hanging Heart T-Light Holder	211744.5	78374	4430
Top by units	All years	Domestic	4	22197	Small Popcorn Holder	52396.94	69404	1560
Top by units	All years	Domestic	5	17003	Brocade Ring Purse	14225.37	68223	359
Top by units	All years	International	1	37410	Black And White Paisley Flower Mug	2516.4	25164	2
Top by units	All years	International	2	21212	Pack Of 72 Retrospot Cake Cases	11040.43	22981	380
Top by units	All years	International	3	22492	Mini Paint Set Vintage	11113.85	18073	176
Top by units	All years	International	4	23084	Rabbit Night Light	28782.08	15437	157
Top by units	All years	International	5	21731	Red Toadstool Led Night Light	21214.65	13765	363

-- ---------------------------------------------------------------------
-- 5) INTERNATIONAL COUNTRIES: top 5 by sales, by order count, and by AOV
--    AOV ranking requires at least 30 orders so one-order countries cannot top it.
--    Change min_orders_for_aov to adjust.
-- ---------------------------------------------------------------------
ranking	Period	rnk	Country	Sales	Orders	Customers	Avg_Order_Value
Top by AOV (min orders)	2010	1	Netherlands	260738.22	129	22	2021.23
Top by AOV (min orders)	2010	2	EIRE	329056.2	293	5	1123.06
Top by AOV (min orders)	2010	3	Switzerland	44089.31	40	14	1102.23
Top by AOV (min orders)	2010	4	Australia	30415	37	15	822.03
Top by AOV (min orders)	2010	5	Sweden	54819.91	67	15	818.21
Top by AOV (min orders)	2011	1	Netherlands	276612.06	91	8	3039.69
Top by AOV (min orders)	2011	2	Australia	137107.7	52	9	2636.69
Top by AOV (min orders)	2011	3	Switzerland	54908.58	49	21	1120.58
Top by AOV (min orders)	2011	4	EIRE	250336.46	242	3	1034.45
Top by AOV (min orders)	2011	5	Sweden	34295.53	34	8	1008.69
Top by AOV (min orders)	All years	1	Netherlands	537350.28	220	22	2442.5
Top by AOV (min orders)	All years	2	Australia	167522.7	89	15	1882.28
Top by AOV (min orders)	All years	3	Denmark	63318.13	41	12	1544.34
Top by AOV (min orders)	All years	4	Switzerland	98997.89	89	22	1112.34
Top by AOV (min orders)	All years	5	EIRE	579392.66	535	5	1082.98
Top by orders	2010	1	Germany	199689.71	341	69	585.6
Top by orders	2010	2	EIRE	329056.2	293	5	1123.06
Top by orders	2010	3	France	141068.16	231	47	610.68
Top by orders	2010	4	Netherlands	260738.22	129	22	2021.23
Top by orders	2010	5	Sweden	54819.91	67	15	818.21
Top by orders	2011	1	Germany	210152.95	423	93	496.82
Top by orders	2011	2	France	197069.01	367	84	536.97
Top by orders	2011	3	EIRE	250336.46	242	3	1034.45
Top by orders	2011	4	Belgium	39300.48	93	25	422.59
Top by orders	2011	5	Netherlands	276612.06	91	8	3039.69
Top by orders	All years	1	Germany	409842.66	764	107	536.44
Top by orders	All years	2	France	338137.17	598	95	565.45
Top by orders	All years	3	EIRE	579392.66	535	5	1082.98
Top by orders	All years	4	Netherlands	537350.28	220	22	2442.5
Top by orders	All years	5	Belgium	63305.27	145	29	436.59
Top by sales	2010	1	EIRE	329056.2	293	5	1123.06
Top by sales	2010	2	Netherlands	260738.22	129	22	2021.23
Top by sales	2010	3	Germany	199689.71	341	69	585.6
Top by sales	2010	4	France	141068.16	231	47	610.68
Top by sales	2010	5	Sweden	54819.91	67	15	818.21
Top by sales	2011	1	Netherlands	276612.06	91	8	3039.69
Top by sales	2011	2	EIRE	250336.46	242	3	1034.45
Top by sales	2011	3	Germany	210152.95	423	93	496.82
Top by sales	2011	4	France	197069.01	367	84	536.97
Top by sales	2011	5	Australia	137107.7	52	9	2636.69
Top by sales	All years	1	EIRE	579392.66	535	5	1082.98
Top by sales	All years	2	Netherlands	537350.28	220	22	2442.5
Top by sales	All years	3	Germany	409842.66	764	107	536.44
Top by sales	All years	4	France	338137.17	598	95	565.45
Top by sales	All years	5	Australia	167522.7	89	15	1882.28

-- ---------------------------------------------------------------------
-- 6) YEAR-OVER-YEAR, JAN-NOV (like-for-like; Dec 2011 is incomplete)
--    Sales, orders, customers, items and AOV for 2010 vs 2011, by market.
-- ---------------------------------------------------------------------
Market	sales_2010	sales_2011	sales_yoy_pct	orders_2010	orders_2011	orders_yoy_pct	customers_2010	customers_2011	items_2010	items_2011	items_yoy_pct	aov_2010	aov_2011
All markets	7616757.35	7607048.3	-0.127	16765	16254	-3.05	4129	4158	4890254	4438518	-9.24	454.32	468.01
Domestic	6368525.21	6163651.17	-3.217	15358	14584	-5.04	3804	3765	3874853	3606942	-6.91	414.67	422.63
International	1248232.14	1443397.13	15.635	1407	1670	18.69	326	393	1015401	831576	-18.1	887.16	864.31

-- 6b) International growth by country, Jan-Nov (who drove the +x%?)

Country	sales_2010	sales_2011	change_gbp	change_pct
Australia	29450	137108	107658	365.6
France	131457	189774	58317	44.4
Spain	28464	55729	27266	95.8
Japan	4804	29711	24908	518.5
Norway	5755	28617	22862	397.2
Germany	184526	202169	17642	9.6
Belgium	22195	37883	15688	70.7
Finland	6816	20421	13605	199.6
Netherlands	251954	264884	12930	5.1
Switzerland	42784	54909	12124	28.3
Singapore	4038	9120	5083	125.9
Portugal	19118	23891	4773	25
Poland	2705	7022	4317	159.6
Israel	3199	7216	4016	125.5
Cyprus	7805	11399	3593	46
Iceland	612	3373	2762	451.6
Canada	1217	3666	2450	201.3
Italy	14125	16308	2182	15.5
Lebanon	0	1694	1694	
European Community	0	1300	1300	
Brazil	268	1144	875	326.3
Czech Republic	0	827	827	
Saudi Arabia	0	146	146	
RSA	931	1002	71	7.6
Malta	2687	2706	19	0.7
Nigeria	140	0	-140	-100
Bahrain	806	548	-258	-32
West Indies	536	0	-536	-100
Korea	950	0	-950	-100
Austria	11061	9238	-1822	-16.5
Channel Islands	22209	19586	-2624	-11.8
Thailand	3071	0	-3071	-100
Lithuania	3232	0	-3232	-100
USA	4645	1116	-3530	-76
United Arab Emirates	6766	1902	-4864	-71.9
Greece	13715	4080	-9635	-70.3
Sweden	50986	34058	-16928	-33.2
Denmark	44373	17494	-26879	-60.6
EIRE	320833	243358	-77475	-24.1

-- ---------------------------------------------------------------------
-- 7) DECEMBER 1-9 LIKE-FOR-LIKE (the only December days present in both years)
-- ---------------------------------------------------------------------
Year	sales_dec_1_to_9	orders	largest_single_line
2010	309242.14	773	3828
2011	348150.33	775	3861


-- ---------------------------------------------------------------------
-- 8) CUSTOMER CONCENTRATION: share of sales from top customer tiers
-- ---------------------------------------------------------------------
tier	customers	sales	pct_of_total_sales
Top 10 customers	10	2583239.18	16
Top 1% of customers	58	4992605.91	30.9
Top 5% of customers	288	8214735.64	50.9
Top 10% of customers	576	10151868.91	62.9
Top 20% of customers	1152	12341990.99	76.5

-- 8b) The 10 largest customers

CustomerID	Country	Sales	Orders
18102	United Kingdom	538698.9	136
14646	Netherlands	512693.35	145
14156	EIRE	298843.61	147
14911	EIRE	268836.94	375
17450	United Kingdom	233675.91	49
13694	United Kingdom	171199.08	131
17511	United Kingdom	162870.06	58
12415	Australia	144299.72	27
16684	United Kingdom	140258.97	50
15061	United Kingdom	111862.64	117

-- 8c) International concentration: share of international sales from the top 5 / top 10 customers

top5_pct	top10_pct	international_customers
45.3	50.9	514

-- ---------------------------------------------------------------------
-- 9) CONCENTRATION INSIDE EACH COUNTRY: how much does the biggest customer
--    (or the biggest two) drive a country's sales? Read this before comparing
--    country AOVs.
-- ---------------------------------------------------------------------
Country	sales	customers	top_customer_pct	top2_customers_pct
United Kingdom	13327180	5249	4	5.8
EIRE	579393	5	51.6	98
Netherlands	537350	22	95.4	96.3
Germany	409843	107	8.9	15.9
France	338137	95	10.1	18.7
Australia	167523	15	86.1	90.7
Switzerland	98998	22	23.4	41.9
Sweden	89115	18	53.4	78
Spain	86353	41	25.2	43.9
Denmark	63318	12	47.4	67.8
Belgium	63305	29	12.9	22.1
Portugal	48197	23	18.5	33.9
Channel Islands	42357	13	29.3	41.9
Japan	42118	10	50.6	70.8
Norway	40945	11	41	53.4


-- ---------------------------------------------------------------------
-- 10) ORDER AND CUSTOMER PROFILE
-- ---------------------------------------------------------------------
-- 10a) Median vs mean order value

median_order_value	mean_order_value
302.15	458.61

-- 10b) Orders per customer, and share of one-order customers

customers	pct_one_order_customers	median_orders_per_customer
5762	27.7	3


-- ---------------------------------------------------------------------
-- 11) SEASONALITY
-- ---------------------------------------------------------------------
-- 11a) Share of each year's sales in Sep-Nov.
--      sep_nov_pct_of_year is NOT like-for-like for 2011 (the data ends on 9 Dec);
--      use sep_nov_pct_of_jan_nov to compare the two years.

Year	sep_nov_sales	sep_nov_pct_of_year	sep_nov_pct_of_jan_nov
2010	2960591	36.2	38.9
2011	3087596	38.8	40.6

-- 11b) Sales by day of week (are there Saturday sales?)

weekday	pct_of_sales
Thursday	21.9
Tuesday	18.8
Wednesday	17.7
Monday	16.3
Friday	14.8
Sunday	10.5

-- 11c) Last trading date in each December (Dec 2010 ends before Christmas)

Year	first_date	last_date
2010	2010-12-01	2010-12-23
2011	2011-12-01	2011-12-09


-- ---------------------------------------------------------------------
-- 12) NON-MERCHANDISE LINES still present in cleaned_sales (Manual, Postage, ...)
--     They count towards Sales/Orders KPIs but are excluded from product rankings above.
-- ---------------------------------------------------------------------
non_merchandise_sales	pct_of_total_sales
209319.55	1.3