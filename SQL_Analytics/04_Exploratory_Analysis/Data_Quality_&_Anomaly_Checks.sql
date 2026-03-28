/* ============================================================================
   DATA QUALITY & ANOMALY DETECTION AUDIT
   ============================================================================
   Description:
   Proactively identifies missing values, orphaned foreign keys, and logical 
   inconsistencies across dimensional and fact tables before downstream analysis.
   ============================================================================
*/

-- 1. Logical Anomaly Detection (Trailer Acquisition Data)
-- Flags trailers where the acquisition year is logically impossible (before model year)
WITH data_cleaning AS (
    SELECT 
        trailer_id,
        model_year,
        EXTRACT(YEAR FROM acquisition_date) AS age_acquisition,
        EXTRACT(YEAR FROM acquisition_date) - model_year AS acquisition_gap
    FROM dim_trailers
)
SELECT * FROM data_cleaning
WHERE acquisition_gap < 0; 

-- 2. Master Data Integrity Check (Routes)
-- Identifies routes missing critical pricing or distance metrics
SELECT route_id, origin_city, destination_city
FROM dim_routes
WHERE base_rate_per_mile IS NULL 
   OR fuel_surcharge_rate IS NULL 
   OR typical_distance_miles IS NULL
   OR typical_distance_miles <= 0;

-- 3. Transactional Integrity (Delivery Events)
-- Checks for missing operational IDs and validates the 'on_time_flag'
WITH delivery_base AS (
    SELECT
        COUNT(*) AS total_records,
        COUNT(*) FILTER (WHERE load_id IS NULL) AS missing_load_id,
        COUNT(*) FILTER (WHERE facility_id IS NULL) AS missing_facility_id,
        COUNT(*) FILTER (WHERE on_time_flag NOT IN ('True', 'False') AND on_time_flag IS NOT NULL) AS invalid_on_time_flag
    FROM fact_delivery_events
)
SELECT 'Total Delivery Records' AS metric, total_records::TEXT AS value FROM delivery_base
UNION ALL SELECT 'Missing Load IDs', missing_load_id::TEXT FROM delivery_base
UNION ALL SELECT 'Missing Facility IDs', missing_facility_id::TEXT FROM delivery_base
UNION ALL SELECT 'Invalid On-Time Flags', invalid_on_time_flag::TEXT FROM delivery_base;
