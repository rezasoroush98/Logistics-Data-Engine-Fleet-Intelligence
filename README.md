# 🚛 Freight & Fleet Analytics: An End-to-End SQL Portfolio

![SQL](https://img.shields.io/badge/SQL-PostgreSQL-blue?style=for-the-badge&logo=postgresql)
![Data Analysis](https://img.shields.io/badge/Data_Analysis-Business_Intelligence-success?style=for-the-badge)
![Logistics](https://img.shields.io/badge/Domain-Logistics_&_Supply_Chain-orange?style=for-the-badge)

## 📌 Project Overview
Welcome to my SQL portfolio project. This repository is not just a collection of queries; it's a complete **data-driven audit of a hypothetical logistics and transportation network**. 

The goal of this project is to demonstrate how raw relational data (trucks, drivers, fuel purchases, safety incidents, and routes) can be transformed into actionable business intelligence to **reduce operational costs, optimize asset lifecycles, and identify financial leakage**.

## 🧠 Business Questions Answered
Through advanced SQL, I tackled real-world logistics challenges:
* **Financial Forensics:** Where are we losing money on fuel purchases compared to company benchmarks?
* **Asset Management:** At what age or mileage do certain truck brands become too expensive to maintain (MCPM)?
* **Operational Efficiency:** Which facilities cause the highest driver detention times?
* **Safety Impact:** What is the true bottom-line financial impact of safety incidents across specific lanes?

---

## 📂 Repository Structure

The project is structured logically into four main phases, mirroring a real-world analytics workflow:

### `01_Schema_&_Data_Dictionary/`
The foundation of the project. Contains the DDL (Data Definition Language) scripts to build the relational database, define primary/foreign keys, and map out the Star Schema architecture.

### `02_Operational_Deep_Dives/`
Focused on the day-to-day logistics operations.
* **Highlights:** Facility efficiency matrices (using `CUBE` for multidimensional roll-ups), route profitability analysis, and customer booking strategies.

### `03_Financial_&_Fuel_Forensics/`
The "bottom-line" directory. Focused on cost reduction and asset depreciation.
* **Highlights:** Calculating Maintenance Cost Per Mile (MCPM), detecting fuel consumption anomalies (fraud detection), and CapEx vs. OpEx evaluations for aging fleets.

### `04_Exploratory_Analysis/`
Pre-analysis steps including Data Quality checks and Exploratory Data Analysis (EDA).
* **Highlights:** Using statistical functions (`STDDEV`, `PERCENTILE_CONT`, `VAR_POP`) to measure cost dispersion, and identifying missing IDs or logical anomalies in legacy data.

---

## 🛠️ SQL Techniques & Skills Demonstrated
To extract these insights, I heavily utilized advanced PostgreSQL features:
* **Complex Joins & Aggregations:** Connecting multiple Fact and Dimension tables.
* **Window Functions:** `LAG()`, `OVER()`, and `PARTITION BY` for Month-over-Month (MoM) growth and trend analysis.
* **Advanced Grouping:** `CUBE` and `ROLLUP` for multi-level management reporting.
* **Statistical Functions:** Calculating exact medians (`PERCENTILE_CONT`) instead of averages to handle data outliers in financial metrics.
* **Data Cleaning:** `FILTER (WHERE...)`, CTEs, and conditional formatting (`CASE WHEN`) to segment data and flag anomalies.

---

## 🚀 How to Navigate
If you only have 3 minutes, I highly recommend reviewing these two files to see my best work:
1. `03_Financial_&_Fuel_Forensics/Fuel_Price_Variance_&_Lost_Money.sql` *(Demonstrates financial logic and anomaly detection)*
2. `03_Financial_&_Fuel_Forensics/Fleet_Maintenance_Financial_Audit.sql` *(Demonstrates advanced joins, CTEs, and KPI generation)*

---

## 📬 Let's Connect
I'm always open to discussing data, supply chain analytics, or new opportunities.

* **Author:** [Your Name / رضا ...]
* **LinkedIn:** [Insert Your LinkedIn URL]
* **Email:** [Insert Your Email]
