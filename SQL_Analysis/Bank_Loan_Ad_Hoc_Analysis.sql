-- ============================================================
-- LOAN DATA ANALYSIS - DATABASE SCHEMA & RISK ANALYTICS
-- ============================================================
-- This script:
--   1. Normalizes a monolithic loan_data table into 4 relational tables
--   2. Performs loan performance & risk analysis
--   3. Builds a custom multi-factor risk scoring model
--   4. Generates a portfolio-level executive summary
-- ============================================================


-- ============================================================
-- SECTION 1: SCHEMA SETUP - NORMALIZATION OF loan_data
-- ============================================================

-- Adding a unique auto-incrementing primary key to the source table.
-- SERIAL generates sequential integers automatically for each row.
-- This applicant_id will serve as the foreign key across all child tables.
ALTER TABLE loan_data ADD COLUMN applicant_id SERIAL PRIMARY KEY;


-- ------------------------------------------------------------
-- Table: applicants
-- Purpose: Stores demographic/personal info about each borrower
-- Grain: One row per applicant
-- ------------------------------------------------------------
CREATE TABLE applicants AS 
SELECT
    applicant_id,          -- Unique identifier (FK to loan_data)
    age,                   -- Age of the applicant
    gender,                -- Gender of the applicant
    marital_status,        -- Marital status (e.g., Single, Married)
    education_level,       -- Highest education attained
    employment_status      -- Current employment type (e.g., Employed, Unemployed, Student)
FROM loan_data;


-- ------------------------------------------------------------
-- Table: financial_profile
-- Purpose: Stores financial health indicators for each borrower
-- Grain: One row per applicant
-- ------------------------------------------------------------
CREATE TABLE financial_profile AS 
SELECT
    applicant_id,          -- FK linking back to the applicant
    annual_income,         -- Yearly income of the borrower
    monthly_income,        -- Monthly income of the borrower
    credit_score,          -- Credit score (typically 300–850 range)
    debt_to_income_ratio   -- Ratio of total debt payments to income (0.0 – 1.0+)
FROM loan_data;


-- ------------------------------------------------------------
-- Table: loan_applications
-- Purpose: Stores loan-specific details and repayment outcome
-- Grain: One row per loan application
-- ------------------------------------------------------------
CREATE TABLE loan_applications AS 
SELECT
    applicant_id,          -- FK linking back to the applicant
    loan_amt,              -- Loan amount requested/approved
    loan_purpose,          -- Purpose of the loan (e.g., Education, Home, Auto)
    interest_rate,         -- Interest rate assigned to the loan
    loan_term,             -- Duration of the loan (in months or years)
    grade_subgrade,        -- Internal risk grade assigned (e.g., A1, B2, D3)
    loan_paid_back         -- Outcome flag: 1 = Repaid, 0 = Defaulted
FROM loan_data;


-- ------------------------------------------------------------
-- Table: credit_history
-- Purpose: Stores historical credit behavior for each borrower
-- Grain: One row per applicant
-- ------------------------------------------------------------
CREATE TABLE credit_history AS 
SELECT
    applicant_id,          -- FK linking back to the applicant
    num_of_open_accounts,  -- Number of currently open credit accounts
    total_credit_limit,    -- Aggregate credit limit across all accounts
    deliquency_history,    -- Record of past-due payments
    public_records         -- Public records (e.g., bankruptcies, liens)
FROM loan_data;


-- ============================================================
-- SECTION 2: EXPLORATORY ANALYSIS - LOAN PERFORMANCE
-- ============================================================


-- ------------------------------------------------------------
-- Query 1: Overall Loan Performance Summary
-- Purpose: Get a high-level view of repayment vs default
-- Key Metric: Default benchmark rate for the entire portfolio
-- ------------------------------------------------------------
SELECT 
    la.loan_paid_back,                                          -- 1 = Repaid, 0 = Defaulted
    SUM(la.loan_amt) AS loan_amount,                            -- Total loan value per category
    COUNT(la.applicant_id) AS total_loans,                      -- Count of loans per category
    ROUND(COUNT(*) * 100 / SUM(COUNT(*)) OVER(), 2) AS percentage  -- Percentage share using window function
FROM loan_applications la 
GROUP BY la.loan_paid_back;
-- Insight: Establishes the baseline default benchmark rate for the portfolio


