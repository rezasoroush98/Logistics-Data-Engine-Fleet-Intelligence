/* QUARTERLY FACILITY PERFORMANCE TRENDS
   Monitors 'Wasted Time' (Schedule Deviation + Detention) 
   and calculates Quarter-over-Quarter (QoQ) performance shifts.
*/

-- BASE CTE: Calculate schedule deviation and wasted time for each event
WITH BASE AS(
    SELECT
        F.facility_id,
        D.Facility_name,
        F.actual_datetime,
        F.scheduled_datetime,
        F.event_type,
        DATE_TRUNC('QUARTER', F.actual_datetime) AS QUARTER,
        -- DIFF_MIN: Schedule deviation in minutes (positive = late, negative = early)
        ROUND((EXTRACT(EPOCH FROM (F.actual_datetime - F.scheduled_datetime))/60), 2) AS DIFF_MIN,
        -- WASTED_TIME: Total delay = schedule deviation + detention time
        ROUND((EXTRACT(EPOCH FROM (F.actual_datetime - F.scheduled_datetime))/60), 2) + detention_minutes AS WASTED_TIME
    FROM 
        fact_delivery_events AS f 
        JOIN dim_facilities AS D ON F.facility_id = D.facility_id
)
-- CAL CTE: Aggregate to quarterly averages by facility, filtering for data quality (>10 events)
, cal AS (
    SELECT
        facility_name,
        QUARTER,
        ROUND(AVG(DIFF_MIN), 2) AS AVG_DIFF_MIN,
        ROUND(AVG(WASTED_TIME), 2) AS AVG_WASTED_TIME
    FROM BASE 
    GROUP BY 1, 2
    HAVING COUNT(*) > 10
)
-- FINAL SELECT: Add QoQ % change calculations using window functions
SELECT
    Facility_name,
    QUARTER,
    AVG_DIFF_MIN,
    -- Previous quarter's average deviation
    LAG(AVG_DIFF_MIN) OVER (PARTITION BY Facility_name ORDER BY QUARTER) AS PREV_QUARTER_AVG_DIFF_MIN,
    -- QoQ % change in schedule deviation
    ROUND((AVG_DIFF_MIN - LAG(AVG_DIFF_MIN) OVER (PARTITION BY Facility_name ORDER BY QUARTER)) 
        / NULLIF(LAG(AVG_DIFF_MIN) OVER (PARTITION BY Facility_name ORDER BY QUARTER), 0) * 100, 2) AS DIFF_AVG_DIFF_MIN_PERCENT,
    AVG_WASTED_TIME,
    -- Previous quarter's average wasted time
    LAG(AVG_WASTED_TIME) OVER (PARTITION BY Facility_name ORDER BY QUARTER) AS PREV_QUARTER_AVG_WASTED_TIME,
    -- QoQ % change in wasted time
    ROUND((AVG_WASTED_TIME - LAG(AVG_WASTED_TIME) OVER (PARTITION BY Facility_name ORDER BY QUARTER)) 
        / NULLIF(LAG(AVG_WASTED_TIME) OVER (PARTITION BY Facility_name ORDER BY QUARTER), 0) * 100, 2) AS DIFF_AVG_WASTED_TIME_PERCENT
FROM cal
ORDER BY Facility_name, QUARTER, DIFF_AVG_WASTED_TIME_PERCENT ASC, AVG_WASTED_TIME DESC
