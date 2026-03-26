/* ============================================================================
   OPERATIONAL COST VARIANCE SEGMENTATION
   ============================================================================
   Description:
   Segments loads into 'Cost Overrun' and 'Cost Underrun' by comparing 
   actual shipment costs against expected contract rates based on distance.
   ============================================================================
*/

WITH COST_CALCULATION AS (
    SELECT 
        fl.load_id,
        dr.origin_city,
        dr.destination_city,
        -- Actual Total Cost
        fl.revenue + fl.accessorial_charges + fl.fuel_surcharge AS actual_total_cost,
        -- Expected Cost based on standard base rates
        (dr.typical_distance_miles) * (dr.base_rate_per_mile + dr.fuel_surcharge_rate) AS expected_cost
    FROM fact_loads fl
    JOIN dim_routes dr ON fl.route_id = dr.route_id
)

SELECT
    CASE 
        WHEN (actual_total_cost - expected_cost) > 0 THEN 'Cost Overrun'
        ELSE 'Cost Underrun'
    END AS variance_segment,
    COUNT(*) AS load_count,
    ROUND(AVG(actual_total_cost - expected_cost), 2) AS avg_variance,
    ROUND(SUM(actual_total_cost - expected_cost), 2) AS total_variance_impact
FROM COST_CALCULATION
GROUP BY variance_segment;