-- ------------------------------------------------------------
-- Query 2: Default Rate by Loan Purpose
-- Purpose: Identify which loan purposes carry the highest risk
-- Key Metric: Default rate per loan purpose category
-- ------------------------------------------------------------
SELECT 
    la.loan_purpose,                                                             -- Category of loan purpose
    COUNT(*) AS total,                                                           -- Total loans for that purpose
    SUM(CASE WHEN la.loan_paid_back = 0 THEN 1 ELSE 0 END) AS defaults,         -- Count of defaulted loans
    ROUND(
        100 * SUM(CASE WHEN loan_paid_back = 0 THEN 1 ELSE 0 END) / COUNT(*), 2
    ) AS default_rate                                                            -- Default rate as a percentage
FROM loan_applications la 
GROUP BY la.loan_purpose 
ORDER BY default_rate DESC;
-- Insight: Education loans emerge as the riskiest loan purpose


-- ============================================================
-- SECTION 3: CREDIT & FINANCIAL RISK ANALYSIS
-- ============================================================


-- ------------------------------------------------------------
-- Query 3: Interest Rate vs Default Rate by Credit Tier
-- Purpose: Examine how credit score tiers correlate with
--          both the interest rate charged and default behavior
-- ------------------------------------------------------------
SELECT
    -- Bucketing credit scores into meaningful tiers
    CASE 
        WHEN fp.credit_score >= 750 THEN 'Excellent (750+)'
        WHEN fp.credit_score >= 700 THEN 'Good (700-749)'
        WHEN fp.credit_score >= 650 THEN 'Fair (650-699)'
        WHEN fp.credit_score >= 600 THEN 'Poor (600-649)'
        ELSE 'Very Poor (<600)'
    END AS credit_tier,
    ROUND(AVG(la.interest_rate), 2) AS avg_interest_rate,      -- Average interest rate per tier
    ROUND(
        AVG(CASE WHEN loan_paid_back = 0 THEN 1 ELSE 0 END) * 100, 2
    ) AS default_rate                                          -- Default rate per tier (as %)
FROM financial_profile fp 
JOIN loan_applications la ON fp.applicant_id = la.applicant_id 
GROUP BY credit_tier 
ORDER BY avg_interest_rate;
-- Insight: As credit score decreases, both interest rate and default rate increase


-- ------------------------------------------------------------
-- Query 4: Debt-to-Income (DTI) Impact on Defaults
-- Purpose: Analyze how DTI ratio levels affect borrower
--          default behavior and average loan size
-- ------------------------------------------------------------
SELECT	
    -- Bucketing DTI ratios into risk tiers
    CASE 
        WHEN debt_to_income_ratio <= 0.1 THEN 'Low (<=10%)'
        WHEN debt_to_income_ratio <= 0.2 THEN 'Moderate (10-20%)'
        WHEN debt_to_income_ratio <= 0.3 THEN 'High (20-30%)'
        WHEN debt_to_income_ratio <= 0.4 THEN 'Very High (30-40%)'
        ELSE 'Critical (>40%)'
    END AS dti_tier,
    COUNT(*) AS borrowers,                                     -- Number of borrowers in each tier
    ROUND(AVG(la.loan_amt), 2) AS avg_loan,                   -- Average loan amount per tier
    ROUND(
        100 * SUM(CASE WHEN loan_paid_back = 0 THEN 1 ELSE 0 END) / COUNT(*), 2
    ) AS default_rate                                          -- Default rate per DTI tier
FROM financial_profile fp 
JOIN loan_applications la ON fp.applicant_id = la.applicant_id 
GROUP BY dti_tier 
ORDER BY MIN(fp.debt_to_income_ratio);                         -- Orders tiers from lowest to highest DTI
-- Insight: Default rate increases proportionally as DTI ratio increases


-- ============================================================
-- SECTION 4: MULTI-FACTOR RISK SCORING MODEL
-- ============================================================


