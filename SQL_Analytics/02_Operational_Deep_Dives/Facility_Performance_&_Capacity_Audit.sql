/* ============================================================================
   FACILITY CAPACITY & OPERATIONAL AUDIT
   ============================================================================
   Description:
   Comprehensive analysis of facility infrastructure, dock door capacity, 
   and geographic distribution across the logistics network.
   ============================================================================
*/

-- 1. Facility Type Distribution Profile
-- Understanding the scale and percentage of each facility category
select distinct facility_type , 
count(*) as number_of_each_type,
round((count(*) ::numeric / (select count(*)from dim_facilities) * 100),2) as percentage_of_each_type
from dim_facilities
group by facility_type
order by number_of_each_type desc
;
-- 2. Multi-dimensional Capacity Matrix (The "CUBE" Analysis)
-- Benchmarking dock door availability by City and Facility Type simultaneously
select 
COALESCE(facility_type,'ALL TYPES') AS facility_type,
COALESCE(city,'ALL CITIES') AS CITY,
count(*) as facility_count,
round(avg(dock_doors),2) as avg_dock_doors,
SUM(dock_doors) AS total_dock_capacity
from dim_facilities
group by cube(facility_type , city)
order by facility_count, avg_dock_doors desc
;
-- 3. Loading Dock Capacity Benchmarking
-- Statistical summary of infrastructure across different facility types
Select 
facility_type,
min(dock_doors)   AS min_doors,
max(dock_doors)   AS max_doors,
round(avg(dock_doors),2) avg_dock_doors
from dim_facilities
group by facility_type
order by avg_dock_doors
