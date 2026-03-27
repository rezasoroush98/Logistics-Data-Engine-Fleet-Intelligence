/* ============================================================================
   ASSET DEPRECIATION & CAPITAL EXPENDITURE (CAPEX) STRATEGY
   ============================================================================
   Description:
   Analyzes fleet age and acquisition mileage to inform the company's 
   asset replacement lifecycle and predict future capital expenditure needs.
   ============================================================================
*/

-- 1. Asset Depreciation & Replacement Cycle Audit
-- Evaluates the aging profile of the fleet to forecast upcoming replacement costs
WITH  Asset_Lifecycle  as (
    SELECT 
        truck_id,
        acquisition_mileage,
        EXTRACT(year FROM acquisition_date ) - model_year AS asset_age_years
FROM dim_trucks
)
SELECT 
    asset_age_years,
    COUNT(*) AS active_trucks_in_tier,
    ROUND(COUNT(*)::numeric/(SELECT count(*) FROM dim_trucks) * 100 ,2) AS  portfolio_percentage,
    -- KPI: Higher starting mileage accelerates depreciation and replacement needs
    ROUND(AVG(acquisition_mileage),2) AS avg_acquisition_mileage
FROM  Asset_Lifecycle 
GROUP BY asset_age_years
ORDER BY active_trucks_in_tier DESC
;

-- 2. CapEx vs OpEx: Fuel Efficiency by Asset Age
-- Analyzes how holding onto older assets impacts operating expenses (fuel consumption)
WITH Fleet_Efficiency AS (
    SELECT
        truck_id,
        EXTRACT(year FROM CURRENT_DATE) - model_year AS asset_age_years,
        CASE 
            WHEN tank_capacity_gallons >= 250 THEN 'High-Consumption (High OpEx)'
            WHEN tank_capacity_gallons <= 200 THEN 'Fuel-Efficient (Low OpEx)'
            ELSE 'Standard-Consumption' 
        END AS opex_efficiency_tier
    FROM dim_trucks
)
SELECT
    opex_efficiency_tier,
    COUNT(*) AS fleet_count,
    ROUND(avg(asset_age_years),2) AS avg_asset_age,
    ROUND(COUNT(*)::NUMERIC / (SELECT COUNT(*) FROM dim_trucks) * 100, 2) AS share_of_fleet_pct
    FROM Fleet_Efficiency 
group by opex_efficiency_tier
ORDER BY fleet_count DESC;
