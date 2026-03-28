/* ============================================================================
   NETWORK TOPOLOGY & ROUTING EDA
   ============================================================================
   Description:
   Analyzes the structure of the logistics network, focusing on the split 
   between local and long-haul routes, and distance consistency.
   ============================================================================
*/

-- 1. Network Corridor Classification (Interstate vs Intrastate)
SELECT 
    -- Classifies routes based on state borders. This is critical for logistics operations 
    -- as Interstate (Long-haul) routes face different compliance rules, fuel taxes, and driver Hours of Service (HOS) limits.
    CASE 
         WHEN origin_state = destination_state THEN 'Intrastate (Local)'
         ELSE 'Interstate (Long-haul)'
    END AS route_scope,
    
    COUNT(*) AS total_routes,
    ROUND(AVG(typical_distance_miles), 2) AS avg_miles,
    ROUND(AVG(base_rate_per_mile), 2) AS avg_base_rate_usd
FROM dim_routes
GROUP BY 1 
ORDER BY total_routes DESC;


-- ============================================================================


-- 2. Route Cost Statistical Dispersion
SELECT
    -- Calculates the baseline expected cost/revenue per trip (Rate * Distance)
    ROUND(MIN(base_rate_per_mile * typical_distance_miles), 2) AS min_trip_cost,
    ROUND(MAX(base_rate_per_mile * typical_distance_miles), 2) AS max_trip_cost,
    ROUND(AVG(base_rate_per_mile * typical_distance_miles), 2) AS avg_trip_cost,
    
    -- Computes the exact continuous Median (50th percentile) trip cost.
    -- This provides a robust benchmark that is highly resistant to extreme long-haul outliers.
    PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY base_rate_per_mile * typical_distance_miles ASC) AS median_trip_cost,
    
    -- Calculates Standard Deviation to evaluate the price volatility and variability across the entire routing network.
    ROUND(STDDEV(base_rate_per_mile * typical_distance_miles), 2) AS cost_standard_deviation
FROM dim_routes;
