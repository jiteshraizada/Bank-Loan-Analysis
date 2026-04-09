# 🏦 Bank Loan Default Analysis — Dashboard & SQL Ad Hoc Analysis

![Banner](https://img.shields.io/badge/Tools-SQL%20%7C%20Power%20BI-blue)
![Status](https://img.shields.io/badge/Status-Completed-brightgreen)
![License](https://img.shields.io/badge/License-MIT-yellow)

## 📌 Project Overview

This project provides a **comprehensive analysis of bank loan data**
focused on understanding **loan defaults, borrower profiles, and risk
assessment** using:
- **SQL** — for ad hoc querying, KPI generation, and data exploration
- **Power BI** — for interactive dashboard visualization

The goal is to identify key factors driving loan defaults, analyze
borrower demographics, and validate the risk scoring model for
data-driven lending decisions.

---

## 🗂️ Table of Contents
- [Problem Statement](#-problem-statement)
- [Dashboards](#-dashboards)
- [SQL Ad Hoc Analysis](#-sql-ad-hoc-analysis)
- [Key Insights](#-key-insights)
- [Tools Used](#️-tools-used)
- [How to Use](#-how-to-use)
- [Contact](#-contact)

---

## 🎯 Problem Statement

The bank needs to understand its loan portfolio performance and identify
the key drivers behind loan defaults. This project analyzes:
- Overall portfolio health — total borrowers, loan amounts, default rates
- Borrower demographics — age, gender, employment status, income
- Credit & risk factors — credit tier, DTI tier, loan grade, risk score
- Loan characteristics — purpose, term, interest rates
- Risk model validation — evaluating the composite risk scoring model

---

## 📊 Dashboards

### 1️⃣ Loan Portfolio Overview
> High-level portfolio snapshot with default rate analysis by loan purpose.

![Loan Portfolio Overview](Dashboard/Screenshots/Loan_Portfolio_Overview.png)

**Key KPIs:**
| KPI | Value |
|-----|-------|
| Total Borrowers | 20,000 |
| Total Loan Amount | \$302,586,018 |
| Avg Interest Rate | 12.40% |
| Default Rate | 20.01% |
| Average Credit Score | 679.26 |
| Average Income | \$43,549.6 |

**Visuals:**
| Chart | Purpose |
|-------|---------|
| 🍩 Donut Chart | Total Borrowers by Loan Status (Paid Back vs Defaulted) |
| 📊 Bar Chart | Default Rate by Loan Purpose |
| 📋 Table | Loan Purpose breakdown — Avg Interest Rate, Default Rate, Total Loan |

**Filters:** Risk Category, Employment Status, Loan Term

---

### 2️⃣ Borrower Profile
> Deep dive into borrower demographics and their impact on default rates.

![Borrower Details Dashboard](Dashboard/Screenshots/Borrower_Details_Dashboard.png)

**Key KPIs:**
| KPI | Value |
|-----|-------|
| Average DTI | 17.70 |
| Average Age | 48.03 |
| Avg Total Accounts | 5.01 |

**Visuals:**
| Chart | Purpose |
|-------|---------|
| 📊 Bar Chart | Default Rate by Credit Tier (Excellent to Very Poor) |
| 📊 Stacked Bar Chart | Default Rate & Paid Back Rate by Employment Status |
| 🍩 Donut Chart | Total Borrowers by Gender (Male, Female, Other) |
| 📊 Bar Chart | Default Rate by DTI Tier (Low to Critical) |
| 📊 Bar Chart | Default Rate by Loan Grade (A to F) |

**Filters:** Risk Category, Employment Status, Loan Term

---

### 3️⃣ Risk Analysis Dashboard
> Risk model validation with default rate analysis across risk categories
> and risk scores.

![Risk Analysis Dashboard](Dashboard/Screenshots/Risk_Analysis_Dashboard.png)

**Key KPIs:**
| KPI | Value |
|-----|-------|
| Average Risk Score | 6.67 |
| High Risk Default Rate | 43.46% |
| Very High Risk Default Rate | 91.21% |
| Borrowers with Low Risk | 2,298 |

**Visuals:**
| Chart | Purpose |
|-------|---------|
| 🍩 Donut Chart | Total Borrowers by Risk Category (Low, Medium, High, Very High) |
| 📊 Bar Chart | Default Rate by Risk Category |
| 📈 Line Chart | Default Rate by Risk Score |
| 📋 Table | Risk Category — Defaulted Count, Paid Back Count, Total Borrowers |

**Risk Model Validation:**
> Borrowers classified as Very High Risk show 91.2% default rate compared
> to 0.1% for Low Risk borrowers — a 91 percentage point difference,
> confirming strong predictive accuracy of the composite risk scoring model.

**Filters:** Risk Category, Employment Status, Loan Term, DTI Tier, Credit Tier

---

## 🛢️ SQL Ad Hoc Analysis

All SQL queries used for data extraction, KPI calculation, and analysis
are available in
[`SQL_Analysis/Bank_Loan_Ad_Hoc_Analysis.sql`](SQL_Analysis/Bank_Loan_Ad_Hoc_Analysis.sql)

### Queries Include:

#### 📌 A. Portfolio Level KPIs

```sql
-- Total Borrowers
SELECT COUNT(*) AS Total_Borrowers FROM bank_loan_data;

-- Total Loan Amount
SELECT SUM(loan_amount) AS Total_Loan_Amount FROM bank_loan_data;

-- Average Interest Rate
SELECT ROUND(AVG(interest_rate), 2) AS Avg_Interest_Rate FROM bank_loan_data;

-- Overall Default Rate
SELECT
    ROUND(COUNT(CASE WHEN loan_status = 'Defaulted' THEN 1 END) * 100.0
    / COUNT(*), 2) AS Default_Rate
FROM bank_loan_data;

-- Average Credit Score
SELECT ROUND(AVG(credit_score), 2) AS Avg_Credit_Score FROM bank_loan_data;

-- Average Income
SELECT ROUND(AVG(income), 2) AS Avg_Income FROM bank_loan_data;
