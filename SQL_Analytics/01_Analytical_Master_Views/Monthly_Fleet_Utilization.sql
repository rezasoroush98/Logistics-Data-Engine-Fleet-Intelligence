/* ============================================================================
   FLEET MONTHLY UTILIZATION & PERFORMANCE REPORT
   ============================================================================
   Description:
   This query aggregates multi-source data (Revenue, Maintenance, Safety, and Fuel)
   into a single monthly analytical view per truck.
   
   Key Features:
   - Backbone Strategy: Ensures no data loss for inactive months.
   - Dynamic Benchmarking: Compares truck performance against fleet averages.
   - Asset Categorization: Groups trucks into 'Star Asset', 'Money Pit', etc.
   ============================================================================
*/

-- CTE 1: Calculate revenue, distance, and RPM per truck/month
WITH TripsRevenue AS (
    SELECT
        COALESCE(ft.truck_id, 'Unknown') AS truck_id,
        -- Standardizing month format for grouping
        TO_CHAR(DATE_TRUNC('month', ft.dispatch_date)::DATE, 'YYYY-Mon') AS report_month,
        -- Aggregating total revenue (Gross = Base + Accessorial + Fuel Surcharge)
        SUM(COALESCE(fl.revenue, 0) + COALESCE(fl.accessorial_charges, 0) + COALESCE(fl.fuel_surcharge, 0)) AS gross_revenue,
        SUM(ft.actual_distance_miles) AS distance_miles,
        COUNT(ft.trip_id) AS total_trips,
        -- Revenue Per Mile (RPM) calculation
        ROUND(SUM(COALESCE(fl.revenue, 0) + COALESCE(fl.accessorial_charges, 0) + COALESCE(fl.fuel_surcharge, 0)) / 
              NULLIF(SUM(ft.actual_distance_miles), 0), 2) AS RPM
    FROM fact_loads fl
    JOIN fact_trips ft ON fl.load_id = ft.load_id
    GROUP BY 1, 2
),

-- CTE 2: Aggregate maintenance expenses and downtime hours
MAINTENANCE AS (
    SELECT
        COALESCE(truck_id, 'Unknown') AS truck_id,
        TO_CHAR(DATE_TRUNC('month', maintenance_date)::DATE, 'YYYY-Mon') AS report_month,
        SUM(total_cost) AS maintenance_cost,
        SUM(downtime_hours) AS downtime
    FROM fact_maintenance_records
    GROUP BY 1, 2
),

-- CTE 3: Sum vehicle and cargo damage costs from incidents
SAFETY AS (
    SELECT
        COALESCE(truck_id, 'Unknown') AS truck_id,
        TO_CHAR(DATE_TRUNC('month', incident_date)::DATE, 'YYYY-Mon') AS report_month,
        SUM(COALESCE(cargo_damage_cost, 0) + COALESCE(vehicle_damage_cost, 0)) AS damage_cost
    FROM fact_safety_incidents 
    GROUP BY 1, 2     
),

-- CTE 4: Total fuel spend per truck/month
FUEL AS (
    SELECT
        COALESCE(truck_id, 'Unknown') AS truck_id,
        TO_CHAR(DATE_TRUNC('month', purchase_date)::DATE, 'YYYY-Mon') AS report_month,
        SUM(COALESCE(total_cost, 0)) AS fuel_cost
    FROM fact_fuel_purchases 
    GROUP BY 1, 2
),

-- CTE 5: Creating the Backbone (Spine) to prevent data gaps
BACKBONE AS (
    SELECT truck_id, report_month FROM TripsRevenue
    UNION SELECT truck_id, report_month FROM MAINTENANCE
    UNION SELECT truck_id, report_month FROM SAFETY
    UNION SELECT truck_id, report_month FROM FUEL
),

-- CTE 6: Joining all modules and calculating core KPIs
FINAL_METRICS AS (
    SELECT
        b.truck_id,
        b.report_month,
        COALESCE(tr.gross_revenue, 0) AS gross_revenue,
        COALESCE(tr.distance_miles, 0) AS distance_miles,
        -- Identify active vs. idle assets
        CASE 
            WHEN COALESCE(tr.distance_miles, 0) = 0 THEN 'Idle'
            ELSE 'Active'
        END AS utilization_status,
        -- Net Profit = Revenue - (Maintenance + Safety + Fuel)
        COALESCE(tr.gross_revenue, 0) - (COALESCE(m.maintenance_cost, 0) + COALESCE(s.damage_cost, 0) + COALESCE(f.fuel_cost, 0)) AS net_profit,
        -- Fuel Cost Per Mile (FCPM)
        ROUND(COALESCE(f.fuel_cost, 0) / NULLIF(tr.distance_miles, 0), 3) AS FCPM,
        COALESCE(m.maintenance_cost, 0) AS maintenance_cost,
        -- Maintenance Cost Per Mile (MCPM)
        ROUND(COALESCE(m.maintenance_cost, 0) / NULLIF(tr.distance_miles, 0), 3) AS MCPM,
        COALESCE(m.downtime, 0) AS downtime_hours,
        -- Downtime Ratio: % of time truck was out of service
        ROUND((COALESCE(m.downtime, 0) / (NULLIF((CURRENT_DATE - COALESCE(dr.acquisition_date, CAST('2018-03-13' AS DATE))), 0) * 24)) * 100, 3) AS downtime_ratio,
        COALESCE(s.damage_cost, 0) AS total_damage_cost,
        -- Safety Drain: Damage cost per mile driven
        ROUND(COALESCE(s.damage_cost, 0) / NULLIF(tr.distance_miles, 0), 3) AS safety_drain
    FROM BACKBONE b 
    LEFT JOIN dim_trucks dr ON b.truck_id = dr.truck_id
    LEFT JOIN TripsRevenue tr ON b.truck_id = tr.truck_id AND b.report_month = tr.report_month
    LEFT JOIN MAINTENANCE m ON b.truck_id = m.truck_id AND b.report_month = m.report_month
    LEFT JOIN SAFETY s ON b.truck_id = s.truck_id AND b.report_month = s.report_month
    LEFT JOIN FUEL f ON b.truck_id = f.truck_id AND b.report_month = f.report_month
)

-- FINAL STEP: Peer benchmarking and Asset Categorization
SELECT
    *,
    -- Monthly fleet average profit for benchmarking
    ROUND(AVG(net_profit) OVER(PARTITION BY report_month), 3) AS avg_fleet_profit,
    -- Intelligent Asset Categorization
    CASE
        WHEN distance_miles = 0 THEN 'Underutilized'
        WHEN net_profit < 0 THEN 'Money Pit'
        WHEN net_profit > AVG(net_profit) OVER(PARTITION BY report_month) 
             AND maintenance_cost < AVG(maintenance_cost) OVER(PARTITION BY report_month) THEN 'Star Asset'
        WHEN maintenance_cost > (gross_revenue * 0.05) THEN 'High Maintenance'   
        ELSE 'Steady Performer'
    END AS asset_category
FROM FINAL_METRICS
ORDER BY report_month ASC, net_profit DESC;
