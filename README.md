# 🏦 Bank Loan Analysis — Dashboard & SQL Ad Hoc Analysis

![Banner](https://img.shields.io/badge/Tools-SQL%20%7C%20Power%20BI-blue)
![Status](https://img.shields.io/badge/Status-Completed-brightgreen)
![License](https://img.shields.io/badge/License-MIT-yellow)

## 📌 Project Overview

This project provides a **comprehensive analysis of bank loan data** using:
- **SQL** — for ad hoc querying, KPI generation, and data validation
- **Power BI / Tableau** — for interactive dashboard visualization

The goal is to monitor lending activities, track key performance indicators,
and derive actionable insights for data-driven decision-making.

---

## 🗂️ Table of Contents
- [Problem Statement](#-problem-statement)
- [Dashboards](#-dashboards)
- [SQL Ad Hoc Analysis](#-sql-ad-hoc-analysis)
- [Key Metrics & KPIs](#-key-metrics--kpis)
- [Tools Used](#️-tools-used)
- [How to Use](#-how-to-use)
- [Key Insights](#-key-insights)
- [Contact](#-contact)

---

## 🎯 Problem Statement

The bank needs to monitor and assess its lending activities and performance.
This project creates a **Bank Loan Report** that provides insights into:
- Total loan applications, funded amounts, and amounts received
- Average interest rates and debt-to-income (DTI) ratios
- Trends by month, state, loan term, employee length, purpose, and
  home ownership
- Loan status distribution across the portfolio

---

## 📊 Dashboards

### 1️⃣ Summary Dashboard
> High-level KPIs with Month-over-Month (MoM) and Month-to-Date (MTD)
> tracking.

![Summary Dashboard](Dashboard/Screenshots/Summary_Dashboard.png)

**Key KPIs:**
| KPI | Description |
|-----|-------------|
| Total Loan Applications | Total + MTD + MoM % change |
| Total Funded Amount | Total disbursed + MTD + MoM |
| Total Amount Received | Total repayments + MTD + MoM |
| Avg Interest Rate | Average across all loans + MTD + MoM |
| Avg DTI | Average Debt-to-Income ratio + MTD + MoM |

---

### 2️⃣ Overview Dashboard
> Visual analytics with multiple chart types for trend and
> dimensional analysis.

![Overview Dashboard](Dashboard/Screenshots/Overview_Dashboard.png)

| Chart | Purpose |
|-------|---------|
| 📈 Line Chart | Monthly Trends by Issue Date |
| 🗺️ Filled Map | Regional Analysis by State |
| 🍩 Donut Chart | Loan Term Distribution (36 vs 60 months) |
| 📊 Bar Chart | Employee Length Analysis |
| 🎯 Bar Chart | Loan Purpose Breakdown |
| 🏠 Tree Map | Home Ownership Analysis |

---

### 3️⃣ Details Dashboard
> Granular, table-based view serving as a holistic snapshot of all
> key loan metrics and borrower profiles.

![Details Dashboard](Dashboard/Screenshots/Details_Dashboard.png)

---

## 🛢️ SQL Ad Hoc Analysis

All SQL queries used for data extraction, KPI calculation, and dashboard
validation are available in
[`SQL_Analysis/Bank_Loan_Ad_Hoc_Analysis.sql`](SQL_Analysis/Bank_Loan_Ad_Hoc_Analysis.sql)

### Queries Include:

#### 📌 A. Key Performance Indicators (KPIs)

```sql
-- 1. Total Loan Applications
SELECT COUNT(id) AS Total_Loan_Applications FROM bank_loan_data;

-- 2. MTD Loan Applications
SELECT COUNT(id) AS MTD_Total_Loan_Applications
FROM bank_loan_data
WHERE MONTH(issue_date) = 12 AND YEAR(issue_date) = 2021;

-- 3. PMTD Loan Applications
SELECT COUNT(id) AS PMTD_Total_Loan_Applications
FROM bank_loan_data
WHERE MONTH(issue_date) = 11 AND YEAR(issue_date) = 2021;

-- 4. Total Funded Amount
SELECT SUM(loan_amount) AS Total_Funded_Amount FROM bank_loan_data;

-- 5. MTD Total Funded Amount
SELECT SUM(loan_amount) AS MTD_Total_Funded_Amount
FROM bank_loan_data
WHERE MONTH(issue_date) = 12 AND YEAR(issue_date) = 2021;

-- 6. Total Amount Received
SELECT SUM(total_payment) AS Total_Amount_Received FROM bank_loan_data;

-- 7. MTD Total Amount Received
SELECT SUM(total_payment) AS MTD_Total_Amount_Received
FROM bank_loan_data
WHERE MONTH(issue_date) = 12 AND YEAR(issue_date) = 2021;<span class="ml-2" /><span class="inline-block w-3 h-3 rounded-full bg-neutral-a12 align-middle mb-[0.1rem]" />
