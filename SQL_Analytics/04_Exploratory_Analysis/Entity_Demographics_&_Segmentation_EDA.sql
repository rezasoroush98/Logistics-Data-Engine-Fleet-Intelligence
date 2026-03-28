/* ============================================================================
   ENTITY DEMOGRAPHICS & SEGMENTATION EDA
   ============================================================================
   Description:
   Exploratory Data Analysis covering Driver demographics (age/experience segmentation)
   and Customer financial statistical profiles.
   ============================================================================
*/

-- 1. Driver Workforce Segmentation (Age & Experience Matrix)
WITH drivers_age AS (
    SELECT 
        driver_id,
        -- Dynamically calculates the driver's exact age in years based on today's date. 
        -- This ensures the report remains accurate over time without hardcoding ages.
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, date_of_birth)) AS age,
        years_experience
    FROM dim_drivers
),
segmentation AS (
    SELECT 
        driver_id,
        -- Converts continuous age data into discrete categorical 'bins' for easier demographic analysis
        CASE 
            WHEN age < 40 THEN 'Under 40'
            WHEN age BETWEEN 40 AND 50 THEN '40 to 50'
            WHEN age BETWEEN 51 AND 60 THEN '51 to 60'
            ELSE 'Over 60'
        END AS age_segment,
        
        -- Segments drivers by experience level to identify potential succession planning or training needs
        CASE 
            WHEN years_experience < 5 THEN 'Junior'
            WHEN years_experience BETWEEN 5 AND 10 THEN 'Mid-Level'
            ELSE 'Senior'
        END AS experience_segment
    FROM drivers_age
)
SELECT 
    age_segment,
    experience_segment,
    COUNT(driver_id) AS total_drivers
FROM segmentation
GROUP BY age_segment, experience_segment
ORDER BY age_segment, total_drivers DESC;

-- ============================================================================

-- 2. Customer Revenue Statistical Profile (Dispersion Analysis)
SELECT 
    ROUND(AVG(annual_revenue_potential), 2) AS mean_revenue,
    
    -- Computes the exact continuous Median (50th percentile). 
    -- This is crucial for financial data as it provides a realistic central tendency that is not skewed by extreme outliers (unlike the mean).
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY annual_revenue_potential ASC) AS median_revenue,
    
    MAX(annual_revenue_potential) AS max_revenue,
    MIN(annual_revenue_potential) AS min_revenue,
    
    -- Calculates the Standard Deviation to measure revenue volatility and how widely customer revenues are dispersed around the mean.
    ROUND(STDDEV(annual_revenue_potential), 2) AS standard_deviation
FROM dim_customers;
