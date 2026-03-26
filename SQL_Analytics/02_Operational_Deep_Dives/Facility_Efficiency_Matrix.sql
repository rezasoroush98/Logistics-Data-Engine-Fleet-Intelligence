/* HIERARCHICAL FACILITY EFFICIENCY MATRIX
   Analyzes delivery events, average detention, and on-time percentages 
   using multi-dimensional roll-ups (CUBE).
*/

-- CUBE aggregation: Generates hierarchical rollups across facility and event type dimensions
-- Returns detail, facility totals, event type totals, and grand total rows
SELECT
    -- Dimension columns with coalesce to label rollup rows
    coalesce(df.facility_name,'All-Facilities')  as Facility_name,
    coalesce(fd.event_type,'All-types')          as event_type,
    
    -- Performance metrics
    round(avg(fd.detention_minutes),2)           as avg_detention,
    count(fd.event_id)                           as number_of_events,
    round((count(*) filter (where on_time_flag='True')::numeric/count(*)) * 100,2)  as on_times_percent,
    
    -- Hierarchical level indicator using GROUPING function
    -- GROUPING returns 1 if column is aggregated (rolled up), 0 if it's a detail value
    case
        when grouping(df.facility_name)=0 and grouping(fd.event_type)=0 THEN 'Detail'
        when grouping(df.facility_name)=0 and grouping(fd.event_type)=1 THEN 'Facility total'
        when grouping(df.facility_name)=1 and grouping(fd.event_type)=0 THEN 'Event type total'
        ELSE 'Grand total'
    END AS report_level

from
    fact_delivery_events     as             fd
    join dim_facilities      as             df         on  fd.facility_id=df.facility_id

-- CUBE generates all possible combinations of grouping
group by cube(df.facility_name,fd.event_type)

-- Sort by rollup hierarchy level, then by dimension values
order by 
    grouping (df.facility_name) desc,
    df.facility_name asc,
    grouping(fd.event_type) asc
;
