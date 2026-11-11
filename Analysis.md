# Online Retail Sales Analysis

Full write-up of the analysis behind the [Online Retail Sales Dashboard](https://public.tableau.com/shared/2TMCWW8RW?:display_count=n&:origin=viz_share_link
). For the project overview, pipeline and repo layout, see the [README](README.md). Every figure below comes from a query in this repo; the raw outputs are in [`Query Results`](./Query%20Results/).

**Dataset:** Online Retail II (UK-based giftware retailer, mostly wholesale customers), 4 Jan 2010 – 9 Dec 2011 after cleaning. All amounts are in £ (GBP).

---

## Executive summary

1. **Sales were flat year over year.** On a like-for-like Jan–Nov basis, sales were £7.617M in 2010 and £7.607M in 2011 (-0.13%). Orders fell 3.1% and units fell 9.2%, but average order value rose 3.0%. Customers bought less often and spent more per order.
2. **The Domestic Market, United Kingdom, is the core of the business and is softening.** The UK is 82.6% of sales (£13.33M of £16.14M) and fell 3.2% Jan–Nov. UK customer numbers were about level (-1.0%) but orders fell 5.0%, so the average UK customer placed fewer orders (4.0 → 3.9 in Jan–Nov).
3. **International Sales grew 15.6%, partly on one account.** Orders rose 18.7% and customers 20.6%, so growth was real and fairly broad, led by France (+44%) and Germany (+10%). But Australia, where one customer is 86% of sales, supplied 55% of the £ growth; excluding Australia, international grew about 7%.
4. **International sales depend on a handful of accounts.** One customer is 95% of Netherlands sales, two customers are 98% of EIRE sales, and the top 5 international customers produce 45% of all international sales. EIRE fell 24% and went from 5 active customers in 2010 to 3 in 2011.
5. **Sales are concentrated in a minority of customers.** The top 10% of customers generate 63% of sales and the top 20% generate 77%. 28% of customers placed only one order.
6. **Retention is the main lever.** Only 63% of 2010 customers bought again in 2011. The 37% who did not had spent £1.19M in 2010, 14.6% of that year's sales. New 2011 customers (£1.53M, 19.2% of 2011 sales) more than offset that, but the customers who stayed spent less: £6.42M in 2011 against £6.99M in 2010 (-8%, partly because 2011 lacks 10 December onwards).
7. **The business is highly seasonal.** September–November produce 36% of a full year's sales (39–41% of Jan–Nov), with a step-up every September (+37% MoM in 2010, +47% in 2011).

> **Note:** Dec 2011 contains only 1–9 December and Dec 2010 ends on 23 December. Wherever a 2010 vs 2011 comparison is made, it uses Jan–Nov unless stated otherwise.

---

## Data and Methodology
| Step | Detail |
|---|---|
| Source | Online Retail II, two yearly sheets (Dec 2009 – Dec 2011), loaded to BigQuery as `sheet1` and `sheet2` |
| Cleaning | SQL in BigQuery: [`3_Layer_Data_Processing_Script.sql`](./SQL%20Queries/3_Layer_Data_Processing_Script.sql) (raw → clean invoice → sales layer) |
| Checks | [`Data_Validation.sql`](./SQL%20Queries/Data_Validation.sql) profiles the data and reconciles every excluded row |
| Dashboard | Tableau, fed from the exported `cleaned_sales` table |
| Domestic / International | Domestic = United Kingdom; International = every other country |
| Result | 744,786 line items, 35,188 invoices, 5,762 customers |

### Cleaning Steps