-- ------------------------------------------------------------
-- Query 5: Aggregated Risk Score Analysis
-- Purpose: Build a composite risk score (3–12) from three 
--          independent risk factors and validate it against
--          actual default rates
-- Scoring Logic:
--   • DTI Risk:        1 (low) to 4 (critical)
--   • Credit Risk:     1 (excellent) to 4 (poor)
--   • Employment Risk: 1 (employed) to 4 (unemployed)
--   • Total Range:     3 (safest) to 12 (riskiest)
-- ------------------------------------------------------------
WITH risk_profile AS (
    SELECT 
        a.applicant_id,
        a.age,
        a.employment_status,
        a.education_level,
        fp.credit_score,
        fp.debt_to_income_ratio,
        loan_applications.loan_paid_back,
        loan_applications.loan_amt,

        -- DTI Risk: Higher DTI = higher risk score
        CASE
            WHEN fp.debt_to_income_ratio > 0.4 THEN 4    -- Critical DTI
            WHEN fp.debt_to_income_ratio > 0.3 THEN 3    -- Very high DTI
            WHEN fp.debt_to_income_ratio > 0.2 THEN 2    -- Moderate DTI
            ELSE 1                                        -- Low/safe DTI
        END AS dti_risk,

        -- Credit Risk: Lower credit score = higher risk score
        CASE
            WHEN fp.credit_score > 750 THEN 1             -- Excellent credit
            WHEN fp.credit_score > 700 THEN 2             -- Good credit
            WHEN fp.credit_score > 650 THEN 3             -- Fair credit
            ELSE 4                                         -- Poor credit
        END AS credit_risk,

        -- Employment Risk: Less stable employment = higher risk score
        CASE
            WHEN a.employment_status LIKE 'Unemployed'    THEN 4  -- Highest risk
            WHEN a.employment_status LIKE 'Student'       THEN 3  -- High risk
            WHEN a.employment_status LIKE 'Self Employed' THEN 2  -- Moderate risk
            ELSE 1                                                -- Low risk (Employed/Full-time)
        END AS employment_risk

    FROM applicants a
    JOIN financial_profile fp ON a.applicant_id = fp.applicant_id 
    JOIN loan_applications ON fp.applicant_id = loan_applications.applicant_id 
)
-- Aggregate by total risk score to see how well the model predicts defaults
SELECT
    (credit_risk + dti_risk + employment_risk) AS total_risk_score,  -- Composite score (3–12)
    COUNT(*) AS borrowers,                                           -- Borrowers at each score level
    ROUND(
        100 * SUM(CASE WHEN loan_paid_back = 0 THEN 1 ELSE 0 END) / COUNT(*), 2
    ) AS actual_default_rate,                                        -- Observed default rate
    ROUND(AVG(loan_amt), 2) AS avg_loan_exposure                    -- Average loan amount at risk
FROM risk_profile
GROUP BY total_risk_score
ORDER BY total_risk_score DESC;
-- Custom ranking system: Validates that higher composite scores align with higher default rates


-- ------------------------------------------------------------
-- Query 6: Risk Categorization by Individual Applicant
-- Purpose: Assign each applicant a risk score AND a human-readable
--          risk category label for downstream use (dashboards, reports)
-- Categories:
--   • Very High Risk: Defaulted + score > 10
--   • High Risk:      Defaulted + score > 7
--   • Moderate Risk:  Defaulted + score > 4
--   • Low Risk:       All others (repaid or low score)
-- ------------------------------------------------------------
WITH risk_profile AS (
    SELECT 
        a.applicant_id,
        a.age,
        a.employment_status,
        a.education_level,
        fp.credit_score,
        fp.debt_to_income_ratio,
        loan_applications.loan_paid_back,
        loan_applications.loan_amt,

        -- DTI Risk scoring (same logic as Query 5)
        CASE
            WHEN fp.debt_to_income_ratio > 0.4 THEN 4
            WHEN fp.debt_to_income_ratio > 0.3 THEN 3
            WHEN fp.debt_to_income_ratio > 0.2 THEN 2
            ELSE 1
        END AS dti_risk,

        -- Credit Risk scoring (same logic as Query 5)
        CASE
            WHEN fp.credit_score > 750 THEN 1
            WHEN fp.credit_score > 700 THEN 2
            WHEN fp.credit_score > 650 THEN 3
            ELSE 4
        END AS credit_risk,

        -- Employment Risk scoring (same logic as Query 5)
        CASE
            WHEN a.employment_status LIKE 'Unemployed'    THEN 4
            WHEN a.employment_status LIKE 'Student'       THEN 3
            WHEN a.employment_status LIKE 'Self Employed' THEN 2
            ELSE 1
        END AS employment_risk

    FROM applicants a
    JOIN financial_profile fp ON a.applicant_id = fp.applicant_id 
    JOIN loan_applications ON fp.applicant_id = loan_applications.applicant_id 
)
SELECT
    applicant_id,
    (credit_risk + dti_risk + employment_risk) AS total_risk_score,    -- Composite score (range: 3 to 12)
    -- Loan outcome as a readable label
    CASE 
        WHEN loan_paid_back = 0 THEN 'Default' 
        ELSE 'Repaid' 
    END AS actual_default_rate,
    loan_amt AS loan_exposure,                                          -- Dollar amount at risk
    -- Risk category: Combines actual outcome with composite score
    CASE 
        WHEN loan_paid_back = 0 AND credit_risk + dti_risk + employment_risk > 10 THEN 'Very High Risk'
        WHEN loan_paid_back = 0 AND credit_risk + dti_risk + employment_risk > 7  THEN 'High Risk'
        WHEN loan_paid_back = 0 AND credit_risk + dti_risk + employment_risk > 4  THEN 'Moderate Risk'
        ELSE 'Low Risk'
    END AS risk_category                                                -- Human-readable risk label
