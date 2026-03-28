/* ============================================================================
   SAFETY INCIDENT FINANCIAL IMPACT & COST GROWTH AUDIT
   ============================================================================
   Description:
   Quantifies the direct financial losses caused by safety incidents across 
   routes, and compares incident cost growth against maintenance investments.
   ============================================================================
*/

-- 1. Route-Level Financial Impact Analysis
-- (Original Logic: Identifies which lanes cause the highest financial drain due to accidents)
SELECT
    -- Concatenates origin and destination to create a single readable route name (e.g., 'City A to City B')
    r.origin_city || ' to ' || r.destination_city AS lane_path,
    
    COUNT(s.incident_id) AS incidents_count,
    SUM(s.vehicle_damage_cost + s.cargo_damage_cost) AS total_damage_usd,
    
    -- Uses NULLIF to prevent "division by zero" errors if the incident count is somehow 0
    ROUND(SUM(s.vehicle_damage_cost + s.cargo_damage_cost) / NULLIF(COUNT(s.incident_id),0), 2) AS avg_damage_per_incident

FROM fact_safety_incidents AS s
JOIN fact_trips AS t ON s.trip_id = t.trip_id
JOIN fact_loads AS l ON t.load_id = l.load_id
JOIN dim_routes AS r ON l.route_id = r.route_id
GROUP BY 1
-- Filters out routes with 3 or fewer incidents to ensure we only analyze statistically significant patterns
HAVING COUNT(s.incident_id) > 3
ORDER BY total_damage_usd DESC;


-- ============================================================================


-- 2. Incident Costs vs. Preventive Maintenance Investment (MoM Trend)
-- (Original Logic: Tracking if increased maintenance spending reduces accident costs)
WITH monthly_cte AS(
    SELECT
        DATE_TRUNC('month', incident_date) AS report_month,
        COUNT(*) AS total_incidents,
        SUM(vehicle_damage_cost + cargo_damage_cost) AS incident_monthly_cost,
        
        -- Window function (LAG) fetches the total cost from the EXACT PREVIOUS month to allow Month-over-Month comparison
        LAG(SUM(vehicle_damage_cost + cargo_damage_cost)) OVER (ORDER BY DATE_TRUNC('month', incident_date)) AS prev_month_incident_cost
    FROM fact_safety_incidents
    GROUP BY 1
),
maintenance_cte AS (
    SELECT
        DATE_TRUNC('month', maintenance_date) AS report_month,
        SUM(total_cost) AS maint_monthly_cost,
        
        -- Fetching previous month's maintenance cost
        LAG(SUM(total_cost)) OVER(ORDER BY DATE_TRUNC ('month', maintenance_date)) AS prev_month_maint_cost
    FROM fact_maintenance_records
    GROUP BY 1 
)

SELECT
    -- Formats the raw timestamp into a clean 'YYYY-MM' string for reporting dashboards
    TO_CHAR(mc.report_month,'YYYY-MM') AS report_month,
    
    -- ================= Incident Metrics =================
    mc.incident_monthly_cost,
    
    -- Calculates Month-over-Month (MoM) percentage growth. Formula: ((Current - Previous) / Previous) * 100
    ROUND(((mc.incident_monthly_cost - mc.prev_month_incident_cost)::NUMERIC / NULLIF(mc.prev_month_incident_cost,0)) * 100, 2) AS incident_growth_pct,
    
    CASE 
       WHEN mc.incident_monthly_cost < mc.prev_month_incident_cost THEN 'Decreasing'
       WHEN mc.prev_month_incident_cost IS NULL THEN 'First Month'
       ELSE 'Increasing'
    END AS incident_cost_trend,

    -- ================= Maintenance Metrics =================
    mcc.maint_monthly_cost,
    
    -- Calculates MoM percentage growth for maintenance spending
    ROUND(((mcc.maint_monthly_cost - mcc.prev_month_maint_cost) / NULLIF(mcc.prev_month_maint_cost,0)) * 100, 2) AS maint_growth_pct,
    
    CASE 
       WHEN mcc.maint_monthly_cost < mcc.prev_month_maint_cost THEN 'Decreasing'
       WHEN mcc.prev_month_maint_cost IS NULL THEN 'First Month'
       ELSE 'Increasing'
    END AS maint_cost_trend

FROM monthly_cte AS mc
JOIN maintenance_cte AS mcc ON mc.report_month = mcc.report_month
ORDER BY mc.report_month;
