-- CTE 1: Aggregate revenue streams per route
-- This CTE consolidates all revenue and cost data by route and quarter
with QUARTERLY_DATA AS (
SELECT 
-- Create readable lane identifier combining origin and destination cities
    r.origin_city ||' to ' || r.destination_city AS lane_path,
-- Extract year from dispatch date for temporal analysis
    EXTRACT(YEAR from ft.dispatch_date) as REPORT_YEAR,
-- Extract quarter from dispatch date for quarterly grouping
    EXTRACT(QUARTER from ft.dispatch_date)as REPORT_QUARTER,
    
-- Sum all revenue sources: base revenue + fuel surcharges + accessorial charges
    SUM(l.revenue + l.fuel_surcharge + l.accessorial_charges) AS gross_revenue,
    
-- Sum total operational costs: fuel purchases + cargo damage + vehicle damage
    SUM(COALESCE(fp.total_cost,0)+COALESCE(si.cargo_damage_cost,0)+COALESCE(si.vehicle_damage_cost,0)) as total_costs,
    
-- Count total loads transported on this route for volume metrics
    COUNT(l.load_id) AS load_count
    
 FROM
    dim_routes      as r
    JOIN fact_loads as l              on r.route_id=l.route_id
    JOIN fact_trips as ft             on l.load_id = ft.load_id
-- Left joins preserve routes with no fuel/safety incident data
    LEFT JOIN fact_fuel_purchases as fp  on ft.trip_id=fp.trip_id
    LEFT JOIN fact_safety_incidents as si on ft.trip_id=si.trip_id
    
 GROUP BY 1,2,3
),

-- CTE 2: Calculate profitability metrics and year-over-year comparisons
FINAL_METRICS AS (
     SELECT 
          *,
     -- Calculate net profit (revenue minus all costs)
          (gross_revenue - total_costs) AS net_profit,
          
     -- Calculate profit margin as percentage of gross revenue
          ROUND((gross_revenue - total_costs) / NULLIF(gross_revenue, 0) * 100, 2) AS profit_margin_pct,
          
     -- Year-over-year comparison: profit from same quarter previous year
          LAG(gross_revenue - total_costs) OVER(PARTITION BY lane_path, report_quarter ORDER BY report_year) AS prev_year_same_quarter_profit
     FROM QUARTERLY_DATA
)

-- Final result set with KPIs ordered for easy analysis
SELECT 
     lane_path,
-- Format quarter as YYYY-QX for readability
     report_year || '-Q' || report_quarter AS quarter_label,
     load_count,
-- Rounded net profit for cleaner reporting
     ROUND(net_profit, 0) AS q_net_profit,
     profit_margin_pct,
     
-- KPI: Year-over-year profit growth percentage vs same quarter last year
     ROUND(((net_profit - prev_year_same_quarter_profit) / NULLIF(ABS(prev_year_same_quarter_profit), 0)) * 100, 2) AS yoy_growth_pct
FROM FINAL_METRICS
-- Sort by route, then descending year and quarter for chronological view
ORDER BY lane_path, report_year DESC, report_quarter;
