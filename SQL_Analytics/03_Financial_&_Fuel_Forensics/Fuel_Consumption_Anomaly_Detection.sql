/* ============================================================================
   FUEL CONSUMPTION ANOMALY & FRAUD DETECTION
   ============================================================================
   Description:
   Compares the total gallons of fuel purchased against the reported gallons 
   used on trips per truck. A high variance indicates potential fuel theft, 
   unrecorded idling, or missing trip data.
   ============================================================================
*/

WITH purchase_cte AS (
    SELECT
        TO_CHAR(DATE_TRUNC('month', purchase_date), 'YYYY-MM') AS report_month,
        truck_id,
        SUM(gallons) AS purchased_gallons
    FROM fact_fuel_purchases
    GROUP BY 1, 2
),
trip_cte AS (
    SELECT
        TO_CHAR(DATE_TRUNC('month', dispatch_date), 'YYYY-MM') AS report_month,
        truck_id,
        SUM(fuel_gallons_used) AS trip_used_gallons
    FROM fact_trips
    GROUP BY 1, 2
)
SELECT
    p.report_month,
    COALESCE(p.truck_id, 'Unknown') AS truck_id,
    ROUND(p.purchased_gallons, 2)   AS purchased_gallons,
    ROUND(t.trip_used_gallons, 2)   AS trip_used_gallons,
    ROUND(COALESCE(p.purchased_gallons, 0) - COALESCE(t.trip_used_gallons, 0), 2) AS gallon_variance,
    -- Flagging variance > 10%
    ROUND(((COALESCE(p.purchased_gallons, 0) - COALESCE(t.trip_used_gallons, 0)) / NULLIF(p.purchased_gallons, 0)) * 100, 2) AS variance_pct
FROM purchase_cte p 
LEFT JOIN trip_cte t ON p.truck_id = t.truck_id AND p.report_month = t.report_month
WHERE 
    (((COALESCE(p.purchased_gallons, 0) - COALESCE(t.trip_used_gallons, 0)) / NULLIF(p.purchased_gallons, 0)) * 100) >= 10 
    OR 
    (((COALESCE(p.purchased_gallons, 0) - COALESCE(t.trip_used_gallons, 0)) / NULLIF(p.purchased_gallons, 0)) * 100) <= -10
ORDER BY p.report_month DESC, variance_pct DES
