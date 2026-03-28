# Logistics Operations Analytics: SQL Portfolio

This repository showcases an end-to-end SQL analysis of a freight and logistics network. The primary focus of this project is on unit economics, operational bottlenecks, and financial auditing using raw relational data.

## Data Source
The queries in this repository are built on the **Logistics Operations Database**. The original schema and raw tables can be found on Kaggle:  
[Logistics Operations Database on Kaggle](https://www.kaggle.com/datasets/yogape/logistics-operations-database)
## Database Schema & Architecture
The underlying data architecture follows a Star Schema design, consisting of central Fact tables (Trips, Loads, Deliveries, Finances) connected to multiple Dimension tables (Assets, Locations, Personnel).

## Database Schema & Architecture
The underlying data architecture follows a Star Schema design, consisting of central Fact tables (Trips, Loads, Deliveries, Finances) connected to multiple Dimension tables (Assets, Locations, Personnel).

```mermaid
erDiagram
    CUSTOMERS {
        string customer_id PK
        string customer_name
        string customer_type
    }
    ROUTES {
        string route_id PK
        string origin_city
        string destination_city
    }
    LOADS {
        string load_id PK
        string customer_id FK
        string route_id FK
    }
    TRIPS {
        string trip_id PK
        string load_id FK
        string driver_id FK
        string truck_id FK
        string trailer_id FK
    }
    DRIVERS {
        string driver_id PK
        string first_name
        string last_name
    }
    TRUCKS {
        string truck_id PK
        string make
        string model_year
    }
    TRAILERS {
        string trailer_id PK
        string trailer_type
    }
    FUEL_PURCHASES {
        string fuel_purchase_id PK
        string trip_id FK
        numeric total_cost
    }
    MAINTENANCE_RECORDS {
        string maintenance_id PK
        string truck_id FK
        numeric total_cost
    }
    DELIVERY_EVENTS {
        string event_id PK
        string trip_id FK
        boolean on_time_flag
    }
    SAFETY_INCIDENTS {
        string incident_id PK
        string trip_id FK
        numeric claim_amount
    }

    CUSTOMERS ||--o{ LOADS : "places"
    ROUTES ||--o{ LOADS : "assigned to"
    LOADS ||--|| TRIPS : "fulfilled by"
    DRIVERS ||--o{ TRIPS : "drives"
    TRUCKS ||--o{ TRIPS : "used in"
    TRAILERS ||--o{ TRIPS : "pulled in"
    TRIPS ||--o{ FUEL_PURCHASES : "incurs"
    TRUCKS ||--o{ MAINTENANCE_RECORDS : "undergoes"
    TRIPS ||--o{ DELIVERY_EVENTS : "tracks"
    TRIPS ||--o{ SAFETY_INCIDENTS : "records"
<details>
<summary><b>📋 Click to expand: Data Dictionary & Relationships</b></summary>

### Key Entities:
* **Fact Tables:** `LOADS`, `TRIPS`, `FUEL_PURCHASES`, `MAINTENANCE_RECORDS`, `DELIVERY_EVENTS`, `SAFETY_INCIDENTS`
* **Dimension Tables:** `DRIVERS`, `TRUCKS`, `TRAILERS`, `CUSTOMERS`, `FACILITIES`, `ROUTES`

### Core Relationships:
* `loads` -> `customers` (many-to-one)
* `loads` -> `routes` (many-to-one)
* `trips` -> `loads` (one-to-one)
* `trips` -> `drivers`, `trucks`, `trailers` (many-to-one)
* `fuel_purchases`, `delivery_events`, `safety_incidents` -> `trips` (many-to-one)
* `maintenance_records` -> `trucks` (many-to-one)

</details>
## Project Structure

The repository is logically organized into four main directories:

### `01_Analytical_Master_Views`
Contains high-level, aggregated SQL views designed for executive reporting. 
* **Key areas:** Monthly fleet utilization metrics and driver performance tracking.

### `02_Operational_Deep_Dives`
Queries analyzing day-to-day logistics operations and network capacity. 
* **Key areas:** Driver detention times, facility efficiency matrix, YoY route profitability, and customer booking strategies.

### `03_Financial_&_Fuel_Forensics`
Focused on cost reduction, asset management, and financial auditing.
* **Key areas:** Calculating Maintenance Cost Per Mile (MCPM), fuel price variance mapping (identifying overpriced fuel purchases), fraud detection, and the financial impact of safety incidents.

### `04_Exploratory_Analysis`
Data quality checks and initial Exploratory Data Analysis (EDA).
* **Key areas:** Flagging missing foreign keys, identifying logical anomalies (e.g., trailers acquired before their build year), and statistical profiling using variance and medians.

## SQL Techniques Applied
* **Advanced Aggregations:** `CUBE` and `ROLLUP` for multi-dimensional reporting.
* **Window Functions:** `LAG()` and `OVER()` for Month-over-Month (MoM) cost growth tracking.
* **Statistical Functions:** `PERCENTILE_CONT`, `STDDEV`, and `VAR_POP` for cost dispersion and median analysis.
* **Data Cleansing:** Handling edge cases and missing data using `FILTER (WHERE...)`, `NULLIF`, and `CASE` statements.

## Quick Start
If you want to review a sample of the code, I recommend starting with these three queries which highlight my approach to financial, operational, and executive reporting:

1. **Financial Auditing:** `03_Financial_&_Fuel_Forensics/Fuel_Price_Variance_&_Lost_Money.sql` *(Demonstrates complex CTEs and cost leakage analysis)*
2. **Operational Efficiency:** `02_Operational_Deep_Dives/Facility_Efficiency_Matrix.sql` *(Uses CUBE and ROLLUP for multidimensional performance tracking)*
3. **Executive Master Views:** `01_Analytical_Master_Views/Monthly_Fleet_Utilization.sql` *(High-level aggregations for management dashboards)*

---
**Contact:** [Reza Asgari Soroush] | [https://www.linkedin.com/in/reza-asgari-soroush-251590198]