| Step | Lines | Note |
|---|---:|---|
| Source lines (both sheets) | 1,067,371 | 525,461 + 541,910 |
| Duplicates removed (`UNION DISTINCT`) | -34,335 | 22,202 rows in both sheets + 12,133 identical repeat lines inside a sheet |
| Raw layer | 1,033,036 | Deduplicated Union of 2 Sheets |
| Cancellation invoices (`C…`) | -19,104 | |
| Other non-positive quantities | -3,393 | Negative-quantity lines not on a `C` invoice (typically write-offs and adjustments) |
| Zero or negative unit price | -2,644 | Free items, samples, corrections |
| No Customer ID | -228,488 | See scope notes |
| `Unspecified` country | -518 | |
| 2009 | -30,272 |2009 Data is Partial and is Removed for Analysis |
| Orders cancelled in full within 30 days | -3,831 | See [Data Decisions that Move the Numbers](#data-decisions-that-move-the-numbers) |
| **`cleaned_sales`** | **744,786** | |

### KPI Definitions

| KPI | Definition |
|---|---|
| Sales | `UnitPrice × Quantity`, excluding returns, cancellation invoices and orders cancelled in full within 30 days (see [Data Decisions that Move the Numbers](#data-decisions-that-move-the-numbers)) |
| Orders | Distinct invoices |
| Customers | Distinct customer IDs with at least one qualifying line |
| Items sold | Sum of `Quantity` |
| AOV | Sales ÷ Orders |
| Repeat purchase rate | Customers with 2 or more distinct invoices in the period ÷ all customers in the period, within the stated market |

**Important scope notes:**

- 235,151 raw lines (22.8%) have no Customer ID, and 228,488 of those would otherwise qualify as sales. They are excluded from every figure here, so "Sales" means *sales to identified customers*, not total company revenue.
- 2009 data is excluded, so Jan 2010 is the first month and has no MoM change.
- Product rankings use merchandise only (5-digit product codes) and rank by stock code, with one canonical name per code. Postage, manual entries, carriage, adjustments, bank charges, discounts and test items stay in Sales and KPI totals (£209,320, or 1.3% of sales) but not in product rankings.
- There is no cost, margin, marketing or churn data (see [Limitations](#limitations)).

### Data Decisions that Move the Numbers

Three cleaning decisions affect the headline figures, so they are worth being explicit about.

**1. Orders cancelled in full are excluded (-£545k, -3.3% of sales).**
The pipeline matches each cancellation invoice (`C…`) to the original order: same customer, product and quantity, cancelled on or after the order date and within 30 days. Matched orders are removed. This took out 3,831 lines worth £545,181, including two giant single-line orders that had been inflating the data:

| Invoice | Date | Customer | Product | Qty | Sales | Cancelled by |
|---|---|---|---|---:|---:|---|
| 581483 | 2011-12-09 | 16446 | Paper Craft, Little Birdie | 80,995 | £168,470 | C581484, same day |
| 541431 | 2011-01-18 | 12346 | Medium Ceramic Top Storage Jar | 74,215 | £77,184 | C541433, same day |

Those two orders alone were £245,653. Without this step, "Paper Craft, Little Birdie" would rank third by sales on a single order that never completed, and Dec 1–9 2011 would look about 66% up on 2010 instead of 12.6%.

| Headline KPI | Before the rule | After |
|---|---:|---:|
| Sales | £16,682,693 | £16,137,512 |
| Orders | 35,441 | 35,188 |
| Customers | 5,783 | 5,762 |
| Items sold | 10,110,161 | 9,843,273 |
| AOV | £470.72 | £458.61 |

*Caveat.* The other £299,528 of removed sales is a mix of mistaken orders and genuine returns of an entire line. Sales is therefore net of full-line cancellations and returns within 30 days, but gross of partial returns and later ones. A full return rate would need a separate net-sales analysis.

**2. Duplicate rows are collapsed.**
The two source sheets overlap in early December 2010, so 22,202 rows appear in both. `UNION DISTINCT` keeps one copy of each, which is correct. It also collapses 12,133 identical lines *within* a sheet (1.1% of source lines). These are treated as duplicate entries, not as genuine repeated lines on an invoice. That is an assumption: if some were real repeat purchases, sales are slightly understated.

**3. Product names are standardised by stock code.**
1,188 stock codes in the raw data carry more than one description (for example "Retro Spot" vs "Retrospot", or spelling variants). Each code now has a single canonical description (the most frequent), so product rankings no longer split a product's sales across several names.


---

## Headline KPIs
**By Market**
| | Total | Domestic | International |
|---|---:|---:|---:|
| Sales | £16,137,512 | £13,327,180 | £2,810,332 |
| Share of sales | 100% | 82.6% | 17.4% |
| Orders | 35,188 | 31,932 | 3,256 |
| Customers | 5,762 | 5,249 | 514 |
| Items sold | 9,843,273 | 7,925,582 | 1,917,691 |
| Average order value | £458.61 | £417.36 | £863.12 |

One customer bought in both markets, so Domestic + International customers is 5,763 against 5,762 distinct customers overall.

**By year**

| | 2010 | 2011 (to 9 Dec) |
|---|---:|---:|
| Sales | £8,182,313 | £7,955,199 |
| Orders | 18,159 | 17,029 |
| Customers | 4,208 | 4,203 |
| AOV | £450.59 | £467.16 |
| International share of sales | 16.1% | 18.7% |

These full-year totals are **not** like-for-like (2010 runs to 23 Dec, 2011 stops on 9 Dec), so the like-for-like view is below.

![Jan–Nov 2011 vs 2010](<./Figures/yoy_jan_nov.png>)


| Jan–Nov | 2010 | 2011 | Change |
|---|---:|---:|---:|
| Sales | £7,616,757 | £7,607,048 | -0.13% |
| Domestic sales | £6,368,525 | £6,163,651 | -3.22% |
| International sales | £1,248,232 | £1,443,397 | +15.64% |
| Orders | 16,765 | 16,254 | -3.1% |
| Customers | 4,129 | 4,158 | +0.7% |
| Items sold | 4,890,254 | 4,438,518 | -9.2% |
| AOV | £454.32 | £468.01 | +3.0% |

---

| Jan–Nov | Domestic 2010 | Domestic 2011 | International 2010 | International 2011 |
|---|---:|---:|---:|---:|
| Orders | 15,358 | 14,584 (-5.0%) | 1,407 | 1,670 (+18.7%) |
| Customers | 3,804 | 3,765 (-1.0%) | 326 | 393 (+20.6%) |
| Items sold | 3,874,853 | 3,606,942 (-6.9%) | 1,015,401 | 831,576 (-18.1%) |
| AOV | £414.67 | £422.63 (+1.9%) | £887.16 | £864.31 (-2.6%) |

**Interpretation:** The United Kingdom is the weaker half. It kept almost the same number of customers but they placed 5% fewer orders, each slightly larger. International moved the other way: many more customers and orders, with lower average value per order. International units fell even as sales rose, partly because 2010 included some very large low-priced bulk orders (for example 25,164 mugs from two orders). Without cost data, we cannot say whether the shift towards higher-value orders helps profit.

---

## Sales over time

![Monthly sales by market](<./Figures/monthly_sales_by_market.png>)

| Month | Domestic | International | Total | MoM (total) |
|---|---:|---:|---:|---:|
| 2010-01 | 403,219 | 134,398 | 537,617 | — |
| 2010-02 | 406,220 | 88,492 | 494,712 | -8.0% |
| 2010-03 | 572,365 | 94,411 | 666,776 | +34.8% |
| 2010-04 | 494,217 | 88,667 | 582,884 | -12.6% |
| 2010-05 | 485,004 | 94,542 | 579,546 | -0.6% |
| 2010-06 | 527,569 | 97,080 | 624,649 | +7.8% |
| 2010-07 | 492,911 | 82,517 | 575,428 | -7.9% |
| 2010-08 | 501,292 | 93,263 | 594,555 | +3.3% |
| 2010-09 | 674,711 | 140,023 | 814,734 | +37.0% |
| 2010-10 | 860,211 | 147,263 | 1,007,474 | +23.7% |
| 2010-11 | 950,806 | 187,577 | 1,138,383 | +13.0% |
| 2010-12 | 492,410 | 73,146 | 565,556 | -50.3% |
| 2011-01 | 359,276 | 126,992 | 486,268 | -14.0% |
| 2011-02 | 353,543 | 90,953 | 444,496 | -8.6% |
| 2011-03 | 461,107 | 125,552 | 586,659 | +32.0% |
| 2011-04 | 406,164 | 51,515 | 457,680 | -22.0% |
| 2011-05 | 537,495 | 122,095 | 659,590 | +44.1% |
| 2011-06 | 519,496 | 135,818 | 655,314 | -0.6% |
| 2011-07 | 479,686 | 109,173 | 588,859 | -10.1% |
| 2011-08 | 494,551 | 146,036 | 640,586 | +8.8% |
| 2011-09 | 786,797 | 154,942 | 941,738 | +47.0% |
| 2011-10 | 799,077 | 201,715 | 1,000,793 | +6.3% |
| 2011-11 | 966,459 | 178,605 | 1,145,064 | +14.4% |
| 2011-12 | 302,594 | 45,557 | 348,150 | -69.6% |

*£ per month. Dec 2011 covers 1–9 Dec only; Dec 2010 ends 23 Dec.*

**Domestic**
- Jan–Aug 2010 is a flat base of about £468k a month, then sales climb from September.
- 2011 Monthly sales range from £354k (Feb 2011) to £966k (Nov 2011), averaging £566k.
- January and February are the low point of both years (Jan 2010 £403k and Feb 2011 £354k are the lowest months of their years).
- Sales peak in November both years (£951k in 2010, £966k in 2011), then fall sharply in December. That fall is partly structural: Dec 2010 trading ended on 23 December and Dec 2011 stops on the 9th, so it should not be read as demand collapsing.

**International**
- Monthly sales range from £52k (Apr 2011) to £202k (Oct 2011), averaging £120k; Jan–Aug averages about £105k.
- Peaks fall in Nov 2010 (£188k) and Oct 2011 (£202k), about a month earlier in 2011. The lowest months are Dec 2010 (£73k) and Apr 2011.
- Swings are much larger than in the Domestic Market (for example -59.0% in Apr 2011, then +137.0% in May 2011), because a few accounts drive the totals (Section 7).

**Seasonality**
- Sep–Nov generated 36.2% of 2010's full-year sales. Because 2011 stops on 9 Dec, the like-for-like measure is the share of Jan–Nov sales: 38.9% in 2010 and 40.6% in 2011.
- September is the step-up month: total sales rose 37.0% MoM in 2010 and 47.0% in 2011.
- Trading days: there are no Saturday sales in the data, and Thursday is the busiest day (21.9% of sales).

**December like-for-like.** For 1–9 December, sales were £348,150 in 2011 against £309,242 in 2010 (+12.6%). Order counts were almost identical (775 vs 773), so the growth came from larger orders, not more of them.

---

## Customers

| Measure | Value |
|---|---:|
| Median order value | £302 |
| Mean order value (AOV) | £459 |
| Customers with one order only | 27.7% |
| Median orders per customer | 3 |
| Top 1% of customers (58) | 30.9% of sales |
| Top 10% of customers (576) | 62.9% of sales |
| Top 20% of customers (1,152) | 76.5% of sales |
| Top 10 customers | 16.0% of sales |

The gap between the median (£302) and mean (£459) order shows that a minority of large orders pulls the average up. The sales base is more concentrated than the customer count suggests. The largest customers are in the UK (customers 18102, 17450, 13694), the Netherlands (14646, £513k), EIRE (14156 and 14911, £299k and £269k) and Australia (12415).

### Repeat purchase rate

Customers with two or more distinct invoices in the calendar year ([`Repeat_Purchase_Rate.sql`](./SQL%20Queries/Repeat_Purchase_Rate.sql)):

| Segment | 2010 | 2011 | Difference |
|---|---:|---:|---:|
| Overall | 66.52% | 64.41% | -2.11% |
| Domestic | 66.65% | 64.27% | -2.38% |
| International | 64.79% | 65.66% | +0.87% |

Two-thirds of customers buy more than once in a year, and the rate is similar across markets. The domestic rate slipped about 2.4 points while the international rate edged up. A single customer bought in both markets in 2010 and none in 2011; excluding that customer changes the 2010 rates by at most 0.2 points.

This is a **within-year** measure. It says nothing about whether a customer returns the following year, so it is paired with a cross-year view:

### Year-over-year retention

| | Customers | Share |
|---|---:|---:|
| 2010 customers | 4,208 | |
| …who also bought in 2011 | 2,649 | 63.0% |
| …who did not return in 2011 | 1,559 | 37.0% |
| New customers in 2011 (not seen in 2010) | 1,554 | 37.0% of 2011 customers |

---

| Revenue | Amount | Share |
|---|---:|---:|
| 2010 sales from customers who did not return in 2011 | £1,192,006 | 14.6% of 2010 sales |
| 2011 sales from new customers | £1,530,632 | 19.2% of 2011 sales |
| 2011 sales from retained customers | £6,424,567 | 80.8% of 2011 sales |

New customers more than offset the lapsed revenue (£1.53M vs £1.19M). Total sales still fell from £8.18M to £7.96M because the customers who stayed spent less: £6.42M in 2011 against £6.99M from the same group in 2010 (-8.1%). Part of that gap is the missing December: 2010 had £256k of sales between 10 and 23 December that 2011 does not. The caveat on the lapsed figure is that 2011 stops on 9 Dec, so a few late-December buyers could appear as "not returned".

---

## International markets

![Concentration by country](<./Figures/customer_concentration.png>)

| Country | Sales | Orders | Customers | AOV | Largest customer's share |
|---|---:|---:|---:|---:|---:|
| EIRE | £579,393 | 535 | 5 | £1,083 | 52% (top 2: 98%) |
| Netherlands | £537,350 | 220 | 22 | £2,443 | 95% |
| Germany | £409,843 | 764 | 107 | £536 | 9% |
| France | £338,137 | 598 | 95 | £565 | 10% |
| Australia | £167,523 | 89 | 15 | £1,882 | 86% |

**Findings**

- **Germany and France are the only large markets with a broad customer base** (107 and 95 customers). Their AOVs (£536, £565) are above the UK's (£417) but far below the Netherlands'. Both are growing: Jan–Nov sales +9.6% in Germany and +44.4% in France, with active customers up from 69 to 93 in Germany and from 47 to 84 in France.
- **The Netherlands' £2,443 AOV is one customer.** Customer 14646 placed 145 orders worth £512,693. The other 21 Dutch customers average £329 per order. The market also narrowed: 22 Dutch customers bought in 2010 but only 8 in 2011, while Jan–Nov sales still rose 5.1% because of that one account.
- **EIRE is five customers, and it is shrinking.** Two of them make up 98% of sales. EIRE fell 24.1% (Jan–Nov £321k → £243k) and had 3 active customers in 2011, down from 5. This is the biggest decline in the international book and it is a single relationship at risk.
- **Australia drove over half of international growth.** Jan–Nov sales rose from £29k to £137k (+£108k), 55% of the +£195k total growth. Excluding Australia, international grew about 7%.
- **Smaller markets are growing from tiny bases:** Spain (+£27k), Japan (+£25k), Norway (+£23k). **Denmark (-61%), Sweden (-33%) and Greece (-70%) fell** from small bases with few accounts.
- Country AOV rankings must be read with the customer counts beside them. Netherlands, Australia and Denmark top the AOV ranking (minimum 30 orders), and all three rest on a few buyers.

---

## Products

Rankings are merchandise only, by stock code (see [Data and Methodology](#data-and-methodology)).

**Top 5 by sales**

| Product | Sales | Orders containing it |
|---|---:|---:|
| Regency Cakestand 3 Tier | £273,833 | 3,273 |
| White Hanging Heart T-Light Holder | £229,472 | 4,606 |
| Jumbo Bag Red Retrospot | £160,921 | 3,136 |
| Assorted Colour Bird Ornament | £116,399 | 2,546 |
| Party Bunting | £102,204 | 2,050 |

---

**Top 5 by units sold**

| Product | Units | Sales |
|---|---:|---:|
| World War 2 Gliders Asstd Designs | 102,146 | £23,466 |
| Jumbo Bag Red Retrospot | 89,434 | £160,921 |
| White Hanging Heart T-Light Holder | 85,108 | £229,472 |
| Pack Of 72 Retrospot Cake Cases | 84,808 | £40,960 |
| Small Popcorn Holder | 75,296 | £57,002 |

**Findings**

- **Consistent top sellers.** Regency Cakestand, White Hanging Heart and Jumbo Bag Red Retrospot are the top three by sales in both years, and Assorted Colour Bird Ornament is in the top five in both. White Hanging Heart is the most frequently ordered item overall and in the UK (4,606 orders overall). Party Bunting rose into the top five in 2011, replacing Doormat Union Flag.
- **Units and revenue tell different stories.** World War 2 Gliders sell the most units but earn only £23k (about 23 GBP per unit): a low-priced volume item. Ranking by units favours cheap items.
- **There is no hero product.** The top 5 products account for only 5.5% of sales, so revenue sits in a long tail of giftware lines.
- **Domestic and international tastes differ.** Domestic leads with cakestands, T-light holders, bags and ornaments. International leads with Regency Cakestand, Round Snack Boxes (Woodland), Rabbit Night Light, Red Toadstool LED Night Light and Spaceboy Lunch Box.
- **Bulk orders distort unit rankings.** The top international unit seller in 2010 (Black And White Paisley Flower Mug, 25,164 units) came from just two orders. Orders containing the item is the better popularity measure.
- **"Manual" and "Postage" are not products.** They are service lines (stock codes `M` and `POST`; £67.8k and £112.5k of sales after cancellations are removed). Together with carriage, adjustments, bank charges, discounts and test items they account for £209,320, or 1.3% of sales. They are kept in sales totals but excluded from product rankings.

---

## Limitations

- **No cost or margin data.** We can say what sells, not what is profitable. Nothing here establishes which market or product is the most profitable.
- **Sales net of full-line cancellations only.** Orders cancelled in full within 30 days are removed, but partial and later returns (past 30 days) are not netted off, so sales are somewhat overstated and the return rate is not measured.
- **Identified customers only.** Lines without a Customer ID (228,488 otherwise-qualifying lines) are excluded, so totals understate company sales and say nothing about guest or unattributed purchasing.
- **Duplicate handling is an assumption.** Identical repeat lines within a sheet (12,133) are collapsed as duplicate entries.
- **Two years of data, with partial months.** That is too short to separate trend from one-off patterns, and Dec 2011 is incomplete, having only 9 days of invoices.
- **Small international bases.** Many countries have few customers, so country-level growth rates and AOVs swing with single accounts. "European Community" appears as a country in the source data and is counted as international.
- **No acquisition-cost or channel data.** Growth cannot be judged for sustainability or return on marketing.
- **No churn definition.** Retention here is "bought again in the next calendar year", not a measured churn rate.

---

## Recommendations
### 1. Prioritize Retention, Conduct Marketing Campaigns for Lapsed Accounts
*Evidence: 37% of 2010 customers did not return; they were worth £1.19M in 2010. Customers who stayed spent about 8% less in 2011 (£6.42M vs £6.99M). 27.7% of customers placed a single order. The within-year repeat rate fell from 66.5% to 64.4%.*
- Build an RFM segmentation (recency, frequency, monetary) on the sales layer and list lapsed customers by their 2010 value. Start with the high-value segment, where each recovered account is worth far more than a new one.
- Time outreach to the Aug–Sep pre-season window, when buyers are placing autumn orders.
- Add a second-order nudge for first-time buyers (follow-up and incentive within 30–60 days).
- Success measure: lift the year-over-year retention rate from 63%, and track the within-year repeat rate.

### 2. Manage Top Customers as Named Accounts
*Evidence: top 10% of customers = 63% of sales; top 5 international customers = 45% of international sales; EIRE is down 24% with two accounts at 98% of sales and only 3 active customers in 2011.*
- Assign account owners to roughly the top 60 customers (top 1% = 31% of sales).
- Review the EIRE and Dutch accounts now: understand why EIRE fell and why only 8 of 22 Dutch customers bought in 2011.
- Track a concentration KPI (top-10 customer share) on the dashboard.

### 3. Keep International Market Growth through Germany and France
*Evidence: international orders +18.7% and customers +20.6%, led by France (47 → 84 active customers, +44% sales) and Germany (69 → 93, +10%); but Australia supplied 55% of the £ growth from one customer.*
- Direct acquisition effort at Germany and France first, where customer volume is broad and results do not depend on a single buyer.
- Treat the Netherlands, Australia and EIRE as account-management problems (recommendation 2), not as proof the market for those countries is large.
- Do not rank markets by AOV without a minimum number of orders and customers.

### 4. Address the UK Order-Frequency Decline
*Evidence: UK Jan–Nov customers -1.0% but orders -5.0%; orders per customer 4.0 → 3.9; the repeat rate fell 2.4 points.*
- Segment UK customers by order frequency and find where the drop is concentrated (large accounts ordering less, or smaller accounts lapsing).
- Test reorder prompts for regular buyers of the consistent top sellers.

### 5. Plan Each Year Around the September–November Season
*Evidence: Sep–Nov = 36% of a full year's sales (39–41% of Jan–Nov); September jumps +37% to +47% month on month; Jan–Aug is a flat base of roughly £470k domestic.*
- Build and confirm stock for the top sellers by August, and pre-book wholesale orders.
- Use the Jan–Aug base for activity that smooths demand: trade promotions, new-range launches and the win-back work from recommendation 1. January and February are consistently the weakest months.
- Treat December as a short trading month (shipping stops around 23 December) when setting targets, so it is not judged against November.

### 6. Understand Why Average Order Value is Rising While Volume Falls
*Evidence: Jan–Nov orders -3.1%, units -9.2%, AOV +3.0%. The Dec 1–9 comparison shows the same pattern: order counts flat, sales +12.6%.*
- Split AOV into price and mix: is it price increases, larger baskets of fewer lines, or a shift towards higher-priced lines?
- Test a minimum-order or free-delivery threshold set near the median order (£302) and observe the effect on frequency and basket size. This is a hypothesis to test, not a conclusion from the data.

### 7. Rationalize and Protect the Product Range with Margin Data
*Evidence: top 5 products = 5.5% of sales; the same products were previously listed under several names.*
- Add unit cost to rank products by margin as well as sales, then review the long tail for lines that sell rarely and in small amounts.
- Keep the consistent sellers (Regency Cakestand, White Hanging Heart, Jumbo Bag Red Retrospot) well stocked ahead of the autumn peak.

### 8. Extend and Improve Analytics
- Extend the cancellation handling to a proper **net sales** and **return rate** analysis, including partial and late returns.
- Review how many of the 12,133 collapsed repeat lines were genuine repeat purchases.
- Add cost and acquisition data, and extend the history, to separate trend from one-off effects.

---

## Methodology notes

- All figures come from queries in [`SQL Queries/`](<./SQL%20Queries/>): 
    - [`Observation_Queries.sql`](<./SQL%20Queries/Observation_Queries.sql>) (monthly sales, KPIs, products, countries, concentration, seasonality)
    - [`Repeat_Purchase_Rate.sql`](<./SQL%20Queries/Repeat_Purchase_Rate.sql>) 
    - [`Customer_Retention.sql`](<./SQL%20Queries/Customer_Retention.sql>) 
    - [`Data_Validation.sql`](<./SQL%20Queries/Data_Validation.sql>). 
    - Outputs from these queries are saved in [`Query Results/`](<./SQL%20Queries/>).
- Month-over-month changes are calculated from monthly sales totals.
- Like-for-like comparisons use Jan–Nov (or 1–9 December) because the data ends on 9 Dec 2011.
- Derived ratios (for example orders per customer, shares of growth, and the Sep–Nov share of Jan–Nov) are calculated from those outputs.