FROM risk_profile
ORDER BY total_risk_score DESC, loan_exposure DESC;
-- Loan risk categorization: Each applicant tagged with score + risk label


-- ============================================================
-- SECTION 5: PEER COMPARISON USING WINDOW FUNCTIONS
-- ============================================================


-- ------------------------------------------------------------
-- Query 7: Rank Borrowers Within Their Credit Grade
-- Purpose: Compare borrowers against peers in the same grade
--          using income rank and credit score percentile
-- Filter: Grade D borrowers only (higher risk segment)
-- Limit:  Top 20 results for quick inspection
-- ------------------------------------------------------------
SELECT 
    a.applicant_id,
    a.employment_status,
    la.grade_subgrade,
    fp.annual_income,
    fp.credit_score,

    -- RANK(): Assigns rank by income within each grade subgrade
    -- Ties get the same rank; next rank is skipped
    RANK() OVER (
        PARTITION BY la.grade_subgrade 
        ORDER BY fp.annual_income DESC
    ) AS income_rank_in_grade,

    -- PERCENT_RANK(): Shows how good (or bad) an applicant's credit score is
    -- relative to peers in the same grade subgrade (0% = worst, 100% = best)
    ROUND(
        (PERCENT_RANK() OVER (
            PARTITION BY la.grade_subgrade 
            ORDER BY fp.credit_score DESC
        ) * 100)::NUMERIC, 2
    ) AS credit_percentile

FROM applicants a
JOIN financial_profile fp ON a.applicant_id = fp.applicant_id
JOIN loan_applications la ON a.applicant_id = la.applicant_id
WHERE la.grade_subgrade LIKE 'D%'    -- Filter: Only Grade D (high-risk) borrowers
LIMIT 20;
-- Ranks top 20 Grade-D applicants by income and shows their credit standing among peers


-- ============================================================
-- SECTION 6: EXECUTIVE SUMMARY - PORTFOLIO OVERVIEW
-- ============================================================


-- ------------------------------------------------------------
-- Query 8: One Query That Tells the Whole Story
-- Purpose: Provide a side-by-side comparison of the full portfolio
--          vs. the high-risk segment (credit < 600 AND DTI > 0.3)
-- Output: Two rows — one for overall portfolio, one for high-risk
-- Use Case: Executive dashboards, board-level reporting
-- ------------------------------------------------------------

-- Row 1: Full portfolio overview
SELECT 
    'Portfolio_Overview' AS metric_category,                         -- Label for this summary row
    COUNT(DISTINCT a.applicant_id) AS total_borrowers,               -- Unique borrowers in portfolio
    ROUND(SUM(la.loan_amt), 2) AS loan_exposure,                    -- Total outstanding loan value
    ROUND(AVG(la.interest_rate), 2) AS avg_interest_rate,            -- Portfolio-wide avg interest rate
    ROUND(
        100 * SUM(CASE WHEN la.loan_paid_back = 0 THEN 1 ELSE 0 END) / COUNT(*), 2
    ) AS default_rate                                                -- Portfolio-wide default rate
FROM applicants a 
JOIN loan_applications la ON a.applicant_id = la.applicant_id 

UNION ALL 

-- Row 2: High-risk segment (poor credit AND high DTI)
SELECT 
    'High Risk (Credit < 600 and DTI > 0.3)' AS metric_category,    -- Label for high-risk segment
    COUNT(DISTINCT a.applicant_id) AS total_borrowers,
    ROUND(SUM(la.loan_amt), 2) AS loan_exposure,
    ROUND(AVG(la.interest_rate), 2) AS avg_interest_rate,
    ROUND(
        100 * SUM(CASE WHEN la.loan_paid_back = 0 THEN 1 ELSE 0 END) / COUNT(*), 2
    ) AS default_rate
FROM applicants a 
JOIN loan_applications la ON a.applicant_id = la.applicant_id 
JOIN financial_profile fp ON la.applicant_id = fp.applicant_id 
WHERE fp.credit_score < 600                                          -- Filter: Poor credit scores
  AND fp.debt_to_income_ratio > 0.3;                                 -- Filter: High debt burden
-- Summary: Compares full portfolio health against the highest-risk borrower segment
-- Useful for quantifying how much risk the high-risk segment contributes to the whole
