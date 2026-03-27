/* ============================================================================
   FLEET MAINTENANCE FINANCIAL AUDIT & MCPM
   ============================================================================
   Description:
   Evaluates the financial efficiency of the fleet by calculating Maintenance 
   Cost Per Mile (MCPM) and tracking Month-over-Month (MoM) cost fluctuations 
   and emergency repair ratios.
   ============================================================================
*/

-- 1. Asset-Level Efficiency: MCPM & Repair Ratio
-- Combines Maintenance and Trip data to find the most expensive trucks to operate

WITH maintenance_cte AS (
SELECT 
    truck_id,
    sum(total_cost) AS total_maint_cost ,
    sum(downtime_hours) AS total_downtime,
    count(*) AS total_maintenance_count,
    -- KPI: High repair ratio indicates reactive rather than preventive maintenance
    round(count(CASE WHEN maintenance_type='Repair'THEN 1 END)::numeric/count(*) * 100,2) AS Repair_ratio
FROM
fact_maintenance_records 
GROUP BY truck_id
)
, 
trip_cte AS (
SELECT
    truck_id,
    sum(actual_distance_miles) AS total_miles,
    SUM(fuel_gallons_used) AS total_fuel
FROM fact_trips
GROUP by truck_id
) 

SELECT
    m.truck_id,
    m.total_maint_cost,
    m.total_downtime,
    m.repair_ratio,
    t.total_miles,
    -- KPI: Maintenance Cost Per Mile (Financial benchmark)
    ROUND( m.total_maint_cost::numeric / nullif(t.total_miles,0),3 ) AS MCPM,
    -- KPI: Miles Per Gallon (Fuel efficiency indicator)
    ROUND(t.total_miles::numeric / nullif(t.total_fuel,0),3) AS Truck_MPG
FROM maintenance_cte m 
JOIN trip_cte AS t ON m.truck_id=t.truck_id
WHERE t.total_miles > 500 -- Filtering out anomalies with too few miles
ORDER by MCPM DESC
;



-- 2. Time-Series Financial Trends: MoM Cost & Emergency Ratio
-- Analyzes how maintenance costs grow over time and the impact of emergency repairs
WITH monthly_maint AS (
    SELECT
        TO_CHAR(DATE_TRUNC('month', maintenance_date), 'YYYY-MM') AS report_month,
        COUNT(*) AS total_num_maintenance,
        ROUND(AVG(downtime_hours), 2) AS avg_downtime,
        SUM(total_cost) AS total_monthly_cost,
        ROUND(COUNT(CASE WHEN maintenance_type IN ('Repair', 'Emergency') THEN 1 END)::NUMERIC / COUNT(*) * 100, 2) AS emergency_ratio_pct
    FROM fact_maintenance_records
    GROUP BY 1
),
trend_analysis AS (
    SELECT
        *,
        LAG(total_monthly_cost) OVER(ORDER BY report_month) AS prev_month_cost
    FROM monthly_maint
)
SELECT
    report_month,
    total_num_maintenance,
    avg_downtime,
    total_monthly_cost,
    emergency_ratio_pct,
    -- KPI: Month-over-Month (MoM) Cost Growth
    ROUND(((total_monthly_cost - prev_month_cost) / NULLIF(prev_month_cost, 0)) * 100, 2) AS cost_mom_growth_pct
FROM trend_analysis
ORDER BY report_month;
