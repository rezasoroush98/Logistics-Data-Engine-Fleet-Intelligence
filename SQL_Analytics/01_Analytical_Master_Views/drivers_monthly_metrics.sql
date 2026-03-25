-- ============================================================================
-- DRIVERS MONTHLY METRICS REPORT
-- Purpose: Aggregates driver performance metrics (revenue, safety, fuel, delivery)
-- ============================================================================

-- CTE 1: Calculate revenue metrics per driver per month
WITH DRIVER_REV AS (
    SELECT
        COALESCE(ft.driver_id, 'Unknown') AS driver_id,
        TO_CHAR(DATE_TRUNC('MONTH', ft.dispatch_date), 'YYYY-MM') AS report_month,
        COUNT(ft.trip_id) FILTER(WHERE ft.trip_status = 'Completed') AS completed_trips,
        SUM(COALESCE(ft.actual_distance_miles, 0)) AS total_miles,
        SUM(COALESCE(fl.revenue, 0) + COALESCE(fl.accessorial_charges, 0) + COALESCE(fl.fuel_surcharge, 0)) AS revenue,
        ROUND(AVG(COALESCE(ft.idle_time_hours, 0)), 2) AS average_idle_hours
    FROM fact_trips AS ft
    JOIN fact_loads AS fl ON ft.load_id = fl.load_id
    GROUP BY 1, 2
),

-- CTE 2: Calculate on-time delivery percentage per driver per month
DELIVERY AS (
    SELECT
        COALESCE(ft.driver_id, 'Unknown') AS driver_id,
        TO_CHAR(DATE_TRUNC('MONTH', ft.dispatch_date), 'YYYY-MM') AS report_month,
        ROUND((COUNT(*) FILTER(WHERE fd.on_time_flag = 'TRUE') / NULLIF(COUNT(*), 0)::NUMERIC) * 100.0, 2) AS on_time_deliveries
    FROM fact_trips AS ft
    JOIN fact_delivery_events AS fd ON ft.trip_id = fd.trip_id
    GROUP BY 1, 2
),

-- CTE 3: Calculate safety metrics (incidents, damage costs) per driver per month
SAFETY AS (
    SELECT
        COALESCE(driver_id, 'Unknown') AS driver_id,
        TO_CHAR(DATE_TRUNC('MONTH', incident_date), 'YYYY-MM') AS report_month,
        SUM(COALESCE(vehicle_damage_cost, 0) + COALESCE(cargo_damage_cost, 0)) AS total_damage_cost,
        SUM(CASE WHEN at_fault_flag = 'TRUE' AND preventable_flag = 'TRUE' 
            THEN COALESCE(vehicle_damage_cost, 0) + COALESCE(cargo_damage_cost, 0) 
            ELSE 0 END) AS controllable_damage_cost,
        COUNT(*) AS total_incidents,
        COUNT(*) FILTER(WHERE at_fault_flag = 'TRUE') AS at_fault_count,
        COUNT(*) FILTER(WHERE injury_flag = 'TRUE') AS severe_incidents,
        COUNT(*) FILTER(WHERE preventable_flag = 'TRUE') AS preventable_count
    FROM fact_safety_incidents
    GROUP BY 1, 2
),

-- CTE 4: Calculate fuel consumption metrics per driver per month
FUEL AS (
    SELECT
        COALESCE(driver_id, 'Unknown') AS driver_id,
        TO_CHAR(DATE_TRUNC('MONTH', purchase_date), 'YYYY-MM') AS report_month,
        SUM(COALESCE(gallons, 0)) AS total_gallons,
        SUM(COALESCE(total_cost, 0)) AS total_fuel_cost
    FROM fact_fuel_purchases
    GROUP BY 1, 2
),

-- CTE 5: Create backbone of all driver-month combinations from all CTEs
BACKBONE AS (
    SELECT driver_id, report_month FROM DRIVER_REV
    UNION
    SELECT driver_id, report_month FROM DELIVERY
    UNION
    SELECT driver_id, report_month FROM SAFETY
    UNION
    SELECT driver_id, report_month FROM FUEL
)

-- Final SELECT: Join all metrics and calculate performance indicators
SELECT
    d.driver_id,
    d.first_name || ' ' || d.last_name AS driver_fullname,
    b.report_month,
    (CURRENT_DATE - d.date_of_birth) / 365 AS age,
    d.years_experience,
    r.completed_trips,
    r.total_miles,
    r.revenue AS gross_revenue,
    -- Net revenue excluding controllable damage costs
    (COALESCE(r.revenue, 0) - (f.total_fuel_cost + COALESCE(s.controllable_damage_cost, 0))) AS net_revenue_controllable,
    -- Net revenue excluding all damage costs
    (COALESCE(r.revenue, 0) - (f.total_fuel_cost + COALESCE(s.total_damage_cost, 0))) AS net_revenue_total,
    -- Fuel efficiency (miles per gallon)
    ROUND(r.total_miles / NULLIF(f.total_gallons, 0), 2) AS average_mpg,
    f.total_gallons,
    -- On-time delivery percentage
    dl.on_time_deliveries AS on_time_delivery_pct,
    r.average_idle_hours
FROM backbone AS b
LEFT JOIN dim_drivers AS d ON b.driver_id = d.driver_id
LEFT JOIN driver_rev AS r ON b.driver_id = r.driver_id AND b.report_month = r.report_month
LEFT JOIN delivery AS dl ON b.driver_id = dl.driver_id AND b.report_month = dl.report_month
LEFT JOIN safety AS s ON b.driver_id = s.driver_id AND b.report_month = s.report_month
LEFT JOIN fuel AS f ON b.driver_id = f.driver_id AND b.report_month = f.report_month
WHERE d.date_of_birth is not null
ORDER BY d.driver_id, b.report_month;
