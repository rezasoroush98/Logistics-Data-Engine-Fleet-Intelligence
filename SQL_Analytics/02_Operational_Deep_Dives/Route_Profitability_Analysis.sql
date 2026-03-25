/*
================================================================================
ROUTE PROFITABILITY ANALYSIS QUERY
================================================================================
PURPOSE:
      Calculate profitability metrics for each logistics route by combining revenue
      data with operational costs (fuel and safety incidents).
================================================================================
*/

-- CTE 1: Aggregate revenue streams per route
with route_revenue AS (
 SELECT 
 r.route_id,
 r.origin_city,
 r.destination_city,
 -- Sum all revenue sources: base revenue, fuel surcharges, accessorial charges
 SUM(l.revenue + l.fuel_surcharge + l.accessorial_charges) AS total_revenue,
 -- Count total loads transported on this route
 COUNT(l.load_id) AS total_load
 FROM
 dim_routes      as     r
 JOIN fact_loads as     l      on r.route_id=l.route_id
 GROUP BY 1,2,3
),

-- CTE 2: Calculate total operational costs per route
route_costs AS (
      SELECT 
      l.route_id,
      -- Sum fuel purchase costs
      sum(fp.total_cost) as total_fuel_cost,
      -- Sum safety incident costs (cargo + vehicle damage), treating NULL as 0
      sum(COALESCE(si.cargo_damage_cost,0)+COALESCE(si.vehicle_damage_cost,0)) as total_incident_cost
      FROM
      fact_loads      as                  l
      join fact_trips as                  ft         on l.load_id = ft.load_id
      -- Left joins to handle routes without fuel/safety data
      LEFT JOIN fact_fuel_purchases       fp         on ft.trip_id=fp.trip_id
      LEFT JOIN fact_safety_incidents     si         on ft.trip_id=si.trip_id
      GROUP BY 1
)

-- Final result set: Combine revenue and costs to calculate profitability
SELECT 
-- Create human-readable lane identifier
rv.origin_city || ' to ' || rv.destination_city  as lane,
rv.total_load,
-- Profitability metrics (all rounded to 2 decimal places)
ROUND(rv.total_revenue, 2)       as gross_revenue,
ROUND(rc.total_fuel_cost, 2)     as fuel_expenses,
ROUND(rc.total_incident_cost, 2) as safety_expenses,
-- Net profit = Total revenue minus all expenses
ROUND(rv.total_revenue - (COALESCE(rc.total_fuel_cost,0)+COALESCE(rc.total_incident_cost,0)),2) as net_profit,
-- Profit per load = Net profit divided by load count (unit economics)
ROUND((rv.total_revenue - (COALESCE(rc.total_fuel_cost,0)+COALESCE(rc.total_incident_cost,0)))/ rv.total_load ,2) as profit_per_load
FROM
route_revenue    as    rv
-- Inner join ensures only routes with cost data are included
join route_costs as    rc    on    rv.route_id=rc.route_id
