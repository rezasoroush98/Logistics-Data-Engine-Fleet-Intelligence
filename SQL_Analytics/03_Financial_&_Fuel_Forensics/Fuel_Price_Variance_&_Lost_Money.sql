/* ============================================================================
   FUEL PRICE VARIANCE & FINANCIAL LEAKAGE AUDIT ("LOST MONEY")
   ============================================================================
   Description:
   Identifies financial losses by comparing actual fuel purchase prices 
   against the company's benchmark price. Analyzed at both the City and Driver levels.
   ============================================================================
*/

-- 1. City-Level Price Gap & Extra Cost Analysis
-- Extract base fuel purchase data with date components
with Base_cte as (
    SELECT
        fuel_purchase_id,
        Extract(year from purchase_date) as report_year,           -- Extract year for grouping
        Extract(Quarter from purchase_date) as report_quarter,     -- Extract quarter for grouping
        location_city,
        price_per_gallon,
        gallons,
        total_cost
    FROM fact_fuel_purchases
    WHERE purchase_date <= '2024-12-31'                            -- Filter historical data only
),

-- Calculate per-city average prices and transaction metrics
location_cte as(
    SELECT
        location_city,
        report_year,
        report_quarter,
        round(sum(total_cost) / nullif(sum(gallons),0),3) as avg_price_per_gallon,  -- Avg price per gallon by city
        count(fuel_purchase_id) as Transaction_Count,              -- Number of transactions
        round(sum(gallons),2) as total_gallons_per_city            -- Total volume per city
    FROM Base_cte
    GROUP BY 1,2,3                                                 -- Group by city, year, quarter
),

-- Calculate company-wide average prices for benchmarking
company_cte as(
    SELECT
        report_year,
        report_quarter,
        round(sum(total_cost) / nullif(sum(gallons),0),3) as company_avg_price_per_gallon  -- Company benchmark price
    FROM Base_cte
    GROUP BY 1,2                                                   -- Group by year, quarter
)

-- Final output: Compare city prices to company average
SELECT
    l.report_year || '-Q' || l.report_quarter AS quarter_label,   -- Format quarter as "YYYY-QX"
    l.location_city,
    l.avg_price_per_gallon as city_price,                         -- City's average price
    c.company_avg_price_per_gallon as company_benchmark,          -- Company-wide average for comparison
    round(l.avg_price_per_gallon - c.company_avg_price_per_gallon,3) as Price_Gap,  -- Price difference
    round((l.avg_price_per_gallon - c.company_avg_price_per_gallon) * l.total_gallons_per_city,2) as Total_Extra_Cost,  -- Total overspend/savings
    case 
        when l.avg_price_per_gallon > c.company_avg_price_per_gallon then 'Over'     -- City costs more
        when l.avg_price_per_gallon < c.company_avg_price_per_gallon then 'Under'    -- City costs less
        else 'Equal'                                               -- Same as company average
    end as price_direction
FROM location_cte as l
JOIN company_cte as c ON l.report_year = c.report_year AND l.report_quarter = c.report_quarter  -- Match by year and quarter
ORDER BY l.report_year Asc , l.report_quarter Asc, Total_Extra_Cost DESC;  -- Sort by time, then overspend amount


-- 2. Driver-Level Purchasing Behavior & Financial Loss


    -- Step 1: Calculate each driver's average price per gallon and total gallons per month
WITH driver_cte AS (
    -- We use weighted average: SUM(total_cost) / SUM(gallons)
    SELECT
        TO_CHAR(DATE_TRUNC('month', p.purchase_date), 'YYYY-MM') AS month,
        CONCAT(d.first_name, ' ', d.last_name) AS driver_full_name,
        ROUND(SUM(p.total_cost) / NULLIF(SUM(p.gallons), 0), 3) AS driver_monthly_avg_price,
        SUM(p.gallons) AS gallons_per_month
    FROM fact_fuel_purchases p
    JOIN dim_drivers d ON p.driver_id = d.driver_id
    GROUP BY 1, 2
),
    -- Step 2: Calculate the company-wide weighted average fuel price per month
company_total AS (
    -- This is used as the benchmark for comparison
    SELECT
        TO_CHAR(DATE_TRUNC('month', purchase_date), 'YYYY-MM') AS month,
        ROUND(SUM(total_cost) / NULLIF(SUM(gallons), 0), 3) AS company_monthly_avg
    FROM fact_fuel_purchases
    GROUP BY 1
)

-- Final Step: Compare each driver to the company average and calculate financial impact
SELECT
    d.month,
    d.driver_full_name,
    d.driver_monthly_avg_price,
    t.company_monthly_avg,
    ROUND(d.driver_monthly_avg_price - t.company_monthly_avg, 3) AS price_diff,                             -- How much more/less per gallon
    ROUND((d.driver_monthly_avg_price - t.company_monthly_avg) * d.gallons_per_month, 2) AS lost_money_usd  -- Extra money spent due to higher price
FROM driver_cte d 
JOIN company_total t ON d.month = t.month
WHERE (d.driver_monthly_avg_price - t.company_monthly_avg) > 0     -- Only show drivers who overpaid
ORDER BY d.month, lost_money_usd DESC;                             -- Most recent months first, then highest loss

