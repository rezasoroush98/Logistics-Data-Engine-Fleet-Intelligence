/* ============================================================================
   CUSTOMER LIFECYCLE VALUE & REVENUE CONCENTRATION
   ============================================================================
   Description:
   Analyzes customer revenue contributions, market share percentage, and 
   booking behavior (Dedicated vs. Spot vs. Contract) across different years.
   ============================================================================
*/

-- 1. Customer Revenue Share & Booking Portfolio
-- Highlights which customers drive the most revenue and their preferred booking
SELECT
    dc.customer_id,
    dc.customer_name,
    SUM(fl.revenue) AS total_revenue,
    COUNT(*) AS load_count,
    ROUND(AVG(fl.revenue), 2) AS avg_revenue_per_load,
    -- Calculating market share using Window Function
    ROUND(SUM(fl.revenue) * 100.0 / SUM(SUM(fl.revenue)) OVER(), 2) AS revenue_share_pct,
    -- Pivoting booking types for customer profiling
    SUM(CASE WHEN fl.booking_type = 'Dedicated' THEN fl.revenue ELSE 0 END) AS dedicated_revenue,
    SUM(CASE WHEN fl.booking_type = 'Contract' THEN fl.revenue ELSE 0 END) AS contract_revenue,
    SUM(CASE WHEN fl.booking_type = 'Spot' THEN fl.revenue ELSE 0 END) AS spot_revenue
FROM fact_loads fl
JOIN dim_customers dc ON fl.customer_id = dc.customer_id
GROUP BY dc.customer_id, dc.customer_name
ORDER BY total_revenue DESC;



-- 2. Multi-dimensional Growth Trends
-- Analyzing revenue and weight trends by year and customer using CUBE
select
COALESCE(extract(year from fl.load_date)::text,'All years') as year,
COALESCE(dc.customer_name, 'All Customers'),
count(*) as total_num,
sum(fl.revenue) as total_rev,
round(sum(fl.weight_lbs),2) as total_weight,
    sum(case 
        when fl.booking_type ='Dedicated' then fl.revenue
        else 0 
        end) as Dedicated ,
    sum(case 
        when fl.booking_type ='Contract' then fl.revenue
        else 0 
        end) as Contract,
    sum(case 
        when fl.booking_type ='Spot' then fl.revenue
        else 0 
        end) as Spot
from fact_loads as fl
join dim_customers as dc on fl.customer_id=dc.customer_id
group by cube(extract(year from fl.load_date),dc.customer_name)
ORDER by year ;
